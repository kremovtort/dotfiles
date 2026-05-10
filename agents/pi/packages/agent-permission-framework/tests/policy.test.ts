import assert from "node:assert/strict";
import test from "node:test";
import {
  composePolicies,
  evaluateBashPermission,
  evaluateDelegationPermission,
  evaluateFilePermission,
  evaluateSkillPermission,
  evaluateToolPermission,
} from "../src/policy.ts";
import type { PermissionPolicy } from "../src/types.ts";

test("deny overrides allow for tool permissions", () => {
  const policy: PermissionPolicy = {
    default: "ask",
    tools: { default: "allow", deny: ["write"], write: "allow" },
  };
  const decision = evaluateToolPermission(policy, "write", true);
  assert.equal(decision.state, "deny");
});

test("unknown action fails closed without UI", () => {
  const decision = evaluateToolPermission({}, "danger", false);
  assert.equal(decision.state, "deny");
});

test("bash read-only profile allows inspection and denies mutation", () => {
  const policy: PermissionPolicy = { bash: { readOnly: true, default: "deny" } };
  assert.equal(evaluateBashPermission(policy, "ls -la", true).state, "allow");
  assert.equal(evaluateBashPermission(policy, "rm -rf tmp", true).state, "deny");
});

test("file policy denies protected writes", () => {
  const policy: PermissionPolicy = { files: { write: { default: "ask" }, deny: ["secrets/**"] } };
  const decision = evaluateFilePermission(policy, "write", "secrets/api.env", "/repo", true);
  assert.equal(decision.state, "deny");
});

test("delegation policy considers project-local agents", () => {
  const policy: PermissionPolicy = { agents: { default: "allow", project: "ask" } };
  const decision = evaluateDelegationPermission(policy, { agentName: "scout", source: "project" }, true);
  assert.equal(decision.state, "ask");
});

test("composed child policy cannot broaden parent default", () => {
  const parent: PermissionPolicy = { default: "deny", tools: { read: "allow", write: "deny" } };
  const child: PermissionPolicy = { default: "allow", tools: { write: "allow" } };
  const composed = composePolicies(parent, child);
  assert.equal(evaluateToolPermission(composed, "write", true).state, "deny");
  assert.equal(evaluateToolPermission(composePolicies({ default: "deny" }, { tools: { read: "allow" } }), "read", true).state, "deny");
});

test("composed child policy cannot disable parent bash read-only profile", () => {
  const parent: PermissionPolicy = { bash: { readOnly: true, default: "deny" } };
  const child: PermissionPolicy = { bash: { readOnly: false, default: "allow" } };
  const composed = composePolicies(parent, child);
  assert.equal(evaluateBashPermission(composed, "rm -rf tmp", true).state, "deny");
});

test("skill policy evaluates skill-specific usage", () => {
  const policy: PermissionPolicy = { default: "allow", skills: { default: "deny", "openspec-review": "allow" } };
  assert.equal(evaluateSkillPermission(policy, "openspec-review", true).state, "allow");
  assert.equal(evaluateSkillPermission(policy, "unknown-skill", true).state, "deny");
});
