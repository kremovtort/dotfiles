import type { AgentRuntimeState } from "./runtime.ts";
import {
  evaluateBashPermission,
  evaluateDelegationPermission,
  evaluateFilePermission,
  evaluateSkillPermission,
  evaluateToolPermission,
} from "./policy.ts";
import type { DelegationRequest, PermissionDecision, PermissionPolicy } from "./types.ts";

export interface ToolCallLike {
  toolName: string;
  input: Record<string, unknown>;
  toolCallId?: string;
}

export interface EnforcementContextLike {
  cwd: string;
  hasUI?: boolean;
  ui?: {
    confirm?: (title: string, message: string) => Promise<boolean>;
    select?: (title: string, options: string[]) => Promise<string | undefined>;
    notify?: (message: string, level?: "info" | "warning" | "error" | "success") => void;
  };
}

function inputString(input: Record<string, unknown>, keys: string[]): string | undefined {
  for (const key of keys) {
    const value = input[key];
    if (typeof value === "string" && value.trim()) return value;
  }
  return undefined;
}

function requestedAgent(input: Record<string, unknown>): DelegationRequest | undefined {
  const agentName = inputString(input, ["subagent_type", "agent", "type"]);
  if (!agentName) return undefined;
  const model = inputString(input, ["model"]);
  const cwd = inputString(input, ["cwd"]);
  const tools = Array.isArray(input.tools) ? input.tools.map(String) : undefined;
  return {
    agentName,
    background: input.run_in_background === true,
    modelOverride: model,
    toolOverride: tools,
    inheritContext: input.inherit_context === true || input.inheritContext === true,
    inheritExtensions: input.inherit_extensions === true || input.inheritExtensions === true,
    inheritSkills: input.inherit_skills === true || input.inheritSkills === true,
    cwd,
  };
}

function requestedSkill(toolName: string, input: Record<string, unknown>, policy: PermissionPolicy | undefined): string | undefined {
  if (toolName.startsWith("skill:")) return toolName.slice("skill:".length);
  if (toolName.startsWith("skill.")) return toolName.slice("skill.".length);
  if (["skill", "use_skill", "run_skill"].includes(toolName)) return inputString(input, ["skill", "skill_name", "skillName", "name"]);
  const skills = policy?.skills as Record<string, unknown> | undefined;
  if (skills && !["default", "allow", "ask", "deny"].includes(toolName) && Object.prototype.hasOwnProperty.call(skills, toolName)) return toolName;
  return undefined;
}

function fileOperationForTool(toolName: string): "read" | "write" | "edit" | undefined {
  if (["read", "grep", "find", "ls"].includes(toolName)) return "read";
  if (toolName === "write") return "write";
  if (toolName === "edit") return "edit";
  return undefined;
}

function filePathForTool(input: Record<string, unknown>): string | undefined {
  const direct = inputString(input, ["path", "file_path", "filePath"]);
  if (direct) return direct;
  return undefined;
}

let approvalQueue: Promise<void> = Promise.resolve();

async function serializeApproval<T>(fn: () => Promise<T>): Promise<T> {
  const previous = approvalQueue;
  let release!: () => void;
  approvalQueue = new Promise<void>((resolve) => {
    release = resolve;
  });
  await previous.catch(() => undefined);
  try {
    return await fn();
  } finally {
    release();
  }
}

function strictest(decisions: PermissionDecision[]): PermissionDecision {
  return decisions.reduce((current, next) => {
    if (current.state === "deny") return current;
    if (next.state === "deny") return next;
    if (current.state === "ask") return current;
    if (next.state === "ask") return next;
    return current;
  });
}

export function evaluateToolCall(
  runtime: AgentRuntimeState,
  event: ToolCallLike,
  ctx: EnforcementContextLike,
  policy: PermissionPolicy | undefined = runtime.activePolicy,
  options: { includeDelegation?: boolean } = {},
): PermissionDecision {
  const hasUI = ctx.hasUI !== false;
  const includeDelegation = options.includeDelegation ?? true;
  const decisions = [evaluateToolPermission(policy, event.toolName, hasUI)];

  if (event.toolName === "bash") {
    const command = inputString(event.input, ["command"]);
    if (command) decisions.push(evaluateBashPermission(policy, command, hasUI));
  }

  if (includeDelegation && event.toolName === "subagent") {
    const request = requestedAgent(event.input);
    if (request) decisions.push(evaluateDelegationPermission(policy, request, hasUI));
  }

  const skillName = requestedSkill(event.toolName, event.input, policy);
  if (skillName) decisions.push(evaluateSkillPermission(policy, skillName, hasUI));

  const operation = fileOperationForTool(event.toolName);
  const filePath = filePathForTool(event.input);
  if (operation && filePath) decisions.push(evaluateFilePermission(policy, operation, filePath, ctx.cwd, hasUI));

  return strictest(decisions);
}

export async function enforceDecision(
  runtime: AgentRuntimeState,
  decision: PermissionDecision,
  ctx: EnforcementContextLike,
): Promise<{ block?: true; reason?: string } | undefined> {
  const identity = runtime.activeIdentity;

  if (decision.state === "allow" || runtime.hasApproval(identity, decision.fingerprint)) {
    runtime.addAudit(decision, decision.state === "ask");
    return undefined;
  }

  if (decision.state === "deny") {
    runtime.addAudit(decision, false);
    ctx.ui?.notify?.(`Permission denied: ${decision.reason}`, "warning");
    return { block: true, reason: decision.reason };
  }

  if (ctx.hasUI === false || (!ctx.ui?.select && !ctx.ui?.confirm) || !identity) {
    const denied: PermissionDecision = { ...decision, state: "deny", reason: `${decision.reason}; denied because no interactive approval is available` };
    runtime.addAudit(denied, false);
    return { block: true, reason: denied.reason };
  }

  const message = [
    `Agent: ${identity.agentName} (${identity.kind})`,
    `Action: ${decision.fingerprint.normalized}`,
    `Decision: ${decision.reason}`,
    decision.matchedRule ? `Rule: ${decision.matchedRule}` : undefined,
  ].filter(Boolean).join("\n");

  const scope = await serializeApproval<"once" | "session" | undefined>(async () => {
    if (ctx.ui?.select) {
      const choice = await ctx.ui.select(`Required permission\n\n${message}`, [
        "Allow once",
        "Allow for this session",
        "Deny",
      ]);
      if (choice?.startsWith("Allow once")) return "once";
      if (choice?.startsWith("Allow for this session")) return "session";
      return undefined;
    }
    const approved = await ctx.ui?.confirm?.("Permission required", `${message}\n\nAllow this action once?`);
    return approved ? "once" : undefined;
  });

  if (!scope) {
    runtime.addAudit({ ...decision, state: "deny", reason: `${decision.reason}; denied by user` }, false);
    return { block: true, reason: "Permission denied by user" };
  }

  runtime.addApproval(identity, decision.fingerprint, scope);
  runtime.addAudit(decision, true, { approvalScope: scope });
  return undefined;
}
