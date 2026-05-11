import type { AgentRuntimeState } from "./runtime.ts";
import {
  evaluateBashPermission,
  evaluateDelegationPermission,
  evaluateExternalDirectoryPermission,
  evaluateToolPermission,
  normalizePathForPolicy,
} from "./policy.ts";
import type {
  AuditEntry,
  DelegationRequest,
  PendingPermissionRequest,
  PermissionApprovalBroker,
  PermissionApprovalRequest,
  PermissionApprovalResult,
  PermissionDecision,
  PermissionPolicy,
} from "./types.ts";

export interface ToolCallLike {
  toolName: string;
  input: Record<string, unknown>;
  toolCallId?: string;
}

type UIRequestOptions = { signal?: AbortSignal; timeout?: number };

export interface EnforcementContextLike {
  cwd: string;
  hasUI?: boolean;
  signal?: AbortSignal;
  ui?: {
    confirm?: (title: string, message: string, options?: UIRequestOptions) => Promise<boolean>;
    select?: (title: string, options: string[], requestOptions?: UIRequestOptions) => Promise<string | undefined>;
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
  return {
    agentName,
    background: input.run_in_background === true,
    modelOverride: model,
    inheritContext: input.inherit_context === true || input.inheritContext === true,
    inheritExtensions: input.inherit_extensions === true || input.inheritExtensions === true,
    inheritSkills: input.inherit_skills === true || input.inheritSkills === true,
    cwd,
  };
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

function stableInputString(input: Record<string, unknown>): string {
  const stable = (value: unknown): string => {
    if (value == null || typeof value !== "object") return JSON.stringify(value);
    if (Array.isArray(value)) return `[${value.map(stable).join(",")}]`;
    const record = value as Record<string, unknown>;
    return `{${Object.keys(record).sort().map((key) => `${JSON.stringify(key)}:${stable(record[key])}`).join(",")}}`;
  };
  return stable(input);
}

function pathTargetForTool(input: Record<string, unknown>, cwd: string): string | undefined {
  const rawPath = filePathForTool(input);
  if (!rawPath) return undefined;
  const normalized = normalizePathForPolicy(cwd, rawPath);
  return normalized.external ? normalized.absolute : normalized.projectRelative;
}

function primaryTargetForTool(toolName: string, input: Record<string, unknown>, cwd: string): string {
  if (toolName === "bash") return inputString(input, ["command"]) ?? stableInputString(input);
  if (toolName === "subagent") return inputString(input, ["subagent_type", "agent", "type"]) ?? stableInputString(input);
  if (toolName === "get_subagent_result" || toolName === "steer_subagent") return inputString(input, ["agent_id", "run_id", "id"]) ?? stableInputString(input);
  const pathTarget = pathTargetForTool(input, cwd);
  if (pathTarget) return pathTarget;
  return inputString(input, ["skill", "skill_name", "skillName", "query", "pattern", "glob", "url", "uri", "command", "name"]) ?? stableInputString(input);
}

const approvalQueues = new WeakMap<PermissionApprovalBroker, Promise<void>>();

async function serializeApprovalForBroker<T>(broker: PermissionApprovalBroker, fn: () => Promise<T>): Promise<T> {
  const previous = approvalQueues.get(broker) ?? Promise.resolve();
  let release!: () => void;
  approvalQueues.set(broker, new Promise<void>((resolve) => {
    release = resolve;
  }));
  await previous.catch(() => undefined);
  try {
    return await fn();
  } finally {
    release();
  }
}

const uiApprovalBrokers = new WeakMap<object, PermissionApprovalBroker>();

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
  const target = primaryTargetForTool(event.toolName, event.input, ctx.cwd);
  const decisions = [evaluateToolPermission(policy, event.toolName, hasUI, target)];

  if (event.toolName === "bash") {
    const command = inputString(event.input, ["command"]);
    if (command) decisions.push(evaluateBashPermission(policy, command, hasUI));
  }

  if (includeDelegation && event.toolName === "subagent") {
    const request = requestedAgent(event.input);
    if (request) decisions.push(evaluateDelegationPermission(policy, request, hasUI));
  }

  const operation = fileOperationForTool(event.toolName);
  const filePath = filePathForTool(event.input);
  if (operation && filePath) {
    const normalized = normalizePathForPolicy(ctx.cwd, filePath);
    if (normalized.external) decisions.push(evaluateExternalDirectoryPermission(policy, filePath, ctx.cwd, hasUI));
  }

  return strictest(decisions);
}

const DEFAULT_APPROVAL_TIMEOUT_MS = 5 * 60 * 1000;

export interface EnforceDecisionOptions {
  approvalBroker?: PermissionApprovalBroker;
  allowContextUI?: boolean;
  signal?: AbortSignal;
  approvalTimeoutMs?: number;
  onPendingApproval?: (pending: PendingPermissionRequest | undefined) => void;
  onAudit?: (audit: AuditEntry) => void;
}

function recordAudit(
  runtime: AgentRuntimeState,
  decision: PermissionDecision,
  approved: boolean,
  details: Record<string, unknown> | undefined,
  options: EnforceDecisionOptions | undefined,
): AuditEntry {
  const entry = runtime.addAudit(decision, approved, details);
  options?.onAudit?.(entry);
  return entry;
}

function approvalMessage(identity: NonNullable<AgentRuntimeState["activeIdentity"]>, decision: PermissionDecision): string {
  return [
    `Agent: ${identity.agentName} (${identity.kind})`,
    `Action: ${decision.fingerprint.normalized}`,
    `Decision: ${decision.reason}`,
    decision.matchedRule ? `Rule: ${decision.matchedRule}` : undefined,
  ].filter(Boolean).join("\n");
}

function unavailableApprovalReason(identity: NonNullable<AgentRuntimeState["activeIdentity"]> | undefined): string {
  return identity?.kind === "subagent"
    ? "denied because no parent-visible interactive approval is available for the subagent request"
    : "denied because no interactive approval is available";
}

export function createUIApprovalBroker(ctx: EnforcementContextLike): PermissionApprovalBroker | undefined {
  if (ctx.hasUI === false || (!ctx.ui?.select && !ctx.ui?.confirm)) return undefined;
  const cacheKey = (ctx.ui ?? ctx) as object;
  const cached = uiApprovalBrokers.get(cacheKey);
  if (cached) return cached;
  const broker: PermissionApprovalBroker = {
    async requestApproval(request: PermissionApprovalRequest): Promise<PermissionApprovalResult> {
      if (ctx.ui?.select) {
        const choice = await ctx.ui.select(`Required permission\n\n${request.message}`, [
          "Allow once",
          "Allow for this session",
          "Deny",
        ], { signal: request.signal });
        if (choice?.startsWith("Allow once")) return { outcome: "approved", scope: "once" };
        if (choice?.startsWith("Allow for this session")) return { outcome: "approved", scope: "session" };
        return { outcome: "denied", reason: "Permission denied by user" };
      }
      const approved = await ctx.ui?.confirm?.("Permission required", `${request.message}\n\nAllow this action once?`, { signal: request.signal });
      return approved ? { outcome: "approved", scope: "once" } : { outcome: "denied", reason: "Permission denied by user" };
    },
  };
  uiApprovalBrokers.set(cacheKey, broker);
  return broker;
}

async function requestApprovalWithGuards(
  broker: PermissionApprovalBroker,
  request: PermissionApprovalRequest,
): Promise<PermissionApprovalResult> {
  if (request.signal?.aborted) return { outcome: "aborted", reason: "Permission approval aborted" };

  const controller = new AbortController();
  const cleanup: Array<() => void> = [];
  let settledByGuard = false;

  if (request.signal) {
    const onAbort = () => {
      settledByGuard = true;
      controller.abort();
    };
    request.signal.addEventListener("abort", onAbort, { once: true });
    cleanup.push(() => request.signal?.removeEventListener("abort", onAbort));
  }

  const brokerPromise = broker.requestApproval({ ...request, signal: controller.signal }).catch((error): PermissionApprovalResult => ({
    outcome: settledByGuard ? "aborted" : "unavailable",
    reason: error instanceof Error ? error.message : String(error),
  }));

  const races: Array<Promise<PermissionApprovalResult>> = [brokerPromise];

  if (request.signal) {
    races.push(new Promise<PermissionApprovalResult>((resolve) => {
      const onAbort = () => {
        settledByGuard = true;
        resolve({ outcome: "aborted", reason: "Permission approval aborted" });
        controller.abort();
      };
      request.signal?.addEventListener("abort", onAbort, { once: true });
      cleanup.push(() => request.signal?.removeEventListener("abort", onAbort));
    }));
  }

  if (request.timeoutMs != null && request.timeoutMs > 0) {
    races.push(new Promise<PermissionApprovalResult>((resolve) => {
      const timeout = setTimeout(() => {
        settledByGuard = true;
        resolve({ outcome: "timeout", reason: `Permission approval timed out after ${request.timeoutMs}ms` });
        controller.abort();
      }, request.timeoutMs);
      cleanup.push(() => clearTimeout(timeout));
    }));
  }

  try {
    return await Promise.race(races);
  } finally {
    for (const dispose of cleanup) dispose();
  }
}

function denialReasonForApprovalOutcome(decision: PermissionDecision, result: Exclude<PermissionApprovalResult, { outcome: "approved" }>): string {
  if (result.reason) return result.reason;
  if (result.outcome === "timeout") return "Permission approval timed out";
  if (result.outcome === "aborted") return "Permission approval aborted";
  if (result.outcome === "unavailable") return "Permission approval unavailable";
  return "Permission denied by user";
}

export async function enforceDecision(
  runtime: AgentRuntimeState,
  decision: PermissionDecision,
  ctx: EnforcementContextLike,
  options: EnforceDecisionOptions = {},
): Promise<{ block?: true; reason?: string } | undefined> {
  const identity = runtime.activeIdentity;

  if (decision.state === "allow" || runtime.hasApproval(identity, decision.fingerprint)) {
    recordAudit(runtime, decision, decision.state === "ask", decision.state === "ask" ? { approvalState: "reused" } : undefined, options);
    return undefined;
  }

  if (decision.state === "deny") {
    recordAudit(runtime, decision, false, { approvalState: "not_required" }, options);
    ctx.ui?.notify?.(`Permission denied: ${decision.reason}`, "warning");
    return { block: true, reason: decision.reason };
  }

  if (!identity) {
    const denied: PermissionDecision = { ...decision, state: "deny", reason: `${decision.reason}; denied because no active agent identity is available` };
    recordAudit(runtime, denied, false, { approvalState: "unavailable", denialReason: denied.reason }, options);
    return { block: true, reason: denied.reason };
  }

  const broker = options.approvalBroker ?? (options.allowContextUI === false ? undefined : createUIApprovalBroker(ctx));
  if (!broker) {
    const reason = unavailableApprovalReason(identity);
    const denied: PermissionDecision = { ...decision, state: "deny", reason: `${decision.reason}; ${reason}` };
    recordAudit(runtime, denied, false, { approvalState: "unavailable", denialReason: reason }, options);
    return { block: true, reason: denied.reason };
  }

  const pending: PendingPermissionRequest = {
    fingerprint: decision.fingerprint,
    action: decision.fingerprint.normalized,
    reason: decision.reason,
    matchedRule: decision.matchedRule,
    requestedAt: Date.now(),
  };
  const message = approvalMessage(identity, decision);
  recordAudit(runtime, decision, false, { approvalState: "pending" }, options);
  options.onPendingApproval?.(pending);

  const result = await serializeApprovalForBroker(broker, async () => requestApprovalWithGuards(broker, {
    identity,
    decision,
    message,
    signal: options.signal ?? ctx.signal,
    timeoutMs: options.approvalTimeoutMs ?? DEFAULT_APPROVAL_TIMEOUT_MS,
  })).finally(() => {
    options.onPendingApproval?.(undefined);
  });

  if (result.outcome !== "approved") {
    const reason = denialReasonForApprovalOutcome(decision, result);
    const denied: PermissionDecision = { ...decision, state: "deny", reason: `${decision.reason}; ${reason}` };
    recordAudit(runtime, denied, false, { approvalState: result.outcome, denialReason: reason }, options);
    return { block: true, reason: denied.reason };
  }

  runtime.addApproval(identity, decision.fingerprint, result.scope);
  recordAudit(runtime, decision, true, { approvalState: "approved", approvalScope: result.scope }, options);
  return undefined;
}
