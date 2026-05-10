import assert from "node:assert/strict";
import { mkdtempSync, rmSync, mkdirSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import test from "node:test";
import { discoverAgents } from "../src/agents.ts";

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
