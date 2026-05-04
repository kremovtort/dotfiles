## 1. Command API Implementation

- [x] 1.1 Replace the separate `Tabterm*` user command registrations in `nvim/plugins/tabterm/plugin/tabterm.lua` with one `Tabterm` dispatcher command.
- [x] 1.2 Add a local subcommand table for `toggle`, `open`, `close`, `shell`, `command`, `start`, `rename`, `delete`, `next`, and `prev` that calls the existing tabterm Lua actions.
- [x] 1.3 Preserve optional trailing command text for `:Tabterm command [cmd]` and pass it to the existing command-terminal creation behavior.
- [x] 1.4 Add command-line completion for the supported `:Tabterm` subcommands using the same subcommand source as dispatch.

## 2. Repository References

- [x] 2.1 Search the repository for old `Tabterm*` command references outside the OpenSpec change and update any runtime configuration or documentation to the new `:Tabterm <subcommand>` form.
- [x] 2.2 Confirm no old top-level `Tabterm*` commands remain registered as compatibility aliases.

## 3. Verification

- [x] 3.1 Run Lua formatting or lint checks relevant to the tabterm plugin.
- [x] 3.2 Build or check the Neovim configuration to verify the updated plugin loads successfully.
- [x] 3.3 Manually verify command completion includes all supported subcommands and excludes old top-level command names where practical.
