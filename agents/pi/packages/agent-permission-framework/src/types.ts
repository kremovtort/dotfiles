export type DecisionState = "allow" | "ask" | "deny";
export type PermissionAction = DecisionState;
export type AgentKind = "main" | "subagent";
export type AgentSource = "builtin" | "user" | "project" | "child";
export type ThinkingLevel = "off" | "minimal" | "low" | "medium" | "high" | "xhigh";

export interface PermissionPatternRule {
  pattern: string;
  decision: PermissionAction;
}

export interface PermissionRuleObject {
  rules: PermissionPatternRule[];
}

export type PermissionRule = PermissionAction | PermissionRuleObject;

export interface ToolPermissionEntry {
  pattern: string;
  rule: PermissionRule;
}

export interface ToolPermissionObject {
  entries: ToolPermissionEntry[];
}

export type ToolPermission = PermissionAction | ToolPermissionObject;

export interface PermissionPolicy {
  default?: PermissionAction;
  tools?: ToolPermission;
  bash?: PermissionRule;
  subagents?: PermissionRule;
  external_directory?: PermissionRule;
}

export interface AgentDefinition {
  name: string;
  kind: AgentKind;
  description: string;
  prompt: string;
  source: AgentSource;
  filePath?: string;
  enabled: boolean;
  /** @deprecated Legacy migration input only. Runtime tool availability is derived from permission. */
  tools?: string[];
  /** @deprecated Legacy migration input only. Runtime tool availability is derived from permission. */
  disallowedTools?: string[];
  model?: string;
  thinking?: ThinkingLevel;
  maxTurns?: number;
  promptMode: "replace" | "append";
  inheritContext?: boolean;
  inheritExtensions?: boolean;
  inheritSkills?: boolean;
  runInBackground?: boolean;
  permission?: PermissionPolicy;
}

export interface AgentIdentity {
  id: string;
  agentName: string;
  kind: AgentKind;
  source: AgentSource;
  parentId?: string;
  runId?: string;
  sessionId?: string;
  policyHash: string;
  createdAt: number;
}

export interface ActionFingerprint {
  category: "tool" | "bash" | "file" | "subagent" | "agent" | "skill";
  operation: string;
  target: string;
  normalized: string;
}

export interface PermissionDecision {
  state: DecisionState;
  reason: string;
  matchedRule?: string;
  fingerprint: ActionFingerprint;
}

export interface ApprovalRecord {
  id: string;
  identityId: string;
  fingerprint: ActionFingerprint;
  scope: "once" | "session" | "ttl";
  createdAt: number;
  expiresAt?: number;
  turnsRemaining?: number;
}

export type PermissionApprovalScope = "once" | "session";

export type PermissionApprovalResult =
  | { outcome: "approved"; scope: PermissionApprovalScope }
  | { outcome: "denied" | "timeout" | "aborted" | "unavailable"; reason?: string };

export interface PermissionApprovalRequest {
  identity: AgentIdentity;
  decision: PermissionDecision;
  message: string;
  signal?: AbortSignal;
  timeoutMs?: number;
}

export interface PermissionApprovalBroker {
  requestApproval(request: PermissionApprovalRequest): Promise<PermissionApprovalResult>;
}

export interface PendingPermissionRequest {
  fingerprint: ActionFingerprint;
  action: string;
  reason: string;
  matchedRule?: string;
  requestedAt: number;
}

export interface AuditEntry {
  id: string;
  timestamp: number;
  identity?: AgentIdentity;
  decision: PermissionDecision;
  approved?: boolean;
  details?: Record<string, unknown>;
}

export interface DelegationRequest {
  agentName: string;
  source?: AgentSource;
  background?: boolean;
  modelOverride?: string;
  inheritContext?: boolean;
  inheritExtensions?: boolean;
  inheritSkills?: boolean;
  cwd?: string;
}

export interface SubagentRunRecord {
  id: string;
  agentName: string;
  description?: string;
  task: string;
  status: "queued" | "running" | "completed" | "failed" | "aborted" | "steered" | "interrupted";
  startedAt?: number;
  completedAt?: number;
  output: string;
  error?: string;
  identity: AgentIdentity;
  cwd: string;
  pid?: number;
  sessionId?: string;
  childSessionId?: string;
  childSessionFile?: string;
  parentSessionId?: string;
  parentSessionFile?: string;
  resumable?: boolean;
  resumedFromRunId?: string;
  turnCount?: number;
  maxTurns?: number;
  toolUses?: number;
  activeTools?: string[];
  queuedPosition?: number;
  pendingPermission?: PendingPermissionRequest;
  steering: string[];
}
