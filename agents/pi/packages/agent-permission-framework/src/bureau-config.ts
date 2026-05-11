import { existsSync, readFileSync, statSync } from "node:fs";
import { join } from "node:path";
import { parse as parseJsonc, printParseErrorCode, type ParseError } from "jsonc-parser";
import { parseDocument } from "yaml";
import { normalizePermissionPolicy } from "./policy.ts";
import type { AgentKind, AgentSource, PermissionPolicy, ThinkingLevel } from "./types.ts";

export const BUREAU_CONFIG_FILENAMES = ["bureau.jsonc", "bureau.json", "bureau.yaml", "bureau.yml"] as const;

export interface BureauAgentPatch {
  name: string;
  source: AgentSource;
  filePath: string;
  enabled?: boolean;
  kind?: AgentKind;
  description?: string;
  prompt?: string;
  model?: string;
  thinking?: ThinkingLevel;
  maxTurns?: number;
  promptMode?: "replace" | "append";
  inheritContext?: boolean;
  inheritExtensions?: boolean;
  inheritSkills?: boolean;
  runInBackground?: boolean;
  permission?: PermissionPolicy;
}

export interface BureauConfigLayer {
  source: AgentSource;
  filePath: string;
  agentPatches: BureauAgentPatch[];
  permission?: PermissionPolicy;
  warnings: Array<{ filePath: string; reason: string }>;
}

export interface BureauConfigLoadResult {
  layer?: BureauConfigLayer;
  warnings: Array<{ filePath: string; reason: string }>;
}

const TOP_LEVEL_KEYS = new Set(["agent", "permission"]);
const AGENT_KEYS = new Set([
  "kind",
  "description",
  "model",
  "thinking",
  "max_turns",
  "prompt_mode",
  "inherit_context",
  "inherit_extensions",
  "inherit_skills",
  "run_in_background",
  "enabled",
  "prompt",
  "permission",
]);

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function isFile(path: string): boolean {
  try {
    return statSync(path).isFile();
  } catch {
    return false;
  }
}

function asString(value: unknown): string | undefined {
  return typeof value === "string" && value.trim() ? value.trim() : undefined;
}

function asNumber(value: unknown): number | undefined {
  return typeof value === "number" && Number.isFinite(value) ? value : undefined;
}

function asBoolean(value: unknown): boolean | undefined {
  if (typeof value === "boolean") return value;
  return undefined;
}

function asKind(value: unknown): AgentKind | undefined {
  return value === "main" || value === "subagent" ? value : undefined;
}

function asThinking(value: unknown): ThinkingLevel | undefined {
  return typeof value === "string" && ["off", "minimal", "low", "medium", "high", "xhigh"].includes(value)
    ? value as ThinkingLevel
    : undefined;
}

function asPromptMode(value: unknown): "replace" | "append" | undefined {
  return value === "replace" || value === "append" ? value : undefined;
}

function parseJsonLike(text: string, filePath: string): unknown {
  const errors: ParseError[] = [];
  const jsonc = filePath.endsWith(".jsonc");
  const value = parseJsonc(text, errors, {
    allowTrailingComma: jsonc,
    disallowComments: !jsonc,
  });
  if (errors.length > 0) {
    const summary = errors
      .map((error) => `${printParseErrorCode(error.error)} at offset ${error.offset}`)
      .join(", ");
    throw new Error(summary);
  }
  return value;
}

function parseYamlLike(text: string): unknown {
  const document = parseDocument(text, { prettyErrors: false });
  if (document.errors.length > 0) {
    throw new Error(document.errors.map((error) => error.message).join("; "));
  }
  return document.toJSON();
}

export function selectBureauConfigFile(dir: string): { filePath?: string; warnings: Array<{ filePath: string; reason: string }> } {
  const candidates = BUREAU_CONFIG_FILENAMES.map((name) => join(dir, name)).filter((path) => existsSync(path) && isFile(path));
  const selected = candidates[0];
  const warnings = candidates.slice(1).map((filePath) => ({
    filePath,
    reason: `ignored because ${selected} has higher bureau config precedence in the same directory`,
  }));
  return { filePath: selected, warnings };
}

export function parseBureauConfigFile(filePath: string, source: AgentSource): BureauConfigLayer {
  const text = readFileSync(filePath, "utf8");
  const raw = filePath.endsWith(".yaml") || filePath.endsWith(".yml") ? parseYamlLike(text) : parseJsonLike(text, filePath);
  if (!isRecord(raw)) throw new Error("bureau config must be an object");

  const unsupportedTopLevel = Object.keys(raw).filter((key) => !TOP_LEVEL_KEYS.has(key));
  if (unsupportedTopLevel.length > 0) {
    throw new Error(`unsupported top-level bureau config field${unsupportedTopLevel.length === 1 ? "" : "s"}: ${unsupportedTopLevel.join(", ")}`);
  }

  let permission: PermissionPolicy | undefined;
  if (Object.hasOwn(raw, "permission")) {
    permission = normalizePermissionPolicy(raw.permission);
  }

  const warnings: Array<{ filePath: string; reason: string }> = [];
  const agentPatches: BureauAgentPatch[] = [];
  const agentRaw = raw.agent;
  if (agentRaw != null) {
    if (!isRecord(agentRaw)) throw new Error("bureau config field agent must be an object");
    for (const [name, value] of Object.entries(agentRaw)) {
      const parsed = parseBureauAgentPatch(name, value, source, filePath);
      warnings.push(...parsed.warnings.map((reason) => ({ filePath, reason })));
      if (parsed.patch) agentPatches.push(parsed.patch);
    }
  }

  return { source, filePath, agentPatches, permission, warnings };
}

