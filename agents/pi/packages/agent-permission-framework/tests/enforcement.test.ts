import assert from "node:assert/strict";
import test from "node:test";
import { enforceDecision, evaluateToolCall } from "../src/enforcement.ts";
import { normalizePermissionPolicy } from "../src/policy.ts";
import { AgentRuntimeState } from "../src/runtime.ts";
import type { PermissionApprovalBroker, PermissionDecision, PermissionPolicy } from "../src/types.ts";

function runtime(policy: PermissionPolicy): AgentRuntimeState {
  const state = new AgentRuntimeState();
  state.activePolicy = policy;
  return state;
}

const policy = (value: unknown): PermissionPolicy => normalizePermissionPolicy(value) ?? {};

test("tool call enforcement applies ordinary tool permissions for skill-prefixed tools", () => {
  const decision = evaluateToolCall(
    runtime(policy({ "*": "allow", tools: { "skill:*": "deny", "skill:openspec-review": "allow" } })),
    { toolName: "skill:unknown", input: {} },
    { cwd: "/repo", hasUI: true },
  );
  assert.equal(decision.state, "deny");
});

test("tool call enforcement applies ordinary tool permissions from explicit skill input", () => {
  const decision = evaluateToolCall(
    runtime(policy({ "*": "allow", tools: { use_skill: { "*": "deny", "openspec-review": "allow" } } })),
    { toolName: "use_skill", input: { skill: "openspec-review" } },
    { cwd: "/repo", hasUI: true },
  );
  assert.equal(decision.state, "allow");
});

test("subagent preflight can enforce only tool permission without delegation prompt", () => {
  const permissions = policy({
    "*": "allow",
    tools: { subagent: "allow" },
    subagents: { "*": "ask" },
  });

  const preflight = evaluateToolCall(
    runtime(permissions),
    { toolName: "subagent", input: { subagent_type: "openspec-reviewer-gpt", run_in_background: true } },
    { cwd: "/repo", hasUI: true },
    permissions,
    { includeDelegation: false },
  );
  assert.equal(preflight.state, "allow");

  const full = evaluateToolCall(
    runtime(permissions),
    { toolName: "subagent", input: { subagent_type: "openspec-reviewer-gpt", run_in_background: true } },
    { cwd: "/repo", hasUI: true },
  );
  assert.equal(full.state, "ask");
});

test("bash command guard denies despite generic bash tool access", () => {
  const decision = evaluateToolCall(
    runtime(policy({ "*": "allow", tools: { bash: "allow" }, bash: { "*": "allow", "rm *": "deny" } })),
    { toolName: "bash", input: { command: "rm -rf tmp" } },
    { cwd: "/repo", hasUI: true },
  );
  assert.equal(decision.state, "deny");
});

test("file external-directory guard combines with tool permission", () => {
  const decision = evaluateToolCall(
    runtime(policy({ "*": "allow", tools: { read: "allow" }, external_directory: { "/tmp/**": "ask" } })),
    { toolName: "read", input: { path: "/tmp/outside.txt" } },
    { cwd: "/repo", hasUI: true },
  );
  assert.equal(decision.state, "ask");
  assert.equal(decision.matchedRule, "external_directory:/tmp/**");
  assert.equal(decision.fingerprint.normalized, "file:external_directory:read:/tmp/outside.txt");
});

test("external-directory guard keeps matching path-only while fingerprint includes concrete tool", () => {
  const decision = evaluateToolCall(
    runtime(policy({ "*": "allow", tools: { grep: "allow" }, external_directory: { "/tmp/**": "ask" } })),
    { toolName: "grep", input: { path: "/tmp/logs/app.log", pattern: "ERROR" } },
    { cwd: "/repo", hasUI: true },
  );

  assert.equal(decision.state, "ask");
  assert.equal(decision.matchedRule, "external_directory:/tmp/**");
  assert.equal(decision.fingerprint.normalized, "file:external_directory:grep:/tmp/logs/app.log");
});

