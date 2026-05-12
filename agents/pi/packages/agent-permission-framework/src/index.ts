import { readFileSync } from "node:fs";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { AgentRuntimeState, persistAudit, persistRuntime, restoreRuntimeFromSession } from "./runtime.ts";
import { builtinAgents } from "./builtins.ts";
import { discoverAgents, findAgent, selectMainAgents } from "./agents.ts";
import { enforceDecision, evaluateToolCall } from "./enforcement.ts";
import { formatAuditActionSummary } from "./permission-display.ts";
import { deriveActiveToolNames, stablePolicyHash } from "./policy.ts";
import { registerSubagentTools, SUBAGENT_RUN_ENTRY, SubagentRegistry } from "./subagents.ts";
import { SubagentWidget } from "./subagent-widget.ts";
import type { AgentDefinition, PermissionPolicy } from "./types.ts";
import { debugLog } from "./debug.ts";

function splitModel(model: string): { provider: string; id: string } | undefined {
  const index = model.indexOf("/");
  if (index <= 0 || index === model.length - 1) return undefined;
  return { provider: model.slice(0, index), id: model.slice(index + 1) };
}

function getEntries(ctx: ExtensionContext): Array<Record<string, unknown>> {
  try {
    return ctx.sessionManager.getEntries() as Array<Record<string, unknown>>;
  } catch {
    return [];
  }
}

async function applyMainAgentSettings(pi: ExtensionAPI, ctx: ExtensionContext, agent: AgentDefinition): Promise<void> {
  const availableTools = pi.getAllTools().map((tool) => tool.name);
  pi.setActiveTools(deriveActiveToolNames(agent.permission, availableTools, ctx.hasUI !== false));
  if (agent.thinking) pi.setThinkingLevel(agent.thinking);
  if (agent.model) {
    const parsed = splitModel(agent.model);
    const model = parsed ? ctx.modelRegistry.find(parsed.provider, parsed.id) : undefined;
    if (model) {
      const ok = await pi.setModel(model);
      if (!ok) ctx.ui.notify(`Agent ${agent.name}: model ${agent.model} has no available API key`, "warning");
    } else {
      ctx.ui.notify(`Agent ${agent.name}: model ${agent.model} not found`, "warning");
    }
  }
}

function promptForAgent(systemPrompt: string, agent: AgentDefinition): string {
  const marker = [`[AGENT ACTIVE: ${agent.name}]`, agent.prompt].join("\n");
  return agent.promptMode === "replace" ? marker : `${systemPrompt}\n\n${marker}`;
}

