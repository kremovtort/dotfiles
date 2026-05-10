import { relative, resolve } from "node:path";
import type {
  ActionFingerprint,
  DecisionState,
  DelegationRequest,
  FilePolicy,
  PatternRuleSet,
  PermissionDecision,
  PermissionPolicy,
} from "./types.ts";

const DECISIONS = new Set(["allow", "ask", "deny"]);
const SAFE_READ_ONLY_COMMANDS = [
  /^\s*(cat|head|tail|less|more|grep|rg|find|fd|ls|pwd|echo|printf|wc|sort|uniq|diff|file|stat|du|df|tree|which|whereis|type|env|printenv|uname|whoami|id|date|ps|jq|bat|eza)\b/i,
  /^\s*git\s+(status|log|diff|show|branch|remote|config\s+--get|ls-)\b/i,
  /^\s*npm\s+(list|ls|view|info|search|outdated|audit)\b/i,
  /^\s*node\s+--version\b/i,
  /^\s*python\s+--version\b/i,
];

const COMPOSED_POLICY = Symbol("agent-permission-framework.composedPolicy");
type ComposedPolicy = PermissionPolicy & { [COMPOSED_POLICY]?: { parent?: PermissionPolicy; child?: PermissionPolicy } };

function composed(policy: PermissionPolicy | undefined): { parent?: PermissionPolicy; child?: PermissionPolicy } | undefined {
  return (policy as ComposedPolicy | undefined)?.[COMPOSED_POLICY];
}

function strictestDecision(a: PermissionDecision, b: PermissionDecision): PermissionDecision {
  if (a.state === "deny" || b.state === "deny") return a.state === "deny" ? a : b;
  if (a.state === "ask" || b.state === "ask") return a.state === "ask" ? a : b;
  return a;
}

function neutralDecision(category: ActionFingerprint["category"], operation: string, target: string): PermissionDecision {
  return decision("allow", `${category} ${target} has no child restriction`, makeFingerprint(category, operation, target));
}

function childPolicyForCategory(policy: PermissionPolicy | undefined, category: keyof PermissionPolicy): PermissionPolicy | undefined {
  if (!policy) return undefined;
  return policy.default != null || policy[category] != null ? policy : undefined;
}

function withComposedPolicy(base: PermissionPolicy, parent: PermissionPolicy | undefined, child: PermissionPolicy | undefined): PermissionPolicy {
  Object.defineProperty(base, COMPOSED_POLICY, { value: { parent, child }, enumerable: false });
  return base;
}

function isDecision(value: unknown): value is DecisionState {
  return typeof value === "string" && DECISIONS.has(value);
}

function globToRegExp(pattern: string): RegExp {
  const escaped = pattern
    .replace(/[.+^${}()|[\]\\]/g, "\\$&")
    .replace(/\*\*/g, "__DOUBLE_STAR__")
    .replace(/\*/g, "[^/]*")
    .replace(/__DOUBLE_STAR__/g, ".*");
  return new RegExp(`^${escaped}$`);
}

export function matchesPattern(pattern: string, value: string): boolean {
  if (pattern === value) return true;
  if (pattern.includes("*") || pattern.includes("?")) return globToRegExp(pattern.replace(/\?/g, "[^/]")).test(value);
  if (pattern.startsWith("^") || pattern.includes("\\b") || pattern.endsWith("$")) {
    try {
      return new RegExp(pattern).test(value);
    } catch {
      return false;
    }
  }
  return value.includes(pattern);
}

function collectFromRuleSet(ruleSet: PatternRuleSet | undefined, target: string): Array<{ state: DecisionState; rule: string }> {
  if (!ruleSet) return [];
  const matches: Array<{ state: DecisionState; rule: string }> = [];
  for (const state of ["deny", "ask", "allow"] as const) {
    const rules = ruleSet[state] ?? [];
    for (const rule of rules) {
      if (matchesPattern(rule, target)) matches.push({ state, rule: `${state}:${rule}` });
    }
  }
  return matches;
}

