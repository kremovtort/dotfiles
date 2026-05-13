import assert from "node:assert/strict";
import test from "node:test";
import { PermissionApprovalComponent } from "../src/permission-approval-ui.ts";
import type { AgentIdentity, PermissionApprovalResult, PermissionDecision } from "../src/types.ts";

const identity: AgentIdentity = {
  id: "main-build-test",
  agentName: "build",
  kind: "main",
  source: "builtin",
  policyHash: "test",
  createdAt: 1,
};

function decision(command: string): PermissionDecision {
  return {
    state: "ask",
    reason: "bash command resolved to ask",
    matchedRule: "bash:*",
    fingerprint: { category: "bash", operation: "exec", target: command, normalized: `bash:exec:${command}` },
  };
}

function keybindings() {
  const bindings: Record<string, string[]> = {
    "tui.select.up": ["\x1b[A"],
    "tui.select.down": ["\x1b[B"],
    "tui.select.confirm": ["\r"],
    "tui.select.cancel": ["\x1b", "\x03"],
    "app.tools.expand": ["\x0f"],
  };
  return {
    matches: (data: string, binding: string) => bindings[binding]?.includes(data) ?? false,
    getKeys: (binding: string) => binding === "app.tools.expand" ? ["ctrl+o"] : bindings[binding] ?? [],
  };
}

function makeComponent(command: string, rows = 24) {
  return makeDecisionComponent(decision(command), rows);
}

function makeDecisionComponent(permissionDecision: PermissionDecision, rows = 24) {
  const results: PermissionApprovalResult[] = [];
  const component = new PermissionApprovalComponent({
    identity,
    decision: permissionDecision,
    keybindings: keybindings(),
    getRows: () => rows,
    highlightCode: (code) => code.split("\n").map((line) => `hl:${line}`),
    onDone: (result) => results.push(result),
  });
  return { component, results };
}

function toolDecision(toolName: string, target: string): PermissionDecision {
  const fingerprintTarget = `${toolName}:${target}`;
  return {
    state: "ask",
    reason: `tool ${toolName} resolved to ask for ${target}`,
    matchedRule: `tools.${toolName}`,
    fingerprint: { category: "tool", operation: "call", target: fingerprintTarget, normalized: `tool:call:${fingerprintTarget}` },
  };
}

function externalFileDecision(toolName: string, target: string): PermissionDecision {
  const fingerprintTarget = `${toolName}:${target}`;
  return {
    state: "ask",
    reason: `external path ${target} resolved to ask`,
    matchedRule: "external_directory:/tmp/**",
    fingerprint: {
      category: "file",
      operation: "external_directory",
      target: fingerprintTarget,
      normalized: `file:external_directory:${fingerprintTarget}`,
    },
  };
}

test("permission approval component renders compact stacked layout with preview before decisions", () => {
  const { component } = makeComponent("python <<'PY'\nimport os\nPY", 18);
  const lines = component.render(70);

  assert.equal(lines[0], "─".repeat(70));
  assert.equal(lines[1], "Permission required");
  assert.match(lines[3] ?? "", /Agent: build \(main\).*sha256:[a-f0-9]{8}/);
  assert.ok(lines.some((line) => line.includes("hl:python <<'PY'")));
  assert.ok(lines.some((line) => line.includes("1–3 / 3 · u/d scroll · Ctrl+O expand")));

  const previewIndex = lines.findIndex((line) => line.includes("hl:python"));
  const decisionIndex = lines.findIndex((line) => line.includes("❯ Deny"));
  assert.ok(previewIndex > 0);
  assert.ok(decisionIndex > previewIndex);
  assert.equal(lines.at(-2), "─".repeat(70));
  assert.ok(lines.at(-1)?.includes("u/d scroll · Ctrl+O expand"));
});

