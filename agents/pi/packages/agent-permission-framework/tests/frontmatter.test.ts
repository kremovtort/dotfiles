import assert from "node:assert/strict";
import test from "node:test";
import { parseAgentMarkdown } from "../src/agents.ts";

test("parses agent markdown frontmatter and permission block", () => {
  const parsed = parseAgentMarkdown(`---
name: build
kind: main
description: Build mode
tools: read,bash,edit
thinking: high
permission:
  tools:
    read: allow
    edit: ask
  bash:
    default: ask
    deny:
      - "\\bsudo\\b"
---
Build prompt.
`, "user", "/tmp/build.md");

  assert.ok(!("error" in parsed));
  assert.equal(parsed.name, "build");
  assert.equal(parsed.kind, "main");
  assert.deepEqual(parsed.tools, ["read", "bash", "edit"]);
  assert.equal(parsed.permission?.tools?.read, "allow");
  assert.equal(parsed.permission?.bash?.default, "ask");
  assert.deepEqual(parsed.permission?.bash?.deny, ["\\bsudo\\b"]);
});

test("rejects incomplete agent definitions", () => {
  const parsed = parseAgentMarkdown(`---
name: broken
---
`, "user", "/tmp/broken.md");
  assert.ok("error" in parsed);
});
