## 1. Implementation

- [x] 1.1 Add a tabterm helper that resolves the current visible workspace panel and executes a requested normal-mode scroll command inside the panel window with `nvim_win_call`.
- [x] 1.2 Make the helper return early when the workspace UI is not visible or the panel window is invalid, without checking `panel.kind`.
- [x] 1.3 Add sidebar normal-mode mappings for `<C-d>`, `<C-u>`, `<C-f>`, and `<C-b>` that delegate to the helper with the corresponding panel scroll commands.

## 2. Verification

- [x] 2.1 Verify the sidebar mappings keep focus in the sidebar after scrolling the panel.
- [x] 2.2 Verify the mappings operate on a valid terminal panel and do not send control characters to the terminal job.
- [x] 2.3 Verify the mappings are harmless for a valid placeholder panel and do not require `panel.kind` branching.
- [x] 2.4 Run the relevant Neovim/Nix validation command for this repository, or document why it cannot be run.
