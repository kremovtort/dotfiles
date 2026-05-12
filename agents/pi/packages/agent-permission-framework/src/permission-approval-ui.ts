import {
  createPermissionDisplay,
  formatPermissionMetadata,
  padVisible,
  truncateVisible,
} from "./permission-display.ts";
import type { AgentIdentity, PermissionApprovalResult, PermissionDecision } from "./types.ts";

export type HighlightCodeFn = (code: string, lang?: string) => string[];

type ThemeLike = {
  fg?: (color: string, text: string) => string;
  bold?: (text: string) => string;
};

type KeybindingsLike = {
  matches?: (data: string, keybinding: string) => boolean;
  getKeys?: (keybinding: string) => string[];
};

export interface PermissionApprovalComponentOptions {
  identity: AgentIdentity;
  decision: PermissionDecision;
  theme?: ThemeLike;
  keybindings?: KeybindingsLike;
  highlightCode?: HighlightCodeFn;
  getRows?: () => number;
  onDone: (result: PermissionApprovalResult) => void;
}

interface Choice {
  label: string;
  result: PermissionApprovalResult;
}

const CHOICES: Choice[] = [
  { label: "Deny", result: { outcome: "denied", reason: "Permission denied by user" } },
  { label: "Allow once", result: { outcome: "approved", scope: "once" } },
  { label: "Allow session", result: { outcome: "approved", scope: "session" } },
];

const WIDE_MIN_WIDTH = 96;
const WIDE_DECISION_WIDTH = 24;
const WIDE_SEPARATOR_WIDTH = 3;
const COMPACT_PREVIEW_ROWS = 12;
const MIN_COMPONENT_ROWS = 11;

function color(theme: ThemeLike | undefined, name: string, text: string): string {
  return theme?.fg?.(name, text) ?? text;
}

function bold(theme: ThemeLike | undefined, text: string): string {
  return theme?.bold?.(text) ?? text;
}

function normalizeKeyText(value: string | undefined, fallback: string): string {
  const raw = value ?? fallback;
  return raw
    .replace(/^ctrl\+/i, "Ctrl+")
    .replace(/^shift\+/i, "Shift+")
    .replace(/^alt\+/i, "Alt+")
    .replace(/\+([a-z])$/i, (_m, ch: string) => `+${ch.toUpperCase()}`);
}

function keyText(keybindings: KeybindingsLike | undefined, binding: string, fallback: string): string {
  try {
    return normalizeKeyText(keybindings?.getKeys?.(binding)?.[0], fallback);
  } catch {
    return fallback;
  }
}

function matchesBinding(keybindings: KeybindingsLike | undefined, data: string, binding: string): boolean {
  try {
    return keybindings?.matches?.(data, binding) === true;
  } catch {
    return false;
  }
}

function isUp(data: string, keybindings?: KeybindingsLike): boolean {
  return matchesBinding(keybindings, data, "tui.select.up") || data === "\x1b[A";
}

function isDown(data: string, keybindings?: KeybindingsLike): boolean {
  return matchesBinding(keybindings, data, "tui.select.down") || data === "\x1b[B";
}

function isConfirm(data: string, keybindings?: KeybindingsLike): boolean {
  return matchesBinding(keybindings, data, "tui.select.confirm") || data === "\r" || data === "\n";
}

function isCancel(data: string, keybindings?: KeybindingsLike): boolean {
  return matchesBinding(keybindings, data, "tui.select.cancel") ||
    matchesBinding(keybindings, data, "app.interrupt") ||
    data === "\x1b" ||
    data === "\x03";
}

function isPageUp(data: string): boolean {
  return data === "\x1b[5~";
}

function isPageDown(data: string): boolean {
  return data === "\x1b[6~";
}

function isExpand(data: string, keybindings?: KeybindingsLike): boolean {
  return matchesBinding(keybindings, data, "app.tools.expand") || data === "\x0f";
}

function splitLines(value: string): string[] {
  return value.length ? value.split("\n") : [""];
}

function compactWhitespace(value: string): string {
  return value.replace(/\s+/g, " ").trim();
}

export class PermissionApprovalComponent {
  private readonly identity: AgentIdentity;
  private readonly decision: PermissionDecision;
  private readonly theme?: ThemeLike;
  private readonly keybindings?: KeybindingsLike;
  private readonly highlightCode?: HighlightCodeFn;
  private readonly getRows: () => number;
  private readonly onDone: (result: PermissionApprovalResult) => void;
  private readonly display;
  private selected = 0;
  private scroll = 0;
  private expanded = false;
  private lastPreviewRows = 1;
  private cachedHighlightKey: string | undefined;
  private cachedHighlightedLines: string[] | undefined;

