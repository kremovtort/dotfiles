import assert from "node:assert/strict";
import test from "node:test";
import { parseAgentMarkdown } from "../src/agents.ts";
import { evaluateBashPermission, evaluateToolPermission } from "../src/policy.ts";

test("parses agent markdown frontmatter and OpenCode-style permission block", () => {
  const parsed = parseAgentMarkdown(`---
name: build
kind: main
description: Build mode
thinking: high
permission:
  *: ask
  tools:
    read: allow
    edit: ask
  bash:
    *: ask
    "git status*": allow
---
Build prompt.
`, "user", "/tmp/build.md");

  assert.ok(!("error" in parsed));
  assert.equal(parsed.name, "build");
  assert.equal(parsed.kind, "main");
  assert.equal(evaluateToolPermission(parsed.permission, "read", true).state, "allow");
  assert.equal(evaluateToolPermission(parsed.permission, "edit", true).state, "ask");
  assert.equal(evaluateBashPermission(parsed.permission, "git status --short", true).state, "allow");
});

test("parses scalar permission frontmatter", () => {
  const parsed = parseAgentMarkdown(`---
name: ask
description: Ask mode
permission: deny
---
Prompt.
`, "user", "/tmp/ask.md");

  assert.ok(!("error" in parsed));
  assert.equal(evaluateToolPermission(parsed.permission, "bash", true).state, "deny");
});

test("migrates legacy tool declarations to permission tools rules", () => {
  const parsed = parseAgentMarkdown(`---
name: legacy
description: Legacy mode
tools: read,bash,edit
disallowed_tools: edit
---
Prompt.
`, "user", "/tmp/legacy.md");

  assert.ok(!("error" in parsed));
  assert.deepEqual(parsed.tools, ["read", "bash", "edit"]);
  assert.equal(evaluateToolPermission(parsed.permission, "read", true).state, "allow");
  assert.equal(evaluateToolPermission(parsed.permission, "edit", true).state, "deny");
  assert.equal(evaluateToolPermission(parsed.permission, "write", true).state, "deny");
});

test("rejects unsupported permission categories", () => {
  const parsed = parseAgentMarkdown(`---
name: broken
description: Broken mode
permission:
  mcp: allow
---
Prompt.
`, "user", "/tmp/broken.md");

  assert.ok("error" in parsed);
  assert.match(parsed.error, /Unsupported permission category "mcp"/);
});

test("rejects incomplete agent definitions", () => {
  const parsed = parseAgentMarkdown(`---
name: broken
---
`, "user", "/tmp/broken.md");
  assert.ok("error" in parsed);
});
