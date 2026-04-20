## 1. Plugin scaffolding and Nix integration

- [x] 1.1 Create a local plugin directory under `nvim/plugins/` with the initial Lua entrypoints and module layout for config, state, reducer, reconcile, ui, and persistence helpers
- [x] 1.2 Add a dedicated `nvim/plugins/*.nix` module that installs the local plugin and exposes the initial setup configuration
- [x] 1.3 Wire the new plugin module into `nvim/plugins.nix` and decide whether the current floaterm module should be disabled or kept during migration

## 2. Core state and event model

- [x] 2.1 Implement the tab-scoped `WorkspaceState` and `TerminalRecord` data model with separate `spec`, `snapshot`, and `runtime` sections
- [x] 2.2 Implement the internal event enum, reducer, and workspace lookup keyed by tabpage handles
- [x] 2.3 Implement `reconcile(workspace)` so terminal ordering, active selection, mounted window references, and placeholder-versus-terminal panel state stay valid after every event

## 3. Terminal lifecycle and metadata tracking

- [x] 3.1 Implement terminal creation, selection, rename, delete, move, and explicit start actions for shell and command terminals
- [x] 3.2 Connect Neovim terminal lifecycle events (`TermOpen`, `TermClose`, buffer invalidation) to runtime state updates and last-result persistence
- [x] 3.3 Connect terminal metadata and shell integration events (`term_title`, cwd reporting, shell command execution/finish signals) to snapshot updates and waiting-state tracking

## 4. Floating UI and placeholder rendering

- [x] 4.1 Implement the floating workspace UI with sidebar plus panel windows and tabpage-local open/close/toggle behavior
- [x] 4.2 Implement compact and detailed sidebar rendering, including derived terminal naming and two-line detailed entries
- [x] 4.3 Implement placeholder rendering for empty, dormant, and exited terminals, and ensure exited active terminals collapse back to placeholder content

## 5. Session restore and validation

- [x] 5.1 Implement session snapshot capture and restore for terminal descriptors and snapshots without automatically restarting processes
- [x] 5.2 Ensure restored workspaces reopen with dormant terminals, valid placeholder state, and no stale mounted UI handles
- [x] 5.3 Validate the plugin in the local Neovim configuration, including tabpage isolation, explicit start behavior, sidebar rendering, and external window-close invalidation