test("external-directory approvals are scoped by concrete file tool and path", async () => {
  const state = runtime(policy({ "*": "allow", tools: { read: "allow", write: "allow" }, external_directory: { "/tmp/**": "ask" } }));
  state.activeIdentity = {
    id: "main-build-test",
    agentName: "build",
    kind: "main",
    source: "builtin",
    policyHash: "test",
    createdAt: 1,
  };

  const readDecision = evaluateToolCall(
    state,
    { toolName: "read", input: { path: "/tmp/outside.txt" } },
    { cwd: "/repo", hasUI: false },
  );
  const writeDecision = evaluateToolCall(
    state,
    { toolName: "write", input: { path: "/tmp/outside.txt", content: "new" } },
    { cwd: "/repo", hasUI: false },
  );
  assert.equal(readDecision.fingerprint.normalized, "file:external_directory:read:/tmp/outside.txt");
  assert.equal(writeDecision.fingerprint.normalized, "file:external_directory:write:/tmp/outside.txt");

  let prompts = 0;
  const broker: PermissionApprovalBroker = {
    requestApproval: async (request) => {
      prompts++;
      assert.equal(request.decision.fingerprint.normalized, "file:external_directory:read:/tmp/outside.txt");
      return { outcome: "approved", scope: "session" };
    },
  };

  assert.equal(await enforceDecision(state, readDecision, { cwd: "/repo", hasUI: false }, { approvalBroker: broker }), undefined);
  assert.equal(prompts, 1);

  assert.equal(await enforceDecision(state, readDecision, { cwd: "/repo", hasUI: false }), undefined);
  assert.equal(prompts, 1);

  const writeResult = await enforceDecision(state, writeDecision, { cwd: "/repo", hasUI: false });
  assert.equal(writeResult?.block, true);
  assert.match(writeResult?.reason ?? "", /no interactive approval is available/);
});

test("interactive approval prompt keeps permission details out of select choices", async () => {
  const state = new AgentRuntimeState();
  state.activeIdentity = {
    id: "main-build-test",
    agentName: "build",
    kind: "main",
    source: "builtin",
    policyHash: "test",
    createdAt: 1,
  };

  let capturedPrompt = "";
  let capturedOptions: string[] = [];
  const ctx = {
    cwd: "/repo",
    hasUI: true,
    ui: {
      select: async (prompt: string, options: string[]) => {
        capturedPrompt = prompt;
        capturedOptions = options;
        return "Allow session";
      },
    },
  };
  const decision: PermissionDecision = {
    state: "ask",
    reason: "matched ask rule",
    matchedRule: "tools.write",
    fingerprint: { category: "tool", operation: "call", target: "write", normalized: "tool:call:write" },
  };

  const result = await enforceDecision(state, decision, ctx);

  assert.equal(result, undefined);
  assert.match(capturedPrompt, /Permission required/);
  assert.match(capturedPrompt, /Agent: build \(main\)/);
  assert.match(capturedPrompt, /Action: tool write/);
  assert.match(capturedPrompt, /Reason: matched ask rule/);
  assert.match(capturedPrompt, /Rule: tools\.write/);
  assert.match(capturedPrompt, /sha256:[a-f0-9]{8}/);
  assert.deepEqual(capturedOptions, ["Deny", "Allow once", "Allow session"]);
  for (const option of capturedOptions) {
    assert.doesNotMatch(option, /Agent:|Action:|Reason:|Rule:/);
  }
});

