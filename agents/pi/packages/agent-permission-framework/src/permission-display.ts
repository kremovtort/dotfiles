import { createHash } from "node:crypto";
import type { ActionFingerprint, AgentIdentity, PermissionDecision } from "./types.ts";

const ANSI_PATTERN = /\x1b\[[0-9;?]*[ -/]*[@-~]|\x1b\][^\x07]*(?:\x07|\x1b\\)|\x1b[PX^_][\s\S]*?\x1b\\/g;
const DEFAULT_SUMMARY_WIDTH = 96;
const DEFAULT_PREVIEW_LINE_LIMIT = 20;

export interface ParsedAction {
  category: string;
  operation: string;
  target: string;
}

export interface PermissionDisplay {
  normalized: string;
  parsed: ParsedAction;
  sha256: string;
  shortHash: string;
  sourceText: string;
  sourceLines: string[];
  lineCount: number;
  language?: string;
  actionLabel: string;
  summary: string;
  previewText: string;
  truncatedPreview: boolean;
}

export interface PermissionDisplayOptions {
  summaryWidth?: number;
  previewLineLimit?: number;
}

export function stripAnsi(value: string): string {
  return value.replace(ANSI_PATTERN, "");
}

export function visibleWidth(value: string): number {
  return Array.from(stripAnsi(value)).length;
}

export function truncateVisible(value: string, width: number, ellipsis = "…"): string {
  if (width <= 0) return "";
  if (visibleWidth(value) <= width) return value;
  const suffix = width > visibleWidth(ellipsis) ? ellipsis : "";
  const limit = Math.max(0, width - visibleWidth(suffix));
  let output = "";
  let used = 0;

  for (let i = 0; i < value.length;) {
    const rest = value.slice(i);
    const ansi = rest.match(/^(?:\x1b\[[0-9;?]*[ -/]*[@-~]|\x1b\][^\x07]*(?:\x07|\x1b\\)|\x1b[PX^_][\s\S]*?\x1b\\)/);
    if (ansi?.[0]) {
      output += ansi[0];
      i += ansi[0].length;
      continue;
    }

    const codePoint = value.codePointAt(i);
    if (codePoint == null) break;
    const char = String.fromCodePoint(codePoint);
    if (used + 1 > limit) break;
    output += char;
    used += 1;
    i += char.length;
  }

  return output + suffix;
}

export function padVisible(value: string, width: number): string {
  return value + " ".repeat(Math.max(0, width - visibleWidth(value)));
}

export function parseNormalizedAction(value: string): ParsedAction {
  const first = value.indexOf(":");
  const second = first >= 0 ? value.indexOf(":", first + 1) : -1;
  if (first < 0 || second < 0) return { category: "action", operation: "request", target: value };
  return {
    category: value.slice(0, first),
    operation: value.slice(first + 1, second),
    target: value.slice(second + 1),
  };
}

function stripToolPrefix(parsed: ParsedAction): { sourceText: string; actionLabel: string; language?: string } {
  if (parsed.category === "bash") {
    return { sourceText: parsed.target, actionLabel: "bash exec", language: "bash" };
  }

  if (parsed.category === "tool" && parsed.operation === "call") {
    const toolSeparator = parsed.target.indexOf(":");
    const toolName = toolSeparator >= 0 ? parsed.target.slice(0, toolSeparator) : parsed.target;
    const toolTarget = toolSeparator >= 0 ? parsed.target.slice(toolSeparator + 1) : parsed.target;
    if (toolName === "bash") return { sourceText: toolTarget, actionLabel: "bash exec", language: "bash" };
    return { sourceText: toolTarget, actionLabel: `tool ${toolName || "call"}` };
  }

  return { sourceText: parsed.target || `${parsed.category}:${parsed.operation}`, actionLabel: `${parsed.category} ${parsed.operation}` };
}

