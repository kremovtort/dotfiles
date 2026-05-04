## Context

Tabterm's floating UI has a sidebar window and a panel window tracked in `ui_state`. The sidebar already owns navigation keymaps and can move focus into the panel, but it does not currently provide a way to scroll the panel while keeping focus in the sidebar.

The requested behavior is limited to sidebar normal-mode mappings. The mappings are the standard control forms `<C-d>`, `<C-u>`, `<C-f>`, and `<C-b>`, and they should operate on the currently valid panel window regardless of whether the panel currently contains a terminal buffer or placeholder buffer.

## Goals / Non-Goals

**Goals:**

- Let sidebar users scroll the visible panel without changing focus from the sidebar.
- Reuse Neovim's normal-mode scroll behavior for the panel window instead of reimplementing scroll offsets.
- Keep the implementation local to tabterm's Lua modules and keymaps.
- Treat any valid panel window as scrollable without checking `panel.kind`.

**Non-Goals:**

- Do not add configuration options for these mappings.
- Do not change panel focus behavior, terminal insert-mode behavior, or existing sidebar navigation mappings.
- Do not send control characters to the running terminal job.
- Do not add new user commands.

## Decisions

### Execute normal-mode scroll commands inside the panel window

Add a public helper such as `scroll_panel(keys)` or `scroll_panel(direction)` in `tabterm/init.lua`. It will resolve the current workspace and `ui.panel.winid`, return early unless the workspace UI is visible and the panel window is valid, then call `vim.api.nvim_win_call(ui.panel.winid, function() ... end)` to execute the corresponding normal-mode scroll command.

Rationale: `nvim_win_call` runs the command with the panel as the current window for the duration of the call, so Neovim applies the same scroll semantics as if the user had focused the panel and pressed the normal-mode key. After the call, focus returns to the sidebar.

Alternative considered: manually adjust `winsaveview().topline` or use window cursor math. That would be more code and could diverge from Vim's built-in half-page and full-page scroll behavior.

### Map control scroll keys in the sidebar only

Add sidebar normal-mode keymaps in `sidebar_keymaps()` for `<C-d>`, `<C-u>`, `<C-f>`, and `<C-b>`. Each mapping delegates to the new panel scroll helper with the corresponding panel normal-mode scroll command.

Rationale: these are Vim's built-in half-page and full-page scroll keys, so using the same keys in the sidebar gives the sidebar a direct panel scroll control surface.

Alternative considered: manually map a separate modifier chord. That was rejected because the desired behavior is plain Ctrl-based scrolling.

### Do not branch on panel kind

The helper will only require a valid panel window. It will not check `ui.panel.kind` before scrolling.

Rationale: both terminal and placeholder panels are regular Neovim windows, and the requested behavior should apply to any valid panel window. Extra kind checks would add unnecessary special cases.

## Risks / Trade-offs

- [Risk] Terminal-mode mappings could accidentally send control characters to the job. -> Mitigation: define these mappings only for sidebar normal mode and execute normal-mode commands in the panel window.
- [Risk] Sidebar mappings override the sidebar's default Ctrl scroll behavior. -> Mitigation: this is intentional for tabterm because these keys should scroll the panel while the sidebar remains focused.
- [Risk] Panel scroll commands may be no-ops for short placeholder content. -> Mitigation: this is acceptable because the requirement is to operate on any valid panel window, not only scrollable content.
