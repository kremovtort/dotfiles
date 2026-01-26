# opencode global rules

These rules are injected globally for OpenCode sessions.

## VCS detection

- Before running any VCS command, determine the VCS in use.
- If the project rules do not explicitly state the VCS, load and follow the `vcs-detect` skill.
- Use the detected VCS (`jj` vs `git`) consistently for the rest of the task.

## Tooling recommendations

- Prefer semi-automatic code editing when it is sufficient:
  - Use `ast_grep_search` / `ast_grep_replace` for simple mechanical refactors.
  - For tasks like “create a new file as a copy of another file”, “move/rename file”, or “copy file”, prefer shell commands like `cp` and `mv` instead of manual edits.

- **Never discard unrelated changes** just because they look “extra”.
  - This includes any destructive commands in any VCS (e.g. `jj restore`, `git reset --hard`, `git checkout --`, force pushes, etc.).
  - If you accidentally mixed multiple concerns in one change, use `jj split` to separate them into multiple commits/changes.
  - If build/generated output (e.g. `flake.lock`) changes unexpectedly, keep it as a separate commit/change. The user decides whether to discard it and will do so themselves.
  - Only discard changes when the user explicitly asked you to do it.

## Subagent usage

### Why subagents matter (use them by default)

The parent agent is best at reasoning and integration. Subagents are best at doing mechanical I/O work (searching, running commands, reading docs, indexing diffs) quickly and without polluting the parent context.

Subagents solve 3 recurring problems:
- Speed: subagents run fast models and are tuned for one job, so they finish quicker than the parent doing the same tool loop.
- Context rot: pasting big diffs/logs/irrelevant code into the parent context degrades later reasoning quality and wastes tokens (https://research.trychroma.com/context-rot). Subagents return only the minimal evidence needed.
- Grounding: subagents are instructed to return raw evidence (file:line refs, verbatim quotes, raw error text) instead of paraphrases. Treat their outputs as trustworthy facts you can cite.

How each subagent helps:
- `runner`: runs builds/tests/lints, then triages logs and returns only PASS/FAIL + the actionable errors.
- `scout`: does multi-file codebase discovery and call-path tracing, then returns only the relevant `path:line` refs.
- `docs_digger`: does multi-source documentation research, then returns compact verbatim quotes with sources.
- `diff_indexer`: answers "what changed" with a compact file list + hunk anchors (no multi-page diffs).

Rule of thumb:
- If you are about to (a) run a build/test/lint, (b) do more than one round of repo discovery reads/searches, (c) look up external docs, or (d) inspect a large diff, STOP and delegate to the right subagent first.
- Only skip delegation when the task is truly trivial (one small tool call) and will not bloat the parent context.

### Examples (copy/paste JSON)

#### `@runner`

Situation: you need to run builds/tests/lints, or you have a long failing log and need only the actionable bits.

```json
{
  "cmd": "just switch",
  "limit": 5,
  "focus": "error|failed|trace"
}
```

```json
{
  "cmd": "nix flake check",
  "limit": 5,
  "focus": "error|fail|assert"
}
```

```json
{
  "cmd": "pytest -q",
  "limit": 5,
  "focus": "E   |FAILED|Traceback"
}
```

#### `@scout`

Situation: you need repo discovery ("where is X?"), indirect call-path tracing, or pinpointing the right file to edit.

```json
{
  "q": "where is the configuration for home-manager defined?",
  "mode": "search",
  "focus": "home-manager"
}
```

```json
{
  "q": "how does the main entry point call the function that applies the configuration?",
  "mode": "trace",
  "from": "entry point",
  "to": "apply",
  "focus": "switch|apply"
}
```

```json
{
  "q": "find all places that read an env var named FOO_BAR",
  "mode": "search",
  "focus": "FOO_BAR"
}
```

#### `@docs_digger`

Situation: you need authoritative docs for a CLI flag/API/config option, or to interpret an error via official documentation.

```json
{
  "q": "What does `git diff --unified=0` mean and what does it change in output?",
  "focus": "--unified",
  "limit": 6,
  "prefer": ["man", "web", "github"]
}
```

```json
{
  "q": "Find the official docs for nix-darwin `services.nix-daemon.enable` (or the closest equivalent) and quote the relevant section.",
  "focus": "nix-daemon",
  "limit": 8,
  "prefer": ["web", "github", "code"]
}
```

```json
{
  "q": "This error mentions `context rot`. Find the original article and quote the definition + recommended mitigations.",
  "focus": "context rot",
  "limit": 6,
  "prefer": ["web"]
}
```

#### `@diff_indexer`

Situation: you need "what changed?" without pasting full diffs (before commit/PR/review).

```json
{
  "scope": "worktree",
  "limit_files": 25,
  "limit_hunks": 50
}
```

```json
{
  "scope": "staged",
  "limit_files": 25,
  "limit_hunks": 50
}
```

```json
{
  "scope": "range",
  "base": "main",
  "head": "HEAD",
  "focus": "nvim|home-manager",
  "limit_files": 25,
  "limit_hunks": 50
}
```

- When invoking subagents, send a single **JSON object** (no prose) matching the contract below.
- Keep subagent prompts tiny; do not paste long context.
- When you need to point a subagent at local context, you can reference it inline using `@<file_path>[:<start_line>[:<end_line>]][::<identifier>]` (1-based lines).
  Examples: `@agents/opencode/_AGENTS.md`, `@agents/opencode/_AGENTS.md:44`, `@agents/opencode/_AGENTS.md:44:72`, `@agents/opencode/_AGENTS.md::<Subagent usage>`, `@agents/opencode/_AGENTS.md:23:80::<Subagent usage>`.

### `@scout` input (JSON)

```json
{
  "q": "what to find/trace",
  "mode": "search|trace",
  "focus": "optional keywords/paths",
  "from": "(trace only) optional start symbol",
  "to": "(trace only) optional target symbol"
}
```

### `@docs_digger` input (JSON)

```json
{
  "q": "the exact question/topic",
  "focus": "optional keywords/paths",
  "limit": 8,
  "prefer": ["man", "context7", "web", "github", "code", "api"],
  "skills": ["optional-skill-name"]
}
```

### `@diff_indexer` input (JSON)

```json
{
  "scope": "worktree|staged|unstaged|range",
  "base": "(scope=range) base rev",
  "head": "(scope=range) head rev",
  "focus": "optional keywords/paths",
  "limit_files": 25,
  "limit_hunks": 50
}
```

### `@runner` input (JSON)

```json
{
  "cmd": "the exact command(s) to run (one line, or multiple commands separated by &&)",
  "limit": 5,
  "focus": "optional keywords/paths"
}
```

## Context hygiene

- If the task needs codebase discovery ("where is X?", "who calls Y?", "find config for Z?"), delegate it to `@scout` immediately.
- In the parent agent, do at most **one** discovery tool call (`glob`/`grep`/`read`) before delegating to `@scout`.
- If the task needs external documentation research, delegate it to `@docs_digger`.
- If the task is "what changed" / diff structure / file list / hunk locations, delegate it to `@diff_indexer`.
- If the task is call-path tracing ("how does X call Y", indirect call chains, wrappers/middleware), delegate it to `@scout` and ask for a chain + `path:line` refs.
- If the task needs running builds/tests/lints (or interpreting their logs), delegate it to `@runner` immediately.
- In the parent agent, do not run long test/build commands or paste their logs; ask `@runner` for PASS/FAIL + raw errors with `path:line` refs.