  constructor(options: PermissionApprovalComponentOptions) {
    this.identity = options.identity;
    this.decision = options.decision;
    this.theme = options.theme;
    this.keybindings = options.keybindings;
    this.highlightCode = options.highlightCode;
    this.getRows = options.getRows ?? (() => 24);
    this.onDone = options.onDone;
    this.display = createPermissionDisplay(options.decision.fingerprint);
  }

  handleInput(data: string): void {
    if (isUp(data, this.keybindings)) {
      this.selected = Math.max(0, this.selected - 1);
      return;
    }
    if (isDown(data, this.keybindings)) {
      this.selected = Math.min(CHOICES.length - 1, this.selected + 1);
      return;
    }
    if (this.usesCodePreview() && (data === "u" || isPageUp(data))) {
      const delta = isPageUp(data) ? this.lastPreviewRows : 1;
      this.scroll = Math.max(0, this.scroll - delta);
      return;
    }
    if (this.usesCodePreview() && (data === "d" || isPageDown(data))) {
      const delta = isPageDown(data) ? this.lastPreviewRows : 1;
      this.scroll = Math.min(this.maxScroll(), this.scroll + delta);
      return;
    }
    if (this.usesCodePreview() && isExpand(data, this.keybindings)) {
      this.expanded = !this.expanded;
      this.scroll = Math.min(this.scroll, this.maxScroll());
      return;
    }
    if (isConfirm(data, this.keybindings)) {
      this.onDone(CHOICES[this.selected]?.result ?? CHOICES[0]!.result);
      return;
    }
    if (isCancel(data, this.keybindings)) {
      this.onDone(CHOICES[0]!.result);
    }
  }

  invalidate(): void {
    this.cachedHighlightKey = undefined;
    this.cachedHighlightedLines = undefined;
  }

  render(width: number): string[] {
    const safeWidth = Math.max(1, width);
    const wide = safeWidth >= WIDE_MIN_WIDTH;
    return wide ? this.renderWide(safeWidth) : this.renderStacked(safeWidth);
  }

  private maxRows(): number {
    return Math.max(MIN_COMPONENT_ROWS, this.getRows() - 2);
  }

  private separator(width: number): string {
    return color(this.theme, "borderMuted", "─".repeat(Math.max(1, width)));
  }

  private splitSeparator(width: number, leftWidth: number, junction: "┬" | "┴"): string {
    const left = "─".repeat(Math.max(1, leftWidth + 1));
    const right = "─".repeat(Math.max(1, width - leftWidth - 2));
    return color(this.theme, "borderMuted", truncateVisible(`${left}${junction}${right}`, width, ""));
  }

  private heading(width: number): string {
    return truncateVisible(color(this.theme, "accent", bold(this.theme, "Permission required")), width);
  }

  private metadata(width: number): string {
    return color(this.theme, "muted", formatPermissionMetadata(this.identity, this.decision, { width }));
  }

  private toolName(): string | undefined {
    if (this.display.parsed.category !== "tool" || this.display.parsed.operation !== "call") return undefined;
    const target = this.display.parsed.target;
    const separator = target.indexOf(":");
    return separator >= 0 ? target.slice(0, separator) : target;
  }

  private usesCodePreview(): boolean {
    if (this.display.parsed.category === "bash") return true;
    return this.display.parsed.category === "tool" && this.toolName() === "bash";
  }

  private compactLines(width: number): string[] {
    const target = compactWhitespace(this.display.sourceText || this.display.parsed.target || this.display.summary);
    const lines = [
      `Request: ${this.display.actionLabel}`,
      `Target: ${target || this.display.summary}`,
    ];
    return lines.map((line) => color(this.theme, "muted", truncateVisible(line, width)));
  }

  private highlightedLines(): string[] {
    const key = `${this.display.language ?? ""}\0${this.display.sourceText}`;
    if (this.cachedHighlightKey === key && this.cachedHighlightedLines) return this.cachedHighlightedLines;

    try {
      const highlighted = this.highlightCode?.(this.display.sourceText, this.display.language);
      this.cachedHighlightedLines = highlighted?.length ? highlighted : splitLines(this.display.sourceText);
    } catch {
      this.cachedHighlightedLines = splitLines(this.display.sourceText);
    }
    this.cachedHighlightKey = key;
    return this.cachedHighlightedLines;
  }

