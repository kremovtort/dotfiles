// Vendored/adapted from tintinweb/pi-subagents src/ui/agent-widget.ts.
// Keep the visible indicator grammar aligned with upstream: status wording,
// Agents widget heading/tree layout, icons, spinner frames, linger, and overflow.

import type { SubagentRegistry } from "./subagent-registry.ts";
import type { SubagentRunRecord } from "./types.ts";

const MAX_WIDGET_LINES = 12;
export const SUBAGENT_WIDGET_SPINNER = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"];
const ERROR_STATUSES = new Set(["failed", "aborted", "interrupted", "steered", "stopped", "error"]);
const TOOL_DISPLAY: Record<string, string> = {
  read: "reading",
  bash: "running command",
  edit: "editing",
  write: "writing",
  grep: "searching",
  find: "finding files",
  ls: "listing",
};
const WIDGET_KEY = "agents";
const STATUS_KEY = "subagents";

export type ThemeLike = {
  fg(color: string, text: string): string;
  bold(text: string): string;
};

export type UICtx = {
  theme: ThemeLike;
  setStatus(key: string, text: string | undefined): void;
  setWidget(
    key: string,
    content: undefined | string[] | ((tui: any, theme: ThemeLike) => { render(width: number): string[]; invalidate(): void; dispose?(): void }),
    options?: { placement?: "aboveEditor" | "belowEditor" },
  ): void;
};

type WidgetRunStatus = SubagentRunRecord["status"] | "stopped" | "error";

type WidgetRun = {
  id: string;
  type: string;
  status: WidgetRunStatus;
  description: string;
  toolUses: number;
  startedAt: number;
  completedAt?: number;
  error?: string;
  turnCount?: number;
  maxTurns?: number;
  activity: string;
};

