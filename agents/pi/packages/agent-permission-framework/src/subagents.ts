import { Type } from "typebox";
import { Text } from "@earendil-works/pi-tui";
import {
  createAgentSession,
  DefaultResourceLoader,
  getAgentDir,
  SessionManager,
  SettingsManager,
  type ExtensionAPI,
  type ExtensionContext,
} from "@earendil-works/pi-coding-agent";
import type { AgentDefinition, SubagentRunRecord } from "./types.ts";
import { AgentRuntimeState, persistAudit, persistRuntime } from "./runtime.ts";
import { createUIApprovalBroker, enforceDecision, evaluateToolCall } from "./enforcement.ts";
import { withoutRecursiveFrameworkExtension } from "./extension-filter.ts";
import { evaluateDelegationPermission } from "./policy.ts";
import { shouldWaitForSubagentResult, waitForSubagentResult } from "./subagent-result-wait.ts";
import { finalSubagentStatus } from "./subagent-status.ts";
import { SubagentRegistry, type RunRecordInternal, type SubagentExecutorHelpers } from "./subagent-registry.ts";
export { SubagentRegistry } from "./subagent-registry.ts";

const AgentParams = Type.Object({
  prompt: Type.String({ description: "The task for the agent to perform." }),
  description: Type.String({ description: "A short (3-5 word) description of the task (shown in UI)." }),
  subagent_type: Type.String({ description: "The type of specialized agent to use." }),
  agent: Type.Optional(Type.String({ description: "Compatibility alias for subagent_type" })),
  task: Type.Optional(Type.String({ description: "Compatibility alias for prompt" })),
  model: Type.Optional(Type.String({ description: 'Optional model override. Accepts "provider/modelId" or fuzzy name. Omit to use the agent type default.' })),
  thinking: Type.Optional(Type.String({ description: "Thinking level: off, minimal, low, medium, high, xhigh. Overrides agent default." })),
  max_turns: Type.Optional(Type.Number({ description: "Maximum number of agentic turns before stopping. Omit for unlimited (default).", minimum: 1 })),
  run_in_background: Type.Optional(Type.Boolean({ description: "Set to true to run in background. Returns agent ID immediately. You will be notified on completion." })),
  resume: Type.Optional(Type.String({ description: "Optional agent ID to resume from. Continues from previous context when the session is still available." })),
  inherit_context: Type.Optional(Type.Boolean({ description: "If true, fork parent conversation into the agent. Default: false (fresh context)." })),
  inherit_extensions: Type.Optional(Type.Boolean({ description: "Compatibility option for extension inheritance." })),
  inherit_skills: Type.Optional(Type.Boolean({ description: "Compatibility option for skill inheritance." })),
  cwd: Type.Optional(Type.String({ description: "Working directory for the subagent session" })),
});

const GetResultParams = Type.Object({
  agent_id: Type.String({ description: "Subagent run identifier" }),
  wait: Type.Optional(Type.Boolean({ description: "Wait for completion before returning" })),
  verbose: Type.Optional(Type.Boolean({ description: "Include verbose run data" })),
});

const SteerParams = Type.Object({
  agent_id: Type.String({ description: "The agent ID to steer (must be currently running)." }),
  message: Type.String({ description: "The steering message to send. This will appear as a user message in the agent's conversation." }),
});

function normalizeMaxTurns(n: number | undefined): number | undefined {
  if (n == null || n === 0) return undefined;
  return Math.max(1, n);
}

function splitModel(model: string): { provider: string; id: string } | undefined {
  const index = model.indexOf("/");
  if (index <= 0 || index === model.length - 1) return undefined;
  return { provider: model.slice(0, index), id: model.slice(index + 1) };
}

function resolveModel(ctx: ExtensionContext, modelInput: string | undefined): any {
  if (!modelInput) return ctx.model;
  const parsed = splitModel(modelInput);
  if (parsed) return ctx.modelRegistry.find(parsed.provider, parsed.id);
  return ctx.modelRegistry.getAll().find((model: any) => model.id === modelInput || model.name === modelInput);
}