export default function agentPermissionFramework(pi: ExtensionAPI): void {
  const runtime = new AgentRuntimeState();
  let subagentWidget: SubagentWidget | undefined;
  const subagents = new SubagentRegistry(4, (run) => {
    pi.appendEntry(SUBAGENT_RUN_ENTRY, run);
    subagentWidget?.update();
  }, (audit) => persistAudit(pi, audit));
  subagentWidget = new SubagentWidget(subagents);
  let agents: AgentDefinition[] = [...builtinAgents];
  let activeMainAgent: AgentDefinition | undefined;
  let cwd = process.cwd();

  pi.registerFlag("agent", {
    description: "Main agent profile to activate (for example: plan, build, ask)",
    type: "string",
  });

  pi.registerFlag("project-agents", {
    description: "Allow project-local .pi/agents and .pi/bureau config for this session",
    type: "boolean",
    default: false,
  });

  function reloadAgents(ctx: ExtensionContext): void {
    cwd = ctx.cwd;
    runtime.trustedProjectAgents = runtime.trustedProjectAgents || pi.getFlag("project-agents") === true;
    const result = discoverAgents({ cwd: ctx.cwd, includeProjectAgents: runtime.trustedProjectAgents }, builtinAgents);
    agents = result.agents;
    for (const ignored of result.ignored) {
      ctx.ui.notify(`Ignored bureau/agent config ${ignored.filePath}: ${ignored.reason}`, "warning");
    }
  }

  function activateAgent(name: string, ctx: ExtensionContext): AgentDefinition | undefined {
    const agent = findAgent(agents, name, "main");
    if (!agent) return undefined;
    activeMainAgent = agent;
    runtime.activateMain(agent, agent.permission);
    persistRuntime(pi, runtime);
    ctx.ui.setStatus("agent", ctx.ui.theme.fg("accent", `agent:${agent.name}`));
    return agent;
  }

  async function reactivateCurrentMainAgent(ctx: ExtensionContext): Promise<AgentDefinition | undefined> {
    const currentName = activeMainAgent?.name ?? (runtime.activeIdentity?.kind === "main" ? runtime.activeIdentity.agentName : undefined);
    const selected = currentName ? activateAgent(currentName, ctx) : undefined;
    if (selected) {
      await applyMainAgentSettings(pi, ctx, selected);
      return selected;
    }

    const fallback = findAgent(agents, "build", "main") ?? selectMainAgents(agents)[0];
    if (fallback) {
      activeMainAgent = fallback;
      runtime.activateMain(fallback, fallback.permission);
      await applyMainAgentSettings(pi, ctx, fallback);
      ctx.ui.setStatus("agent", ctx.ui.theme.fg("accent", `agent:${fallback.name}`));
      if (currentName) ctx.ui.notify(`Main agent ${currentName} is unavailable after loading project config; activated ${fallback.name}.`, "warning");
      return fallback;
    }

    activeMainAgent = undefined;
    runtime.activeIdentity = undefined;
    runtime.activePolicy = undefined;
    ctx.ui.notify("No main agents are available after loading project config.", "error");
    return undefined;
  }

  registerSubagentTools(pi, subagents, runtime, () => agents, () => cwd);

  pi.registerCommand("agent", {
    description: "Select active main agent profile",
    handler: async (args, ctx) => {
      reloadAgents(ctx);
      const requested = args?.trim();
      if (requested) {
        const selected = activateAgent(requested, ctx);
        if (!selected) {
          ctx.ui.notify(`Unknown main agent: ${requested}`, "error");
          return;
        }
        await applyMainAgentSettings(pi, ctx, selected);
        ctx.ui.notify(`Main agent activated: ${selected.name}`, "info");
        return;
      }

      const mains = selectMainAgents(agents);
      const choice = await ctx.ui.select("Select main agent", mains.map((agent) => `${agent.name} — ${agent.description}`));
      if (!choice) return;
      const name = choice.split(" — ")[0];
      const selected = activateAgent(name, ctx);
      if (selected) {
        await applyMainAgentSettings(pi, ctx, selected);
        ctx.ui.notify(`Main agent activated: ${selected.name}`, "info");
      }
    },
  });

  pi.registerCommand("agent-trust-project", {
    description: "Enable project-local .pi/agents and .pi/bureau config for this session",
    handler: async (_args, ctx) => {
      const ok = await ctx.ui.confirm(
        "Trust project-local agents/config?",
        "Project-local .pi/agents definitions and .pi/bureau config are repository-controlled prompts and permissions. Enable them for this session?",
      );
      if (!ok) return;
      runtime.trustedProjectAgents = true;
      reloadAgents(ctx);
      await reactivateCurrentMainAgent(ctx);
      persistRuntime(pi, runtime);
      ctx.ui.notify("Project-local agents/config enabled for this session", "info");
    },
  });

  pi.registerCommand("agent-permissions", {
    description: "Show active agent and recent permission decisions",
    handler: async (_args, ctx) => {
      const identity = runtime.activeIdentity;
      const recent = runtime.audit.slice(-10).map((entry) => {
        const icon = entry.decision.state === "allow" ? "✓" : entry.decision.state === "ask" ? "?" : "✗";
        return `${icon} ${entry.id} ${formatAuditActionSummary(entry.decision.fingerprint, 120)} — ${entry.decision.reason}`;
      });
      ctx.ui.notify([
        identity ? `Active: ${identity.agentName} (${identity.kind}, ${identity.source})` : "Active: none",
        `Policy: ${identity?.policyHash ?? "none"}`,
        identity?.configSources?.length ? `Sources: ${identity.configSources.join(", ")}` : undefined,
        "",
        recent.length ? recent.join("\n") : "No decisions recorded yet.",
      ].filter((line) => line !== undefined).join("\n"), "info");
    },
  });

  pi.registerCommand("agent-explain", {
    description: "Explain a prior permission decision by audit id or action fingerprint",
    handler: async (args, ctx) => {
      const query = args?.trim();
      if (!query) {
        ctx.ui.notify("Usage: /agent-explain <audit-id-or-fingerprint>", "info");
        return;
      }
      const entry = [...runtime.audit].reverse().find((candidate) =>
        candidate.id === query || candidate.decision.fingerprint.normalized === query || candidate.decision.fingerprint.normalized.includes(query)
      );
      if (!entry) {
        ctx.ui.notify(`No audit entry found for ${query}`, "warning");
        return;
      }
      ctx.ui.notify([
        `Audit: ${entry.id}`,
        entry.identity ? `Agent: ${entry.identity.agentName} (${entry.identity.kind}, ${entry.identity.source})` : "Agent: none",
        `Policy: ${entry.identity?.policyHash ?? "none"}`,
        entry.identity?.configSources?.length ? `Sources: ${entry.identity.configSources.join(", ")}` : undefined,
        `Decision: ${entry.decision.state}`,
        `Action: ${formatAuditActionSummary(entry.decision.fingerprint, 120)}`,
        `Reason: ${entry.decision.reason}`,
        entry.decision.matchedRule ? `Rule: ${entry.decision.matchedRule}` : undefined,
        entry.approved ? "Approved: yes" : "Approved: no",
        entry.details ? `Details: ${JSON.stringify(entry.details)}` : undefined,
      ].filter(Boolean).join("\n"), "info");
    },
  });

  pi.on("session_start", async (_event, ctx) => {
    const entries = getEntries(ctx);
    restoreRuntimeFromSession(runtime, entries);
    const restoredSubagents = subagents.restore(entries
      .filter((entry) => entry.type === "custom" && entry.customType === SUBAGENT_RUN_ENTRY)
      .map((entry) => (entry as { data?: unknown }).data)
      .filter((data): data is any => Boolean(data))
    );
    if (restoredSubagents.interrupted.length > 0 && ctx.hasUI !== false) {
      const count = restoredSubagents.interrupted.length;
      ctx.ui.notify(
        `${count} subagent run${count === 1 ? " was" : "s were"} interrupted and can be resumed.\n` +
        "Ask the agent to inspect or resume an interrupted subagent run by ID.",
        "warning",
      );
    }

    const childRuntimeFile = process.env.PI_AGENT_FRAMEWORK_CHILD;
    if (childRuntimeFile) {
      try {
        const child = JSON.parse(readFileSync(childRuntimeFile, "utf8")) as { identity?: typeof runtime.activeIdentity; policy?: PermissionPolicy };
        runtime.activeIdentity = child.identity;
        runtime.activePolicy = child.policy;
      } catch (error) {
        ctx.ui.notify(`Failed to read child agent runtime: ${error instanceof Error ? error.message : String(error)}`, "warning");
      }
    }

    reloadAgents(ctx);
    const flag = pi.getFlag("agent");
    const desired = typeof flag === "string" && flag ? flag : runtime.activeIdentity?.agentName ?? "build";
    activeMainAgent = findAgent(agents, desired, "main") ?? findAgent(agents, "build", "main") ?? selectMainAgents(agents)[0];
    if (activeMainAgent && (!runtime.activeIdentity || runtime.activeIdentity.kind !== "subagent")) {
      const restoredMatches = runtime.activeIdentity?.kind === "main" &&
        runtime.activeIdentity.agentName === activeMainAgent.name &&
        runtime.activeIdentity.policyHash === stablePolicyHash(activeMainAgent.permission);
      if (restoredMatches) {
        runtime.activePolicy = activeMainAgent.permission;
      } else {
        runtime.activateMain(activeMainAgent, activeMainAgent.permission);
      }
      await applyMainAgentSettings(pi, ctx, activeMainAgent);
      persistRuntime(pi, runtime);
    }
    if (runtime.activeIdentity) ctx.ui.setStatus("agent", ctx.ui.theme.fg("accent", `agent:${runtime.activeIdentity.agentName}`));
    subagentWidget?.setUICtx(ctx.hasUI === false ? undefined : ctx.ui);
    subagentWidget?.update();
  });

  pi.on("turn_start", async () => {
    subagentWidget?.onTurnStart();
  });

  pi.on("before_agent_start", async (event, ctx) => {
    if (!activeMainAgent || runtime.activeIdentity?.kind === "subagent") return;
    await applyMainAgentSettings(pi, ctx, activeMainAgent);
    return { systemPrompt: promptForAgent(event.systemPrompt, activeMainAgent) };
  });

  pi.on("tool_call", async (event, ctx) => {
    const decision = evaluateToolCall(
      runtime,
      { toolName: event.toolName, input: event.input as Record<string, unknown>, toolCallId: event.toolCallId },
      ctx,
      runtime.activePolicy,
      { includeDelegation: event.toolName !== "subagent" },
    );
    const result = await enforceDecision(runtime, decision, ctx);
    debugLog("permission_decision", { decision, blocked: result?.block === true, identity: runtime.activeIdentity });
    const lastAudit = runtime.audit.at(-1);
    if (lastAudit) persistAudit(pi, lastAudit);
    persistRuntime(pi, runtime);
    return result;
  });

  pi.on("session_shutdown", async () => {
    subagentWidget?.dispose();
    persistRuntime(pi, runtime);
  });
}
