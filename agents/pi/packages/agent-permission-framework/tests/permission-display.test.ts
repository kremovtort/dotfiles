import assert from "node:assert/strict";
import test from "node:test";
import {
  createPermissionDisplay,
  formatApprovalFallbackMessage,
  formatAuditActionSummary,
  parseNormalizedAction,
  truncateVisible,
} from "../src/permission-display.ts";
import type { PermissionDecision } from "../src/types.ts";

test("permission display parses normalized actions without truncating identity", () => {
  const command = "python <<'PY'\nimport os\nprint(os.getcwd())\nPY";
  const normalized = `bash:exec:${command}`;
  const display = createPermissionDisplay(normalized, { summaryWidth: 36, previewLineLimit: 2 });

  assert.deepEqual(parseNormalizedAction(normalized), { category: "bash", operation: "exec", target: command });
  assert.equal(display.normalized, normalized);
  assert.equal(display.sourceText, command);
  assert.equal(display.lineCount, 4);
  assert.equal(display.language, "python");
  assert.equal(display.previewText, "python <<'PY'\nimport os");
  assert.equal(display.truncatedPreview, true);
  assert.equal(display.shortHash.length, 8);
  assert.ok(display.summary.length <= 36);
});

test("fallback approval message is bounded and keeps full fingerprint out of long preview body", () => {
  const command = Array.from({ length: 50 }, (_, i) => `echo ${i}`).join("\n");
  const normalized = `bash:exec:${command}`;
  const decision: PermissionDecision = {
    state: "ask",
    reason: "matched ask rule",
    matchedRule: "bash:*",
    fingerprint: { category: "bash", operation: "exec", target: command, normalized },
  };

  const message = formatApprovalFallbackMessage(
    { agentName: "build", kind: "main" },
    decision,
    { previewLines: 3, width: 80 },
  );

  assert.match(message, /Permission required/);
  assert.match(message, /Agent: build \(main\)/);
  assert.match(message, /sha256:[a-f0-9]{8}/);
  assert.match(message, /Action: bash exec:/);
  assert.match(message, /… 47 more line\(s\) hidden/);
  assert.doesNotMatch(message, /echo 49/);
});

test("non-bash tool display strips duplicated tool prefix from target", () => {
  const display = createPermissionDisplay("tool:call:read:nvim/plugins/lsp.nix");

  assert.equal(display.actionLabel, "tool read");
  assert.equal(display.sourceText, "nvim/plugins/lsp.nix");
  assert.match(display.summary, /^tool read: nvim\/plugins\/lsp\.nix/);
});

test("audit action summary is compact but correlatable", () => {
  const command = `${"x".repeat(200)}\n${"y".repeat(200)}`;
  const summary = formatAuditActionSummary({
    category: "bash",
    operation: "exec",
    target: command,
    normalized: `bash:exec:${command}`,
  }, 72);

  assert.ok(truncateVisible(summary, 72).length <= 72);
  assert.match(summary, /sha256:[a-f0-9]{8}/);
  assert.doesNotMatch(summary, /yyyyyyyyyyyyyyyyyyyy/);
});
