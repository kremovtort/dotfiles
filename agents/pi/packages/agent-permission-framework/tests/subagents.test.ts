import assert from "node:assert/strict";
import test from "node:test";
import { withoutRecursiveFrameworkExtension } from "../src/extension-filter.ts";
import { AgentRuntimeState } from "../src/runtime.ts";
import { SubagentRegistry } from "../src/subagent-registry.ts";
import type { AgentDefinition, AgentIdentity, SubagentRunRecord } from "../src/types.ts";

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