function chooseDecision(
  matches: Array<{ state: DecisionState; rule: string }>,
  fallback: DecisionState,
): { state: DecisionState; rule?: string } {
  for (const state of ["deny", "ask", "allow"] as const) {
    const match = matches.find((candidate) => candidate.state === state);
    if (match) return { state, rule: match.rule };
  }
  return { state: fallback };
}

function defaultDecision(policy: PermissionPolicy | undefined, hasUI: boolean): DecisionState {
  return policy?.default ?? (hasUI ? "ask" : "deny");
}

function evaluateNamedCategory(
  category: (PatternRuleSet & Record<string, unknown>) | undefined,
  target: string,
  fallback: DecisionState,
): { state: DecisionState; rule?: string } {
  const matches = collectFromRuleSet(category, target);
  const exact = category?.[target];
  if (isDecision(exact)) matches.push({ state: exact, rule: `exact:${target}` });
  return chooseDecision(matches, category?.default ?? fallback);
}

export function makeFingerprint(
  category: ActionFingerprint["category"],
  operation: string,
  target: string,
): ActionFingerprint {
  return { category, operation, target, normalized: `${category}:${operation}:${target}` };
}

function decision(
  state: DecisionState,
  reason: string,
  fingerprint: ActionFingerprint,
  matchedRule?: string,
): PermissionDecision {
  return { state, reason, matchedRule, fingerprint };
}

export function evaluateToolPermission(
  policy: PermissionPolicy | undefined,
  toolName: string,
  hasUI: boolean,
): PermissionDecision {
  const parts = composed(policy);
  if (parts) {
    const parentDecision = parts.parent ? evaluateToolPermission(parts.parent, toolName, hasUI) : neutralDecision("tool", "call", toolName);
    const childDecision = childPolicyForCategory(parts.child, "tools") ? evaluateToolPermission(parts.child, toolName, hasUI) : neutralDecision("tool", "call", toolName);
    return strictestDecision(parentDecision, childDecision);
  }
  const fallback = defaultDecision(policy, hasUI);
  const result = evaluateNamedCategory(policy?.tools, toolName, fallback);
  return decision(result.state, `tool ${toolName} resolved to ${result.state}`, makeFingerprint("tool", "call", toolName), result.rule);
}

export function evaluateBashPermission(
  policy: PermissionPolicy | undefined,
  command: string,
  hasUI: boolean,
): PermissionDecision {
  const parts = composed(policy);
  if (parts) {
    const parentDecision = parts.parent ? evaluateBashPermission(parts.parent, command, hasUI) : neutralDecision("bash", "exec", command);
    const childDecision = childPolicyForCategory(parts.child, "bash") ? evaluateBashPermission(parts.child, command, hasUI) : neutralDecision("bash", "exec", command);
    return strictestDecision(parentDecision, childDecision);
  }
  const bash = policy?.bash;
  const matches = collectFromRuleSet(bash, command);
  if (bash?.readOnly) {
    const safe = SAFE_READ_ONLY_COMMANDS.some((pattern) => pattern.test(command));
    matches.push({ state: safe ? "allow" : "deny", rule: safe ? "readOnly:safe" : "readOnly:blocked" });
  }
  const fallback = bash?.default ?? defaultDecision(policy, hasUI);
  const result = chooseDecision(matches, fallback);
  return decision(result.state, `bash command resolved to ${result.state}`, makeFingerprint("bash", "exec", command), result.rule);
}

function fileRuleSet(filePolicy: FilePolicy | undefined, operation: string): PatternRuleSet | undefined {
  if (!filePolicy) return undefined;
  if (operation === "read") return filePolicy.read;
  if (operation === "write") return filePolicy.write;
  if (operation === "edit") return filePolicy.edit;
  return undefined;
}

export function normalizePathForPolicy(cwd: string, rawPath: string): { absolute: string; projectRelative: string; external: boolean } {
  const absolute = resolve(cwd, rawPath.replace(/^@/, ""));
  const projectRelative = relative(cwd, absolute) || ".";
  return {
    absolute,
    projectRelative,
    external: projectRelative.startsWith("..") || projectRelative === "..",
  };
}

