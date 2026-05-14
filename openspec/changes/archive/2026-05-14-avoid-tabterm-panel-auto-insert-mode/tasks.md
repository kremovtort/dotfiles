## 1. Implementation

- [x] 1.1 Assign `tabterm-panel-placeholder` to placeholder panel buffers instead of the previous placeholder filetype.
- [x] 1.2 Assign `tabterm-panel-shell` and `tabterm-panel-command` to panel terminal buffers based on `terminal.spec.kind` before terminal `BufEnter` auto-insert behavior can act on them.
- [x] 1.3 Update the global `term://*` `BufEnter` autocmd to skip auto-`startinsert` for buffers whose filetype starts with `tabterm-panel-`, both before scheduling and inside the scheduled callback.
- [x] 1.4 Track normal-mode intent for tabterm panel terminals when the user leaves Terminal-mode and when the user scrolls the panel from the sidebar.
- [x] 1.5 Clear normal-mode intent when the user explicitly enters Terminal-mode for the tabterm panel terminal.
- [x] 1.6 Update `focus_panel()` so live shell terminals enter Terminal-mode only when no normal-mode intent is remembered.
- [x] 1.7 Update `focus_panel()` so command terminals do not auto-enter Terminal-mode and exited command terminals still defensively leave Terminal-mode.
- [x] 1.8 Ensure sidebar panel scroll continues to execute normal-mode panel scroll commands without sending input to terminal jobs.

## 2. Verification

- [x] 2.1 Verify a newly focused live shell panel still defaults to Terminal-mode when no normal-mode intent exists.
- [x] 2.2 Verify a shell panel does not re-enter Terminal-mode after the user manually leaves Terminal-mode and focuses the panel again from the sidebar.
- [x] 2.3 Verify sidebar panel scrolling prevents later shell panel focus from immediately re-entering Terminal-mode.
- [x] 2.4 Verify command terminal panels do not auto-enter Terminal-mode when focused from the sidebar.
- [x] 2.5 Verify exited command terminal panels are not left in Terminal-mode when focused from the sidebar.
- [x] 2.6 Verify tabterm panel buffers use `tabterm-panel-shell`, `tabterm-panel-command`, and `tabterm-panel-placeholder` as appropriate.
- [x] 2.7 Verify non-tabterm terminal buffers still receive the global auto-`startinsert` behavior.
- [x] 2.8 Run the relevant Neovim/Nix validation command for this repository, or document why it cannot be run.