test("interactive approval prompts are serialized for parallel asks in the same context", async () => {
  const state = new AgentRuntimeState();
  state.activeIdentity = {
    id: "main-build-test",
    agentName: "build",
    kind: "main",
    source: "builtin",
    policyHash: "test",
    createdAt: 1,
  };

  let activePrompts = 0;
  let maxActivePrompts = 0;
  const ctx = {
    cwd: "/repo",
    hasUI: true,
    ui: {
      select: async () => {
        activePrompts++;
        maxActivePrompts = Math.max(maxActivePrompts, activePrompts);
        await new Promise((resolve) => setTimeout(resolve, 5));
        activePrompts--;
        return "Allow once\nserialized";
      },
    },
  };
  const decisions: PermissionDecision[] = ["one", "two", "three"].map((target) => ({
    state: "ask",
    reason: `ask ${target}`,
    fingerprint: { category: "subagent", operation: "delegate", target, normalized: `subagent:delegate:${target}` },
  }));

  const results = await Promise.all(decisions.map((decision) => enforceDecision(state, decision, ctx)));
  assert.deepEqual(results, [undefined, undefined, undefined]);
  assert.equal(maxActivePrompts, 1);
});

test("independent approval brokers do not share a global queue", async () => {
  const slowState = new AgentRuntimeState();
  slowState.activeIdentity = {
    id: "main-slow",
    agentName: "build",
    kind: "main",
    source: "builtin",
    policyHash: "test",
    createdAt: 1,
  };
  const fastState = new AgentRuntimeState();
  fastState.activeIdentity = { ...slowState.activeIdentity, id: "main-fast" };
  let releaseSlow!: () => void;
  const slowBroker: PermissionApprovalBroker = {
    requestApproval: async () => {
      slowStartedResolve();
      await new Promise<void>((innerResolve) => {
        releaseSlow = innerResolve;
      });
      return { outcome: "approved", scope: "once" };
    },
  };
  let slowStartedResolve!: () => void;
  const slowStarted = new Promise<void>((resolve) => {
    slowStartedResolve = resolve;
  });
  const slowPromise = enforceDecision(slowState, {
    state: "ask",
    reason: "slow ask",
    fingerprint: { category: "tool", operation: "call", target: "slow", normalized: "tool:call:slow" },
  }, { cwd: "/repo", hasUI: false }, { approvalBroker: slowBroker, approvalTimeoutMs: 1000 });
  await slowStarted;

  const fastBroker: PermissionApprovalBroker = { requestApproval: async () => ({ outcome: "approved", scope: "once" }) };
  const fast = await enforceDecision(fastState, {
    state: "ask",
    reason: "fast ask",
    fingerprint: { category: "tool", operation: "call", target: "fast", normalized: "tool:call:fast" },
  }, { cwd: "/repo", hasUI: false }, { approvalBroker: fastBroker, approvalTimeoutMs: 50 });

  assert.equal(fast, undefined);
  releaseSlow();
  assert.equal(await slowPromise, undefined);
});

const childIdentity = {
  id: "child-scout-test",
  agentName: "scout",
  kind: "subagent" as const,
  source: "builtin" as const,
  parentId: "main-build-test",
  runId: "agent-test",
  policyHash: "test",
  createdAt: 1,
};

const askDecision: PermissionDecision = {
  state: "ask",
  reason: "matched ask rule",
  matchedRule: "tools.bash",
  fingerprint: { category: "tool", operation: "call", target: "bash", normalized: "tool:call:bash" },
};

