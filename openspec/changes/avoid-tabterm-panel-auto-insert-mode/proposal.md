## Why

Tabterm panel focus currently re-enters Terminal-mode automatically, which resets scrollback position after sidebar-driven panel scrolling and can make exited command terminals close on the next typed character. Shell terminals should still default to insert mode, but tabterm should not override an explicit user switch to normal mode or a sidebar scroll action.

## What Changes

- Preserve insert mode as the default for shell terminals when there is no explicit normal-mode intent.
- Stop automatically re-entering Terminal-mode after the user manually leaves it or scrolls the panel from the sidebar.
- Keep tabterm panel terminal buffers out of the global `term://*` auto-`startinsert` behavior.
- Classify tabterm panel buffers with role-specific filetypes: `tabterm-panel-shell`, `tabterm-panel-command`, and `tabterm-panel-placeholder`.
- Keep the existing defensive `stopinsert` behavior for exited command terminals when focusing the panel.
- Ensure sidebar panel scrolling continues to execute as panel normal-mode scrolling, without sending input to terminal jobs.

## Capabilities

### New Capabilities

- None.

### Modified Capabilities

- `tab-scoped-terminal-manager`: panel focus and sidebar scroll behavior now require mode-intent tracking and tabterm-specific terminal buffer classification.

## Impact

- Affects the local tabterm Lua plugin under `nvim/plugins/tabterm/lua/tabterm/`.
- Affects the global terminal `BufEnter` autocmd in `nvim/config/autoCmd.nix`.
- No external API or dependency changes.