function textFromMessage(message: any): string {
  if (!message || message.role !== "assistant" || !Array.isArray(message.content)) return "";
  return message.content.filter((part: any) => part.type === "text").map((part: any) => part.text).join("\n");
}

function tail(text: string | undefined, max = 1000): string {
  if (!text) return "";
  return text.length > max ? `…${text.slice(-max)}` : text;
}

const SPINNER = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"];

type AgentDetails = {
  displayName: string;
  description?: string;
  subagentType: string;
  modelName?: string;
  tags?: string[];
  toolUses: number;
  tokens: string;
  turnCount?: number;
  maxTurns?: number;
  durationMs: number;
  status: "queued" | "running" | "background" | "completed" | "steered" | "stopped" | "cancelled" | "error" | "aborted";
  activity?: string;
  spinnerFrame?: number;
  agentId?: string;
  error?: string;
};

function formatMs(ms: number): string {
  if (ms < 1000) return `${ms}ms`;
  const seconds = ms / 1000;
  if (seconds < 60) return `${seconds.toFixed(seconds < 10 ? 1 : 0)}s`;
  const minutes = Math.floor(seconds / 60);
  const rest = Math.round(seconds % 60);
  return `${minutes}m ${rest}s`;
}

function formatTurns(turnCount: number, maxTurns?: number): string {
  return maxTurns != null ? `⟳${turnCount}≤${maxTurns}` : `⟳${turnCount}`;
}

function describeActivity(run: SubagentRunRecord): string {
  if (run.pendingPermission) return `waiting for permission: ${run.pendingPermission.action}`;
  if (run.output) return tail(run.output.replace(/\s+/g, " "), 120);
  if (run.error) return `error: ${tail(run.error.replace(/\s+/g, " "), 120)}`;
  return run.toolUses ? "using tools…" : "thinking…";
}

function detailsFromRun(run: SubagentRunRecord, status?: AgentDetails["status"], spinnerFrame = 0): AgentDetails {
  const mappedStatus = status ?? (run.status === "failed" ? "error" : run.status === "aborted" ? "aborted" : run.status === "running" ? "running" : run.status === "queued" ? "queued" : run.status === "steered" ? "steered" : "completed");
  return {
    displayName: run.agentName,
    description: run.description,
    subagentType: run.agentName,
    toolUses: run.toolUses ?? 0,
    tokens: "",
    turnCount: run.turnCount,
    maxTurns: run.maxTurns,
    durationMs: (run.completedAt ?? Date.now()) - (run.startedAt ?? Date.now()),
    status: mappedStatus,
    activity: describeActivity(run),
    spinnerFrame,
    agentId: run.id,
    error: run.error,
  };
}

function textResult(msg: string, details?: AgentDetails) {
  return { content: [{ type: "text" as const, text: msg }], details: details as any };
}

