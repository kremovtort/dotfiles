import assert from "node:assert/strict";
import { mkdirSync, mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import test from "node:test";
import { loadBureauConfigFromDir, parseBureauConfigFile, selectBureauConfigFile } from "../src/bureau-config.ts";
import { evaluateToolPermission } from "../src/policy.ts";

function tempDir(): string {
  return mkdtempSync(join(tmpdir(), "bureau-config-"));
}

test("parses JSON and JSONC bureau config files", () => {
  const dir = tempDir();
  try {
    const json = join(dir, "bureau.json");
    const jsonc = join(dir, "bureau.jsonc");
    writeFileSync(json, JSON.stringify({ agent: { jsonAgent: { description: "JSON", prompt: "JSON prompt" } } }));
    writeFileSync(jsonc, `{
      // comments and trailing commas are valid in jsonc
      "agent": {
        "jsoncAgent": {
          "description": "JSONC",
          "prompt": "JSONC prompt",
        },
      },
    }`);

    const parsedJson = parseBureauConfigFile(json, "user");
    const parsedJsonc = parseBureauConfigFile(jsonc, "user");

    assert.equal(parsedJson.agentPatches[0].name, "jsonAgent");
    assert.equal(parsedJsonc.agentPatches[0].name, "jsoncAgent");
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});

test("parses YAML/YML bureau config files including block scalar prompts", () => {
  const dir = tempDir();
  try {
    const yaml = join(dir, "bureau.yaml");
    const yml = join(dir, "bureau.yml");
    writeFileSync(yaml, `agent:
  yaml-agent:
    description: YAML agent
    prompt: |
      First line.
      Second line.
permission:
  tools:
    new-tool: deny
`);
    writeFileSync(yml, `agent:
  yml-agent:
    description: YML agent
    prompt: YML prompt
`);

    const parsedYaml = parseBureauConfigFile(yaml, "user");
    const parsedYml = parseBureauConfigFile(yml, "user");

    assert.equal(parsedYaml.agentPatches[0].prompt, "First line.\nSecond line.");
    assert.equal(evaluateToolPermission(parsedYaml.permission, "new-tool", true).state, "deny");
    assert.equal(parsedYml.agentPatches[0].name, "yml-agent");
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});

test("selects one same-scope bureau config deterministically and warns for duplicates", () => {
  const dir = tempDir();
  try {
    mkdirSync(dir, { recursive: true });
    writeFileSync(join(dir, "bureau.json"), "{}");
    writeFileSync(join(dir, "bureau.jsonc"), "{}");
    writeFileSync(join(dir, "bureau.yaml"), "{}");

    const selected = selectBureauConfigFile(dir);

    assert.equal(selected.filePath, join(dir, "bureau.jsonc"));
    assert.equal(selected.warnings.length, 2);
    assert.match(selected.warnings[0].reason, /higher bureau config precedence/);
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});

test("invalid bureau config is ignored with file-specific warning", () => {
  const dir = tempDir();
  try {
    writeFileSync(join(dir, "bureau.json"), `{ "permission": { "new-tool": "deny" } }`);

    const loaded = loadBureauConfigFromDir(dir, "user");

    assert.equal(loaded.layer, undefined);
    assert.equal(loaded.warnings.length, 1);
    assert.equal(loaded.warnings[0].filePath, join(dir, "bureau.json"));
    assert.match(loaded.warnings[0].reason, /Unsupported permission category "new-tool"/);
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});

test("unsupported bureau agent fields warn and are not normalized", () => {
  const dir = tempDir();
  try {
    writeFileSync(join(dir, "bureau.yaml"), `agent:
  build:
    permissions:
      tools:
        read: deny
    tools: read
    disallowed_tools: write
`);

    const loaded = loadBureauConfigFromDir(dir, "user");

    assert.ok(loaded.layer);
    assert.equal(loaded.layer?.agentPatches.length, 0);
    assert.equal(loaded.warnings.length, 3);
    assert.match(loaded.warnings.map((warning) => warning.reason).join("\n"), /agent\.build\.permissions/);
    assert.match(loaded.warnings.map((warning) => warning.reason).join("\n"), /agent\.build\.tools/);
    assert.match(loaded.warnings.map((warning) => warning.reason).join("\n"), /agent\.build\.disallowed_tools/);
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});