export function evaluateFilePermission(
  policy: PermissionPolicy | undefined,
  operation: "read" | "write" | "edit",
  rawPath: string,
  cwd: string,
  hasUI: boolean,
): PermissionDecision {
  const parts = composed(policy);
  if (parts) {
    const parentDecision = parts.parent ? evaluateFilePermission(parts.parent, operation, rawPath, cwd, hasUI) : neutralDecision("file", operation, rawPath);
    const childDecision = childPolicyForCategory(parts.child, "files") ? evaluateFilePermission(parts.child, operation, rawPath, cwd, hasUI) : neutralDecision("file", operation, rawPath);
    return strictestDecision(parentDecision, childDecision);
  }
  const files = policy?.files;
  const normalized = normalizePathForPolicy(cwd, rawPath);
  const target = normalized.projectRelative;
  const matches = [
    ...collectFromRuleSet(files, target),
    ...collectFromRuleSet(fileRuleSet(files, operation), target),
  ];

  if (normalized.external) {
    const external = files?.external_directory;
    if (isDecision(external)) matches.push({ state: external, rule: `external_directory:${external}` });
    else matches.push(...collectFromRuleSet(external, normalized.absolute));
  }

  const fallback = fileRuleSet(files, operation)?.default ?? files?.default ?? defaultDecision(policy, hasUI);
  const result = chooseDecision(matches, fallback);
  return decision(result.state, `${operation} ${target} resolved to ${result.state}`, makeFingerprint("file", operation, target), result.rule);
}

function stableStringify(value: unknown): string {
  if (value == null || typeof value !== "object") return JSON.stringify(value);
  if (Array.isArray(value)) return `[${value.map(stableStringify).join(",")}]`;
  const record = value as Record<string, unknown>;
  return `{${Object.keys(record).sort().filter((key) => record[key] !== undefined).map((key) => `${JSON.stringify(key)}:${stableStringify(record[key])}`).join(",")}}`;
}

function delegationTarget(request: DelegationRequest): string {
  return `${request.agentName}:${stableStringify({
    source: request.source,
    background: request.background,
    modelOverride: request.modelOverride,
    toolOverride: request.toolOverride,
    inheritContext: request.inheritContext,
    inheritExtensions: request.inheritExtensions,
    inheritSkills: request.inheritSkills,
    cwd: request.cwd,
  })}`;
}

export function evaluateDelegationPermission(
  policy: PermissionPolicy | undefined,
  request: DelegationRequest,
  hasUI: boolean,
): PermissionDecision {
  const target = delegationTarget(request);
  const parts = composed(policy);
  if (parts) {
    const parentDecision = parts.parent ? evaluateDelegationPermission(parts.parent, request, hasUI) : neutralDecision("agent", "delegate", target);
    const childDecision = childPolicyForCategory(parts.child, "agents") ? evaluateDelegationPermission(parts.child, request, hasUI) : neutralDecision("agent", "delegate", target);
    return strictestDecision(parentDecision, childDecision);
  }
  const agents = policy?.agents;
  const matches = collectFromRuleSet(agents, request.agentName);
  const exact = agents?.[request.agentName];
  if (isDecision(exact)) matches.push({ state: exact, rule: `agent:${request.agentName}` });
  if (request.source === "project" && isDecision(agents?.project)) {
    matches.push({ state: agents.project, rule: `project:${agents.project}` });
  }
  if (request.background && isDecision(agents?.background)) matches.push({ state: agents.background, rule: "background" });
  if (request.modelOverride && isDecision(agents?.model_override)) matches.push({ state: agents.model_override, rule: "model_override" });
  if (request.toolOverride?.length && isDecision(agents?.tool_override)) matches.push({ state: agents.tool_override, rule: "tool_override" });
  if (request.inheritContext && isDecision(agents?.context_inheritance)) matches.push({ state: agents.context_inheritance, rule: "context_inheritance" });
  if (request.inheritExtensions && isDecision(agents?.extension_inheritance)) matches.push({ state: agents.extension_inheritance, rule: "extension_inheritance" });
  if (request.inheritSkills && isDecision(agents?.skill_inheritance)) matches.push({ state: agents.skill_inheritance, rule: "skill_inheritance" });

  const fallback = agents?.default ?? defaultDecision(policy, hasUI);
  const result = chooseDecision(matches, fallback);
  return decision(result.state, `delegation to ${request.agentName} resolved to ${result.state}`, makeFingerprint("agent", "delegate", target), result.rule);
}

