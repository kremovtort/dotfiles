## Context

Tabterm currently registers each action as a separate Neovim user command in `nvim/plugins/tabterm/plugin/tabterm.lua`: `TabtermToggle`, `TabtermOpen`, `TabtermClose`, `TabtermNewShell`, `TabtermNewCommand`, `TabtermStart`, `TabtermRename`, `TabtermDelete`, `TabtermNext`, and `TabtermPrev`.

The desired command surface is a single `:Tabterm` entry point with lowercase subcommands. This keeps command discovery centered on one command while preserving the existing action behavior behind each subcommand.

## Goals / Non-Goals

**Goals:**

- Replace the current top-level `Tabterm*` user commands with one `Tabterm` user command.
- Dispatch `:Tabterm <subcommand>` to the same Lua functions used by the old commands.
- Map creation commands explicitly: `TabtermNewCommand` to `:Tabterm command`, and `TabtermNewShell` to `:Tabterm shell`.
- Preserve the optional command argument behavior from `TabtermNewCommand` for `:Tabterm command [cmd]`.
- Provide subcommand completion for the supported action names.

**Non-Goals:**

- Do not keep aliases for the old `Tabterm*` commands.
- Do not change tab-scoped workspace behavior, terminal lifecycle behavior, sidebar rendering, or shell integration.
- Do not introduce a new command parser dependency.

## Decisions

- Use a single `vim.api.nvim_create_user_command("Tabterm", ...)` dispatcher in `plugin/tabterm.lua`.
  Alternative considered: keep the old commands and add `Tabterm` as aliases. This was rejected because the proposal intentionally treats the command rename as a breaking API cleanup.

- Represent subcommands in a local Lua table that maps names to handlers.
  Alternative considered: implement a long conditional chain. A table keeps completion and dispatch backed by the same source of truth and reduces the chance of drift.

- Parse the first whitespace-delimited token as the subcommand and pass the remaining text to subcommands that accept arguments.
  Alternative considered: expose each subcommand as a separate custom command argument shape. Neovim user commands only provide one command-level `nargs` contract, so local parsing is simpler and sufficient for the current API.

- Support these subcommand names: `toggle`, `open`, `close`, `shell`, `command`, `start`, `rename`, `delete`, `next`, and `prev`.
  Alternative considered: keep `new-command` and `new-shell` as literal subcommand names. This was rejected because the requested API shortens those actions to `command` and `shell`.

## Risks / Trade-offs

- Existing user mappings or scripts that call `Tabterm*` commands will break -> update repository references and rely on the explicit breaking-change note in the proposal/spec.
- A single command with local parsing gives all subcommands the same Neovim command metadata -> keep parsing minimal and only preserve the existing optional command text for `:Tabterm command`.
- Completion can drift from dispatch if implemented separately -> derive completion candidates from the same subcommand table used for dispatch.
