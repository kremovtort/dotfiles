import assert from "node:assert/strict";
import { appendFileSync, existsSync, mkdtempSync, readFileSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import test from "node:test";
import { withoutRecursiveFrameworkExtension } from "../src/extension-filter.ts";
import { AgentRuntimeState } from "../src/runtime.ts";
import { shouldWaitForSubagentResult, waitForSubagentResult } from "../src/subagent-result-wait.ts";
import { finalSubagentStatus } from "../src/subagent-status.ts";
import { SubagentRegistry, type RunRecordInternal } from "../src/subagent-registry.ts";
import { createSubagentSessionManager, encodeSessionCwd, subagentSessionFile, validateChildSessionFile } from "../src/subagent-session.ts";
import type { AgentDefinition, AgentIdentity, PermissionApprovalBroker, PendingPermissionRequest, SubagentRunRecord } from "../src/types.ts";

test("max-turn soft-limit wrap-up finalizes as steered", () => {
  assert.equal(finalSubagentStatus({ aborted: false, softLimitReached: true }), "steered");
  assert.equal(finalSubagentStatus({ aborted: false, softLimitReached: false }), "completed");
  assert.equal(finalSubagentStatus({ aborted: false, error: "boom", softLimitReached: true }), "failed");
  assert.equal(finalSubagentStatus({ aborted: true, softLimitReached: true }), "aborted");
});

test("child extension inheritance filters recursive framework extension only", () => {
  const result = withoutRecursiveFrameworkExtension({
    runtime: {},
    extensions: [
      { path: "/repo/.pi/agent/packages/agent-permission-framework/src/index.ts", resolvedPath: "/repo/.pi/agent/packages/agent-permission-framework/src/index.ts" },
      { path: "/repo/.pi/agent/packages/web-search/src/index.ts", resolvedPath: "/repo/.pi/agent/packages/web-search/src/index.ts" },
      { path: "<inline:1>", resolvedPath: "<inline:1>" },
    ],
    errors: [
      { path: "/repo/.pi/agent/packages/agent-permission-framework/src/index.ts", error: "failed" },
      { path: "<inline:1>", error: "Tool \"subagent\" conflicts with /repo/.pi/agent/packages/agent-permission-framework/src/index.ts" },
      { path: "/repo/.pi/agent/packages/web-search/src/index.ts", error: "other warning" },
    ],
  });

  assert.deepEqual(result.extensions.map((extension) => extension.path), [
    "/repo/.pi/agent/packages/web-search/src/index.ts",
    "<inline:1>",
  ]);
  assert.deepEqual(result.errors, [
    { path: "/repo/.pi/agent/packages/web-search/src/index.ts", error: "other warning" },
  ]);
});

function deferred(): { promise: Promise<void>; resolve: () => void } {
  let resolve!: () => void;
  const promise = new Promise<void>((innerResolve) => {
    resolve = innerResolve;
  });
  return { promise, resolve };
}

async function waitFor(predicate: () => boolean, label: string): Promise<void> {
  const deadline = Date.now() + 1000;
  while (Date.now() < deadline) {
    if (predicate()) return;
    await new Promise((resolve) => setTimeout(resolve, 5));
  }
  assert.fail(`Timed out waiting for ${label}`);
}

async function withTimeout<T>(promise: Promise<T>, label: string): Promise<T> {
  let timeout: ReturnType<typeof setTimeout> | undefined;
  const timeoutPromise = new Promise<never>((_, reject) => {
    timeout = setTimeout(() => reject(new Error(`Timed out waiting for ${label}`)), 1000);
  });
  try {
    return await Promise.race([promise, timeoutPromise]);
  } finally {
    if (timeout) clearTimeout(timeout);
  }
}

const parentIdentity: AgentIdentity = {
  id: "main-build-test",
  agentName: "build",
  kind: "main",
  source: "builtin",
  policyHash: "test",
  createdAt: 1,
};

const testAgent: AgentDefinition = {
  name: "scout",
  kind: "subagent",
  description: "Test scout",
  prompt: "Test prompt",
  source: "builtin",
  enabled: true,
  promptMode: "replace",
};

function startRun(registry: SubagentRegistry, task: string) {
  return registry.start({
    agent: testAgent,
    task,
    description: task,
    cwd: "/tmp",
    parentIdentity,
    runtime: new AgentRuntimeState(),
    ctx: {} as any,
    background: true,
  });
}

test("subagent session path helper mirrors Pi cwd encoding and names run/session file", () => {
  const file = subagentSessionFile("/agent", "/Users/me/repo:work", "parent/session", "agent-123", "session-456");
  assert.equal(encodeSessionCwd("/Users/me/repo:work"), "--Users-me-repo-work--");
  assert.equal(file, join("/agent", "subagent-sessions", "--Users-me-repo-work--", "parent-session", "agent-123_session-456.jsonl"));
});

test("subagent tool descriptions document interrupted resume", () => {
  const source = readFileSync(new URL("../src/subagents.ts", import.meta.url), "utf8");

  assert.match(source, /interrupted agents resume from their saved child session file/);
  assert.match(source, /Interrupted subagent runs.*can be resumed by passing their run ID in resume/s);
});

test("child session validation requires a matching standard session JSONL header", () => {
  const dir = mkdtempSync(join(tmpdir(), "subagent-validate-"));
  const valid = join(dir, "valid.jsonl");
  const empty = join(dir, "empty.jsonl");
  const malformed = join(dir, "malformed.jsonl");
  const wrongType = join(dir, "wrong-type.jsonl");
  const wrongId = join(dir, "wrong-id.jsonl");
  const wrongCwd = join(dir, "wrong-cwd.jsonl");
  writeFileSync(valid, `${JSON.stringify({ type: "session", id: "session-valid", timestamp: new Date().toISOString(), cwd: "/repo" })}\n`);
  writeFileSync(empty, "");
  writeFileSync(malformed, "not-json\n");
  writeFileSync(wrongType, `${JSON.stringify({ type: "message", id: "session-valid", cwd: "/repo" })}\n`);
  writeFileSync(wrongId, `${JSON.stringify({ type: "session", id: "other", cwd: "/repo" })}\n`);
  writeFileSync(wrongCwd, `${JSON.stringify({ type: "session", id: "session-valid", cwd: "/other" })}\n`);

  assert.equal(validateChildSessionFile(valid, { childSessionId: "session-valid", cwd: "/repo" }).ok, true);
  assert.equal(validateChildSessionFile(undefined).ok, false);
  assert.equal(validateChildSessionFile("").ok, false);
  assert.equal(validateChildSessionFile(join(dir, "missing.jsonl")).ok, false);
  assert.equal(validateChildSessionFile(dir).ok, false);
  assert.equal(validateChildSessionFile(empty).ok, false);
  assert.equal(validateChildSessionFile(malformed).ok, false);
  assert.equal(validateChildSessionFile(wrongType).ok, false);
  assert.equal(validateChildSessionFile(wrongId, { childSessionId: "session-valid", cwd: "/repo" }).ok, false);
  assert.equal(validateChildSessionFile(wrongCwd, { childSessionId: "session-valid", cwd: "/repo" }).ok, false);
});

test("subagent public run keeps durable metadata but hides live-only fields", () => {
  const registry = new SubagentRegistry(1, undefined, undefined, async (run) => {
    run.output = "done";
    run.status = "completed";
  });
  const { run } = registry.start({
    agent: testAgent,
    task: "metadata",
    description: "metadata",
    cwd: "/tmp",
    parentIdentity,
    runtime: new AgentRuntimeState(),
    ctx: {} as any,
    background: true,
    approvalBroker: { requestApproval: async () => ({ outcome: "approved", scope: "once" }) },
  });
  const live = registry.get(run.id)!;
  live.childSessionId = "session-test";
  live.childSessionFile = "/tmp/session.jsonl";
  live.parentSessionId = "parent-test";
  live.parentSessionFile = "/tmp/parent.jsonl";
  live.resumable = true;
  const serializable = registry.publicRun(live);

  assert.equal(serializable.childSessionId, "session-test");
  assert.equal(serializable.childSessionFile, "/tmp/session.jsonl");
  assert.equal(serializable.parentSessionId, "parent-test");
  assert.equal(serializable.parentSessionFile, "/tmp/parent.jsonl");
  assert.equal(serializable.resumable, true);
  assert.equal((serializable as any).approvalBroker, undefined);
  assert.equal((serializable as any).session, undefined);
});

class FakeSessionManager {
  sessionId: string;
  sessionFile: string | undefined;
  fileEntries: Array<Record<string, any>>;
  cwd: string;
  sessionDir: string;

  constructor(cwd: string, sessionDir: string, sessionFile?: string) {
    this.cwd = cwd;
    this.sessionDir = sessionDir;
    if (sessionFile) {
      this.sessionFile = sessionFile;
      const entries = readFileSync(sessionFile, "utf8").trim().split("\n").filter(Boolean).map((line) => JSON.parse(line));
      this.fileEntries = entries;
      this.sessionId = entries.find((entry) => entry.type === "session")?.id ?? "loaded-session";
    } else {
      this.sessionId = "fake-session";
      this.fileEntries = [{ type: "session", id: this.sessionId, timestamp: new Date().toISOString(), cwd }];
      this.sessionFile = join(sessionDir, `${this.sessionId}.jsonl`);
    }
  }

  static create(cwd: string, sessionDir?: string) {
    return new FakeSessionManager(cwd, sessionDir ?? tmpdir());
  }

  static open(path: string, sessionDir?: string, cwdOverride?: string) {
    return new FakeSessionManager(cwdOverride ?? "/tmp", sessionDir ?? tmpdir(), path);
  }

  getSessionId() {
    return this.sessionId;
  }

  getSessionFile() {
    return this.sessionFile;
  }

  getSessionName() {
    return this.fileEntries.find((entry) => entry.type === "session_info")?.name;
  }

  appendSessionInfo(name: string) {
    return this.appendEntry({ type: "session_info", name });
  }

  appendMessage(message: any) {
    return this.appendEntry({ type: "message", message });
  }

  private appendEntry(entry: Record<string, any>) {
    const id = `entry-${this.fileEntries.length}`;
    const fullEntry = { id, parentId: null, timestamp: new Date().toISOString(), ...entry };
    if (this.fileEntries.length === 1 && this.sessionFile) writeFileSync(this.sessionFile, `${JSON.stringify(this.fileEntries[0])}\n`);
    this.fileEntries.push(fullEntry);
    if (this.sessionFile) appendFileSync(this.sessionFile, `${JSON.stringify(fullEntry)}\n`);
    return id;
  }
}

function childRun(overrides: Partial<RunRecordInternal> = {}): RunRecordInternal {
  return {
    id: "agent-jsonl",
    agentName: "scout",
    task: "persist",
    status: "running",
    output: "",
    identity: { ...parentIdentity, id: "child-jsonl", kind: "subagent", parentId: parentIdentity.id, runId: "agent-jsonl" },
    cwd: "/repo",
    steering: [],
    definition: testAgent,
    effectivePolicy: {},
    ...overrides,
  };
}

const parentSessionCtx = {
  sessionManager: {
    getSessionId: () => "parent-jsonl",
    getSessionFile: () => "/tmp/parent.jsonl",
  },
} as any;

test("subagent SessionManager writes standard JSONL entries under child namespace", () => {
  const dir = mkdtempSync(join(tmpdir(), "subagent-session-"));
  const run = childRun();
  const manager = createSubagentSessionManager(run, parentSessionCtx, dir, FakeSessionManager);
  manager.appendSessionInfo("scout subagent (agent-jsonl)");
  manager.appendMessage({ role: "user", content: [{ type: "text", text: "Task: persist" }] } as any);
  manager.appendMessage({ role: "assistant", content: [{ type: "text", text: "done" }] } as any);

  assert.equal(run.childSessionId, "fake-session");
  assert.equal(run.parentSessionId, "parent-jsonl");
  assert.match(run.childSessionFile ?? "", /subagent-sessions.*parent-jsonl.*agent-jsonl_fake-session\.jsonl$/);
  assert.ok(existsSync(run.childSessionFile!));
  const entries = readFileSync(run.childSessionFile!, "utf8").trim().split("\n").map((line) => JSON.parse(line));
  assert.equal(entries[0].type, "session");
  assert.equal(entries[0].id, "fake-session");
  assert.equal(entries[0].parentSession, "/tmp/parent.jsonl");
  assert.equal(entries[1].type, "session_info");
  assert.deepEqual(entries.slice(2).map((entry) => entry.message.role), ["user", "assistant"]);
});

test("subagent SessionManager path override fails loudly for incompatible manager shapes", () => {
  const dir = mkdtempSync(join(tmpdir(), "subagent-incompatible-session-"));
  const incompatibleFactory = {
    create: () => ({
      getSessionId: () => "fake-session",
      getSessionFile: () => undefined,
    }),
    open: FakeSessionManager.open,
  } as any;

  assert.throws(
    () => createSubagentSessionManager(childRun(), parentSessionCtx, dir, incompatibleFactory),
    /expected sessionFile field/,
  );
});

test("parallel background runs synchronously register independent IDs and queue over capacity", async () => {
  const gates = [deferred(), deferred(), deferred()];
  const started: string[] = [];
  const registry = new SubagentRegistry(1, undefined, undefined, async (run) => {
    const index = started.length;
    started.push(run.id);
    await gates[index].promise;
    run.output = `done:${run.task}`;
    run.status = "completed";
  });

  const first = startRun(registry, "one");
  const second = startRun(registry, "two");
  const third = startRun(registry, "three");

  assert.notEqual(first.run.id, second.run.id);
  assert.notEqual(second.run.id, third.run.id);
  assert.equal(first.run.status, "running");
  assert.equal(second.run.status, "queued");
  assert.equal(second.run.queuedPosition, 1);
  assert.equal(third.run.status, "queued");
  assert.equal(third.run.queuedPosition, 2);
  assert.deepEqual(registry.stats(), { active: 1, queued: 2, total: 3 });

  gates[0].resolve();
  await waitFor(() => registry.get(second.run.id)?.status === "running", "second run promotion");
  assert.deepEqual(registry.stats(), { active: 1, queued: 1, total: 3 });

  gates[1].resolve();
  await waitFor(() => registry.get(third.run.id)?.status === "running", "third run promotion");
  assert.deepEqual(registry.stats(), { active: 1, queued: 0, total: 3 });

  gates[2].resolve();
  const results = await Promise.all([first.completion, second.completion, third.completion]);
  assert.deepEqual(results.map((run) => run.status), ["completed", "completed", "completed"]);
  assert.deepEqual(results.map((run) => run.output), ["done:one", "done:two", "done:three"]);
  assert.deepEqual(registry.stats(), { active: 0, queued: 0, total: 3 });
});

test("waiting for a background subagent result can be aborted without aborting the run", async () => {
  const gate = deferred();
  const registry = new SubagentRegistry(1, undefined, undefined, async (run) => {
    await gate.promise;
    run.output = "done";
    run.status = "completed";
  });

  const { run, completion } = startRun(registry, "long-running");
  await waitFor(() => registry.get(run.id)?.status === "running", "run to start");
  const live = registry.get(run.id)!;
  const controller = new AbortController();
  let progressUpdates = 0;

  const wait = waitForSubagentResult(live, {
    signal: controller.signal,
    intervalMs: 5,
    onProgress: () => progressUpdates++,
  });

  await waitFor(() => progressUpdates > 0, "result wait progress");
  controller.abort();

  assert.equal(await withTimeout(wait, "aborted result wait"), "cancelled");
  assert.equal(registry.get(run.id)?.status, "running");
  assert.equal(registry.get(run.id)?.error, undefined);

  gate.resolve();
  const completed = await withTimeout(completion, "background completion after cancelled wait");
  assert.equal(completed.status, "completed");
  assert.equal(completed.output, "done");
  assert.equal(registry.get(run.id)?.status, "completed");
});

test("waiting for a background subagent result resolves normally when the run completes", async () => {
  const gate = deferred();
  const registry = new SubagentRegistry(1, undefined, undefined, async (run) => {
    await gate.promise;
    run.output = "done";
    run.status = "completed";
  });

  const { run, completion } = startRun(registry, "normal-wait");
  await waitFor(() => registry.get(run.id)?.status === "running", "run to start");
  const live = registry.get(run.id)!;
  const wait = waitForSubagentResult(live, { intervalMs: 5 });

  gate.resolve();

  assert.equal(await withTimeout(wait, "normal result wait"), "completed");
  assert.equal((await withTimeout(completion, "normal completion")).status, "completed");
});

test("result wait predicate only waits for requested queued or running runs", async () => {
  assert.equal(shouldWaitForSubagentResult(false, { status: "running" }), false);
  assert.equal(shouldWaitForSubagentResult(undefined, { status: "running" }), false);
  assert.equal(shouldWaitForSubagentResult(true, { status: "completed" }), false);
  assert.equal(shouldWaitForSubagentResult(true, { status: "failed" }), false);
  assert.equal(shouldWaitForSubagentResult(true, { status: "queued" }), true);
  assert.equal(shouldWaitForSubagentResult(true, { status: "running" }), true);
  assert.equal(await waitForSubagentResult({ status: "completed" }, { intervalMs: 5 }), "completed");
});

test("failed setup releases capacity and promotes queued runs", async () => {
  const gate = deferred();
  const registry = new SubagentRegistry(1, undefined, undefined, async (run) => {
    if (run.task === "fail") throw new Error("setup exploded");
    await gate.promise;
    run.output = "ok";
    run.status = "completed";
  });

  const first = startRun(registry, "fail");
  const second = startRun(registry, "after-fail");

  const failed = await first.completion;
  assert.equal(failed.status, "failed");
  assert.match(failed.error ?? "", /setup exploded/);
  await waitFor(() => registry.get(second.run.id)?.status === "running", "promotion after failure");
  assert.deepEqual(registry.stats(), { active: 1, queued: 0, total: 2 });

  gate.resolve();
  const completed = await second.completion;
  assert.equal(completed.status, "completed");
  assert.equal(completed.output, "ok");
  assert.deepEqual(registry.stats(), { active: 0, queued: 0, total: 2 });
});

test("approval broker stays internal while pending permission metadata is public", async () => {
  const broker: PermissionApprovalBroker = { requestApproval: async () => ({ outcome: "approved", scope: "once" }) };
  const pending: PendingPermissionRequest = {
    fingerprint: { category: "tool", operation: "call", target: "bash", normalized: "tool:call:bash" },
    action: "tool:call:bash",
    reason: "matched ask rule",
    requestedAt: 1,
  };
  const updates: Array<string | undefined> = [];
  const registry = new SubagentRegistry(1, (run) => updates.push(run.pendingPermission?.action), undefined, async (run, helpers) => {
    assert.equal(run.approvalBroker, broker);
    assert.equal((helpers as any).approvalBroker, undefined);
    run.pendingPermission = pending;
    helpers.update(run);
    run.pendingPermission = undefined;
    helpers.update(run);
    run.output = "done";
    run.status = "completed";
  });

  const { run, completion } = registry.start({
    agent: testAgent,
    task: "permission",
    description: "permission",
    cwd: "/tmp",
    parentIdentity,
    runtime: new AgentRuntimeState(),
    ctx: {} as any,
    background: true,
    approvalBroker: broker,
  });

  assert.equal((run as any).approvalBroker, undefined);
  assert.equal(registry.get(run.id)?.approvalBroker, broker);
  assert.equal((registry.publicRun(registry.get(run.id)!) as any).approvalBroker, undefined);

  await completion;

  assert.ok(updates.includes("tool:call:bash"));
  assert.equal(registry.publicRun(registry.get(run.id)!).pendingPermission, undefined);
});

test("restore keeps latest record and marks non-live queued or running records interrupted when resumable", () => {
  const identity: AgentIdentity = {
    id: "child-scout-test",
    agentName: "scout",
    kind: "subagent",
    source: "builtin",
    parentId: parentIdentity.id,
    runId: "agent-restored",
    policyHash: "test",
    createdAt: 1,
  };
  const base: SubagentRunRecord = {
    id: "agent-restored",
    agentName: "scout",
    task: "restore",
    status: "queued",
    output: "",
    identity,
    cwd: "/tmp",
    steering: [],
  };

  const dir = mkdtempSync(join(tmpdir(), "subagent-restore-"));
  const childSessionFile = join(dir, "agent-stale-running_session-agent-stale-running.jsonl");
  const invalidChildSessionFile = join(dir, "agent-invalid_session-agent-invalid.jsonl");
  writeFileSync(childSessionFile, JSON.stringify({ type: "session", id: "session-agent-stale-running", timestamp: new Date().toISOString(), cwd: "/tmp" }) + "\n");
  writeFileSync(invalidChildSessionFile, "not-json\n");

  const registry = new SubagentRegistry(1);
  const restored = registry.restore([
    base,
    { ...base, status: "running", startedAt: 2 },
    { ...base, status: "completed", startedAt: 2, completedAt: 3, output: "latest" },
    { ...base, id: "agent-stale-queued", status: "queued", identity: { ...identity, id: "child-stale-queued", runId: "agent-stale-queued" } },
    { ...base, id: "agent-invalid", status: "running", childSessionFile: invalidChildSessionFile, childSessionId: "session-agent-invalid", identity: { ...identity, id: "child-invalid", runId: "agent-invalid" } },
    { ...base, id: "agent-stale-running", status: "running", childSessionFile, childSessionId: "session-agent-stale-running", pendingPermission: { fingerprint: { category: "tool", operation: "call", target: "bash", normalized: "tool:call:bash" }, action: "tool:call:bash", reason: "ask", requestedAt: 1 }, identity: { ...identity, id: "child-stale-running", runId: "agent-stale-running" } },
  ]);

  assert.equal(registry.get("agent-restored")?.status, "completed");
  assert.equal(registry.get("agent-restored")?.output, "latest");
  assert.equal(registry.get("agent-stale-queued")?.status, "aborted");
  assert.match(registry.get("agent-stale-queued")?.error ?? "", /without a live session or durable child session/);
  assert.equal(registry.get("agent-invalid")?.status, "aborted");
  assert.match(registry.get("agent-invalid")?.error ?? "", /without a live session or durable child session/);
  assert.equal(registry.get("agent-stale-running")?.status, "interrupted");
  assert.equal(registry.get("agent-stale-running")?.resumable, true);
  assert.equal(registry.get("agent-stale-running")?.pendingPermission, undefined);
  assert.deepEqual(restored.interrupted.map((run) => run.id), ["agent-stale-running"]);
  assert.deepEqual(registry.stats(), { active: 0, queued: 0, total: 4 });
});

test("interrupted run can be explicitly resumed without changing denied resumes", async () => {
  const dir = mkdtempSync(join(tmpdir(), "subagent-resume-"));
  const childSessionFile = join(dir, "agent-resume_session-agent-resume.jsonl");
  const corruptedSessionFile = join(dir, "agent-corrupt_session-agent-corrupt.jsonl");
  writeFileSync(childSessionFile, JSON.stringify({ type: "session", id: "session-agent-resume", timestamp: new Date().toISOString(), cwd: "/tmp" }) + "\n");
  writeFileSync(corruptedSessionFile, JSON.stringify({ type: "session", id: "session-agent-corrupt", timestamp: new Date().toISOString(), cwd: "/tmp" }) + "\n");
  const identity: AgentIdentity = {
    id: "child-resume",
    agentName: "scout",
    kind: "subagent",
    source: "builtin",
    parentId: parentIdentity.id,
    runId: "agent-resume",
    policyHash: "test",
    createdAt: 1,
  };
  const registry = new SubagentRegistry(1, undefined, undefined, async (run) => {
    run.output = `resumed:${run.task}`;
    run.status = "completed";
  });
  registry.restore([
    { id: "agent-resume", agentName: "scout", task: "old", status: "running", output: "old", identity, cwd: "/tmp", steering: [], childSessionFile, childSessionId: "session-agent-resume" },
    { id: "agent-corrupt", agentName: "scout", task: "old", status: "running", output: "old", identity: { ...identity, id: "child-corrupt", runId: "agent-corrupt" }, cwd: "/tmp", steering: [], childSessionFile: corruptedSessionFile, childSessionId: "session-agent-corrupt" },
  ]);

  assert.equal(registry.get("agent-resume")?.status, "interrupted");
  assert.equal(registry.get("agent-corrupt")?.status, "interrupted");
  writeFileSync(corruptedSessionFile, "not-json\n");
  const missing = registry.resumeInterrupted("missing", {
    agent: testAgent,
    task: "nope",
    parentIdentity,
    runtime: new AgentRuntimeState(),
    ctx: {} as any,
    background: true,
  });
  assert.equal(missing, undefined);

  const corruptResume = registry.resumeInterrupted("agent-corrupt", {
    agent: testAgent,
    task: "continue",
    parentIdentity,
    runtime: new AgentRuntimeState(),
    ctx: {} as any,
    background: true,
  });
  assert.equal(corruptResume, undefined);
  assert.equal(registry.get("agent-corrupt")?.status, "aborted");
  assert.match(registry.get("agent-corrupt")?.error ?? "", /not usable/);

  const resumed = registry.resumeInterrupted("agent-resume", {
    agent: testAgent,
    task: "continue",
    parentIdentity,
    runtime: new AgentRuntimeState(),
    ctx: {} as any,
    background: true,
  });
  assert.ok(resumed);
  assert.equal(resumed.run.status, "running");
  assert.equal(resumed.run.childSessionFile, childSessionFile);
  const completed = await resumed.completion;
  assert.equal(completed.status, "completed");
  assert.equal(completed.output, "resumed:continue");
});
