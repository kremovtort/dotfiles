import { homedir } from "node:os";
import { relative, resolve } from "node:path";
import type {
  ActionFingerprint,
  DecisionState,
  DelegationRequest,
  PermissionDecision,
  PermissionPatternRule,
  PermissionPolicy,
  PermissionRule,
  PermissionRuleObject,
  ToolPermission,
  ToolPermissionEntry,
  ToolPermissionObject,
} from "./types.ts";

const DECISIONS = new Set(["allow", "ask", "deny"]);
const SUPPORTED_PERMISSION_KEYS = new Set(["*", "tools", "bash", "subagents", "external_directory"]);
const RULE_OBJECT_KEYS = new Set(["rules"]);
const TOOL_OBJECT_KEYS = new Set(["entries"]);
const SUPPORTED_KEYS_MESSAGE = "Supported permission entries are '*', 'tools', 'bash', 'subagents', and 'external_directory'. MCP permissions are not supported yet.";

export function isDecision(value: unknown): value is DecisionState {
  return typeof value === "string" && DECISIONS.has(value);
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function isRuleObject(value: PermissionRule | undefined): value is PermissionRuleObject {
  return isRecord(value) && Array.isArray((value as PermissionRuleObject).rules);
}

function isToolObject(value: ToolPermission | undefined): value is ToolPermissionObject {
  return isRecord(value) && Array.isArray((value as ToolPermissionObject).entries);
}

function parseRule(raw: unknown, path: string): PermissionRule {
  if (isDecision(raw)) return raw;
  if (!isRecord(raw)) throw new Error(`${path} must be a permission action or an object of pattern rules.`);

  if (Array.isArray((raw as { rules?: unknown }).rules) && Object.keys(raw).every((key) => RULE_OBJECT_KEYS.has(key))) {
    const rules = (raw as { rules: unknown[] }).rules.map((entry, index): PermissionPatternRule => {
      if (!isRecord(entry) || typeof entry.pattern !== "string" || !isDecision(entry.decision)) {
        throw new Error(`${path}.rules[${index}] must contain a string pattern and allow|ask|deny decision.`);
      }
      return { pattern: entry.pattern, decision: entry.decision };
    });
    return { rules };
  }

  const rules: PermissionPatternRule[] = [];
  for (const [pattern, decision] of Object.entries(raw)) {
    if (!isDecision(decision)) throw new Error(`${path}.${pattern} must be allow, ask, or deny.`);
    rules.push({ pattern, decision });
  }
  return { rules };
}

function parseTools(raw: unknown, path: string): ToolPermission {
  if (isDecision(raw)) return raw;
  if (!isRecord(raw)) throw new Error(`${path} must be a permission action or an object of tool rules.`);

  if (Array.isArray((raw as { entries?: unknown }).entries) && Object.keys(raw).every((key) => TOOL_OBJECT_KEYS.has(key))) {
    const entries = (raw as { entries: unknown[] }).entries.map((entry, index): ToolPermissionEntry => {
      if (!isRecord(entry) || typeof entry.pattern !== "string" || entry.rule == null) {
        throw new Error(`${path}.entries[${index}] must contain a string pattern and rule.`);
      }
      return { pattern: entry.pattern, rule: parseRule(entry.rule, `${path}.entries[${index}].rule`) };
    });
    return { entries };
  }

  const entries: ToolPermissionEntry[] = [];
  for (const [pattern, rule] of Object.entries(raw)) {
    entries.push({ pattern, rule: parseRule(rule, `${path}.${pattern}`) });
  }
  return { entries };
}

function hasPolicyContent(policy: PermissionPolicy): boolean {
  return policy.default != null || policy.tools != null || policy.bash != null || policy.subagents != null || policy.external_directory != null;
}

function legacyToolPolicy(allowedTools?: string[], disallowedTools?: string[]): ToolPermissionObject | undefined {
  const entries: ToolPermissionEntry[] = [];
  if (allowedTools?.length) {
    entries.push({ pattern: "*", rule: "deny" });
    for (const tool of allowedTools) entries.push({ pattern: tool, rule: "allow" });
  }
  for (const tool of disallowedTools ?? []) entries.push({ pattern: tool, rule: "deny" });
  return entries.length ? { entries } : undefined;
}

export function normalizePermissionPolicy(
  raw: unknown,
  legacy: { allowedTools?: string[]; disallowedTools?: string[] } = {},
): PermissionPolicy | undefined {
  let policy: PermissionPolicy = {};

  if (raw == null) {
    policy = {};
  } else if (isDecision(raw)) {
    policy = { default: raw };
  } else if (isRecord(raw)) {
    for (const [key, value] of Object.entries(raw)) {
      if (!SUPPORTED_PERMISSION_KEYS.has(key)) {
        throw new Error(`Unsupported permission category "${key}". ${SUPPORTED_KEYS_MESSAGE}`);
      }
      if (key === "*") {
        if (!isDecision(value)) throw new Error(`permission.* must be allow, ask, or deny.`);
        policy.default = value;
      } else if (key === "tools") policy.tools = parseTools(value, "permission.tools");
      else if (key === "bash") policy.bash = parseRule(value, "permission.bash");
      else if (key === "subagents") policy.subagents = parseRule(value, "permission.subagents");
      else if (key === "external_directory") policy.external_directory = parseRule(value, "permission.external_directory");
    }
  } else {
    throw new Error(`permission must be allow, ask, deny, or an object. ${SUPPORTED_KEYS_MESSAGE}`);
  }

  const legacyTools = legacyToolPolicy(legacy.allowedTools, legacy.disallowedTools);
  if (legacyTools) policy = mergePermissionPolicies(policy, { tools: legacyTools });
  return hasPolicyContent(policy) ? policy : undefined;
}

function escapeRegExp(value: string): string {
  return value.replace(/[.+^${}()|[\]\\]/g, "\\$&");
}

function expandHomePattern(pattern: string): string {
  const home = homedir();
  if (pattern === "~" || pattern === "$HOME") return home;
  if (pattern.startsWith("~/")) return `${home}${pattern.slice(1)}`;
  if (pattern.startsWith("$HOME/")) return `${home}${pattern.slice("$HOME".length)}`;
  return pattern;
}

function globToRegExp(pattern: string): RegExp {
  let source = "";
  for (const ch of pattern) {
    if (ch === "*") source += ".*";
    else if (ch === "?") source += ".";
    else source += escapeRegExp(ch);
  }
  return new RegExp(`^${source}$`);
}

export function matchesPattern(pattern: string, value: string): boolean {
  return globToRegExp(expandHomePattern(pattern)).test(value);
}

function evaluateRule(
  rule: PermissionRule | undefined,
  targets: string[],
  fallback: DecisionState,
  rulePath: string,
): { state: DecisionState; rule?: string } {
  if (!rule) return { state: fallback };
  if (isDecision(rule)) return { state: rule, rule: `${rulePath}:${rule}` };

  let matched: { state: DecisionState; rule: string } | undefined;
  for (const entry of rule.rules) {
    if (targets.some((target) => matchesPattern(entry.pattern, target))) {
      matched = { state: entry.decision, rule: `${rulePath}:${entry.pattern}` };
    }
  }
  return matched ?? { state: fallback };
}

function defaultDecision(policy: PermissionPolicy | undefined, hasUI: boolean): DecisionState {
  return policy?.default ?? (hasUI ? "ask" : "deny");
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

export function strictestDecision(a: PermissionDecision, b: PermissionDecision): PermissionDecision {
  if (a.state === "deny" || b.state === "deny") return a.state === "deny" ? a : b;
  if (a.state === "ask" || b.state === "ask") return a.state === "ask" ? a : b;
  return a;
}

function evaluateToolRule(
  tools: ToolPermission | undefined,
  toolName: string,
  target: string,
  fallback: DecisionState,
): { state: DecisionState; rule?: string } {
  if (!tools) return { state: fallback };
  if (isDecision(tools)) return { state: tools, rule: `tools:${tools}` };

  let matchedEntry: ToolPermissionEntry | undefined;
  for (const entry of tools.entries) {
    if (matchesPattern(entry.pattern, toolName)) matchedEntry = entry;
  }
  if (!matchedEntry) return { state: fallback };
  const rule = matchedEntry.rule;
  if (isDecision(rule)) return { state: rule, rule: `tools:${matchedEntry.pattern}` };
  return evaluateRule(rule, [target], fallback, `tools:${matchedEntry.pattern}`);
}

export function evaluateToolPermission(
  policy: PermissionPolicy | undefined,
  toolName: string,
  hasUI: boolean,
  target = toolName,
): PermissionDecision {
  const fallback = defaultDecision(policy, hasUI);
  const result = evaluateToolRule(policy?.tools, toolName, target, fallback);
  const fingerprintTarget = target === toolName ? toolName : `${toolName}:${target}`;
  return decision(result.state, `tool ${toolName} resolved to ${result.state} for ${target}`, makeFingerprint("tool", "call", fingerprintTarget), result.rule);
}

export function evaluateBashPermission(
  policy: PermissionPolicy | undefined,
  command: string,
  hasUI: boolean,
): PermissionDecision {
  const fallback = defaultDecision(policy, hasUI);
  const result = evaluateRule(policy?.bash, [command], fallback, "bash");
  return decision(result.state, `bash command resolved to ${result.state}`, makeFingerprint("bash", "exec", command), result.rule);
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

export function makeExternalDirectoryFingerprint(
  normalizedPath: string,
  fileToolOrOperation?: string,
): ActionFingerprint {
  const target = fileToolOrOperation ? `${fileToolOrOperation}:${normalizedPath}` : normalizedPath;
  return makeFingerprint("file", "external_directory", target);
}

export function evaluateExternalDirectoryPermission(
  policy: PermissionPolicy | undefined,
  rawPath: string,
  cwd: string,
  hasUI: boolean,
  fileToolOrOperation?: string,
): PermissionDecision {
  const normalized = normalizePathForPolicy(cwd, rawPath);
  if (!normalized.external) {
    return decision("allow", `${normalized.projectRelative} is inside the project`, makeExternalDirectoryFingerprint(normalized.projectRelative));
  }
  const fallback = defaultDecision(policy, hasUI);
  const result = evaluateRule(policy?.external_directory, [normalized.absolute], fallback, "external_directory");
  return decision(
    result.state,
    `external path ${normalized.absolute} resolved to ${result.state}`,
    makeExternalDirectoryFingerprint(normalized.absolute, fileToolOrOperation),
    result.rule,
  );
}

export function evaluateFilePermission(
  policy: PermissionPolicy | undefined,
  operation: "read" | "write" | "edit",
  rawPath: string,
  cwd: string,
  hasUI: boolean,
): PermissionDecision {
  const normalized = normalizePathForPolicy(cwd, rawPath);
  const target = normalized.external ? normalized.absolute : normalized.projectRelative;
  const toolDecision = evaluateToolPermission(policy, operation, hasUI, target);
  if (!normalized.external) return toolDecision;
  return strictestDecision(toolDecision, evaluateExternalDirectoryPermission(policy, rawPath, cwd, hasUI, operation));
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
    inheritContext: request.inheritContext,
    inheritExtensions: request.inheritExtensions,
    inheritSkills: request.inheritSkills,
    cwd: request.cwd,
  })}`;
}

function delegationTargets(request: DelegationRequest): string[] {
  const targets = [request.agentName, delegationTarget(request)];
  if (request.source) targets.push(`source:${request.source}`);
  if (request.background) targets.push("background");
  if (request.modelOverride) targets.push("override:model");
  if (request.inheritContext) targets.push("context_inheritance");
  if (request.inheritExtensions) targets.push("extension_inheritance");
  if (request.inheritSkills) targets.push("skill_inheritance");
  if (request.cwd) targets.push(`cwd:${request.cwd}`);
  return targets;
}

export function evaluateDelegationPermission(
  policy: PermissionPolicy | undefined,
  request: DelegationRequest,
  hasUI: boolean,
): PermissionDecision {
  const target = delegationTarget(request);
  const fallback = defaultDecision(policy, hasUI);
  const result = evaluateRule(policy?.subagents, delegationTargets(request), fallback, "subagents");
  return decision(result.state, `delegation to ${request.agentName} resolved to ${result.state}`, makeFingerprint("subagent", "delegate", target), result.rule);
}

export function evaluateSkillPermission(
  policy: PermissionPolicy | undefined,
  skillName: string,
  hasUI: boolean,
): PermissionDecision {
  return evaluateToolPermission(policy, `skill:${skillName}`, hasUI, skillName);
}

export function fingerprintEquals(a: ActionFingerprint, b: ActionFingerprint): boolean {
  return a.normalized === b.normalized;
}

function asRuleObject(rule: PermissionRule): PermissionRuleObject {
  return isDecision(rule) ? { rules: [{ pattern: "*", decision: rule }] } : rule;
}

function mergeRule(parent?: PermissionRule, child?: PermissionRule): PermissionRule | undefined {
  if (!parent) return child;
  if (!child) return parent;
  if (isDecision(child)) return child;
  return { rules: [...asRuleObject(parent).rules, ...child.rules] };
}

function asToolObject(rule: ToolPermission): ToolPermissionObject {
  return isDecision(rule) ? { entries: [{ pattern: "*", rule }] } : rule;
}

function mergeTools(parent?: ToolPermission, child?: ToolPermission): ToolPermission | undefined {
  if (!parent) return child;
  if (!child) return parent;
  if (isDecision(child)) return child;
  return { entries: [...asToolObject(parent).entries, ...child.entries] };
}

export function mergePermissionPolicies(parent: PermissionPolicy | undefined, child: PermissionPolicy | undefined): PermissionPolicy {
  return {
    default: child?.default ?? parent?.default,
    tools: mergeTools(parent?.tools, child?.tools),
    bash: mergeRule(parent?.bash, child?.bash),
    subagents: mergeRule(parent?.subagents, child?.subagents),
    external_directory: mergeRule(parent?.external_directory, child?.external_directory),
  };
}

export function composePolicies(parent: PermissionPolicy | undefined, child: PermissionPolicy | undefined): PermissionPolicy {
  return mergePermissionPolicies(parent, child);
}

function toolRuleCanResolveNonDeny(rule: PermissionRule, fallback: DecisionState): boolean {
  if (isDecision(rule)) return rule !== "deny";
  const lastCatchAllIndex = rule.rules.findLastIndex((entry) => entry.pattern === "*");
  if (lastCatchAllIndex >= 0) {
    const catchAll = rule.rules[lastCatchAllIndex];
    return catchAll.decision !== "deny" || rule.rules.slice(lastCatchAllIndex + 1).some((entry) => entry.decision !== "deny");
  }
  return fallback !== "deny" || rule.rules.some((entry) => entry.decision !== "deny");
}

export function isToolCategoricallyDenied(policy: PermissionPolicy | undefined, toolName: string, hasUI: boolean): boolean {
  const fallback = defaultDecision(policy, hasUI);
  const tools = policy?.tools;
  if (!tools) return fallback === "deny";
  if (isDecision(tools)) return tools === "deny";

  let matchedEntry: ToolPermissionEntry | undefined;
  for (const entry of tools.entries) {
    if (matchesPattern(entry.pattern, toolName)) matchedEntry = entry;
  }
  if (!matchedEntry) return fallback === "deny";
  return !toolRuleCanResolveNonDeny(matchedEntry.rule, fallback);
}

export function deriveActiveToolNames(policy: PermissionPolicy | undefined, toolNames: string[], hasUI: boolean): string[] {
  return toolNames.filter((toolName) => !isToolCategoricallyDenied(policy, toolName, hasUI));
}

export function stablePolicyHash(policy: PermissionPolicy | undefined): string {
  const json = stableStringify(policy ?? {});
  let hash = 2166136261;
  for (let i = 0; i < json.length; i++) {
    hash ^= json.charCodeAt(i);
    hash = Math.imul(hash, 16777619);
  }
  return (hash >>> 0).toString(16);
}
