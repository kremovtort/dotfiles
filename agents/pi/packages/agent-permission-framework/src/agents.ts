import { existsSync, readdirSync, readFileSync, statSync } from "node:fs";
import { homedir } from "node:os";
import { dirname, join } from "node:path";
import { loadBureauConfigFromDir, type BureauAgentPatch, type BureauConfigLayer } from "./bureau-config.ts";
import { parseFrontmatter, toBoolean, toStringArray } from "./frontmatter.ts";
import { composePolicies, normalizePermissionPolicy } from "./policy.ts";
import type { AgentDefinition, AgentKind, AgentSource, PermissionPolicy, ThinkingLevel } from "./types.ts";

export interface AgentDiscoveryOptions {
  cwd: string;
  includeProjectAgents: boolean;
  userAgentDir?: string;
  projectAgentDir?: string;
  userConfigDir?: string;
  projectConfigDir?: string;
}

export interface AgentDiscoveryResult {
  agents: AgentDefinition[];
  projectAgentDir?: string;
  projectConfigDir?: string;
  projectBureauFile?: string;
  ignored: Array<{ filePath: string; reason: string }>;
}

function asRecord(value: unknown): Record<string, unknown> | undefined {
  return typeof value === "object" && value !== null && !Array.isArray(value) ? value as Record<string, unknown> : undefined;
}

function asString(value: unknown): string | undefined {
  return typeof value === "string" && value.trim() ? value.trim() : undefined;
}

function asNumber(value: unknown): number | undefined {
  return typeof value === "number" && Number.isFinite(value) ? value : undefined;
}

function asThinking(value: unknown): ThinkingLevel | undefined {
  const text = asString(value);
  return text && ["off", "minimal", "low", "medium", "high", "xhigh"].includes(text) ? text as ThinkingLevel : undefined;
}

function asKind(value: unknown): AgentKind | undefined {
  if (value === "main" || value === "subagent") return value;
  return undefined;
}

function defaultAgentBaseDir(): string {
  return process.env.PI_CODING_AGENT_DIR || join(homedir(), ".pi", "agent");
}

function defaultAgentDir(): string {
  return join(defaultAgentBaseDir(), "agents");
}

function isDirectory(path: string): boolean {
  try {
    return statSync(path).isDirectory();
  } catch {
    return false;
  }
}

export function findNearestProjectConfigDir(cwd: string): string | undefined {
  let current = cwd;
  while (true) {
    const candidate = join(current, ".pi");
    if (isDirectory(candidate)) return candidate;
    const parent = dirname(current);
    if (parent === current) return undefined;
    current = parent;
  }
}

export function findNearestProjectAgentsDir(cwd: string): string | undefined {
  const configDir = findNearestProjectConfigDir(cwd);
  if (!configDir) return undefined;
  const agentsDir = join(configDir, "agents");
  return isDirectory(agentsDir) ? agentsDir : undefined;
}

function configSourcesFor(filePath: string | undefined): string[] | undefined {
  return filePath ? [filePath] : undefined;
}

export function parseAgentMarkdown(content: string, source: AgentSource, filePath?: string): AgentDefinition | { error: string } {
  const { frontmatter, body } = parseFrontmatter(content);
  const name = asString(frontmatter.name) ?? (filePath ? filePath.split(/[\\/]/).pop()?.replace(/\.md$/, "") : undefined);
  const description = asString(frontmatter.description);
  const kind = asKind(frontmatter.kind) ?? "subagent";

  if (!name) return { error: "missing name" };
  if (!description) return { error: "missing description" };
  if (!body.trim()) return { error: "missing prompt body" };

  const enabled = toBoolean(frontmatter.enabled) ?? true;
  const promptMode = frontmatter.prompt_mode === "append" ? "append" : "replace";
  const tools = toStringArray(frontmatter.tools);
  const disallowedTools = toStringArray(frontmatter.disallowed_tools);
  let permission;
  try {
    permission = normalizePermissionPolicy(frontmatter.permission, { allowedTools: tools, disallowedTools });
  } catch (error) {
    return { error: error instanceof Error ? error.message : String(error) };
  }

  return {
    name,
    kind,
    description,
    prompt: body.trim(),
    source,
    filePath,
    configSources: configSourcesFor(filePath),
    enabled,
    tools,
    disallowedTools,
    model: asString(frontmatter.model),
    thinking: asThinking(frontmatter.thinking),
    maxTurns: asNumber(frontmatter.max_turns),
    promptMode,
    inheritContext: toBoolean(frontmatter.inherit_context),
    inheritExtensions: toBoolean(frontmatter.extensions ?? frontmatter.inherit_extensions),
    inheritSkills: toBoolean(frontmatter.skills ?? frontmatter.inherit_skills),
    runInBackground: toBoolean(frontmatter.run_in_background),
    permission,
  };
}

