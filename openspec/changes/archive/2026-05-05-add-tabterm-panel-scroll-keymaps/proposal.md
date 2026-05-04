## Why

Tabterm users can navigate the sidebar without leaving it, but scrolling the active panel currently requires moving focus into the panel first. Adding panel scroll keymaps to the sidebar keeps the sidebar as the control surface while preserving normal terminal scroll behavior.

## What Changes

- Add sidebar normal-mode mappings for `<C-d>`, `<C-u>`, `<C-f>`, and `<C-b>`.
- Make those mappings scroll the currently visible panel window as if `<C-d>`, `<C-u>`, `<C-f>`, or `<C-b>` were pressed in that panel's normal mode.
- Keep focus in the sidebar after scrolling the panel.
- Apply the behavior to any valid panel window without checking the panel kind.
- No breaking changes.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `tab-scoped-terminal-manager`: sidebar navigation gains panel-scrolling keymaps that operate on the visible panel window without changing focus.

## Impact

- Affects the local Neovim tabterm plugin under `nvim/plugins/tabterm/lua/tabterm/`.
- Adds keymaps only for tabterm's sidebar buffer.
- Does not add dependencies, user-facing commands, or configuration options.
