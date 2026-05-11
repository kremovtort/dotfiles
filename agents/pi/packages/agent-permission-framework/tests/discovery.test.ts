import assert from "node:assert/strict";
import { mkdtempSync, rmSync, mkdirSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import test from "node:test";
import { discoverAgents } from "../src/agents.ts";
import { builtinAgents } from "../src/builtins.ts";
import { deriveActiveToolNames, evaluateToolPermission, normalizePermissionPolicy } from "../src/policy.ts";
import type { AgentDefinition } from "../src/types.ts";

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

const mainAgent = (name: string, description: string, permission?: unknown): AgentDefinition => ({
  name,
  kind: "main",
  description,
  prompt: `Prompt for ${name}.`,
  source: "builtin",
  enabled: true,
  promptMode: "replace",
  permission: normalizePermissionPolicy(permission),
});

test("loads user bureau config by default and creates new agents", () => {
  const dir = mkdtempSync(join(tmpdir(), "bureau-discovery-"));
  try {
    const userBase = join(dir, "user");
    mkdirSync(join(userBase, "agents"), { recursive: true });
    writeFileSync(join(userBase, "bureau.yaml"), `agent:
  my-new-agent:
    description: New from bureau
    prompt: |
      Bureau prompt.
`);

    const result = discoverAgents({ cwd: dir, userConfigDir: userBase, includeProjectAgents: false });
    const created = result.agents.find((a) => a.name === "my-new-agent");

    assert.equal(created?.kind, "subagent");
    assert.equal(created?.description, "New from bureau");
    assert.equal(created?.prompt, "Bureau prompt.");
    assert.deepEqual(created?.configSources, [join(userBase, "bureau.yaml")]);
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});

test("project bureau config is trust gated", () => {
  const dir = mkdtempSync(join(tmpdir(), "bureau-project-"));
  try {
    const userBase = join(dir, "user");
    const projectRoot = join(dir, "project");
    const projectPi = join(projectRoot, ".pi");
    mkdirSync(join(userBase, "agents"), { recursive: true });
    mkdirSync(projectPi, { recursive: true });
    writeFileSync(join(projectPi, "bureau.yaml"), `agent:
  project-agent:
    description: Project agent
    prompt: Project prompt
`);

    const untrusted = discoverAgents({ cwd: projectRoot, userConfigDir: userBase, includeProjectAgents: false });
    assert.equal(untrusted.agents.some((a) => a.name === "project-agent"), false);

    const trusted = discoverAgents({ cwd: projectRoot, userConfigDir: userBase, includeProjectAgents: true });
    assert.equal(trusted.agents.find((a) => a.name === "project-agent")?.description, "Project agent");
    assert.equal(trusted.projectBureauFile, join(projectPi, "bureau.yaml"));
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});

test("applies full bureau and markdown source precedence", () => {
  const dir = mkdtempSync(join(tmpdir(), "bureau-precedence-"));
  try {
    const userBase = join(dir, "user");
    const userAgents = join(userBase, "agents");
    const projectRoot = join(dir, "project");
    const projectPi = join(projectRoot, ".pi");
    const projectAgents = join(projectPi, "agents");
    mkdirSync(userAgents, { recursive: true });
    mkdirSync(projectAgents, { recursive: true });

    writeFileSync(join(userAgents, "shared.md"), `---
name: shared
kind: main
description: user markdown
permission:
  tools:
    read: allow
---
User prompt.
`);
    writeFileSync(join(userBase, "bureau.yaml"), `agent:
  shared:
    description: user bureau
    permission:
      tools:
        read: deny
`);
    writeFileSync(join(projectAgents, "shared.md"), `---
name: shared
kind: main
description: project markdown
permission:
  tools:
    read: ask
---
Project prompt.
`);
    writeFileSync(join(projectPi, "bureau.yaml"), `agent:
  shared:
    description: project bureau
    permission:
      tools:
        read: allow
`);

    const result = discoverAgents({ cwd: projectRoot, userConfigDir: userBase, includeProjectAgents: true }, [mainAgent("shared", "builtin")]);
    const shared = result.agents.find((a) => a.name === "shared")!;

    assert.equal(shared.description, "project bureau");
    assert.equal(evaluateToolPermission(shared.permission, "read", true).state, "allow");
    assert.deepEqual(shared.configSources, [join(projectAgents, "shared.md"), join(projectPi, "bureau.yaml")]);
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});

test("global bureau permissions compose with agent-local policies by precedence", () => {
  const dir = mkdtempSync(join(tmpdir(), "bureau-policy-"));
  try {
    const userBase = join(dir, "user");
    const projectRoot = join(dir, "project");
    const projectPi = join(projectRoot, ".pi");
    const projectAgents = join(projectPi, "agents");
    mkdirSync(join(userBase, "agents"), { recursive: true });
    mkdirSync(projectAgents, { recursive: true });

    writeFileSync(join(userBase, "bureau.yaml"), `permission:
  tools:
    new-tool: deny
    write: ask
agent:
  build:
    permission:
      tools:
        write: allow
`);

    const userOnly = discoverAgents({ cwd: projectRoot, userConfigDir: userBase, includeProjectAgents: false }, [mainAgent("build", "builtin")]);
    const userBuild = userOnly.agents.find((a) => a.name === "build")!;
    assert.equal(evaluateToolPermission(userBuild.permission, "write", true).state, "allow");
    assert.equal(evaluateToolPermission(userBuild.permission, "new-tool", true).state, "deny");

    writeFileSync(join(projectAgents, "build.md"), `---
name: build
kind: main
description: Project build
permission:
  tools:
    new-tool: allow
---
Project build prompt.
`);
    writeFileSync(join(projectPi, "bureau.yaml"), `permission:
  tools:
    new-tool: deny
agent:
  build:
    permission:
      tools:
        new-tool: allow
`);

    const result = discoverAgents({ cwd: projectRoot, userConfigDir: userBase, includeProjectAgents: true }, [mainAgent("build", "builtin")]);
    const build = result.agents.find((a) => a.name === "build")!;

    assert.equal(evaluateToolPermission(build.permission, "write", true).state, "ask");
    assert.equal(evaluateToolPermission(build.permission, "new-tool", true).state, "allow");
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});

test("disabled bureau entries remove agents until a later layer redefines them", () => {
  const dir = mkdtempSync(join(tmpdir(), "bureau-disabled-"));
  try {
    const userBase = join(dir, "user");
    const projectRoot = join(dir, "project");
    const projectPi = join(projectRoot, ".pi");
    mkdirSync(join(userBase, "agents"), { recursive: true });
    mkdirSync(projectPi, { recursive: true });
    writeFileSync(join(userBase, "bureau.yaml"), `agent:
  build:
    enabled: false
`);

    const disabled = discoverAgents({ cwd: projectRoot, userConfigDir: userBase, includeProjectAgents: false }, [mainAgent("build", "builtin")]);
    assert.equal(disabled.agents.some((a) => a.name === "build"), false);

    writeFileSync(join(projectPi, "bureau.yaml"), `agent:
  build:
    enabled: true
    description: Project build
`);
    const reenabled = discoverAgents({ cwd: projectRoot, userConfigDir: userBase, includeProjectAgents: true }, [mainAgent("build", "builtin")]);
    const build = reenabled.agents.find((a) => a.name === "build");
    assert.equal(build?.description, "Project build");
    assert.equal(build?.prompt, "Prompt for build.");
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});