function hasPatchContent(patch: BureauAgentPatch): boolean {
  return patch.enabled != null || patch.kind != null || patch.description != null || patch.prompt != null || patch.model != null ||
    patch.thinking != null || patch.maxTurns != null || patch.promptMode != null || patch.inheritContext != null ||
    patch.inheritExtensions != null || patch.inheritSkills != null || patch.runInBackground != null || patch.permission != null;
}

function parseBureauAgentPatch(
  name: string,
  raw: unknown,
  source: AgentSource,
  filePath: string,
): { patch?: BureauAgentPatch; warnings: string[] } {
  if (!isRecord(raw)) {
    return { warnings: [`agent.${name} must be an object`] };
  }

  const warnings: string[] = [];
  for (const key of Object.keys(raw)) {
    if (!AGENT_KEYS.has(key)) warnings.push(`unsupported bureau agent config field agent.${name}.${key}`);
  }

  const patch: BureauAgentPatch = { name, source, filePath };
  if (Object.hasOwn(raw, "enabled")) {
    const value = asBoolean(raw.enabled);
    if (value == null) warnings.push(`agent.${name}.enabled must be a boolean`);
    else patch.enabled = value;
  }
  if (Object.hasOwn(raw, "kind")) {
    const value = asKind(raw.kind);
    if (!value) warnings.push(`agent.${name}.kind must be main or subagent`);
    else patch.kind = value;
  }
  if (Object.hasOwn(raw, "description")) {
    const value = asString(raw.description);
    if (!value) warnings.push(`agent.${name}.description must be a non-empty string`);
    else patch.description = value;
  }
  if (Object.hasOwn(raw, "prompt")) {
    const value = asString(raw.prompt);
    if (!value) warnings.push(`agent.${name}.prompt must be a non-empty string`);
    else patch.prompt = value;
  }
  if (Object.hasOwn(raw, "model")) {
    const value = asString(raw.model);
    if (!value) warnings.push(`agent.${name}.model must be a non-empty string`);
    else patch.model = value;
  }
  if (Object.hasOwn(raw, "thinking")) {
    const value = asThinking(raw.thinking);
    if (!value) warnings.push(`agent.${name}.thinking must be off, minimal, low, medium, high, or xhigh`);
    else patch.thinking = value;
  }
  if (Object.hasOwn(raw, "max_turns")) {
    const value = asNumber(raw.max_turns);
    if (value == null) warnings.push(`agent.${name}.max_turns must be a number`);
    else patch.maxTurns = value;
  }
  if (Object.hasOwn(raw, "prompt_mode")) {
    const value = asPromptMode(raw.prompt_mode);
    if (!value) warnings.push(`agent.${name}.prompt_mode must be replace or append`);
    else patch.promptMode = value;
  }
  if (Object.hasOwn(raw, "inherit_context")) {
    const value = asBoolean(raw.inherit_context);
    if (value == null) warnings.push(`agent.${name}.inherit_context must be a boolean`);
    else patch.inheritContext = value;
  }
  if (Object.hasOwn(raw, "inherit_extensions")) {
    const value = asBoolean(raw.inherit_extensions);
    if (value == null) warnings.push(`agent.${name}.inherit_extensions must be a boolean`);
    else patch.inheritExtensions = value;
  }
  if (Object.hasOwn(raw, "inherit_skills")) {
    const value = asBoolean(raw.inherit_skills);
    if (value == null) warnings.push(`agent.${name}.inherit_skills must be a boolean`);
    else patch.inheritSkills = value;
  }
  if (Object.hasOwn(raw, "run_in_background")) {
    const value = asBoolean(raw.run_in_background);
    if (value == null) warnings.push(`agent.${name}.run_in_background must be a boolean`);
    else patch.runInBackground = value;
  }
  if (Object.hasOwn(raw, "permission")) {
    try {
      patch.permission = normalizePermissionPolicy(raw.permission);
    } catch (error) {
      warnings.push(`agent.${name}.permission is invalid: ${error instanceof Error ? error.message : String(error)}`);
    }
  }

  return { patch: hasPatchContent(patch) ? patch : undefined, warnings };
}

export function loadBureauConfigFromDir(dir: string | undefined, source: AgentSource): BureauConfigLoadResult {
  if (!dir) return { warnings: [] };
  const selection = selectBureauConfigFile(dir);
  const warnings = [...selection.warnings];
  if (!selection.filePath) return { warnings };

  try {
    const layer = parseBureauConfigFile(selection.filePath, source);
    return { layer, warnings: [...warnings, ...layer.warnings] };
  } catch (error) {
    warnings.push({
      filePath: selection.filePath,
      reason: error instanceof Error ? error.message : String(error),
    });
    return { warnings };
  }
}