function renderAgentResult(result: any, { expanded, isPartial }: { expanded?: boolean; isPartial?: boolean }, theme: any) {
  const details = result.details as AgentDetails | undefined;
  if (!details) {
    const text = result.content?.[0]?.type === "text" ? result.content[0].text : "";
    return new Text(text, 0, 0);
  }

  const stats = (d: AgentDetails) => {
    const parts: string[] = [];
    if (d.modelName) parts.push(d.modelName);
    if (d.tags) parts.push(...d.tags);
    if (d.turnCount != null && d.turnCount > 0) parts.push(formatTurns(d.turnCount, d.maxTurns));
    if (d.toolUses > 0) parts.push(`${d.toolUses} tool use${d.toolUses === 1 ? "" : "s"}`);
    if (d.tokens) parts.push(d.tokens);
    return parts.map((p) => theme.fg("dim", p)).join(" " + theme.fg("dim", "·") + " ");
  };

  if (details.status === "queued") {
    const s = stats(details);
    let line = theme.fg("accent", "…") + (s ? " " + s : "");
    line += "\n" + theme.fg("dim", `  ⎿  Queued for execution slot (ID: ${details.agentId})`);
    return new Text(line, 0, 0);
  }

  if (isPartial || details.status === "running") {
    const frame = SPINNER[details.spinnerFrame ?? 0];
    const s = stats(details);
    let line = theme.fg("accent", frame) + (s ? " " + s : "");
    line += "\n" + theme.fg("dim", `  ⎿  ${details.activity ?? "thinking…"}`);
    return new Text(line, 0, 0);
  }

  if (details.status === "background") {
    return new Text(theme.fg("dim", `  ⎿  Running in background (ID: ${details.agentId})`), 0, 0);
  }

  if (details.status === "completed" || details.status === "steered") {
    const icon = details.status === "steered" ? theme.fg("warning", "✓") : theme.fg("success", "✓");
    const s = stats(details);
    let line = icon + (s ? " " + s : "");
    line += " " + theme.fg("dim", "·") + " " + theme.fg("dim", formatMs(details.durationMs));
    if (expanded) {
      const resultText = result.content?.[0]?.type === "text" ? result.content[0].text : "";
      if (resultText) {
        const lines = resultText.split("\n").slice(0, 50);
        for (const l of lines) line += "\n" + theme.fg("dim", `  ${l}`);
        if (resultText.split("\n").length > 50) line += "\n" + theme.fg("muted", "  ... (use get_subagent_result with verbose for full output)");
      }
    } else {
      line += "\n" + theme.fg("dim", `  ⎿  ${details.status === "steered" ? "Wrapped up (turn limit)" : "Done"}`);
    }
    return new Text(line, 0, 0);
  }

  if (details.status === "stopped" || details.status === "cancelled") {
    const s = stats(details);
    return new Text(theme.fg("dim", "■") + (s ? " " + s : "") + "\n" + theme.fg("dim", `  ⎿  ${details.status === "cancelled" ? "Cancelled waiting" : "Stopped"}`), 0, 0);
  }

  const s = stats(details);
  let line = theme.fg("error", "✗") + (s ? " " + s : "");
  line += details.status === "error" ? "\n" + theme.fg("error", `  ⎿  Error: ${details.error ?? "unknown"}`) : "\n" + theme.fg("warning", "  ⎿  Aborted (max turns exceeded)");
  return new Text(line, 0, 0);
}

function formatRunProgress(run: SubagentRunRecord): string {
  const elapsed = run.startedAt ? Math.max(0, Math.round((Date.now() - run.startedAt) / 1000)) : 0;
  const parts: string[] = [];
  if (run.turnCount != null) parts.push(run.maxTurns != null ? `turns ${run.turnCount}/${run.maxTurns}` : `turns ${run.turnCount}`);
  if (run.toolUses) parts.push(`${run.toolUses} tool use${run.toolUses === 1 ? "" : "s"}`);
  if (elapsed) parts.push(`${elapsed}s`);

  const queueSuffix = run.status === "queued" && run.queuedPosition ? ` (queue position ${run.queuedPosition})` : "";
  const lines = [`Subagent ${run.agentName} (${run.id}) is ${run.status}${queueSuffix}${parts.length ? ` — ${parts.join(", ")}` : ""}`];
  if (run.status === "queued") lines.push("Waiting for an execution slot.");
  if (run.status === "running" && run.sessionId) lines.push(`Session: ${run.sessionId}`);
  if (run.pendingPermission) {
    lines.push("", `Waiting for permission: ${run.pendingPermission.action}`, `Reason: ${run.pendingPermission.reason}`);
  } else if (run.output) lines.push("", "Latest output:", tail(run.output));
  else if (run.error) lines.push("", "Latest error:", tail(run.error));
  else if (run.status === "running") lines.push("", "No assistant output yet; the subagent may be thinking, waiting for provider response, or executing tools.");
  return lines.join("\n");
}

