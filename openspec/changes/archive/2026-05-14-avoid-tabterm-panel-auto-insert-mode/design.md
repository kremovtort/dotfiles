## Context

Tabterm's floating UI uses a sidebar window for selection and a panel window for terminal or placeholder content. Sidebar panel scrolling now executes normal-mode scroll commands inside the panel window while focus remains in the sidebar. However, moving focus from the sidebar to a terminal panel currently re-enters Terminal-mode automatically, which can reset the user's scrollback view and can make exited command terminals react to typed characters as terminal input.

There are two sources of automatic Terminal-mode entry:

- `tabterm.focus_panel()` explicitly calls `startinsert` for live terminal panels.
- The global `BufEnter` autocmd for `term://*` buffers schedules `startinsert` for any entered terminal buffer.

## Goals / Non-Goals

**Goals:**

- Preserve insert mode as the default for shell terminals when there is no explicit normal-mode intent.
- Make sidebar-to-panel focus navigation respect explicit normal-mode intent after the user manually leaves Terminal-mode or scrolls the panel from the sidebar.
- Preserve automatic `startinsert` behavior for non-tabterm terminal buffers.
- Classify tabterm panel buffers with stable filetypes that the global autocmd can recognize.
- Keep defensive `stopinsert` behavior for already-exited command terminals.
- Keep sidebar panel scrolling as normal-mode panel scrolling, not terminal job input.

**Non-Goals:**

- Do not make shell terminals normal-mode-first when they are newly started or have no remembered normal-mode intent.
- Do not remove normal terminal-mode entry from Neovim terminals; users can still enter Terminal-mode explicitly with standard Neovim keys.
- Do not add configuration options for the new behavior.
- Do not change sidebar navigation mappings or panel terminal keymaps.
- Do not change shell integration or command execution semantics.

## Decisions

### Use role-specific tabterm panel filetypes

Assign panel buffers one of these filetypes:

- `tabterm-panel-shell` for tabterm shell terminal buffers.
- `tabterm-panel-command` for tabterm command terminal buffers.
- `tabterm-panel-placeholder` for tabterm placeholder panel buffers.

Rationale: filetypes are visible to Neovim autocmds and users, and this repository already uses role-based tabterm filetypes for floating UI buffers. Splitting shell, command, and placeholder panels makes the buffer role explicit without requiring the global autocmd to import tabterm internals.

Alternative considered: use a buffer-local marker such as `vim.b.tabterm_managed`. That would avoid filetype semantics, but it is less discoverable and less aligned with the existing role-based filetypes.

### Skip global terminal auto-insert for tabterm panel buffers

Update the global `BufEnter` autocmd for `term://*` buffers to return early when the entered buffer's filetype starts with `tabterm-panel-`. Repeat the same check inside the scheduled callback before calling `startinsert`.

Rationale: the autocmd is intentionally global for normal terminal buffers, but tabterm panel buffers have their own UI semantics. Checking both before scheduling and inside the scheduled callback prevents a delayed `startinsert` from winning after tabterm has focused the panel or stopped insert mode.

### Track panel terminal mode intent

Track whether a tabterm terminal panel should be treated as normal-mode-intended for focus navigation. This intent should become true when the user leaves Terminal-mode for that tabterm panel or when the user scrolls the panel from the sidebar. It should become false when the user explicitly enters Terminal-mode again, and new shell terminals should start with no normal-mode intent so they can default to insert mode.

Rationale: shell terminals should remain convenient for typing by default, but tabterm must not override the user's explicit decision to inspect scrollback in normal mode.

### Start insert only when intent allows it

Keep `tabterm.focus_panel()` allowed to enter Terminal-mode for live shell terminals only when there is no remembered normal-mode intent for that terminal. Do not auto-startinsert for command terminals, and do not auto-startinsert after sidebar scrolling or a manual leave from Terminal-mode.

Rationale: this preserves shell insert mode as the default while preventing tabterm from fighting explicit normal-mode interaction.

### Keep stopinsert only for exited command terminals

Keep the existing defensive `stopinsert` behavior when the active panel terminal is a command terminal whose runtime phase is `exited`. Do not apply broad `stopinsert` normalization to live shell or live command terminals.

Rationale: exited command terminals are the unsafe case where Terminal-mode input can close or disturb the terminal display. Live terminals should not be forced out of Terminal-mode beyond avoiding the automatic entry path.

### Keep sidebar scroll commands normal-mode-only

Sidebar scroll mappings should continue to call the panel scroll helper, and that helper should execute normal-mode scroll commands in the panel window. It should not send control characters to the terminal job. Scrolling a terminal panel from the sidebar should set normal-mode intent for that terminal so later panel focus does not immediately re-enter Terminal-mode and reset the user's scrollback interaction.

Rationale: sidebar scrolling is a UI navigation action, not terminal input. Remembering that intent keeps later focus behavior consistent with what the user just did.

## Risks / Trade-offs

- [Risk] Tracking mode intent can get stale if mode changes are missed. -> Mitigation: update intent from explicit sidebar scroll actions and terminal mode enter/leave events for tabterm panel buffers.
- [Risk] Filetype changes could affect user autocmds or future ftplugins. -> Mitigation: use tabterm-specific names and keep them role-based and stable.
- [Risk] Checking filetype in the global autocmd assumes tabterm sets it before `BufEnter` handling matters. -> Mitigation: set filetype before installing the terminal buffer in the panel and repeat the skip check inside the scheduled callback.
