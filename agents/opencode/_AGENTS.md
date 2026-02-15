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
- Speed: specialized agents run targeted workflows faster than the parent agent doing the same tool loop.
- Context rot: large diffs/logs/noisy outputs stay out of parent context (https://research.trychroma.com/context-rot).
- Grounding: outputs are optimized for evidence (raw errors, verbatim quotes, `path:line` refs).

### Delegation defaults

- Delegate mechanical I/O work by default: heavy search, command execution, external docs lookup, log triage.
- Parent agent owns interpretation and final decisions; subagents collect and compress evidence.
- Skip delegation only for truly trivial one-call tasks that do not risk context bloat.

### Subagent roles (detailed contracts live in agent files)

- `runner`: command execution + build/test/lint log triage. See `agents/opencode/agents/runner.md`.
- `scout`: read-only codebase discovery + call-path tracing. See `agents/opencode/agents/scout.md`.
- `docs-digger`: source-backed documentation research with verbatim quotes. See `agents/opencode/agents/docs-digger.md`.
- `codemodder`: deterministic mechanical multi-file edits with `plan|apply` workflow and safety guardrails. See `agents/opencode/agents/codemodder.md`.

### Invocation rules (all subagents)

- Send a single JSON object matching that subagent's input contract; no prose wrapper.
- Keep prompts tiny and task-focused; do not paste large context blobs.
- To pass local context, use inline refs: `@<file_path>[:<start_line>[:<end_line>]][::<identifier>]` (1-based).
  Examples: `@agents/opencode/_AGENTS.md`, `@agents/opencode/_AGENTS.md:23:60`, `@agents/opencode/_AGENTS.md::<Subagent usage>`.

## Context hygiene

- If the task needs codebase discovery ("where is X?", "who calls Y?", "find config for Z?"), delegate to `@scout` immediately.
- In the parent agent, do at most **one** discovery tool call (`glob`/`grep`/`read`) before delegating to `@scout`.
- If the task needs external documentation research, delegate to `@docs-digger`.
- If the task needs build/test/lint execution or long log interpretation, delegate to `@runner`.
- If the task is a repetitive large mechanical refactor (rename, import-path migration, structural replacement), delegate to `@codemodder`.
- For full review/bug-finding, `@scout` is only evidence gathering; parent does analysis and uses `@runner` for validation.