function visibleWidth(text: string): number {
  return text.replace(/\x1b\[[0-?]*[ -/]*[@-~]/g, "").length;
}

function truncateToWidth(text: string, maxWidth: number, ellipsis = "..."): string {
  if (maxWidth <= 0) return "";
  if (visibleWidth(text) <= maxWidth) return text;
  const targetWidth = Math.max(0, maxWidth - visibleWidth(ellipsis));
  let result = "";
  let width = 0;
  for (let i = 0; i < text.length;) {
    const ansi = /^\x1b\[[0-?]*[ -/]*[@-~]/.exec(text.slice(i));
    if (ansi) {
      result += ansi[0];
      i += ansi[0].length;
      continue;
    }
    const char = text[i]!;
    if (width + 1 > targetWidth) break;
    result += char;
    width++;
    i++;
  }
  return result + ellipsis;
}

function formatMs(ms: number): string {
  return `${(ms / 1000).toFixed(1)}s`;
}

function formatTurns(turnCount: number, maxTurns?: number | null): string {
  return maxTurns != null ? `⟳${turnCount}≤${maxTurns}` : `⟳${turnCount}`;
}

function truncateLine(text: string, len = 60): string {
  const line = text.split("\n").find((candidate) => candidate.trim())?.trim() ?? "";
  if (line.length <= len) return line;
  return line.slice(0, len) + "…";
}

function describeActivity(run: SubagentRunRecord): string {
  if (run.status === "interrupted") return run.resumable ? "ask the agent to inspect or resume this run" : "interrupted";
  if (run.pendingPermission) return `waiting for permission: ${run.pendingPermission.action}`;
  if (run.activeTools && run.activeTools.length > 0) {
    const groups = new Map<string, number>();
    for (const toolName of run.activeTools) {
      const action = TOOL_DISPLAY[toolName] ?? toolName;
      groups.set(action, (groups.get(action) ?? 0) + 1);
    }

    const parts: string[] = [];
    for (const [action, count] of groups) {
      if (count > 1) {
        parts.push(`${action} ${count} ${action === "searching" ? "patterns" : "files"}`);
      } else {
        parts.push(action);
      }
    }
    return parts.join(", ") + "…";
  }

  if (run.output && run.output.trim().length > 0) return truncateLine(run.output);
  if (run.error && run.error.trim().length > 0) return `error: ${truncateLine(run.error)}`;
  return "thinking…";
}

function displayName(type: string): string {
  return type;
}

function toWidgetRun(run: SubagentRunRecord): WidgetRun {
  return {
    id: run.id,
    type: run.agentName,
    status: run.status,
    description: run.description ?? run.agentName,
    toolUses: run.toolUses ?? 0,
    startedAt: run.startedAt ?? Date.now(),
    completedAt: run.completedAt,
    error: run.error,
    turnCount: run.turnCount,
    maxTurns: run.maxTurns,
    activity: describeActivity(run),
  };
}

export function subagentStatusText(runs: SubagentRunRecord[]): string | undefined {
  let runningCount = 0;
  let queuedCount = 0;
  for (const run of runs) {
    if (run.status === "running") runningCount++;
    else if (run.status === "queued") queuedCount++;
  }
  const total = runningCount + queuedCount;
  if (total === 0) return undefined;
  const statusParts: string[] = [];
  if (runningCount > 0) statusParts.push(`${runningCount} running`);
  if (queuedCount > 0) statusParts.push(`${queuedCount} queued`);
  return `${statusParts.join(", ")} agent${total === 1 ? "" : "s"}`;
}

export function renderSubagentWidgetLines(
  runs: SubagentRunRecord[],
  finishedTurnAge: ReadonlyMap<string, number>,
  widgetFrame: number,
  width: number,
  theme: ThemeLike,
): string[] {
  const mapped = runs.map(toWidgetRun);
  const running = mapped.filter((run) => run.status === "running");
  const queued = mapped.filter((run) => run.status === "queued");
  const finished = mapped.filter((run) =>
    run.status !== "running" && run.status !== "queued" && run.completedAt && shouldShowFinished(run.id, run.status, finishedTurnAge),
  );

  const hasActive = running.length > 0 || queued.length > 0;
  const hasFinished = finished.length > 0;
  if (!hasActive && !hasFinished) return [];

  const truncate = (line: string) => truncateToWidth(line, width);
  const headingColor = hasActive ? "accent" : "dim";
  const headingIcon = hasActive ? "●" : "○";
  const frame = SUBAGENT_WIDGET_SPINNER[widgetFrame % SUBAGENT_WIDGET_SPINNER.length];

  const finishedLines = finished.map((run) => truncate(theme.fg("dim", "├─") + " " + renderFinishedLine(run, theme)));

  const runningLines: string[][] = [];
  for (const run of running) {
    const name = displayName(run.type);
    const elapsed = formatMs(Date.now() - run.startedAt);
    const parts: string[] = [];
    if (run.turnCount != null) parts.push(formatTurns(run.turnCount, run.maxTurns));
    if (run.toolUses > 0) parts.push(`${run.toolUses} tool use${run.toolUses === 1 ? "" : "s"}`);
    parts.push(elapsed);
    const statsText = parts.join(" · ");

    runningLines.push([
      truncate(theme.fg("dim", "├─") + ` ${theme.fg("accent", frame)} ${theme.bold(name)}  ${theme.fg("muted", run.description)} ${theme.fg("dim", "·")} ${theme.fg("dim", statsText)}`),
      truncate(theme.fg("dim", "│  ") + theme.fg("dim", `  ⎿  ${run.activity}`)),
    ]);
  }

  const queuedLine = queued.length > 0
    ? truncate(theme.fg("dim", "├─") + ` ${theme.fg("muted", "◦")} ${theme.fg("dim", `${queued.length} queued`)}`)
    : undefined;

  const maxBody = MAX_WIDGET_LINES - 1;
  const totalBody = finishedLines.length + runningLines.length * 2 + (queuedLine ? 1 : 0);
  const lines: string[] = [truncate(theme.fg(headingColor, headingIcon) + " " + theme.fg(headingColor, "Agents"))];

  if (totalBody <= maxBody) {
    lines.push(...finishedLines);
    for (const pair of runningLines) lines.push(...pair);
    if (queuedLine) lines.push(queuedLine);
    fixLastConnector(lines, runningLines.length > 0 && !queuedLine);
  } else {
    let budget = maxBody - 1;
    let hiddenRunning = 0;
    let hiddenFinished = 0;

    for (const pair of runningLines) {
      if (budget >= 2) {
        lines.push(...pair);
        budget -= 2;
      } else {
        hiddenRunning++;
      }
    }

    if (queuedLine && budget >= 1) {
      lines.push(queuedLine);
      budget--;
    }

    for (const line of finishedLines) {
      if (budget >= 1) {
        lines.push(line);
        budget--;
      } else {
        hiddenFinished++;
      }
    }

    const overflowParts: string[] = [];
    if (hiddenRunning > 0) overflowParts.push(`${hiddenRunning} running`);
    if (hiddenFinished > 0) overflowParts.push(`${hiddenFinished} finished`);
    const overflowText = overflowParts.join(", ");
    lines.push(truncate(theme.fg("dim", "└─") + ` ${theme.fg("dim", `+${hiddenRunning + hiddenFinished} more (${overflowText})`)}`));
  }

  return lines;
}

function shouldShowFinished(agentId: string, status: string, finishedTurnAge: ReadonlyMap<string, number>): boolean {
  if (!finishedTurnAge.has(agentId)) return false;
  const age = finishedTurnAge.get(agentId) ?? 0;
  const maxAge = ERROR_STATUSES.has(status) ? 2 : 1;
  return age < maxAge;
}

function renderFinishedLine(run: WidgetRun, theme: ThemeLike): string {
  const name = displayName(run.type);
  const duration = formatMs((run.completedAt ?? Date.now()) - run.startedAt);

  let icon: string;
  let statusText: string;
  if (run.status === "completed") {
    icon = theme.fg("success", "✓");
    statusText = "";
  } else if (run.status === "steered") {
    icon = theme.fg("warning", "✓");
    statusText = theme.fg("warning", " (turn limit)");
  } else if (run.status === "stopped") {
    icon = theme.fg("dim", "■");
    statusText = theme.fg("dim", " stopped");
  } else if (run.status === "failed" || run.status === "error") {
    icon = theme.fg("error", "✗");
    const errMsg = run.error ? `: ${run.error.slice(0, 60)}` : "";
    statusText = theme.fg("error", ` error${errMsg}`);
  } else if (run.status === "interrupted") {
    icon = theme.fg("warning", "⚠");
    statusText = theme.fg("warning", " interrupted · resumable");
  } else {
    icon = theme.fg("error", "✗");
    statusText = theme.fg("warning", " aborted");
  }

  const parts: string[] = [];
  if (run.turnCount != null) parts.push(formatTurns(run.turnCount, run.maxTurns));
  if (run.toolUses > 0) parts.push(`${run.toolUses} tool use${run.toolUses === 1 ? "" : "s"}`);
  parts.push(duration);

  return `${icon} ${theme.fg("dim", name)}  ${theme.fg("dim", run.description)} ${theme.fg("dim", "·")} ${theme.fg("dim", parts.join(" · "))}${statusText}`;
}

function fixLastConnector(lines: string[], lastIsRunningActivity: boolean): void {
  if (lines.length <= 1) return;
  const last = lines.length - 1;
  lines[last] = lines[last]!.replace("├─", "└─");
  if (lastIsRunningActivity && last >= 2) {
    lines[last - 1] = lines[last - 1]!.replace("├─", "└─");
    lines[last] = lines[last]!.replace("│  ", "   ");
  }
}

export class SubagentWidget {
  private uiCtx: UICtx | undefined;
  private widgetFrame = 0;
  private widgetInterval: ReturnType<typeof setInterval> | undefined;
  private finishedTurnAge = new Map<string, number>();
  private widgetRegistered = false;
  private tui: { requestRender(force?: boolean): void } | undefined;
  private lastStatusText: string | undefined;
  private observedActiveRunIds = new Set<string>();
  private registry: Pick<SubagentRegistry, "list">;

  constructor(registry: Pick<SubagentRegistry, "list">) {
    this.registry = registry;
  }

  setUICtx(ctx: UICtx | undefined): void {
    if (ctx !== this.uiCtx) {
      this.uiCtx = ctx;
      this.widgetRegistered = false;
      this.tui = undefined;
      this.lastStatusText = undefined;
    }
  }

  onTurnStart(): void {
    for (const [id, age] of this.finishedTurnAge) this.finishedTurnAge.set(id, age + 1);
    this.update();
  }

  update(): void {
    if (!this.uiCtx) return;
    const runs = this.registry.list();
    for (const run of runs) {
      if (run.status === "running" || run.status === "queued") {
        this.observedActiveRunIds.add(run.id);
      } else if (run.status === "interrupted" && run.resumable && run.completedAt && !this.finishedTurnAge.has(run.id)) {
        this.finishedTurnAge.set(run.id, 0);
      } else if (run.completedAt && this.observedActiveRunIds.has(run.id) && !this.finishedTurnAge.has(run.id)) {
        this.finishedTurnAge.set(run.id, 0);
      }
    }

    const visibleLines = renderSubagentWidgetLines(runs, this.finishedTurnAge, this.widgetFrame, 1_000, this.uiCtx.theme).length;
    const hasVisible = visibleLines > 0;

    if (!hasVisible) {
      this.clearIfNeeded(runs);
      return;
    }

    const newStatusText = subagentStatusText(runs);
    if (newStatusText !== this.lastStatusText) {
      this.uiCtx.setStatus(STATUS_KEY, newStatusText);
      this.lastStatusText = newStatusText;
    }

    this.widgetFrame++;
    if (!this.widgetRegistered) {
      this.uiCtx.setWidget(WIDGET_KEY, (tui, theme) => {
        this.tui = tui;
        return {
          render: (width: number) => renderSubagentWidgetLines(this.registry.list(), this.finishedTurnAge, this.widgetFrame, width, theme),
          invalidate: () => {
            this.widgetRegistered = false;
            this.tui = undefined;
          },
        };
      }, { placement: "aboveEditor" });
      this.widgetRegistered = true;
    } else {
      this.tui?.requestRender();
    }

    if (!this.widgetInterval) {
      this.widgetInterval = setInterval(() => this.update(), 80);
    }
  }

  dispose(): void {
    if (this.widgetInterval) {
      clearInterval(this.widgetInterval);
      this.widgetInterval = undefined;
    }
    if (this.uiCtx) {
      this.uiCtx.setWidget(WIDGET_KEY, undefined);
      this.uiCtx.setStatus(STATUS_KEY, undefined);
    }
    this.widgetRegistered = false;
    this.tui = undefined;
    this.lastStatusText = undefined;
    this.observedActiveRunIds.clear();
  }

  private clearIfNeeded(runs: SubagentRunRecord[]): void {
    if (this.widgetRegistered) {
      this.uiCtx?.setWidget(WIDGET_KEY, undefined);
      this.widgetRegistered = false;
      this.tui = undefined;
    }
    if (this.lastStatusText !== undefined) {
      this.uiCtx?.setStatus(STATUS_KEY, undefined);
      this.lastStatusText = undefined;
    }
    if (this.widgetInterval) {
      clearInterval(this.widgetInterval);
      this.widgetInterval = undefined;
    }
    for (const [id] of this.finishedTurnAge) {
      if (!runs.some((run) => run.id === id)) this.finishedTurnAge.delete(id);
    }
    for (const id of this.observedActiveRunIds) {
      if (!runs.some((run) => run.id === id)) this.observedActiveRunIds.delete(id);
    }
  }
}
