import assert from "node:assert/strict";
import test from "node:test";
import { evaluateToolCall } from "../src/enforcement.ts";
import { AgentRuntimeState } from "../src/runtime.ts";
import type { PermissionPolicy } from "../src/types.ts";

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