test("permission approval component renders decisions left of preview in wide layout", () => {
  const { component } = makeComponent("python <<'PY'\nimport os\nPY", 18);
  const lines = component.render(120);

  const splitLine = lines.find((line) => line.includes("❯ Deny") && line.includes("hl:python <<'PY'"));
  assert.ok(splitLine, lines.join("\n"));
  assert.ok(lines.some((line) => line.includes("┬")));
  assert.ok(lines.at(-2)?.includes("┴"));
  assert.ok(lines.at(-1)?.includes("u/d scroll · Ctrl+O expand"));
  assert.ok(splitLine?.includes("│"));
  assert.ok((splitLine?.indexOf("❯ Deny") ?? -1) < (splitLine?.indexOf("│") ?? -1));
  assert.ok((splitLine?.indexOf("│") ?? -1) < (splitLine?.indexOf("hl:python") ?? -1));
});

test("permission approval component defaults to deny and supports decision navigation", () => {
  const { component, results } = makeComponent("echo ok");

  component.handleInput("\r");
  assert.deepEqual(results.pop(), { outcome: "denied", reason: "Permission denied by user" });

  component.handleInput("\x1b[B");
  component.handleInput("\r");
  assert.deepEqual(results.pop(), { outcome: "approved", scope: "once" });

  component.handleInput("\x1b[B");
  component.handleInput("\r");
  assert.deepEqual(results.pop(), { outcome: "approved", scope: "session" });
});

test("permission approval component scrolls preview with u/d and expands with app.tools.expand", () => {
  const command = Array.from({ length: 30 }, (_, i) => `echo ${i}`).join("\n");
  const { component } = makeComponent(command, 30);

  const compact = component.render(72);
  assert.ok(compact.length < 28);
  assert.ok(compact.some((line) => line.includes("1–12 / 30")));
  assert.doesNotMatch(compact.join("\n"), /echo 20/);

  component.handleInput("d");
  const scrolled = component.render(72);
  assert.ok(scrolled.some((line) => line.includes("2–13 / 30")));
  assert.doesNotMatch(scrolled.join("\n"), /echo 0/);

  component.handleInput("u");
  component.handleInput("\x0f");
  const expanded = component.render(72);
  assert.ok(expanded.length > compact.length);
  assert.ok(expanded.some((line) => line.includes("1–18 / 30")));

  component.handleInput("\x1b[6~");
  const pageDown = component.render(72);
  assert.ok(pageDown.some((line) => line.includes("13–30 / 30")));
  assert.ok(pageDown.some((line) => line.includes("u/d scroll · Ctrl+O collapse")));

  component.handleInput("\x1b[5~");
  const pageUp = component.render(72);
  assert.ok(pageUp.some((line) => line.includes("1–18 / 30")));
  assert.doesNotMatch(pageUp.join("\n"), /PgUp|PgDn/);
});

test("permission approval component keeps compact footprint stable across preview lengths", () => {
  const short = makeComponent("echo ok", 30).component.render(72);
  const long = makeComponent(Array.from({ length: 30 }, (_, i) => `echo ${i}`).join("\n"), 30).component.render(72);

  assert.equal(short.length, long.length);
  assert.ok(short.some((line) => line.includes("1–1 / 1")));
  assert.ok(long.some((line) => line.includes("1–12 / 30")));
});

test("permission approval component uses compact view for non-bash tool requests", () => {
  const { component } = makeDecisionComponent(toolDecision("read", "nvim/plugins/lsp.nix"), 30);
  const lines = component.render(120);
  const text = lines.join("\n");

  assert.match(text, /Request: tool read/);
  assert.match(text, /Target: nvim\/plugins\/lsp\.nix/);
  assert.doesNotMatch(text, /u\/d scroll/);
  assert.doesNotMatch(text, /Ctrl\+O/);
  assert.doesNotMatch(text, /hl:/);
  assert.ok(lines.some((line) => line.includes("│") && line.includes("Target: nvim/plugins/lsp.nix")));
});

test("permission approval component shows concrete external file tool and path", () => {
  for (const toolName of ["read", "write", "edit"]) {
    const { component } = makeDecisionComponent(externalFileDecision(toolName, "/tmp/outside.txt"), 30);
    const lines = component.render(120);
    const text = lines.join("\n");

    assert.match(text, new RegExp(`Request: tool ${toolName}`));
    assert.match(text, /Target: \/tmp\/outside\.txt/);
    assert.doesNotMatch(text, /Request: file external_directory/);
    assert.doesNotMatch(text, /u\/d scroll/);
    assert.doesNotMatch(text, /Ctrl\+O/);
  }
});