function summarizeParentContext(ctx: ExtensionContext): string {
  const entries = ctx.sessionManager.getEntries().slice(-20) as Array<Record<string, unknown>>;
  return entries.map((entry, index) => {
    const type = String(entry.type ?? "unknown");
    const customType = typeof entry.customType === "string" ? `:${entry.customType}` : "";
    const role = typeof entry.role === "string" ? ` role=${entry.role}` : "";
    return `${index + 1}. ${type}${customType}${role}`;
  }).join("\n");
}

function buildSystemPrompt(agent: AgentDefinition, ctx: ExtensionContext, run: RunRecordInternal, maxTurns: number | undefined): string {
  const base = agent.promptMode === "append" ? `${ctx.getSystemPrompt()}\n\n${agent.prompt}` : agent.prompt;
  const extras = [
    "",
    "You are running as a subagent. Return only the result requested by the parent agent.",
    maxTurns != null ? `Maximum agentic turns: ${maxTurns}. When this limit is reached, you will be asked to wrap up immediately.` : undefined,
    run.inheritContext ? `Parent session context summary (entry metadata only; no raw tool outputs or file contents):\n${summarizeParentContext(ctx)}` : undefined,
    run.steering.length ? `Steering messages queued before start:\n${run.steering.map((message, index) => `${index + 1}. ${message}`).join("\n")}` : undefined,
    `Runtime identity: ${JSON.stringify(run.identity)}`,
  ].filter(Boolean);
  return [base, ...extras].join("\n");
}

export const SUBAGENT_RUN_ENTRY = "agent-permission-framework-subagent-run";