export function evaluateSkillPermission(
  policy: PermissionPolicy | undefined,
  skillName: string,
  hasUI: boolean,
): PermissionDecision {
  const parts = composed(policy);
  if (parts) {
    const parentDecision = parts.parent ? evaluateSkillPermission(parts.parent, skillName, hasUI) : neutralDecision("skill", "use", skillName);
    const childDecision = childPolicyForCategory(parts.child, "skills") ? evaluateSkillPermission(parts.child, skillName, hasUI) : neutralDecision("skill", "use", skillName);
    return strictestDecision(parentDecision, childDecision);
  }
  const fallback = defaultDecision(policy, hasUI);
  const result = evaluateNamedCategory(policy?.skills, skillName, fallback);
  return decision(result.state, `skill ${skillName} resolved to ${result.state}`, makeFingerprint("skill", "use", skillName), result.rule);
}

export function fingerprintEquals(a: ActionFingerprint, b: ActionFingerprint): boolean {
  return a.normalized === b.normalized;
}

function minDecision(a: DecisionState | undefined, b: DecisionState | undefined): DecisionState | undefined {
  if (!a) return b;
  if (!b) return a;
  if (a === "deny" || b === "deny") return "deny";
  if (a === "ask" || b === "ask") return "ask";
  return "allow";
}

function mergeRuleSet(parent?: PatternRuleSet, child?: PatternRuleSet): PatternRuleSet | undefined {
  if (!parent && !child) return undefined;
  return {
    default: minDecision(parent?.default, child?.default),
    allow: [...(parent?.allow ?? []), ...(child?.allow ?? [])],
    ask: [...(parent?.ask ?? []), ...(child?.ask ?? [])],
    deny: [...(parent?.deny ?? []), ...(child?.deny ?? [])],
  };
}

function mergeNamedCategory<T extends PatternRuleSet & Record<string, unknown>>(parent?: T, child?: T): T | undefined {
  if (!parent && !child) return undefined;
  const merged: Record<string, unknown> = { ...mergeRuleSet(parent, child) };
  const keys = new Set([...Object.keys(parent ?? {}), ...Object.keys(child ?? {})]);
  for (const key of keys) {
    if (["default", "allow", "ask", "deny"].includes(key)) continue;
    const parentValue = parent?.[key];
    const childValue = child?.[key];
    if (isDecision(parentValue) || isDecision(childValue)) merged[key] = minDecision(parentValue as DecisionState | undefined, childValue as DecisionState | undefined);
    else if (typeof parentValue === "object" || typeof childValue === "object") merged[key] = mergeNamedCategory(parentValue as T | undefined, childValue as T | undefined);
    else merged[key] = childValue ?? parentValue;
  }
  return merged as T;
}

export function composePolicies(parent: PermissionPolicy | undefined, child: PermissionPolicy | undefined): PermissionPolicy {
  return withComposedPolicy({
    default: minDecision(parent?.default, child?.default) ?? "deny",
    tools: mergeNamedCategory(parent?.tools, child?.tools),
    bash: mergeNamedCategory(parent?.bash, child?.bash),
    files: mergeNamedCategory(parent?.files, child?.files),
    agents: mergeNamedCategory(parent?.agents, child?.agents),
    skills: mergeNamedCategory(parent?.skills, child?.skills),
  }, parent, child);
}

export function stablePolicyHash(policy: PermissionPolicy | undefined): string {
  const json = JSON.stringify(policy ?? {}, Object.keys(policy ?? {}).sort());
  let hash = 2166136261;
  for (let i = 0; i < json.length; i++) {
    hash ^= json.charCodeAt(i);
    hash = Math.imul(hash, 16777619);
  }
  return (hash >>> 0).toString(16);
}
