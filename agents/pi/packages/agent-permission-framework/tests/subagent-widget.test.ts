import assert from "node:assert/strict";
import test from "node:test";
import { renderSubagentWidgetLines, SubagentWidget, subagentStatusText } from "../src/subagent-widget.ts";
import type { AgentIdentity, SubagentRunRecord } from "../src/types.ts";

const identity: AgentIdentity = {
  id: "child-scout-test",
  agentName: "scout",
  kind: "subagent",
  source: "builtin",
  runId: "agent-test",
  policyHash: "test",
  createdAt: 1,
};

const theme = {
  fg: (_color: string, text: string) => text,
  bold: (text: string) => text,
};

function run(overrides: Partial<SubagentRunRecord>): SubagentRunRecord {
  return {
    id: "agent-test",
    agentName: "scout",
    description: "Find things",
    task: "search",
    status: "running",
    startedAt: Date.now() - 1000,
    output: "",
    identity,
    cwd: "/repo",
    steering: [],
    ...overrides,
  };
}

test("subagent status text matches pi-subagents running and queued wording", () => {
  assert.equal(subagentStatusText([]), undefined);
  assert.equal(subagentStatusText([run({ status: "running" })]), "1 running agent");
  assert.equal(subagentStatusText([
    run({ id: "one", status: "running" }),
    run({ id: "two", status: "running" }),
    run({ id: "three", status: "queued" }),
  ]), "2 running, 1 queued agents");
});

test("running subagent widget uses copied heading, tree, spinner, stats, and activity layout", () => {
  const lines = renderSubagentWidgetLines([
    run({ status: "running", turnCount: 2, maxTurns: 5, toolUses: 1, output: "Reading repository files" }),
  ], new Map(), 0, 200, theme);

  assert.equal(lines[0], "● Agents");
  assert.match(lines[1], /└─ ⠋ scout  Find things · ⟳2≤5 · 1 tool use · \d+\.\ds/);
  assert.equal(lines[2], "     ⎿  Reading repository files");
});

test("running subagent activity uses upstream active tool wording before output", () => {
  const lines = renderSubagentWidgetLines([
    run({ status: "running", activeTools: ["read", "grep", "grep"], output: "Older response text" }),
  ], new Map(), 0, 200, theme);

  assert.equal(lines[2], "     ⎿  reading, searching 2 patterns…");
});

test("queued subagents render with upstream queued summary", () => {
  const lines = renderSubagentWidgetLines([
    run({ id: "one", status: "queued" }),
    run({ id: "two", status: "queued" }),
  ], new Map(), 0, 200, theme);

  assert.deepEqual(lines, ["● Agents", "└─ ◦ 2 queued"]);
});

test("finished runs use upstream linger and icons", () => {
  const completed = run({ status: "completed", completedAt: Date.now(), toolUses: 2 });
  const failed = run({ id: "failed", status: "failed", completedAt: Date.now(), error: "boom", identity: { ...identity, id: "failed", runId: "failed" } });
  const steered = run({ id: "steered", status: "steered", completedAt: Date.now(), identity: { ...identity, id: "steered", runId: "steered" } });

  assert.match(renderSubagentWidgetLines([completed], new Map([[completed.id, 0]]), 0, 200, theme).join("\n"), /✓ scout/);
  assert.deepEqual(renderSubagentWidgetLines([completed], new Map([[completed.id, 1]]), 0, 200, theme), []);

  assert.match(renderSubagentWidgetLines([failed], new Map([[failed.id, 1]]), 0, 200, theme).join("\n"), /✗ scout.*error: boom/);
  assert.deepEqual(renderSubagentWidgetLines([failed], new Map([[failed.id, 2]]), 0, 200, theme), []);

  assert.match(renderSubagentWidgetLines([steered], new Map([[steered.id, 0]]), 0, 200, theme).join("\n"), /✓ scout.*\(turn limit\)/);
});

test("restored terminal runs do not register as fresh finished widget entries", () => {
  const completed = run({ status: "completed", completedAt: Date.now() });
  let widgetSet = false;
  let statusSet = false;
  const widget = new SubagentWidget({ list: () => [completed] });
  widget.setUICtx({
    theme,
    setStatus: (_key, text) => {
      if (text !== undefined) statusSet = true;
    },
    setWidget: (_key, content) => {
      if (content !== undefined) widgetSet = true;
    },
  });

  widget.update();
  widget.dispose();

  assert.equal(widgetSet, false);
  assert.equal(statusSet, false);
});

test("live active runs linger after terminal transition", () => {
  const live = run({ status: "running" });
  let current = live;
  let component: { render(width: number): string[] } | undefined;
  const rendered: string[][] = [];
  const widget = new SubagentWidget({ list: () => [current] });
  const tui = {
    requestRender: () => {
      if (component) rendered.push(component.render(200));
    },
  };
  widget.setUICtx({
    theme,
    setStatus: () => {},
    setWidget: (_key, content) => {
      if (typeof content === "function") {
        component = content(tui, theme);
        rendered.push(component.render(200));
      }
    },
  });

  widget.update();
  current = { ...live, status: "completed", completedAt: Date.now() };
  widget.update();
  widget.dispose();

  assert.match(rendered.at(-1)?.join("\n") ?? "", /✓ scout/);
});

test("overflow prioritizes running agents and renders upstream overflow summary", () => {
  const runs = Array.from({ length: 6 }, (_, index) => run({
    id: `agent-${index}`,
    description: `Task ${index}`,
    identity: { ...identity, id: `child-${index}`, runId: `agent-${index}` },
  }));

  const lines = renderSubagentWidgetLines(runs, new Map(), 0, 200, theme);

  assert.equal(lines.length, 12);
  assert.equal(lines[0], "● Agents");
  assert.match(lines.at(-1) ?? "", /└─ \+1 more \(1 running\)/);
});
