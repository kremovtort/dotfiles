## Why

Tabterm currently exposes separate CamelCase user commands such as `TabtermStart` and `TabtermToggle`, while the desired interface is a single `:Tabterm` command with subcommands. Consolidating the command surface makes command discovery and completion more consistent and leaves room for future subcommands without adding more top-level command names.

## What Changes

- **BREAKING** Replace the existing top-level `Tabterm*` user commands with `:Tabterm <subcommand>` equivalents.
- Map existing actions to lowercase subcommands: `start`, `toggle`, `command`, `shell`, `prev`, `next`, and equivalent subcommands for the rest of the current command surface.
- Rename the creation commands specifically: `TabtermNewCommand` becomes `:Tabterm command`, and `TabtermNewShell` becomes `:Tabterm shell`.
- Preserve the behavior and arguments of each existing action after it is invoked through the new subcommand form.
- Add command completion for the `:Tabterm` subcommands where practical.

## Capabilities

### New Capabilities

- None.

### Modified Capabilities

- `tab-scoped-terminal-manager`: The user command API changes from multiple `Tabterm*` commands to a single `Tabterm` command with subcommands.

## Impact

- Affects the local Neovim tabterm plugin command registration and command completion.
- Affects NixVim keymaps or configuration that call the old `Tabterm*` commands.
- Requires updating documentation or specs that mention the old command names.
