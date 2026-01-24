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

- Prefer built-in discovery tools:
  - Use `docs_search` (Context7 MCP) to look up library/framework documentation.
  - Use `grep_app` MCP to search for real-world code examples on GitHub.

- **Never discard unrelated changes** just because they look “extra”.
  - This includes any destructive commands in any VCS (e.g. `jj restore`, `git reset --hard`, `git checkout --`, force pushes, etc.).
  - If you accidentally mixed multiple concerns in one change, use `jj split` to separate them into multiple commits/changes.
  - If build/generated output (e.g. `flake.lock`) changes unexpectedly, keep it as a separate commit/change. The user decides whether to discard it and will do so themselves.
  - Only discard changes when the user explicitly asked you to do it.

## Subagent usage

- When invoking `@scout`, keep the prompt tiny: 1-2 sentences + 2-5 keywords (symbols, filenames, error string). Do not paste long context.
- When invoking `@docs_digger`, pass `q=` + optional `focus=` + optional `limit=` + optional `prefer=` + optional `skills=`. Ask for quotes + sources; do not paste long context.
- When invoking `@diff_indexer`, pass only `scope=` + optional `base/head` + optional `focus=` + `limit_files/limit_hunks`. Do not paste diffs.
- When invoking `@runner`, pass only the command + `limit=` + optional `focus=`. Do not paste full logs into the parent session.

## Context hygiene

- If the task needs codebase discovery ("where is X?", "who calls Y?", "find config for Z?"), delegate it to `@scout` immediately.
- In the parent agent, do at most **one** discovery tool call (`glob`/`grep`/`read`) before delegating to `@scout`.
- If the task needs external documentation research and you want sources/quotes ("what do the docs say", "find the exact option/spec", "cite docs"), delegate it to `@docs_digger`.
- If the task is "what changed" / diff structure / file list / hunk locations, delegate it to `@diff_indexer`.
- If the task is call-path tracing ("how does X call Y", indirect call chains, wrappers/middleware), delegate it to `@scout` and ask for a chain + `path:line` refs.
- If the task needs running builds/tests/lints (or interpreting their logs), delegate it to `@runner` immediately.
- In the parent agent, do not run long test/build commands or paste their logs; ask `@runner` for PASS/FAIL + raw errors with `path:line` refs.