  private maxScroll(): number {
    return Math.max(0, this.highlightedLines().length - this.lastPreviewRows);
  }

  private previewRowsFor(availableRows: number): number {
    const bounded = Math.max(1, availableRows);
    return this.expanded ? bounded : Math.max(1, Math.min(COMPACT_PREVIEW_ROWS, bounded));
  }

  private previewLines(width: number, rows: number): string[] {
    this.lastPreviewRows = Math.max(1, rows);
    const lines = this.highlightedLines();
    this.scroll = Math.min(this.scroll, this.maxScroll());

    const visible = lines
      .slice(this.scroll, this.scroll + this.lastPreviewRows)
      .map((line) => truncateVisible(line, width));

    while (visible.length < this.lastPreviewRows) visible.push("");
    return visible;
  }

  private previewHelp(width: number): string {
    const total = this.highlightedLines().length;
    const start = total === 0 ? 0 : this.scroll + 1;
    const end = Math.min(total, this.scroll + this.lastPreviewRows);
    const expandKey = keyText(this.keybindings, "app.tools.expand", "Ctrl+O");
    const mode = this.expanded ? "collapse" : "expand";
    const help = `${start}–${end} / ${total} · u/d scroll · ${expandKey} ${mode}`;
    return color(this.theme, "muted", truncateVisible(help, width));
  }

  private choiceLines(width: number): string[] {
    return CHOICES.map((choice, index) => {
      const prefix = index === this.selected ? "❯ " : "  ";
      const raw = truncateVisible(`${prefix}${choice.label}`, width);
      if (index === this.selected) return color(this.theme, choice.label === "Deny" ? "warning" : "accent", raw);
      return raw;
    });
  }

  private renderStacked(width: number): string[] {
    const header = [
      this.separator(width),
      this.heading(width),
      "",
      this.metadata(width),
      this.separator(width),
    ];
    const decisionLines = this.choiceLines(width);
    if (!this.usesCodePreview()) {
      return [
        ...header,
        ...this.compactLines(width),
        this.separator(width),
        ...decisionLines,
        this.separator(width),
      ].map((line) => truncateVisible(line, width, ""));
    }

    const availablePreviewRows = this.maxRows() - header.length - 1 - 1 - decisionLines.length;
    const previewRows = this.previewRowsFor(availablePreviewRows);
    return [
      ...header,
      ...this.previewLines(width, previewRows),
      this.separator(width),
      ...decisionLines,
      this.separator(width),
      this.previewHelp(width),
    ].map((line) => truncateVisible(line, width, ""));
  }

  private renderWide(width: number): string[] {
    const leftWidth = Math.min(WIDE_DECISION_WIDTH, Math.max(18, Math.floor(width * 0.28)));
    const rightWidth = Math.max(1, width - leftWidth - WIDE_SEPARATOR_WIDTH);
    const header = [
      this.separator(width),
      this.heading(width),
      "",
      this.metadata(width),
      this.splitSeparator(width, leftWidth, "┬"),
    ];
    const availableBodyRows = Math.max(1, this.maxRows() - header.length - 2);
    const bodyRows = this.expanded ? availableBodyRows : Math.min(COMPACT_PREVIEW_ROWS, availableBodyRows);
    const previewRows = Math.max(1, bodyRows);
    const left = this.choiceLines(leftWidth);
    const right = this.usesCodePreview()
      ? this.previewLines(rightWidth, previewRows)
      : this.compactLines(rightWidth);
    const rows = Math.max(left.length, right.length);
    const verticalSeparator = color(this.theme, "borderMuted", "│");
    const body: string[] = [];

    for (let i = 0; i < rows; i++) {
      const leftLine = padVisible(truncateVisible(left[i] ?? "", leftWidth, ""), leftWidth);
      const rightLine = truncateVisible(right[i] ?? "", rightWidth, "");
      body.push(truncateVisible(`${leftLine} ${verticalSeparator} ${rightLine}`, width, ""));
    }

    const footer = [this.splitSeparator(width, leftWidth, "┴")];
    if (this.usesCodePreview()) footer.push(this.previewHelp(width));
    return [...header, ...body, ...footer];
  }
}
