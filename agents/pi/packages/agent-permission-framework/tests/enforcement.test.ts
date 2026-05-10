import assert from "node:assert/strict";
import test from "node:test";
import { enforceDecision, evaluateToolCall } from "../src/enforcement.ts";
import { AgentRuntimeState } from "../src/runtime.ts";
import type { PermissionDecision, PermissionPolicy } from "../src/types.ts";

function runtime(policy: PermissionPolicy): AgentRuntimeState {
  const state = new AgentRuntimeState();
  state.activePolicy = policy;
  return state;
}

test("tool call enforcement applies skill policies for skill-prefixed tools", () => {
  const decision = evaluateToolCall(
    runtime({ default: "allow", skills: { default: "deny", "openspec-review": "allow" } }),
    { toolName: "skill:unknown", input: {} },
    { cwd: "/repo", hasUI: true },
  );
  assert.equal(decision.state, "deny");
});

test("tool call enforcement applies skill policies from explicit skill input", () => {
  const decision = evaluateToolCall(
    runtime({ default: "allow", skills: { default: "deny", "openspec-review": "allow" } }),
    { toolName: "use_skill", input: { skill: "openspec-review" } },
    { cwd: "/repo", hasUI: true },
  );
  assert.equal(decision.state, "allow");
});

test("subagent preflight can enforce only tool permission without delegation prompt", () => {
  const policy: PermissionPolicy = {
    default: "allow",
    tools: { subagent: "allow" },
    agents: { default: "ask" },
  };

  const preflight = evaluateToolCall(
    runtime(policy),
    { toolName: "subagent", input: { subagent_type: "openspec-reviewer-gpt", run_in_background: true } },
    { cwd: "/repo", hasUI: true },
    policy,
    { includeDelegation: false },
  );
  assert.equal(preflight.state, "allow");

  const full = evaluateToolCall(
    runtime(policy),
    { toolName: "subagent", input: { subagent_type: "openspec-reviewer-gpt", run_in_background: true } },
    { cwd: "/repo", hasUI: true },
  );
  assert.equal(full.state, "ask");
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
        return "Allow for this session";
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
  assert.match(capturedPrompt, /Required permission/);
  assert.match(capturedPrompt, /Agent: build \(main\)/);
  assert.match(capturedPrompt, /Action: tool:call:write/);
  assert.match(capturedPrompt, /Decision: matched ask rule/);
  assert.match(capturedPrompt, /Rule: tools\.write/);
  assert.deepEqual(capturedOptions, ["Allow once", "Allow for this session", "Deny"]);
  for (const option of capturedOptions) {
    assert.doesNotMatch(option, /Agent:|Action:|Decision:|Rule:/);
  }
});

test("interactive approval prompts are serialized for parallel asks", async () => {
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
    fingerprint: { category: "agent", operation: "delegate", target, normalized: `agent:delegate:${target}` },
  }));

  const results = await Promise.all(decisions.map((decision) => enforceDecision(state, decision, ctx)));
  assert.deepEqual(results, [undefined, undefined, undefined]);
  assert.equal(maxActivePrompts, 1);
});