function detectHeredocLanguage(sourceText: string): string | undefined {
  const firstLine = sourceText.split(/\r\n|\r|\n/, 1)[0] ?? "";
  const heredoc = firstLine.match(/\b(?<cmd>python3?|node|deno|bun|ruby|perl|php|lua|sh|bash|zsh)\b[^\n]*<<-?\s*['\"]?(?<tag>[A-Za-z0-9_./-]+)['\"]?/i);
  const cmd = heredoc?.groups?.cmd?.toLowerCase();
  if (!cmd) return undefined;
  if (cmd === "python" || cmd === "python3") return "python";
  if (cmd === "node" || cmd === "deno" || cmd === "bun") return "javascript";
  if (cmd === "sh" || cmd === "bash" || cmd === "zsh") return "bash";
  return cmd;
}

function detectLanguage(parsed: ParsedAction, sourceText: string, fallback?: string): string | undefined {
  const heredocLanguage = detectHeredocLanguage(sourceText);
  if (heredocLanguage) return heredocLanguage;
  const trimmed = sourceText.trimStart();
  if (trimmed.startsWith("{") || trimmed.startsWith("[")) return "json";
  if (parsed.category === "bash" || fallback === "bash") return "bash";
  return fallback;
}

function oneLine(value: string): string {
  return value.replace(/\s+/g, " ").trim();
}

export function createPermissionDisplay(
  fingerprint: ActionFingerprint | string,
  options: PermissionDisplayOptions = {},
): PermissionDisplay {
  const normalized = typeof fingerprint === "string" ? fingerprint : fingerprint.normalized;
  const parsed = parseNormalizedAction(normalized);
  const sha256 = createHash("sha256").update(normalized).digest("hex");
  const { sourceText, actionLabel, language: fallbackLanguage } = stripToolPrefix(parsed);
  const sourceLines = sourceText.split(/\r\n|\r|\n/);
  const lineLimit = Math.max(1, options.previewLineLimit ?? DEFAULT_PREVIEW_LINE_LIMIT);
  const previewLines = sourceLines.slice(0, lineLimit);
  const previewText = previewLines.join("\n");
  const language = detectLanguage(parsed, sourceText, fallbackLanguage);
  const firstLine = oneLine(sourceLines[0] ?? sourceText);
  const summaryWidth = Math.max(20, options.summaryWidth ?? DEFAULT_SUMMARY_WIDTH);
  const summary = truncateVisible(`${actionLabel}: ${firstLine || normalized}`, summaryWidth);

  return {
    normalized,
    parsed,
    sha256,
    shortHash: sha256.slice(0, 8),
    sourceText,
    sourceLines,
    lineCount: sourceLines.length,
    language,
    actionLabel,
    summary,
    previewText,
    truncatedPreview: sourceLines.length > previewLines.length,
  };
}

export function formatPermissionMetadata(
  identity: Pick<AgentIdentity, "agentName" | "kind">,
  decision: PermissionDecision,
  options: { width?: number } = {},
): string {
  const display = createPermissionDisplay(decision.fingerprint);
  const pieces = [
    `Agent: ${identity.agentName} (${identity.kind})`,
    decision.matchedRule ? `Rule: ${decision.matchedRule}` : undefined,
    `sha256:${display.shortHash}`,
    display.actionLabel,
    `${display.lineCount} line${display.lineCount === 1 ? "" : "s"}`,
  ].filter((piece): piece is string => Boolean(piece));
  const line = pieces.join(" · ");
  return options.width ? truncateVisible(line, options.width) : line;
}

export function formatApprovalFallbackMessage(
  identity: Pick<AgentIdentity, "agentName" | "kind">,
  decision: PermissionDecision,
  options: { previewLines?: number; width?: number } = {},
): string {
  const display = createPermissionDisplay(decision.fingerprint, { previewLineLimit: options.previewLines ?? 12 });
  const width = options.width ?? 120;
  const preview = display.previewText
    .split("\n")
    .map((line) => truncateVisible(line, width))
    .join("\n");
  const hidden = display.truncatedPreview ? `\n… ${display.lineCount - display.previewText.split("\n").length} more line(s) hidden` : "";

  return [
    "Permission required",
    "",
    formatPermissionMetadata(identity, decision, { width }),
    `Action: ${display.summary}`,
    `Reason: ${decision.reason}`,
    decision.matchedRule ? `Rule: ${decision.matchedRule}` : undefined,
    "",
    "Preview:",
    preview + hidden,
  ].filter((line) => line !== undefined).join("\n");
}

export function formatAuditActionSummary(fingerprint: ActionFingerprint, width = 120): string {
  const display = createPermissionDisplay(fingerprint, { summaryWidth: Math.max(20, width - 24) });
  return truncateVisible(`${display.summary} · sha256:${display.shortHash}`, width);
}
