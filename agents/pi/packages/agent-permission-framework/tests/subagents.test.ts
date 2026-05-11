import assert from "node:assert/strict";
import test from "node:test";
import { withoutRecursiveFrameworkExtension } from "../src/extension-filter.ts";
import { AgentRuntimeState } from "../src/runtime.ts";
import { shouldWaitForSubagentResult, waitForSubagentResult } from "../src/subagent-result-wait.ts";
import { finalSubagentStatus } from "../src/subagent-status.ts";
import { SubagentRegistry } from "../src/subagent-registry.ts";
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

test("restore keeps latest record and marks non-live queued or running records aborted", () => {
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

  const registry = new SubagentRegistry(1);
  registry.restore([
    base,
    { ...base, status: "running", startedAt: 2 },
    { ...base, status: "completed", startedAt: 2, completedAt: 3, output: "latest" },
    { ...base, id: "agent-stale-queued", status: "queued", identity: { ...identity, id: "child-stale-queued", runId: "agent-stale-queued" } },
    { ...base, id: "agent-stale-running", status: "running", identity: { ...identity, id: "child-stale-running", runId: "agent-stale-running" } },
  ]);

  assert.equal(registry.get("agent-restored")?.status, "completed");
  assert.equal(registry.get("agent-restored")?.output, "latest");
  assert.equal(registry.get("agent-stale-queued")?.status, "aborted");
  assert.match(registry.get("agent-stale-queued")?.error ?? "", /without a live session/);
  assert.equal(registry.get("agent-stale-running")?.status, "aborted");
  assert.deepEqual(registry.stats(), { active: 0, queued: 0, total: 3 });
});