async function executeSubagentRun(run: RunRecordInternal, helpers: SubagentExecutorHelpers): Promise<void> {
  const ctx = run.ctx as ExtensionContext | undefined;
  if (!ctx) {
    run.status = "failed";
    run.error = "Subagent run cannot start without an ExtensionContext.";
    return;
  }
  const agent = run.definition;
  const maxTurns = normalizeMaxTurns(run.maxTurnsOverride ?? agent.maxTurns);
  run.maxTurns = maxTurns;
  run.turnCount = 0;
  run.toolUses = 0;
  run.activeTools = [];
  run.status = "running";
  run.startedAt = run.startedAt ?? Date.now();
  helpers.update(run);

  let unsubscribe: (() => void) | undefined;
  let aborted = false;
  let softLimitReached = false;
  const graceTurns = 5;

  try {
    const modelInput = run.modelOverride ?? agent.model;
    const model = resolveModel(ctx, modelInput);
    if (modelInput && !model) throw new Error(`Model not found for subagent ${agent.name}: ${modelInput}`);

    const agentDir = getAgentDir();
    const settingsManager = SettingsManager.create(run.cwd, agentDir);
    const childRuntime = new AgentRuntimeState();
    childRuntime.activeIdentity = run.identity;
    childRuntime.activePolicy = run.effectivePolicy;
    const promptSteeringCount = run.steering.length;
    const loader = new DefaultResourceLoader({
      cwd: run.cwd,
      agentDir,
      settingsManager,
      noExtensions: run.inheritExtensions !== true,
      noSkills: run.inheritSkills === false,
      noPromptTemplates: true,
      noThemes: true,
      noContextFiles: true,
      systemPrompt: buildSystemPrompt(agent, ctx, run, maxTurns),
      extensionsOverride: withoutRecursiveFrameworkExtension,
      extensionFactories: [
        (childPi) => {
          childPi.on("tool_call", async (event, childCtx) => {
            const decision = evaluateToolCall(
              childRuntime,
              { toolName: event.toolName, input: event.input as Record<string, unknown>, toolCallId: event.toolCallId },
              childCtx,
              childRuntime.activePolicy,
              { includeDelegation: event.toolName !== "subagent" },
            );
            return enforceDecision(childRuntime, decision, childCtx, {
              approvalBroker: run.approvalBroker,
              allowContextUI: false,
              approvalTimeoutMs: run.approvalTimeoutMs,
              signal: run.signal ?? childCtx.signal,
              onPendingApproval: (pending) => {
                run.pendingPermission = pending;
                helpers.update(run);
              },
              onAudit: (audit) => helpers.audit(audit),
            });
          });
        },
      ],
    });
    await loader.reload();

    const { session } = await createAgentSession({
      cwd: run.cwd,
      agentDir,
      model,
      thinkingLevel: run.thinkingOverride ?? agent.thinking,
      tools: agent.tools,
      resourceLoader: loader,
      sessionManager: SessionManager.inMemory(run.cwd),
      settingsManager,
    });
    run.session = session;
    run.sessionId = session.sessionId;
    for (const message of run.steering.slice(promptSteeringCount)) {
      await session.steer(message);
    }

    if (agent.disallowedTools?.length) {
      const denied = new Set(agent.disallowedTools);
      session.setActiveToolsByName(session.getActiveToolNames().filter((tool) => !denied.has(tool)));
    }

    const onAbort = () => {
      aborted = true;
      run.status = "aborted";
      run.error = `${run.error ?? ""}\nSubagent aborted by parent signal.`.trim();
      helpers.update(run);
      void session.abort();
    };
    if (run.signal?.aborted) onAbort();
    else run.signal?.addEventListener("abort", onAbort, { once: true });

    let currentMessageText = "";
    unsubscribe = session.subscribe((event: any) => {
      if (event.type === "message_start") currentMessageText = "";
      if (event.type === "message_update" && event.assistantMessageEvent?.type === "text_delta") {
        currentMessageText += event.assistantMessageEvent.delta;
        run.output = currentMessageText;
        helpers.update(run);
      }
      if (event.type === "message_end") {
        const text = textFromMessage(event.message);
        if (text) run.output = text;
        helpers.update(run);
      }
      if (event.type === "tool_execution_start") {
        run.toolUses = (run.toolUses ?? 0) + 1;
        run.activeTools = [...(run.activeTools ?? []), event.toolName].filter((toolName): toolName is string => typeof toolName === "string" && toolName.length > 0);
        helpers.update(run);
      }
      if (event.type === "tool_execution_end") {
        const toolName = typeof event.toolName === "string" ? event.toolName : undefined;
        if (toolName) {
          const active = [...(run.activeTools ?? [])];
          const index = active.indexOf(toolName);
          if (index >= 0) active.splice(index, 1);
          run.activeTools = active;
        } else {
          run.activeTools = [];
        }
        helpers.update(run);
      }
      if (event.type === "turn_end") {
        run.turnCount = (run.turnCount ?? 0) + 1;
        if (maxTurns != null) {
          if (!softLimitReached && run.turnCount >= maxTurns) {
            softLimitReached = true;
            void session.steer("You have reached your turn limit. Wrap up immediately — provide your final answer now.");
          } else if (softLimitReached && run.turnCount >= maxTurns + graceTurns) {
            aborted = true;
            run.status = "aborted";
            run.error = `${run.error ?? ""}\nSubagent exceeded max_turns (${maxTurns}) plus ${graceTurns} grace turns.`.trim();
            void session.abort();
          }
        }
        helpers.update(run);
      }
      if (event.type === "agent_end" && event.finalError) {
        run.error = `${run.error ?? ""}\n${event.finalError}`.trim();
      }
    });

    await session.prompt(`Task: ${run.task}`);
    run.signal?.removeEventListener("abort", onAbort);
    run.activeTools = [];
    run.status = finalSubagentStatus({ aborted, error: run.error, softLimitReached });
    if (!run.output) {
      const lastAssistant = [...session.messages].reverse().find((message: any) => message.role === "assistant");
      run.output = textFromMessage(lastAssistant);
    }
  } catch (error) {
    run.activeTools = [];
    run.status = aborted ? "aborted" : "failed";
    run.error = `${run.error ?? ""}\n${error instanceof Error ? error.message : String(error)}`.trim();
  } finally {
    unsubscribe?.();
    run.session?.dispose?.();
  }
}

