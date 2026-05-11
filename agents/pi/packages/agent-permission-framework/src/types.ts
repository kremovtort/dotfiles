export type DecisionState = "allow" | "ask" | "deny";
export type AgentKind = "main" | "subagent";
export type AgentSource = "builtin" | "user" | "project" | "child";
export type ThinkingLevel = "off" | "minimal" | "low" | "medium" | "high" | "xhigh";

export interface PatternRuleSet {
  default?: DecisionState;
  allow?: string[];
  ask?: string[];
  deny?: string[];
}

export type NamedDecisionMap = Record<string, DecisionState | undefined>;

export interface FilePolicy extends PatternRuleSet {
  read?: PatternRuleSet;
  write?: PatternRuleSet;
  edit?: PatternRuleSet;
  external_directory?: DecisionState | PatternRuleSet;
}

export interface BashPolicy extends PatternRuleSet {
  readOnly?: boolean;
  cwd?: PatternRuleSet;
}

export interface DelegationPolicy extends PatternRuleSet {
  background?: PatternRuleSet | DecisionState;
  project?: DecisionState;
  model_override?: DecisionState;
  tool_override?: DecisionState;
  context_inheritance?: DecisionState;
  extension_inheritance?: DecisionState;
  skill_inheritance?: DecisionState;
}

export interface PermissionPolicy {
  default?: DecisionState;
  tools?: PatternRuleSet & NamedDecisionMap;
  bash?: BashPolicy;
  files?: FilePolicy;
  agents?: DelegationPolicy & NamedDecisionMap;
  skills?: PatternRuleSet & NamedDecisionMap;
}

export interface AgentDefinition {
  name: string;
  kind: AgentKind;
  description: string;
  prompt: string;
  source: AgentSource;
  filePath?: string;
  enabled: boolean;
  tools?: string[];
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
  category: "tool" | "bash" | "file" | "agent" | "skill";
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
  toolOverride?: string[];
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
  status: "queued" | "running" | "completed" | "failed" | "aborted" | "steered";
  startedAt?: number;
  completedAt?: number;
  output: string;
  error?: string;
  identity: AgentIdentity;
  cwd: string;
  pid?: number;
  sessionId?: string;
  turnCount?: number;
  maxTurns?: number;
  toolUses?: number;
  activeTools?: string[];
  queuedPosition?: number;
  pendingPermission?: PendingPermissionRequest;
  steering: string[];
}
