import assert from "node:assert/strict";
import test from "node:test";
import {
  composePolicies,
  deriveActiveToolNames,
  evaluateBashPermission,
  evaluateDelegationPermission,
  evaluateExternalDirectoryPermission,
  evaluateFilePermission,
  evaluateToolPermission,
  normalizePermissionPolicy,
} from "../src/policy.ts";
import type { PermissionPolicy } from "../src/types.ts";

const policy = (value: unknown): PermissionPolicy => normalizePermissionPolicy(value) ?? {};

test("scalar permission becomes global default", () => {
  const allowAll = normalizePermissionPolicy("allow");
  assert.equal(evaluateToolPermission(allowAll, "anything", true).state, "allow");
});

test("unsupported top-level permission categories are rejected", () => {
  assert.throws(() => normalizePermissionPolicy({ mcp: "allow" }), /Unsupported permission category "mcp"/);
  assert.throws(() => normalizePermissionPolicy({ files: { read: "allow" } }), /Unsupported permission category "files"/);
  assert.throws(() => normalizePermissionPolicy({ agents: { scout: "allow" } }), /Unsupported permission category "agents"/);
  assert.throws(() => normalizePermissionPolicy({ skills: { review: "allow" } }), /Unsupported permission category "skills"/);
});

test("last matching rule wins within bash rule objects", () => {
  const permissions = policy({
    "*": "deny",
    bash: {
      "*": "ask",
      "git *": "allow",
      "git push*": "deny",
    },
  });

  assert.equal(evaluateBashPermission(permissions, "git status --short", true).state, "allow");
  assert.equal(evaluateBashPermission(permissions, "git push origin main", true).state, "deny");
});

test("tool input rules permission file paths", () => {
  const permissions = policy({
    "*": "ask",
    tools: {
      write: {
        "*": "allow",
        "secrets/**": "deny",
      },
      read: {
        "*": "allow",
        "*.env": "deny",
        "*.env.example": "allow",
      },
    },
  });

  assert.equal(evaluateFilePermission(permissions, "write", "secrets/api.env", "/repo", true).state, "deny");
  assert.equal(evaluateFilePermission(permissions, "read", ".env", "/repo", true).state, "deny");
  assert.equal(evaluateFilePermission(permissions, "read", ".env.example", "/repo", true).state, "allow");
});

test("tool input fingerprints include concrete targets", () => {
  const permissions = policy({
    "*": "deny",
    tools: {
      write: {
        "a/**": "ask",
        "b/**": "ask",
      },
    },
  });

  const first = evaluateToolPermission(permissions, "write", true, "a/one");
  const second = evaluateToolPermission(permissions, "write", true, "b/two");
  assert.equal(first.state, "ask");
  assert.equal(second.state, "ask");
  assert.equal(first.fingerprint.normalized, "tool:call:write:a/one");
  assert.equal(second.fingerprint.normalized, "tool:call:write:b/two");
});

test("external directory uses top-level permission guard", () => {
  const permissions = policy({
    "*": "allow",
    tools: { read: "allow" },
    external_directory: {
      "*": "ask",
      "/nix/store/**": "allow",
      "/private/**": "deny",
    },
  });

  assert.equal(evaluateExternalDirectoryPermission(permissions, "/nix/store/abc", "/repo", true).state, "allow");
  assert.equal(evaluateExternalDirectoryPermission(permissions, "/private/secret", "/repo", true).state, "deny");
  assert.equal(evaluateFilePermission(permissions, "read", "/outside/file", "/repo", true).state, "ask");
});

test("subagents policy considers project-local and override targets", () => {
  const permissions = policy({
    "*": "allow",
    subagents: {
      "*": "ask",
      scout: "allow",
      "source:project": "ask",
      "override:model": "deny",
    },
  });

  assert.equal(evaluateDelegationPermission(permissions, { agentName: "scout", source: "builtin" }, true).state, "allow");
  assert.equal(evaluateDelegationPermission(permissions, { agentName: "scout", source: "project" }, true).state, "ask");
  assert.equal(evaluateDelegationPermission(permissions, { agentName: "scout", modelOverride: "provider/model" }, true).state, "deny");
});

test("composePolicies uses OpenCode override layering", () => {
  const parent = policy({
    "*": "ask",
    tools: {
      write: "deny",
      read: "ask",
    },
    bash: {
      "*": "ask",
      "git *": "allow",
    },
  });
  const child = policy({
    tools: {
      write: "allow",
      read: "deny",
    },
    bash: {
      "git commit*": "deny",
    },
  });
  const composed = composePolicies(parent, child);

  assert.equal(evaluateToolPermission(composed, "write", true).state, "allow");
  assert.equal(evaluateToolPermission(composed, "read", true).state, "deny");
  assert.equal(evaluateBashPermission(composed, "git status --short", true).state, "allow");
  assert.equal(evaluateBashPermission(composed, "git commit -m test", true).state, "deny");
});

test("active tools are derived from categorical permission outcomes", () => {
  const permissions = policy({
    "*": "ask",
    tools: {
      bash: "deny",
      edit: "ask",
      write: {
        "*": "deny",
        "docs/**": "allow",
      },
      never: {
        "*": "deny",
      },
    },
  });

  assert.deepEqual(deriveActiveToolNames(permissions, ["read", "bash", "edit", "write", "never"], true), ["read", "edit", "write"]);
});

test("active tools omit deny-only input rules even with ask fallback", () => {
  const permissions = policy({
    "*": "ask",
    tools: {
      write: {
        "*": "deny",
      },
    },
  });

  assert.equal(evaluateToolPermission(permissions, "write", true, "anything").state, "deny");
  assert.deepEqual(deriveActiveToolNames(permissions, ["write"], true), []);
});
