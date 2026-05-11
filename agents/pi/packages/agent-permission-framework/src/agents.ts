import { existsSync, readdirSync, readFileSync, statSync } from "node:fs";
import { homedir } from "node:os";
import { dirname, join } from "node:path";
import { parseFrontmatter, toBoolean, toStringArray } from "./frontmatter.ts";
import { normalizePermissionPolicy } from "./policy.ts";
import type { AgentDefinition, AgentKind, AgentSource, ThinkingLevel } from "./types.ts";

export interface AgentDiscoveryOptions {
  cwd: string;
  includeProjectAgents: boolean;
  userAgentDir?: string;
  projectAgentDir?: string;
}

export interface AgentDiscoveryResult {
  agents: AgentDefinition[];
  projectAgentDir?: string;
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

function defaultAgentDir(): string {
  const base = process.env.PI_CODING_AGENT_DIR || join(homedir(), ".pi", "agent");
  return join(base, "agents");
}

function isDirectory(path: string): boolean {
  try {
    return statSync(path).isDirectory();
  } catch {
    return false;
  }
}

export function findNearestProjectAgentsDir(cwd: string): string | undefined {
  let current = cwd;
  while (true) {
    const candidate = join(current, ".pi", "agents");
    if (isDirectory(candidate)) return candidate;
    const parent = dirname(current);
    if (parent === current) return undefined;
    current = parent;
  }
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

export function discoverAgents(options: AgentDiscoveryOptions, builtins: AgentDefinition[] = []): AgentDiscoveryResult {
  const userDir = options.userAgentDir ?? defaultAgentDir();
  const projectDir = options.projectAgentDir ?? findNearestProjectAgentsDir(options.cwd);
  const loadedUser = loadAgentsFromDir(userDir, "user");
  const loadedProject = projectDir && options.includeProjectAgents ? loadAgentsFromDir(projectDir, "project") : { agents: [], ignored: [] };

  const byName = new Map<string, AgentDefinition>();
  for (const agent of builtins) byName.set(agent.name, agent);
  for (const agent of loadedUser.agents) byName.set(agent.name, agent);
  for (const agent of loadedProject.agents) byName.set(agent.name, agent);

  return {
    agents: [...byName.values()],
    projectAgentDir: projectDir,
    ignored: [...loadedUser.ignored, ...loadedProject.ignored],
  };
}

export function selectMainAgents(agents: AgentDefinition[]): AgentDefinition[] {
  return agents.filter((agent) => agent.kind === "main");
}

export function findAgent(agents: AgentDefinition[], name: string, kind?: AgentKind): AgentDefinition | undefined {
  return agents.find((agent) => agent.name === name && (!kind || agent.kind === kind));
}
