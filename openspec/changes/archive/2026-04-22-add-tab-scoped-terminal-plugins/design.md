## Context

The current Neovim configuration installs `nvzone/floaterm` through `nvim/plugins/floaterm.nix`, but that plugin keeps global state, exposes a small configuration surface, and does not fit the desired tabpage-oriented workflow. The repository already organizes Neovim features as per-plugin Nix modules under `nvim/plugins/*.nix`, and the new terminal manager should follow that structure while keeping the Lua implementation in a dedicated local plugin directory under `nvim/plugins/`.

The desired workflow is centered on tabpages rather than a single global terminal list. Each tabpage needs its own terminal workspace, a persistent sidebar, compact and detailed sidebar rendering, and manual restore semantics so restored terminals appear as entries without automatically starting their jobs. The design also needs to preserve useful terminal metadata such as cwd, title, last result, and last output line for both sidebar rows and placeholder content.

## Goals / Non-Goals

**Goals:**
- Provide a local tab-scoped floating terminal manager that owns its own state instead of wrapping upstream global state.
- Keep one terminal workspace per tabpage, with its own active terminal, ordering, and floating UI lifecycle.
- Support compact and detailed sidebar modes, derived names, and placeholder rendering for empty, dormant, and exited terminals.
- Restore terminal entries from session data without automatically restarting their processes.
- Integrate the plugin into the existing NixVim layout through a dedicated Nix module and local plugin directory.

**Non-Goals:**
- Full scrollback persistence or restoring live terminal process state across Neovim restarts.
- Project-scoped sharing of terminals across multiple tabpages.
- Split-layout terminal management outside the floating sidebar plus panel workflow.
- Generalizing the plugin for external reuse before the personal workflow is stable.

## Decisions

### Use a local plugin instead of forking or wrapping the current floaterm
The implementation will be a local Lua plugin stored in its own directory under `nvim/plugins/` and loaded via a dedicated `nvim/plugins/*.nix` module. This keeps the behavior fully controllable and avoids inheriting the upstream plugin's global singleton state and fixed layout assumptions.

Alternatives considered:
- Fork `nvzone/floaterm`: faster initial bootstrap, but it preserves the same global-state model and layout rigidity.
- Build on top of `snacks.terminal`: reduces low-level process work, but couples the terminal manager to another plugin's abstractions and makes the custom state model less direct.

### Model terminal state as workspace state plus terminal records
Each tabpage will own a `WorkspaceState` containing `active_terminal_id`, `terminal_order`, `terminals_by_id`, and runtime-only UI handles. Each terminal entry will be represented by a `TerminalRecord` split into `spec`, `snapshot`, and `runtime` sections so persisted intent and last-known metadata stay separate from live Neovim handles.

Alternatives considered:
- A single flat global terminal list keyed by buffers: rejected because it cannot express tabpage-scoped workspaces cleanly.
- A single terminal object mixing persisted and runtime fields: rejected because manual restore becomes harder to reason about and more error-prone.

### Treat session restore as descriptor restore, not process restore
The plugin will save and restore terminal descriptors and snapshots, but it will not automatically restart terminal jobs after session restore. Restored entries will come back as dormant terminals and will render through the placeholder panel until explicitly started.

Alternatives considered:
- Reuse Neovim's terminal session restore directly: rejected because restoring terminal windows by command restart conflicts with the desired manual-only restart behavior.
- Restore nothing and always start from an empty workspace: rejected because the workflow needs visible terminal history and restart targets after reopening sessions.

### Use normalized internal events and a reconcile step
Neovim events and user actions will be normalized into internal events that update state through a reducer. After each event, a `reconcile(workspace)` step will repair ordering, active selection, mounted window references, and placeholder-versus-terminal panel state.

Alternatives considered:
- Directly mutating state inside each autocmd and mapping callback: rejected because lifecycle and UI edge cases become fragile.
- A heavy event-bus framework: rejected because the plugin only needs a small, deterministic reducer plus reconcile model.

### Exited and externally closed UI states collapse to placeholder or closed workspace
When the active terminal exits, the panel will immediately switch to a placeholder card instead of continuing to show an exited terminal buffer. When the sidebar or panel is closed externally, the whole workspace UI is considered closed and runtime UI handles are cleared atomically.

Alternatives considered:
- Keep exited terminal buffers mounted in the panel: rejected because the intended workflow uses explicit restart semantics and placeholder cards as the primary recovery surface.
- Try to preserve partially open UI after external window closure: rejected because it creates half-mounted states that complicate reconcile logic.

### Sidebar modes affect sidebar rendering only
Compact and detailed modes apply to sidebar item rendering, while the panel placeholder remains a dedicated card-style view. This keeps the main panel informative even when the sidebar is configured to be compact.

Alternatives considered:
- Tie panel detail level directly to sidebar mode: rejected because the main panel serves a different purpose and should stay informative.

## Risks / Trade-offs

- [Shell command status depends on shell integration quality] → Track result source explicitly (`process`, `shell`, `unknown`) and fall back to `unknown` when the shell cannot provide reliable command-finish signals.
- [Floating UI lifecycle can desynchronize from Neovim windows] → Use normalized invalidation events and a strict reconcile pass that collapses broken mounted UI into `visible = false`.
- [Session restore adds custom persistence logic] → Keep persistence limited to terminal descriptors and snapshots, not live process state or scrollback.
- [A local personal plugin may need renaming or reshaping later] → Keep the first implementation narrow and repository-specific until the workflow stabilizes.

## Migration Plan

1. Add the local plugin directory and a dedicated Nix module that installs and configures it.
2. Wire the module into `nvim/plugins.nix` without removing unrelated terminal integrations.
3. Disable or replace the current `floaterm` module once the new plugin covers the intended workflow.
4. Verify basic startup, tabpage isolation, sidebar rendering, and dormant restore behavior in a rebuilt Neovim configuration.

## Open Questions

- The exact local plugin name and Lua module path can be finalized during implementation as long as the repository layout stays `nvim/plugins/<plugin-dir>/` plus `nvim/plugins/<plugin>.nix`.
