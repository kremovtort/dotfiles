import { spawn, which } from "bun";
import { tool } from "@opencode-ai/plugin";

/**
 * AST-grep tools for OpenCode.
 *
 * Uses the `ast-grep` CLI (https://ast-grep.github.io/).
 * For patterns, metavariables, and best practices see the bundled `ast-grep` skill.
 */

/**
 * Check if ast-grep CLI is available on the system.
 * Returns installation instructions if not found.
 */
async function checkAstGrepAvailable(): Promise<{ available: boolean; message?: string }> {
  const astGrepPath = which("ast-grep");
  if (astGrepPath) return { available: true };

  return {
    available: false,
    message:
      "ast-grep CLI (ast-grep) not found. AST-aware search/replace will not work.\n" +
      "Install with one of:\n" +
      "  npm install -g @ast-grep/cli\n" +
      "  cargo install ast-grep --locked\n" +
      "  brew install ast-grep",
  };
}

const LANGUAGES = [
  "c",
  "cpp",
  "csharp",
  "css",
  "dart",
  "elixir",
  "go",
  "haskell",
  "html",
  "java",
  "javascript",
  "json",
  "kotlin",
  "lua",
  "php",
  "python",
  "ruby",
  "rust",
  "scala",
  "sql",
  "swift",
  "tsx",
  "typescript",
  "yaml",
] as const;

interface Match {
  file: string;
  range: { start: { line: number; column: number }; end: { line: number; column: number } };
  text: string;
  replacement?: string;
}

async function runAstGrep(args: string[]): Promise<{ matches: Match[]; error?: string }> {
  const availability = await checkAstGrepAvailable();
  if (!availability.available) {
    return { matches: [], error: availability.message };
  }

  try {
    const proc = spawn(["ast-grep", ...args], {
      stdout: "pipe",
      stderr: "pipe",
    });

    const [stdout, stderr, exitCode] = await Promise.all([
      new Response(proc.stdout).text(),
      new Response(proc.stderr).text(),
      proc.exited,
    ]);

    if (exitCode !== 0 && !stdout.trim()) {
      if (stderr.includes("No files found")) return { matches: [] };
      return { matches: [], error: stderr.trim() || `Exit code ${exitCode}` };
    }

    if (!stdout.trim()) return { matches: [] };

    try {
      const matches = JSON.parse(stdout) as Match[];
      return { matches };
    } catch {
      return { matches: [], error: "Failed to parse output" };
    }
  } catch (e) {
    const err = e as Error;
    return { matches: [], error: err.message };
  }
}

function formatMatches(matches: Match[], isDryRun = false): string {
  if (matches.length === 0) return "No matches found";

  const MAX = 100;
  const truncated = matches.length > MAX;
  const shown = matches.slice(0, MAX);

  const lines = shown.map((m) => {
    const loc = `${m.file}:${m.range.start.line}:${m.range.start.column}`;
    const text = m.text.length > 100 ? `${m.text.slice(0, 100)}...` : m.text;

    if (isDryRun && m.replacement) {
      return `${loc}\n  - ${text}\n  + ${m.replacement}`;
    }

    return `${loc}: ${text}`;
  });

  if (truncated) {
    lines.unshift(`Found ${matches.length} matches (showing first ${MAX}):`);
  }

  return lines.join("\n");
}

export const ast_grep_search = tool({
  description:
    "AST-aware search using ast-grep (CLI: ast-grep). " +
    "Use meta-variables: $VAR (single node), $$$ (multiple nodes). " +
    "For more info: see the `ast-grep` skill.",
  args: {
    pattern: tool.schema.string().describe("AST pattern with meta-variables"),
    lang: tool.schema.enum(LANGUAGES).describe("Target language"),
    paths: tool.schema.array(tool.schema.string()).optional().describe("Paths to search (default: .)"),
  },
  execute: async (args) => {
    const sgArgs = ["run", "-p", args.pattern, "--lang", args.lang, "--json=compact"];

    if (args.paths?.length) {
      sgArgs.push(...args.paths);
    } else {
      sgArgs.push(".");
    }

    const result = await runAstGrep(sgArgs);
    if (result.error) return `Error: ${result.error}`;
    return formatMatches(result.matches);
  },
});

export const ast_grep_replace = tool({
  description:
    "AST-aware replace using ast-grep (CLI: ast-grep). " +
    "Dry-run by default (apply=false). " +
    "For patterns and examples: see the `ast-grep` skill.",
  args: {
    pattern: tool.schema.string().describe("AST pattern to match"),
    rewrite: tool.schema.string().describe("Replacement pattern"),
    lang: tool.schema.enum(LANGUAGES).describe("Target language"),
    paths: tool.schema.array(tool.schema.string()).optional().describe("Paths to search (default: .)"),
    apply: tool.schema.boolean().optional().describe("Apply changes (default: false, dry-run)"),
  },
  execute: async (args) => {
    const sgArgs = [
      "run",
      "-p",
      args.pattern,
      "-r",
      args.rewrite,
      "--lang",
      args.lang,
      "--json=compact",
    ];

    if (args.apply) {
      sgArgs.push("--update-all");
    }

    if (args.paths?.length) {
      sgArgs.push(...args.paths);
    } else {
      sgArgs.push(".");
    }

    const result = await runAstGrep(sgArgs);
    if (result.error) return `Error: ${result.error}`;

    const isDryRun = !args.apply;
    const output = formatMatches(result.matches, isDryRun);

    if (isDryRun && result.matches.length > 0) {
      return `${output}\n\n(Dry run - use apply=true to apply changes)`;
    }

    if (args.apply && result.matches.length > 0) {
      return `Applied ${result.matches.length} replacements:\n${output}`;
    }

    return output;
  },
});