export function registerSubagentTools(pi: ExtensionAPI, registry: SubagentRegistry, runtime: AgentRuntimeState, getAgents: () => AgentDefinition[], defaultCwd: () => string): void {
  registry.setExecutor(executeSubagentRun);

  function persistPermissionSideEffects(): void {
    const lastAudit = runtime.audit.at(-1);
    if (lastAudit) persistAudit(pi, lastAudit);
    persistRuntime(pi, runtime);
  }

  function emitToolProgress(onUpdate: ((partial: { content: Array<{ type: "text"; text: string }>; details?: Record<string, unknown> }) => void) | undefined, runId: string): void {
    if (!onUpdate) return;
    const live = registry.get(runId);
    if (!live) return;
    const run = registry.publicRun(live);
    const spinnerFrame = Math.floor(Date.now() / 80) % SPINNER.length;
    onUpdate({ content: [{ type: "text", text: formatRunProgress(run) }], details: detailsFromRun(run, undefined, spinnerFrame) });
  }

  pi.registerTool({
    name: "subagent",
    label: "Subagent",
    description: [
      "Launch a specialized subagent with its own context window, system prompt, tools, model, and permissions.",
      "For parallel work, use run_in_background: true on each agent. Foreground calls run sequentially.",
      "Use get_subagent_result for background results and steer_subagent to redirect a running background agent.",
      "Use inherit_context if the agent needs the parent conversation history.",
    ].join("\n"),
    parameters: AgentParams,
    renderCall(args, theme) {
      const displayName = args.subagent_type ?? args.agent ?? "Agent";
      const desc = args.description ?? "";
      return new Text("▸ " + theme.fg("toolTitle", theme.bold(displayName)) + (desc ? "  " + theme.fg("muted", desc) : ""), 0, 0);
    },
    renderResult: renderAgentResult,
    async execute(_toolCallId, params, signal, onUpdate, ctx) {
      const agentName = params.subagent_type ?? params.agent;
      const task = params.prompt ?? params.task;
      if (!agentName || !task) return textResult("subagent requires subagent_type and prompt.", { displayName: agentName ?? "subagent", subagentType: agentName ?? "subagent", description: params.description, toolUses: 0, tokens: "", durationMs: 0, status: "error", error: "missing subagent_type or prompt" });

      if (params.resume) {
        const existing = registry.get(params.resume);
        if (!existing) return textResult(`Agent not found: "${params.resume}". It may have been cleaned up.`);
        if (!existing.session || existing.status !== "running") return textResult(`Agent "${params.resume}" has no active session to resume (status: ${existing.status}).`);
        const decision = evaluateDelegationPermission(runtime.activePolicy, {
          agentName: existing.agentName,
          source: existing.identity.source,
          background: params.run_in_background === true,
          modelOverride: params.model,
          inheritContext: params.inherit_context,
          inheritExtensions: params.inherit_extensions,
          inheritSkills: params.inherit_skills,
          cwd: existing.cwd,
        }, ctx.hasUI !== false);
        const blocked = await enforceDecision(runtime, decision, ctx);
        persistPermissionSideEffects();
        if (blocked?.block) return textResult(`Permission denied: ${blocked.reason}`, { displayName: existing.agentName, subagentType: existing.agentName, description: params.description, toolUses: existing.toolUses ?? 0, tokens: "", durationMs: 0, status: "error", error: blocked.reason });
        await registry.steer(params.resume, task);
        if (params.run_in_background) return textResult(`Steering message sent to agent ${params.resume}.`, detailsFromRun(registry.publicRun(existing), "background"));
        const progressTimer = setInterval(() => emitToolProgress(onUpdate, params.resume!), 1000);
        const completed = await new Promise<SubagentRunRecord>((resolve) => {
          const interval = setInterval(() => {
            const live = registry.get(params.resume!);
            if (!live || (live.status !== "queued" && live.status !== "running")) {
              clearInterval(interval);
              resolve(live ? registry.publicRun(live) : registry.publicRun(existing));
            }
          }, 250);
        }).finally(() => clearInterval(progressTimer));
        return textResult(completed.output || completed.error || "No output.", detailsFromRun(completed));
      }

      const agent = getAgents().find((candidate) => candidate.name === agentName && candidate.kind === "subagent");
      if (!agent) return textResult(`Agent not found: "${agentName}". It may have been cleaned up.`, { displayName: agentName, subagentType: agentName, description: params.description, toolUses: 0, tokens: "", durationMs: 0, status: "error", error: "unknown agent" });
      const background = params.run_in_background ?? agent.runInBackground ?? false;
      const decision = evaluateDelegationPermission(runtime.activePolicy, {
        agentName: agent.name,
        source: agent.source,
        background,
        modelOverride: params.model,
        inheritContext: params.inherit_context,
        inheritExtensions: params.inherit_extensions,
        inheritSkills: params.inherit_skills,
        cwd: params.cwd ?? defaultCwd(),
      }, ctx.hasUI !== false);
      const blocked = await enforceDecision(runtime, decision, ctx);
      persistPermissionSideEffects();
      if (blocked?.block) return textResult(`Permission denied: ${blocked.reason}`, { displayName: agent.name, subagentType: agent.name, description: params.description, toolUses: 0, tokens: "", durationMs: 0, status: "error", error: blocked.reason });
      const { run, completion } = registry.start({
        agent,
        task,
        description: params.description,
        cwd: params.cwd ?? defaultCwd(),
        parentIdentity: runtime.activeIdentity,
        runtime,
        ctx,
        parentPolicy: runtime.activePolicy,
        background,
        modelOverride: params.model,
        thinkingOverride: params.thinking,
        maxTurnsOverride: params.max_turns,
        signal: background ? undefined : signal,
        inheritContext: params.inherit_context,
        inheritExtensions: params.inherit_extensions,
        inheritSkills: params.inherit_skills,
        approvalBroker: createUIApprovalBroker(ctx),
      });
      if (background) {
        const isQueued = run.status === "queued";
        return textResult(
          `Agent ${isQueued ? "queued" : "started"} in background.\n` +
          `Agent ID: ${run.id}\n` +
          `Type: ${agent.name}\n` +
          `Description: ${params.description}\n` +
          (isQueued ? `Queue position: ${run.queuedPosition ?? "unknown"}\n` : `Status: running\n`) +
          `\nYou will be notified when this agent completes.\n` +
          `Use get_subagent_result to retrieve full results, or steer_subagent to send it messages.\n` +
          `Do not duplicate this agent's work.`,
          detailsFromRun(run, isQueued ? "queued" : "background"),
        );
      }
      emitToolProgress(onUpdate, run.id);
      const progressTimer = setInterval(() => emitToolProgress(onUpdate, run.id), 1000);
      const completed = await completion.finally(() => clearInterval(progressTimer));
      emitToolProgress(onUpdate, run.id);
      const details = detailsFromRun(completed);
      if (completed.status === "failed") return textResult(`Agent failed: ${completed.error}`, { ...details, status: "error", error: completed.error });
      const statsParts = [`${completed.toolUses ?? 0} tool uses`];
      return textResult(
        `Agent completed in ${formatMs(details.durationMs)} (${statsParts.join(", ")}).\n\n` +
        (completed.output?.trim() || completed.error?.trim() || "No output."),
        details,
      );
    },
  });

  pi.registerTool({
    name: "get_subagent_result",
    label: "Get Agent Result",
    description: "Check status and retrieve results from a background agent. Use the agent ID returned by subagent with run_in_background.",
    parameters: GetResultParams,
    renderCall(args, theme) {
      return new Text("▸ " + theme.fg("toolTitle", theme.bold("Get Agent Result")) + "  " + theme.fg("muted", args.agent_id ?? ""), 0, 0);
    },
    renderResult: renderAgentResult,
    async execute(_toolCallId, params, signal, onUpdate) {
      const run = registry.get(params.agent_id);
      if (!run) return textResult(`Agent not found: "${params.agent_id}". It may have been cleaned up.`);
      if (shouldWaitForSubagentResult(params.wait, run)) {
        const waitOutcome = await waitForSubagentResult(run, {
          signal,
          onProgress: () => emitToolProgress(onUpdate, params.agent_id),
        });
        if (waitOutcome === "cancelled") {
          const current = registry.publicRun(run);
          const status = current.status === "failed" ? "error" : current.status;
          return textResult(
            `Result wait cancelled for agent ${current.id}.\n` +
            `Agent is still ${status}; the background run was not cancelled.\n` +
            `Use get_subagent_result with this agent ID to retrieve the current or completed result later.`,
            detailsFromRun(current, "cancelled"),
          );
        }
      }
      const serializable = registry.publicRun(run);
      const duration = serializable.startedAt ? formatMs((serializable.completedAt ?? Date.now()) - serializable.startedAt) : "0ms";
      const status = serializable.status === "failed" ? "error" : serializable.status;
      let output =
        `Agent: ${serializable.id}\n` +
        `Type: ${serializable.agentName} | Status: ${status} | Tool uses: ${serializable.toolUses ?? 0} | Duration: ${duration}\n` +
        `Description: ${serializable.description ?? serializable.agentName}\n\n`;
      if (serializable.status === "queued") {
        output += `Agent is queued${serializable.queuedPosition ? ` at position ${serializable.queuedPosition}` : ""}. Waiting for an execution slot; use wait: true or check back later.`;
      } else if (serializable.status === "running") output += "Agent is running. Use wait: true or check back later.";
      else if (serializable.status === "failed") output += `Error: ${serializable.error}`;
      else output += serializable.output?.trim() || "No output.";
      if (params.verbose) {
        output += "\n\n--- Agent Details ---\n" + [
          `Run ID: ${serializable.id}`,
          `Session: ${serializable.sessionId ?? "(none)"}`,
          `Turns: ${serializable.turnCount ?? 0}${serializable.maxTurns != null ? `/${serializable.maxTurns}` : ""}`,
          `Steering messages: ${serializable.steering.length}`,
          serializable.error ? `Error: ${serializable.error}` : undefined,
        ].filter(Boolean).join("\n");
      }
      return textResult(output, detailsFromRun(serializable));
    },
  });

  pi.registerTool({
    name: "steer_subagent",
    label: "Steer Agent",
    description: "Send a steering message to a running agent. The message will interrupt the agent after its current tool execution and be injected into its conversation, allowing you to redirect its work mid-run. Only works on running agents.",
    parameters: SteerParams,
    renderCall(args, theme) {
      return new Text("▸ " + theme.fg("toolTitle", theme.bold("Steer Agent")) + "  " + theme.fg("muted", args.agent_id ?? ""), 0, 0);
    },
    renderResult(result, _state, theme) {
      const text = result.content?.[0]?.type === "text" ? result.content[0].text : "";
      return new Text(theme.fg("dim", `  ⎿  ${text.split("\n")[0] ?? "Done"}`), 0, 0);
    },
    async execute(_toolCallId, params) {
      const existing = registry.get(params.agent_id);
      if (!existing) return textResult(`Agent not found: "${params.agent_id}". It may have been cleaned up.`);
      if (existing.status !== "running") return textResult(`Agent "${params.agent_id}" is not running (status: ${existing.status}). Cannot steer a non-running agent.`);
      const run = await registry.steer(params.agent_id, params.message);
      if (!run) return textResult(`Agent not found: "${params.agent_id}". It may have been cleaned up.`);
      if (!existing.session) return textResult(`Steering message queued for agent ${run.id}. It will be delivered once the session initializes.`);
      return textResult(
        `Steering message sent to agent ${run.id}. The agent will process it after its current tool execution.\n` +
        `Current state: ${run.toolUses ?? 0} tool ${(run.toolUses ?? 0) === 1 ? "use" : "uses"}`,
      );
    },
  });
}