test("broker-approved child ask stores child-scoped approval and reuses it", async () => {
  const state = new AgentRuntimeState();
  state.activeIdentity = childIdentity;

  let prompts = 0;
  const broker: PermissionApprovalBroker = {
    requestApproval: async (request) => {
      prompts++;
      assert.equal(request.identity.id, childIdentity.id);
      assert.equal(request.decision.fingerprint.normalized, "tool:call:bash");
      return { outcome: "approved", scope: "session" };
    },
  };
  const pendingStates: Array<string | undefined> = [];
  const auditStates: Array<unknown> = [];

  const result = await enforceDecision(state, askDecision, { cwd: "/repo", hasUI: false }, {
    approvalBroker: broker,
    approvalTimeoutMs: 50,
    onPendingApproval: (pending) => pendingStates.push(pending?.action),
    onAudit: (audit) => auditStates.push(audit.details?.approvalState),
  });

  assert.equal(result, undefined);
  assert.equal(prompts, 1);
  assert.deepEqual(pendingStates, ["tool:call:bash", undefined]);
  assert.deepEqual(auditStates, ["pending", "approved"]);

  const reused = await enforceDecision(state, askDecision, { cwd: "/repo", hasUI: false });
  assert.equal(reused, undefined);
  assert.equal(prompts, 1);

  state.activeIdentity = { ...childIdentity, id: "child-other", runId: "agent-other" };
  const sibling = await enforceDecision(state, askDecision, { cwd: "/repo", hasUI: false });
  assert.equal(sibling?.block, true);
  assert.match(sibling?.reason ?? "", /parent-visible interactive approval is available/);
});

test("child ask fails closed without broker", async () => {
  const state = new AgentRuntimeState();
  state.activeIdentity = childIdentity;

  const result = await enforceDecision(state, askDecision, { cwd: "/repo", hasUI: false }, { approvalTimeoutMs: 10 });

  assert.equal(result?.block, true);
  assert.match(result?.reason ?? "", /parent-visible interactive approval is available/);
  assert.equal(state.audit.at(-1)?.details?.approvalState, "unavailable");
});

test("child ask does not fall back to child context UI when bridge is disabled", async () => {
  const state = new AgentRuntimeState();
  state.activeIdentity = childIdentity;
  let prompts = 0;

  const result = await enforceDecision(state, askDecision, {
    cwd: "/repo",
    hasUI: true,
    ui: {
      select: async () => {
        prompts++;
        return "Allow once";
      },
    },
  }, { allowContextUI: false, approvalTimeoutMs: 10 });

  assert.equal(result?.block, true);
  assert.equal(prompts, 0);
  assert.match(result?.reason ?? "", /parent-visible interactive approval is available/);
});

test("approval broker timeout and abort fail closed with explicit reasons", async () => {
  const neverBroker: PermissionApprovalBroker = { requestApproval: async () => new Promise(() => {}) };

  const timeoutState = new AgentRuntimeState();
  timeoutState.activeIdentity = childIdentity;
  const timedOut = await enforceDecision(timeoutState, askDecision, { cwd: "/repo", hasUI: false }, {
    approvalBroker: neverBroker,
    approvalTimeoutMs: 5,
  });
  assert.equal(timedOut?.block, true);
  assert.match(timedOut?.reason ?? "", /timed out/);
  assert.equal(timeoutState.audit.at(-1)?.details?.approvalState, "timeout");

  const abortState = new AgentRuntimeState();
  abortState.activeIdentity = childIdentity;
  const controller = new AbortController();
  setTimeout(() => controller.abort(), 5);
  const aborted = await enforceDecision(abortState, askDecision, { cwd: "/repo", hasUI: false }, {
    approvalBroker: neverBroker,
    approvalTimeoutMs: 100,
    signal: controller.signal,
  });
  assert.equal(aborted?.block, true);
  assert.match(aborted?.reason ?? "", /aborted/);
  assert.equal(abortState.audit.at(-1)?.details?.approvalState, "aborted");
});

test("approval broker user denial fails closed and records denial reason", async () => {
  const state = new AgentRuntimeState();
  state.activeIdentity = childIdentity;
  const broker: PermissionApprovalBroker = {
    requestApproval: async () => ({ outcome: "denied", reason: "not today" }),
  };

  const result = await enforceDecision(state, askDecision, { cwd: "/repo", hasUI: false }, {
    approvalBroker: broker,
    approvalTimeoutMs: 50,
  });

  assert.equal(result?.block, true);
  assert.match(result?.reason ?? "", /not today/);
  assert.equal(state.audit.at(-1)?.details?.approvalState, "denied");
  assert.equal(state.audit.at(-1)?.details?.denialReason, "not today");
});