function loadAgentsFromDir(dir: string, source: AgentSource): { agents: AgentDefinition[]; ignored: Array<{ filePath: string; reason: string }> } {
  const agents: AgentDefinition[] = [];
  const ignored: Array<{ filePath: string; reason: string }> = [];
  if (!existsSync(dir)) return { agents, ignored };

  for (const entry of readdirSync(dir, { withFileTypes: true })) {
    if (!entry.name.endsWith(".md") || (!entry.isFile() && !entry.isSymbolicLink())) continue;
    const filePath = join(dir, entry.name);
    try {
      const parsed = parseAgentMarkdown(readFileSync(filePath, "utf8"), source, filePath);
      if ("error" in parsed) {
        ignored.push({ filePath, reason: parsed.error });
        continue;
      }
      if (!parsed.enabled) {
        ignored.push({ filePath, reason: "disabled" });
        continue;
      }
      agents.push(parsed);
    } catch (error) {
      ignored.push({ filePath, reason: error instanceof Error ? error.message : String(error) });
    }
  }
  return { agents, ignored };
}

function cloneAgent(agent: AgentDefinition): AgentDefinition {
  return {
    ...agent,
    configSources: agent.configSources ? [...agent.configSources] : configSourcesFor(agent.filePath),
  };
}

function appendSource(sources: string[] | undefined, filePath: string | undefined): string[] | undefined {
  if (!filePath) return sources;
  const next = [...(sources ?? [])];
  if (!next.includes(filePath)) next.push(filePath);
  return next;
}

function appendSources(sources: string[] | undefined, additions: string[] | undefined): string[] | undefined {
  let next = sources;
  for (const source of additions ?? []) next = appendSource(next, source);
  return next;
}

function withGlobalPolicy(agent: AgentDefinition, globalPolicy: PermissionPolicy | undefined, globalSources: string[]): AgentDefinition {
  const cloned = cloneAgent(agent);
  return {
    ...cloned,
    permission: composePolicies(globalPolicy, cloned.permission),
    configSources: appendSources(globalSources.length ? [...globalSources] : undefined, cloned.configSources),
  };
}

function applyGlobalPolicy(byName: Map<string, AgentDefinition>, layer: BureauConfigLayer, globalPolicy: PermissionPolicy | undefined): PermissionPolicy | undefined {
  if (!layer.permission) return globalPolicy;
  for (const [name, agent] of byName) {
    byName.set(name, {
      ...agent,
      permission: composePolicies(agent.permission, layer.permission),
      configSources: appendSource(agent.configSources, layer.filePath),
    });
  }
  return composePolicies(globalPolicy, layer.permission);
}

function applyBureauPatch(
  byName: Map<string, AgentDefinition>,
  disabledBases: Map<string, AgentDefinition>,
  patch: BureauAgentPatch,
  globalPolicy: PermissionPolicy | undefined,
  globalSources: string[],
  currentLayerGlobalPolicy: PermissionPolicy | undefined,
): { filePath: string; reason: string } | undefined {
  if (patch.enabled === false) {
    const existing = byName.get(patch.name) ?? disabledBases.get(patch.name);
    if (existing) disabledBases.set(patch.name, cloneAgent(existing));
    byName.delete(patch.name);
    return undefined;
  }

  const liveExisting = byName.get(patch.name);
  const disabledExisting = patch.enabled === true && !liveExisting ? disabledBases.get(patch.name) : undefined;
  const existing = liveExisting ?? disabledExisting;
  if (!existing && (!patch.description || !patch.prompt)) {
    return { filePath: patch.filePath, reason: `agent.${patch.name} is missing prompt or description` };
  }

  let base: AgentDefinition = existing ? cloneAgent(existing) : {
    name: patch.name,
    kind: patch.kind ?? "subagent",
    description: patch.description!,
    prompt: patch.prompt!,
    source: patch.source,
    filePath: patch.filePath,
    configSources: appendSource(globalSources.length ? [...globalSources] : undefined, patch.filePath),
    enabled: patch.enabled ?? true,
    promptMode: patch.promptMode ?? "replace",
    permission: globalPolicy,
  };
  if (disabledExisting && currentLayerGlobalPolicy) {
    base = {
      ...base,
      permission: composePolicies(base.permission, currentLayerGlobalPolicy),
      configSources: appendSource(base.configSources, patch.filePath),
    };
  }

  const next: AgentDefinition = {
    ...base,
    kind: patch.kind ?? base.kind,
    description: patch.description ?? base.description,
    prompt: patch.prompt ?? base.prompt,
    source: patch.source,
    filePath: patch.filePath,
    configSources: appendSource(base.configSources, patch.filePath),
    enabled: patch.enabled ?? base.enabled,
    model: patch.model ?? base.model,
    thinking: patch.thinking ?? base.thinking,
    maxTurns: patch.maxTurns ?? base.maxTurns,
    promptMode: patch.promptMode ?? base.promptMode,
    inheritContext: patch.inheritContext ?? base.inheritContext,
    inheritExtensions: patch.inheritExtensions ?? base.inheritExtensions,
    inheritSkills: patch.inheritSkills ?? base.inheritSkills,
    runInBackground: patch.runInBackground ?? base.runInBackground,
    permission: composePolicies(base.permission, patch.permission),
  };
  byName.set(patch.name, next);
  disabledBases.delete(patch.name);
  return undefined;
}

