import { existsSync, mkdirSync, readFileSync, statSync } from "node:fs";
import { dirname, join } from "node:path";
import type { RunRecordInternal } from "./subagent-registry.ts";

type ParentSessionContextLike = {
  sessionManager: {
    getSessionId?: () => string;
    getSessionFile?: () => string | undefined;
  };
};

export type SubagentSessionManagerLike = {
  getSessionId(): string;
  getSessionFile(): string | undefined;
  getSessionName?(): string | undefined;
  appendSessionInfo?(name: string): string;
};

export type SubagentSessionManagerFactory = {
  create(cwd: string, sessionDir?: string): SubagentSessionManagerLike;
  open(path: string, sessionDir?: string, cwdOverride?: string): SubagentSessionManagerLike;
};

export type ChildSessionValidationOptions = {
  childSessionId?: string;
  cwd?: string;
};

export type ChildSessionValidationResult =
  | { ok: true; header: Record<string, unknown> }
  | { ok: false; reason: string };

export function encodeSessionCwd(cwd: string): string {
  return `--${cwd.replace(/^[\\/]/, "").replace(/[\\/:]/g, "-")}--`;
}

function safePathPart(value: string): string {
  return value.replace(/[^a-zA-Z0-9_.=-]/g, "-");
}

export function subagentSessionDir(agentDir: string, cwd: string, parentSessionId: string): string {
  return join(agentDir, "subagent-sessions", encodeSessionCwd(cwd), safePathPart(parentSessionId));
}

export function subagentSessionFile(agentDir: string, cwd: string, parentSessionId: string, runId: string, childSessionId: string): string {
  return join(subagentSessionDir(agentDir, cwd, parentSessionId), `${safePathPart(runId)}_${safePathPart(childSessionId)}.jsonl`);
}

export function validateChildSessionFile(path: string | undefined, options: ChildSessionValidationOptions = {}): ChildSessionValidationResult {
  if (typeof path !== "string" || path.length === 0) return { ok: false, reason: "missing child session file path" };
  if (!existsSync(path)) return { ok: false, reason: `child session file does not exist: ${path}` };

  let stats;
  try {
    stats = statSync(path);
  } catch (error) {
    return { ok: false, reason: `cannot stat child session file: ${error instanceof Error ? error.message : String(error)}` };
  }
  if (!stats.isFile()) return { ok: false, reason: `child session path is not a regular file: ${path}` };

  let firstLine = "";
  try {
    const content = readFileSync(path, "utf8");
    firstLine = content.split(/\r?\n/, 1)[0]?.trim() ?? "";
  } catch (error) {
    return { ok: false, reason: `cannot read child session file: ${error instanceof Error ? error.message : String(error)}` };
  }
  if (!firstLine) return { ok: false, reason: "child session file is empty" };

  let header: Record<string, unknown>;
  try {
    const parsed = JSON.parse(firstLine);
    if (!parsed || typeof parsed !== "object" || Array.isArray(parsed)) return { ok: false, reason: "child session header is not a JSON object" };
    header = parsed as Record<string, unknown>;
  } catch (error) {
    return { ok: false, reason: `child session header is not valid JSON: ${error instanceof Error ? error.message : String(error)}` };
  }

  if (header.type !== "session") return { ok: false, reason: "child session header is not a session entry" };
  if (typeof header.id !== "string" || header.id.length === 0) return { ok: false, reason: "child session header has no session id" };
  if (typeof header.cwd !== "string" || header.cwd.length === 0) return { ok: false, reason: "child session header has no cwd" };
  if (options.childSessionId && header.id !== options.childSessionId) {
    return { ok: false, reason: `child session id mismatch: expected ${options.childSessionId}, found ${header.id}` };
  }
  if (options.cwd && header.cwd !== options.cwd) {
    return { ok: false, reason: `child session cwd mismatch: expected ${options.cwd}, found ${header.cwd}` };
  }

  return { ok: true, header };
}

export function hasUsableChildSessionFile(path: string | undefined, options: ChildSessionValidationOptions = {}): boolean {
  return validateChildSessionFile(path, options).ok;
}

function parentSessionMetadata(ctx: ParentSessionContextLike): { parentSessionId: string; parentSessionFile?: string } {
  const parentSessionId = ctx.sessionManager.getSessionId?.() ?? "unknown-parent-session";
  const parentSessionFile = ctx.sessionManager.getSessionFile?.();
  return { parentSessionId, parentSessionFile };
}

function setSessionFileWithParentHeader(manager: SubagentSessionManagerLike, filePath: string, parentSessionFile: string | undefined): void {
  // Pi's SessionManager.create() only accepts a directory and chooses its own filename.
  // Keep this adapter small and defensive until the SDK exposes a public custom-file API
  // that preserves the already allocated session id and lets us attach parentSession.
  const mutable = manager as unknown as { sessionFile?: string; fileEntries?: Array<Record<string, unknown>> };
  if (!("sessionFile" in mutable)) throw new Error("SessionManager does not expose expected sessionFile field for subagent session path override");
  if (!Array.isArray(mutable.fileEntries)) throw new Error("SessionManager does not expose expected fileEntries array for subagent session header update");
  const header = mutable.fileEntries.find((entry) => entry.type === "session");
  if (!header) throw new Error("SessionManager has no session header for subagent session path override");

  mutable.sessionFile = filePath;
  if (parentSessionFile) header.parentSession = parentSessionFile;
  if (manager.getSessionFile() !== filePath) throw new Error("SessionManager did not accept subagent session path override");
}

export function createSubagentSessionManager(
  run: RunRecordInternal,
  ctx: ParentSessionContextLike,
  agentDir: string,
  SessionManagerImpl: SubagentSessionManagerFactory,
): SubagentSessionManagerLike {
  const { parentSessionId, parentSessionFile } = parentSessionMetadata(ctx);
  run.parentSessionId = run.parentSessionId ?? parentSessionId;
  run.parentSessionFile = run.parentSessionFile ?? parentSessionFile;

  if (run.childSessionFile) {
    const validation = validateChildSessionFile(run.childSessionFile, { childSessionId: run.childSessionId, cwd: run.cwd });
    if (!validation.ok) throw new Error(`Saved child session file is not usable: ${validation.reason}`);
    const manager = SessionManagerImpl.open(run.childSessionFile, dirname(run.childSessionFile), run.cwd);
    run.childSessionId = manager.getSessionId();
    run.identity.sessionId = run.childSessionId;
    run.childSessionFile = manager.getSessionFile() ?? run.childSessionFile;
    return manager;
  }

  const dir = subagentSessionDir(agentDir, run.cwd, run.parentSessionId);
  mkdirSync(dir, { recursive: true });
  const manager = SessionManagerImpl.create(run.cwd, dir);
  const childSessionId = run.childSessionId ?? manager.getSessionId();
  const filePath = subagentSessionFile(agentDir, run.cwd, run.parentSessionId, run.id, childSessionId);
  setSessionFileWithParentHeader(manager, filePath, run.parentSessionFile);
  run.childSessionId = childSessionId;
  run.identity.sessionId = childSessionId;
  run.childSessionFile = filePath;
  return manager;
}
