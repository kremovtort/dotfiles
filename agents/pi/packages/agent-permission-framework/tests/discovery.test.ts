import assert from "node:assert/strict";
import { mkdtempSync, rmSync, mkdirSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import test from "node:test";
import { discoverAgents } from "../src/agents.ts";
import { builtinAgents } from "../src/builtins.ts";
import { deriveActiveToolNames, evaluateToolPermission } from "../src/policy.ts";

const agent = (name: string, description = name) => `---
name: ${name}
kind: subagent
description: ${description}
---
Prompt for ${name}.
`;

test("discovers user agents and excludes project agents until trusted", () => {
  const dir = mkdtempSync(join(tmpdir(), "agent-discovery-"));
  try {
    const userDir = join(dir, "user-agents");
    const projectRoot = join(dir, "project");
    const projectDir = join(projectRoot, ".pi", "agents");
    mkdirSync(userDir, { recursive: true });
    mkdirSync(projectDir, { recursive: true });
    writeFileSync(join(userDir, "scout.md"), agent("scout", "user scout"));
    writeFileSync(join(projectDir, "scout.md"), agent("scout", "project scout"));

    const untrusted = discoverAgents({ cwd: projectRoot, userAgentDir: userDir, includeProjectAgents: false });
    assert.equal(untrusted.agents.find((a) => a.name === "scout")?.description, "user scout");

    const trusted = discoverAgents({ cwd: projectRoot, userAgentDir: userDir, includeProjectAgents: true });
    assert.equal(trusted.agents.find((a) => a.name === "scout")?.description, "project scout");
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});

test("built-in agents derive active tools from permissions", () => {
  for (const agent of builtinAgents) {
    assert.equal(agent.tools, undefined);
  }

  const plan = builtinAgents.find((agent) => agent.name === "plan")!;
  assert.equal(evaluateToolPermission(plan.permission, "new_tool", true).state, "allow");
  assert.equal(evaluateToolPermission(plan.permission, "grep", true, "secrets/key").state, "deny");
  assert.equal(evaluateToolPermission(plan.permission, "ls", true, ".git/config").state, "deny");
  assert.deepEqual(
    deriveActiveToolNames(plan.permission, ["read", "bash", "edit", "write", "subagent", "new_tool"], true),
    ["read", "bash", "subagent", "new_tool"],
  );

  const build = builtinAgents.find((agent) => agent.name === "build")!;
  assert.equal(evaluateToolPermission(build.permission, "new_tool", true).state, "allow");
  assert.equal(evaluateToolPermission(build.permission, "write", true, "secrets/key").state, "deny");
  assert.equal(evaluateToolPermission(build.permission, "edit", true, ".git/config").state, "deny");
  assert.equal(evaluateToolPermission(build.permission, "write", true, ".env.example").state, "deny");
  assert.deepEqual(
    deriveActiveToolNames(build.permission, ["read", "edit", "write", "new_tool"], true),
    ["read", "edit", "write", "new_tool"],
  );

  const ask = builtinAgents.find((agent) => agent.name === "ask")!;
  assert.equal(evaluateToolPermission(ask.permission, "new_tool", true).state, "allow");
  assert.equal(evaluateToolPermission(ask.permission, "find", true, "secrets/key").state, "deny");
  assert.equal(evaluateToolPermission(ask.permission, "read", true, ".env.example").state, "allow");
  assert.deepEqual(
    deriveActiveToolNames(ask.permission, ["read", "bash", "edit", "write", "new_tool"], true),
    ["read", "new_tool"],
  );
});

test("invalid and disabled agents are ignored", () => {
  const dir = mkdtempSync(join(tmpdir(), "agent-discovery-"));
  try {
    const userDir = join(dir, "user-agents");
    mkdirSync(userDir, { recursive: true });
    writeFileSync(join(userDir, "broken.md"), `---
name: broken
---
`);
    writeFileSync(join(userDir, "disabled.md"), `---
name: disabled
kind: subagent
description: disabled
enabled: false
---
Prompt.
`);
    const result = discoverAgents({ cwd: dir, userAgentDir: userDir, includeProjectAgents: false });
    assert.equal(result.agents.length, 0);
    assert.equal(result.ignored.length, 2);
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});