function applyBureauLayer(
  byName: Map<string, AgentDefinition>,
  disabledBases: Map<string, AgentDefinition>,
  layer: BureauConfigLayer | undefined,
  globalPolicy: PermissionPolicy | undefined,
  globalSources: string[],
  ignored: Array<{ filePath: string; reason: string }>,
): PermissionPolicy | undefined {
  if (!layer) return globalPolicy;
  const nextGlobalPolicy = applyGlobalPolicy(byName, layer, globalPolicy);
  if (layer.permission && !globalSources.includes(layer.filePath)) globalSources.push(layer.filePath);
  for (const patch of layer.agentPatches) {
    const warning = applyBureauPatch(byName, disabledBases, patch, nextGlobalPolicy, globalSources, layer.permission);
    if (warning) ignored.push(warning);
  }
  return nextGlobalPolicy;
}

export function discoverAgents(options: AgentDiscoveryOptions, builtins: AgentDefinition[] = []): AgentDiscoveryResult {
  const userConfigDir = options.userConfigDir ?? (options.userAgentDir ? dirname(options.userAgentDir) : defaultAgentBaseDir());
  const userDir = options.userAgentDir ?? defaultAgentDir();
  const projectConfigDir = options.projectConfigDir ?? (options.projectAgentDir ? dirname(options.projectAgentDir) : findNearestProjectConfigDir(options.cwd));
  const projectDir = options.projectAgentDir ?? (projectConfigDir ? join(projectConfigDir, "agents") : undefined);

  const loadedUser = loadAgentsFromDir(userDir, "user");
  const loadedUserBureau = loadBureauConfigFromDir(userConfigDir, "user");
  const loadedProject = projectDir && options.includeProjectAgents ? loadAgentsFromDir(projectDir, "project") : { agents: [], ignored: [] };
  const loadedProjectBureau = projectConfigDir && options.includeProjectAgents ? loadBureauConfigFromDir(projectConfigDir, "project") : { warnings: [] };

  const ignored = [
    ...loadedUser.ignored,
    ...loadedUserBureau.warnings,
    ...loadedProject.ignored,
    ...loadedProjectBureau.warnings,
  ];
  const byName = new Map<string, AgentDefinition>();
  const disabledBases = new Map<string, AgentDefinition>();
  let globalPolicy: PermissionPolicy | undefined;
  const globalSources: string[] = [];

  for (const agent of builtins) byName.set(agent.name, cloneAgent(agent));
  for (const agent of loadedUser.agents) {
    byName.set(agent.name, withGlobalPolicy(agent, globalPolicy, globalSources));
    disabledBases.delete(agent.name);
  }
  globalPolicy = applyBureauLayer(byName, disabledBases, loadedUserBureau.layer, globalPolicy, globalSources, ignored);
  for (const agent of loadedProject.agents) {
    byName.set(agent.name, withGlobalPolicy(agent, globalPolicy, globalSources));
    disabledBases.delete(agent.name);
  }
  globalPolicy = applyBureauLayer(byName, disabledBases, loadedProjectBureau.layer, globalPolicy, globalSources, ignored);

  return {
    agents: [...byName.values()],
    projectAgentDir: projectDir && isDirectory(projectDir) ? projectDir : undefined,
    projectConfigDir,
    projectBureauFile: loadedProjectBureau.layer?.filePath,
    ignored,
  };
}

export function selectMainAgents(agents: AgentDefinition[]): AgentDefinition[] {
  return agents.filter((agent) => agent.kind === "main");
}

export function findAgent(agents: AgentDefinition[], name: string, kind?: AgentKind): AgentDefinition | undefined {
  return agents.find((agent) => agent.name === name && (!kind || agent.kind === kind));
}
