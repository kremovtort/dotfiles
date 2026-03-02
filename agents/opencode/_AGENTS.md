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

## **Never discard unrelated changes** just because they look “extra”.
- This includes any destructive commands in any VCS (e.g. `jj restore`, `git reset --hard`, `git checkout --`, force pushes, etc.).
- If you accidentally mixed multiple concerns in one change, use `jj split` to separate them into multiple commits/changes.
- If build/generated output (e.g. `flake.lock`) changes unexpectedly, keep it as a separate commit/change. The user decides whether to discard it and will do so themselves.
- Only discard changes when the user explicitly asked you to do it.

## Subagent usage (this section applies only to primary agents, i.e. @build and @plan)

### Why subagents matter (use them by default)

The parent agent is best at reasoning and integration. Subagents are best at doing mechanical I/O work (searching, running commands, reading docs, indexing diffs) quickly and without polluting the parent context.

Subagents solve 3 recurring problems:
- Speed: specialized agents run targeted workflows faster than the parent agent doing the same tool loop.
- Context rot: large diffs/logs/noisy outputs stay out of parent context (https://research.trychroma.com/context-rot).
- Grounding: outputs are optimized for evidence (raw errors, verbatim quotes, `path:line` refs).

### Delegation defaults

- Delegate mechanical I/O work by default: heavy search, command execution, external docs lookup, log triage.
- Parent agent owns interpretation and final decisions; subagents collect and compress evidence.
- Skip delegation only for truly trivial one-call tasks that do not risk context bloat.

### Invocation rules (all subagents)

- Send a single JSON object matching that subagent's input contract; no prose wrapper.
- Keep prompts tiny and task-focused; do not paste large context blobs.
- To pass local context, use inline refs: `@<file_path>[:<start_line>[:<end_line>]][::<identifier>]` (1-based).
  Examples: `@agents/opencode/_AGENTS.md`, `@agents/opencode/_AGENTS.md:23:60`, `@agents/opencode/_AGENTS.md::<Subagent usage>`.
- Subagents cannot invoke other subagents (`task` is unavailable in subagent context). Any further delegation must be done by the parent agent.

### Subagent roles and contracts

- `scout`:
  - Purpose: fast read-only codebase discovery and call-path tracing.
  - Delegate by default for repository navigation work: locating files/symbols/config entries, finding usages, mapping references, and tracing indirect flows (`X -> wrapper/layer -> Y`).
  - How it helps: faster targeted discovery, less context bloat from search I/O, and grounded evidence via precise `path:line` refs.
  - Input contract (single JSON object):
    ```json
    {
      "q": "what to find/trace",
      "mode": "search|trace",
      "focus": "optional keywords/paths",
      "from": "trace start (optional)",
      "to": "trace target (optional)"
    }
    ```
  - Context refs: `q`/`focus` may include inline refs (for example `@path:line` or `@path::identifier`) to narrow discovery without opening extra files.
  - Output contract: 2-6 concise sentences in the user's language with clickable refs like `path/to/file.ext:line`; for trace mode include a compact hop chain like `A -> B -> C` plus 2-5 refs.
  - Search style: minimal targeted reads/searches, prefer high-signal refs over exhaustive dumps.
  - Hard scope: discovery/indexing helper only. Do not use for full code review, final quality/security/performance verdicts, or autonomous bug-finding loops.
  - Parent ownership: interpretation, architecture decisions, and validation via `runner` when execution checks are needed.

- `runner`:
  - Purpose: build/test/lint execution and log triage to keep parent context clean.
  - Delegate by default whenever command output can be noisy: project builds/checks, test suites, linters, or long failure logs that need quick actionable extraction.
  - How it helps: faster execution triage, less context bloat from long logs, and grounded diagnostics with raw verbatim errors and resolved `path:line[:col]`.
  - Input contract (single JSON object):
    ```json
    {
      "cmd": "exact command",
      "cwd": "optional working directory",
      "limit": 5,
      "focus": "optional regex/keywords/paths"
    }
    ```
  - Output contract: one Markdown `toml` code block containing strict TOML with `result` (`PASS`/`FAIL`), included/omitted counters, and up to `limit` raw actionable diagnostics.
  - Diagnostic rules: MUST run `cmd` for real; never simulate. On failure include verbatim error text and resolved `path:line[:col]` when possible. On pass include warnings (up to `limit`) and aggregate the rest.
  - Selection rules: prioritize `focus` matches, earliest root-cause-like errors, and cross-file/module coverage; if errors exist do not emit full warnings (counts only).
  - Path handling: prefer repo-relative locations; attempt path resolution for toolchains that print non-repo-relative paths.
  - Not for final product decisions: parent agent owns interpretation, fixes, and user-facing conclusions.

- `docs-digger`:
  - Purpose: documentation research for authoritative, quotable evidence with minimal context bloat.
  - Delegate when parent needs source-backed facts: CLI flag semantics, API behavior, config options, standards/spec details, or error interpretation from official docs.
  - How it helps: faster source lookup, less context bloat from broad web/doc exploration, and grounded answers via short verbatim quotes with explicit sources.
  - Input contract (single JSON object):
    ```json
    {
      "q": "exact research question",
      "focus": "optional keywords/paths",
      "limit": 8,
      "prefer": ["man", "context7", "web", "github", "code", "api"],
      "skills": ["optional-skill-name"]
    }
    ```
  - Context refs: can consume inline refs in `q`/`focus` like `@path:line` for targeted local grounding.
  - Research order: official and primary sources first (man pages, Context7, vendor/framework docs, specs), then authoritative web pages (quoted via fetch), then GitHub/community examples as supporting material.
  - Output contract: Markdown citations pack, not a full end-user solution. Each quote must be verbatim, short, and paired with mandatory `Source:` metadata (URL, man command, repo/path, or local `path:line`).
  - Quality rules: no paraphrasing inside quote blocks, clearly label non-official/community evidence, and avoid dumping large pages.
  - Not for codebase tracing or command execution triage; those belong to `scout` and `runner`.

- `codemodder`:
  - Purpose: deterministic mechanical edits for large repetitive refactors.
  - Delegate for broad but simple code transformations that follow explicit rules.
  - How it helps: faster repetitive refactors, less context bloat from large edit loops, and grounded edit evidence via deterministic machine-readable results.
  - Input contract (single JSON object):
    ```json
    {
      "goal": "what to transform",
      "mode": "plan|apply",
      "include": ["glob"],
      "exclude": ["glob"],
      "edits": [
        {
          "id": "rule-id",
          "kind": "ast_replace|regex_replace|literal_replace",
          "lang": "optional",
          "pattern": "match",
          "rewrite": "replacement"
        }
      ],
      "safety": {
        "max_files": 200,
        "max_edits_per_file": 50,
        "allow_new_files": false,
        "allow_delete_files": false,
        "stop_on_ambiguous": true
      },
      "focus": "optional keywords/paths"
    }
    ```
  - Output contract: single machine-readable JSON object with status, counts, changed paths, skipped items, manual follow-ups, and idempotency remainder.
  - Hard scope: mechanical edits only. No architecture decisions, no tests/builds, no VCS operations.

### Summary

- If the task needs codebase discovery ("where is X?", "who calls Y?", "find config for Z?"), delegate to `@scout` immediately.
- In the parent agent, do at most **one** discovery tool call (`glob`/`grep`/`read`) before delegating to `@scout`.
- If the task needs external documentation research, delegate to `@docs-digger`.
- If the task needs build/test/lint execution or long log interpretation, delegate to `@runner`.
- If the task is a repetitive large mechanical refactor (rename, import-path migration, structural replacement), delegate to `@codemodder`.
- For full review/bug-finding, `@scout` is only evidence gathering; parent does analysis and uses `@runner` for validation.
- Subagents cannot call other subagents; only the parent agent can perform further delegation.
