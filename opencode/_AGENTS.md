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

## Jujutsu workflow

When the detected VCS is **Jujutsu** (`jj`), follow this workflow:

0. **Sanity-check repo state**
   - Run `jj status` before making the first change.

1. **Create a bookmark before starting work**
   - If the working copy commit (`@`) is **empty** and has **no description**, create the bookmark on the parent:
     - `jj bookmark create <task>/before -r @-`
   - Otherwise, create the bookmark on the current revision:
     - `jj bookmark create <task>/before -r @`

2. **Commit as you go**
   - Prefer `jj describe -m "..."` for the **first** change if `@` is empty/unnamed (avoid introducing an empty commit in the middle of history).
   - Commit changes as needed with documentative messages that explain *what* and *why*.
   - It is especially important to create a commit **before any destructive/irreversible operation**.

3. **Create a bookmark when done**
   - After completing the task, create a bookmark named `<task>/done` pointing at the final revision.

### Naming rules

- If the task comes from OpenSpec:
  - Use `<task>` = the OpenSpec `change` name.
  - If the current session implements only part of a `change`, then use:
    - `<change>/<task>/(before|done)`
    - The agent may choose a short, descriptive `<task>` name.
- Otherwise: agent is free to choose a short, descriptive name for `<task>` name.
