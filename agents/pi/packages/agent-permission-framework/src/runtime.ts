import type {
  ActionFingerprint,
  AgentDefinition,
  AgentIdentity,
  ApprovalRecord,
  AuditEntry,
  PermissionDecision,
  PermissionPolicy,
} from "./types.ts";
import { fingerprintEquals, stablePolicyHash } from "./policy.ts";

export const STATE_ENTRY = "agent-permission-framework-state";
export const AUDIT_ENTRY = "agent-permission-framework-audit";

function id(prefix: string): string {
  return `${prefix}-${Date.now().toString(36)}-${Math.random().toString(36).slice(2, 8)}`;
}

export class AgentRuntimeState {
  activeIdentity: AgentIdentity | undefined;
  activePolicy: PermissionPolicy | undefined;
  approvals: ApprovalRecord[] = [];
  audit: AuditEntry[] = [];
  trustedProjectAgents = false;

  activateMain(agent: AgentDefinition, policy: PermissionPolicy | undefined): AgentIdentity {
    const identity: AgentIdentity = {
      id: id(`main-${agent.name}`),
      agentName: agent.name,
      kind: "main",
      source: agent.source,
      policyHash: stablePolicyHash(policy),
      createdAt: Date.now(),
    };
    this.activeIdentity = identity;
    this.activePolicy = policy;
    return identity;
  }

  createChild(parent: AgentIdentity | undefined, agent: AgentDefinition, runId: string, policy: PermissionPolicy | undefined): AgentIdentity {
    return {
      id: id(`child-${agent.name}`),
      agentName: agent.name,
      kind: "subagent",
      source: agent.source,
      parentId: parent?.id,
      runId,
      policyHash: stablePolicyHash(policy),
      createdAt: Date.now(),
    };
  }

  addApproval(identity: AgentIdentity, fingerprint: ActionFingerprint, scope: ApprovalRecord["scope"] = "session", ttlMs?: number): ApprovalRecord {
    const approval: ApprovalRecord = {
      id: id("approval"),
      identityId: identity.id,
      fingerprint,
      scope,
      createdAt: Date.now(),
      expiresAt: ttlMs ? Date.now() + ttlMs : undefined,
    };
    this.approvals.push(approval);
    return approval;
  }

  hasApproval(identity: AgentIdentity | undefined, fingerprint: ActionFingerprint): boolean {
    if (!identity) return false;
    const now = Date.now();
    const index = this.approvals.findIndex((approval) => {
      if (approval.identityId !== identity.id) return false;
      if (approval.expiresAt && approval.expiresAt < now) return false;
      return fingerprintEquals(approval.fingerprint, fingerprint);
    });
    if (index < 0) return false;
    const approval = this.approvals[index];
    if (approval.scope === "once") this.approvals.splice(index, 1);
    return true;
  }

  addAudit(decision: PermissionDecision, approved = false, details?: Record<string, unknown>): AuditEntry {
    const entry: AuditEntry = {
      id: id("audit"),
      timestamp: Date.now(),
      identity: this.activeIdentity,
      decision,
      approved,
      details,
    };
    this.audit.push(entry);
    if (this.audit.length > 200) this.audit = this.audit.slice(-200);
    return entry;
  }

  snapshot(): Record<string, unknown> {
    return {
      activeIdentity: this.activeIdentity,
      activePolicy: this.activePolicy,
      approvals: this.approvals,
      trustedProjectAgents: this.trustedProjectAgents,
    };
  }

  restore(data: unknown): void {
    if (!data || typeof data !== "object") return;
    const record = data as {
      activeIdentity?: AgentIdentity;
      activePolicy?: PermissionPolicy;
      approvals?: ApprovalRecord[];
      trustedProjectAgents?: boolean;
    };
    this.activeIdentity = record.activeIdentity;
    this.activePolicy = record.activePolicy;
    this.approvals = Array.isArray(record.approvals) ? record.approvals : [];
    this.trustedProjectAgents = record.trustedProjectAgents ?? false;
  }
}

export function restoreRuntimeFromSession(runtime: AgentRuntimeState, entries: Array<Record<string, unknown>>): void {
  const stateEntries = entries.filter((entry) => entry.type === "custom" && entry.customType === STATE_ENTRY);
  const last = stateEntries.at(-1) as { data?: unknown } | undefined;
  if (last?.data) runtime.restore(last.data);
  runtime.audit = entries
    .filter((entry) => entry.type === "custom" && entry.customType === AUDIT_ENTRY)
    .map((entry) => (entry as { data?: unknown }).data)
    .filter((data): data is AuditEntry => Boolean(data));
  if (runtime.audit.length > 200) runtime.audit = runtime.audit.slice(-200);
}

export function persistRuntime(pi: { appendEntry: (customType: string, data?: unknown) => void }, runtime: AgentRuntimeState): void {
  pi.appendEntry(STATE_ENTRY, runtime.snapshot());
}

export function persistAudit(pi: { appendEntry: (customType: string, data?: unknown) => void }, audit: AuditEntry): void {
  pi.appendEntry(AUDIT_ENTRY, audit);
}
