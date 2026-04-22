local reconcile = require("tabterm.reconcile")
local reducer = require("tabterm.reducer")
local model = require("tabterm.model")
local state = require("tabterm.state")
local types = require("tabterm.types")
local ui = require("tabterm.ui")
local util = require("tabterm.util")

local M = {
  types = types,
}



local function stabilize_panel_for_terminal_dispose(workspace)
  if not workspace or not workspace.runtime.visible then
    return false
  end

  local sidebar_win = workspace.runtime.sidebar.winid
  if #workspace.terminal_order > 1 and util.valid_win(sidebar_win) and vim.api.nvim_get_current_win() ~= sidebar_win then
    pcall(vim.api.nvim_set_current_win, sidebar_win)
  end

  local panel_win = workspace.runtime.panel.winid
  if not util.valid_win(panel_win) then
    return false
  end

  local scratch = vim.api.nvim_create_buf(false, true)
  vim.bo[scratch].buftype = "nofile"
  vim.bo[scratch].bufhidden = "wipe"
  vim.bo[scratch].swapfile = false
  vim.bo[scratch].modifiable = false
  pcall(vim.api.nvim_win_set_buf, panel_win, scratch)
  return true
end

local function prepare_shell_delete_transition(workspace, terminal_id)
  if not workspace or not workspace.runtime.visible or workspace.active_terminal_id ~= terminal_id then
    return false
  end

  if util.valid_win(workspace.runtime.panel.winid) then
    state.suppress_winclosed[workspace.runtime.panel.winid] = true
  end

  stabilize_panel_for_terminal_dispose(workspace)

  state.set_autoclose_suspended(workspace.runtime.tabpage, true)
  return true
end

local function set_suspend_autoclose_from_pending(tabpage)
  local key = state.tab_key(tabpage)
  state.set_autoclose_suspended(key, state.pending_shell_dispose[key] ~= nil)
end

local function schedule_shell_dispose(workspace, terminal, ref)
  if not workspace or not terminal or not ref or terminal.spec.kind ~= "shell" then
    return false
  end

  local panel_winid = workspace.runtime.panel.winid

  local key = state.tab_key(ref.tabpage)
  local pending = state.pending_shell_dispose[key]
  if pending and pending.terminal_id == ref.terminal_id then
    return true
  end

  local keep_open = prepare_shell_delete_transition(workspace, ref.terminal_id)
  state.pending_shell_dispose[key] = {
    terminal_id = ref.terminal_id,
    keep_open = keep_open,
    panel_winid = panel_winid,
  }
  set_suspend_autoclose_from_pending(key)

  vim.schedule(function()
    local latest_pending = state.pending_shell_dispose[key]
    if not latest_pending or latest_pending.terminal_id ~= ref.terminal_id then
      if panel_winid then
        state.suppress_winclosed[panel_winid] = nil
      end
      set_suspend_autoclose_from_pending(key)
      return
    end

    state.pending_shell_dispose[key] = nil

    M.dispatch({
      type = types.TERMINAL_DELETE_REQUESTED,
      tabpage = ref.tabpage,
      terminal_id = ref.terminal_id,
    }, { defer_refresh = true })

    local latest = state.get_workspace(ref.tabpage, false)
    if latest_pending.keep_open and latest then
      if #latest.terminal_order > 0 then
        local ok, tabterm = pcall(require, "tabterm")
        if ok then
          tabterm.open()
          tabterm.focus_sidebar()
        else
          latest.runtime.visible = true
          ui.ensure_open(latest)
          reconcile.workspace(latest)
          ui.refresh(latest)
          if util.valid_win(latest.runtime.sidebar.winid) then
            pcall(vim.api.nvim_set_current_win, latest.runtime.sidebar.winid)
          end
        end
      else
        M.dispatch({
          type = types.WORKSPACE_CLOSE_REQUESTED,
          tabpage = ref.tabpage,
        }, { defer_refresh = true })
      end
    end

    if latest_pending.panel_winid then
      state.suppress_winclosed[latest_pending.panel_winid] = nil
    end

    vim.defer_fn(function()
      set_suspend_autoclose_from_pending(key)
    end, 100)
  end)

  return true
end

local function refresh_workspace_now(workspace)
  reconcile.workspace(workspace)
  ui.refresh(workspace)
end

local function refresh_workspace_later(workspace)
  if not workspace then
    return
  end

  local key = state.tab_key(workspace.runtime and workspace.runtime.tabpage or nil)
  if state.refresh_scheduled[key] then
    return
  end

  state.refresh_scheduled[key] = true
  vim.schedule(function()
    state.refresh_scheduled[key] = nil
    local latest = state.get_workspace(key, false)
    if latest then
      refresh_workspace_now(latest)
    end
  end)
end

local function refresh_all_now()
  for _, other in pairs(state.workspaces_by_tab) do
    refresh_workspace_now(other)
  end
end

local function refresh_all_later()
  for _, other in pairs(state.workspaces_by_tab) do
    refresh_workspace_later(other)
  end
end

local function workspace_has_waiting_terminal(workspace)
  if not workspace then
    return false
  end

  for _, terminal in pairs(workspace.terminals_by_id) do
    if model.is_waiting(terminal) then
      return true
    end
  end

  return false
end

local function visible_waiting_workspaces()
  local waiting = {}
  for _, workspace in pairs(state.workspaces_by_tab) do
    if workspace.runtime.visible and workspace_has_waiting_terminal(workspace) then
      table.insert(waiting, workspace)
    end
  end
  return waiting
end

local function stop_spinner_ticker()
  if state.spinner_timer then
    state.spinner_timer:stop()
    state.spinner_timer:close()
    state.spinner_timer = nil
  end
  state.reset_spinner_frame()
end

local function ensure_spinner_ticker()
  if state.spinner_timer then
    return
  end

  local timer = (vim.uv or vim.loop).new_timer()
  if not timer then
    return
  end

  state.spinner_timer = timer
  timer:start(
    state.spinner_interval,
    state.spinner_interval,
    vim.schedule_wrap(function()
      local waiting = visible_waiting_workspaces()
      if #waiting == 0 then
        stop_spinner_ticker()
        return
      end

      state.advance_spinner_frame()
      for _, workspace in ipairs(waiting) do
        refresh_workspace_now(workspace)
      end
    end)
  )
end

local function update_spinner_ticker()
  if #visible_waiting_workspaces() > 0 then
    ensure_spinner_ticker()
  else
    stop_spinner_ticker()
  end
end

local function tracked_terminal_from_buffer(bufnr)
  local ref = state.lookup_buffer(bufnr)
  if not ref then
    return nil, nil, nil
  end

  local workspace = state.get_workspace(ref.tabpage, false)
  local terminal = workspace and workspace.terminals_by_id[ref.terminal_id] or nil
  return workspace, terminal, ref
end

local function last_meaningful_line(bufnr, firstline, lastline)
  if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
    return nil
  end

  local line_count = vim.api.nvim_buf_line_count(bufnr)
  local start = math.max(0, firstline or math.max(0, line_count - 20))
  local finish = math.min(line_count, lastline or line_count)
  if finish <= start then
    finish = line_count
    start = math.max(0, line_count - 20)
  end

  local lines = vim.api.nvim_buf_get_lines(bufnr, start, finish, false)
  for index = #lines, 1, -1 do
    local line = tostring(lines[index] or "")
    line = line:gsub("[%z\1-\31]", "")
    line = line:gsub("^%s+", ""):gsub("%s+$", "")
    if line ~= "" and not line:match("^%[Process exited") then
      return line
    end
  end
end

local function sync_title(workspace, terminal, opts)
  if not terminal or not terminal.runtime.bufnr or not vim.api.nvim_buf_is_valid(terminal.runtime.bufnr) then
    return
  end

  local title = vim.b[terminal.runtime.bufnr].term_title
  if title and title ~= "" and title ~= terminal.snapshot.title then
    M.dispatch({
      type = types.TERMINAL_TITLE_UPDATED,
      tabpage = workspace.runtime.tabpage,
      terminal_id = terminal.id,
      payload = { title = title },
    }, opts)
  end
end

local function parse_background_job_line(line)
  line = tostring(line or "")
  if line == "" then
    return nil
  end

  local normalized = line:lower()
  if not normalized:match("^%[%d+%][%s%+%-]*") then
    return nil
  end

  if normalized:match("%f[%a]done%f[%A]") then
    return "success"
  end

  if normalized:match("%f[%a]exit%f[%A]") or normalized:match("%f[%a]killed%f[%A]") or normalized:match("%f[%a]terminated%f[%A]") or normalized:match("%f[%a]stopped%f[%A]") then
    return "error"
  end

  return "unknown"
end

local function attach_output_listener(bufnr, tabpage, terminal_id)
  vim.api.nvim_buf_attach(bufnr, false, {
    on_lines = function(_, _, _, firstline, _, new_lastline)
      local workspace = state.get_workspace(tabpage, false)
      local terminal = workspace and workspace.terminals_by_id[terminal_id] or nil
      if not workspace or not terminal then
        return true
      end

      sync_title(workspace, terminal, { defer_refresh = true })

      if terminal.spec.kind == "shell" and terminal.runtime.command.phase == "prompt" then
        local detail = last_meaningful_line(bufnr, firstline, new_lastline)
        if detail then
          local kind = parse_background_job_line(detail)
          if kind and terminal.snapshot.notification.line ~= detail then
            M.dispatch({
              type = types.SHELL_BACKGROUND_JOB_NOTIFIED,
              tabpage = tabpage,
              terminal_id = terminal_id,
              payload = {
                kind = kind,
                line = detail,
              },
            }, { defer_refresh = true })
          end
        end
      end
    end,
    on_detach = function()
      -- Detach also happens on normal terminal job shutdown; real buffer removal
      -- is handled via BufDelete/BufWipeout below.
    end,
  })
end

local function parse_term_request(sequence)
  local code = sequence:match("^%z?\27%]133;([ABCD])") or sequence:match("^\27%]133;([ABCD])")
  local exit_code = tonumber(sequence:match("^\27%]133;D;(%d+)"))
  local cwd = sequence:gsub("^\27%]7;file://[^/]*", "")
  local cwd_changed = cwd ~= sequence
  return code, exit_code, cwd_changed and cwd or nil
end

function M.dispatch(event, opts)
  local workspace = reducer.apply(event)

  if event.type == types.WORKSPACE_OPEN_REQUESTED then
    ui.ensure_open(workspace)
  elseif event.type == types.WORKSPACE_TOGGLE_REQUESTED then
    if workspace and workspace.runtime.visible then
      ui.ensure_open(workspace)
    else
      ui.unmount(workspace)
    end
  elseif event.type == types.WORKSPACE_CLOSE_REQUESTED or event.type == types.SIDEBAR_WINDOW_CLOSED_EXTERNALLY or event.type == types.PANEL_WINDOW_CLOSED_EXTERNALLY then
    ui.unmount(workspace)
  elseif event.type == types.TERMINAL_START_REQUESTED and workspace then
    ui.ensure_open(workspace)
    local terminal = workspace.terminals_by_id[event.terminal_id or workspace.active_terminal_id]
    if terminal then
      local bufnr, channel_id, err, failed_bufnr = ui.start_terminal(workspace, terminal)
      if not bufnr or not channel_id then
        reducer.apply({
          type = types.TERMINAL_START_FAILED,
          tabpage = workspace.runtime.tabpage,
          terminal_id = terminal.id,
          payload = { message = err },
        })
        sync_title(workspace, terminal)
        if opts and opts.defer_refresh then
          refresh_workspace_later(workspace)
        else
          refresh_workspace_now(workspace)
        end
        if failed_bufnr and vim.api.nvim_buf_is_valid(failed_bufnr) then
          vim.schedule(function()
            state.suppress_bufdelete[failed_bufnr] = true
            pcall(vim.api.nvim_buf_delete, failed_bufnr, { force = true })
            state.suppress_bufdelete[failed_bufnr] = nil
          end)
        end
        return workspace
      end

      state.index_buffer(bufnr, workspace.runtime.tabpage, terminal.id)
      attach_output_listener(bufnr, workspace.runtime.tabpage, terminal.id)
      reducer.apply({
        type = types.TERMINAL_PROCESS_OPENED,
        tabpage = workspace.runtime.tabpage,
        terminal_id = terminal.id,
        payload = {
          bufnr = bufnr,
          channel_id = channel_id,
        },
      })
      sync_title(workspace, terminal)
    end
  end

  if workspace then
    if opts and opts.defer_refresh then
      refresh_workspace_later(workspace)
    elseif vim.in_fast_event() then
      refresh_workspace_later(workspace)
    else
      refresh_workspace_now(workspace)
    end
  else
    if opts and opts.defer_refresh then
      refresh_all_later()
    elseif vim.in_fast_event() then
      refresh_all_later()
    else
      refresh_all_now()
    end
  end

  update_spinner_ticker()

  return workspace
end

function M.setup_autocmds()
  if state.augroup then
    return
  end

  state.augroup = vim.api.nvim_create_augroup("Tabterm", { clear = true })

  vim.api.nvim_create_autocmd("TermOpen", {
    group = state.augroup,
    callback = function(ev)
      local workspace, terminal = tracked_terminal_from_buffer(ev.buf)
      if workspace and terminal then
        sync_title(workspace, terminal, { defer_refresh = true })
      end
    end,
  })

  vim.api.nvim_create_autocmd("TermClose", {
    group = state.augroup,
    callback = function(ev)
      local workspace, terminal, ref = tracked_terminal_from_buffer(ev.buf)
      if not ref then
        return
      end

      if terminal and terminal.spec.kind == "shell" then
        schedule_shell_dispose(workspace, terminal, ref)
        return
      end

      M.dispatch({
        type = types.TERMINAL_PROCESS_EXITED,
        tabpage = ref.tabpage,
        terminal_id = ref.terminal_id,
        payload = {
          code = type(vim.v.event) == "table" and vim.v.event.status or 0,
        },
      }, { defer_refresh = true })
    end,
  })

  vim.api.nvim_create_autocmd("TermRequest", {
    group = state.augroup,
    callback = function(ev)
      local ref = state.lookup_buffer(ev.buf)
      if not ref then
        return
      end

      local sequence = ev.data and ev.data.sequence or ""
      local code, exit_code, cwd = parse_term_request(sequence)
      if cwd then
        M.dispatch({
          type = types.TERMINAL_CWD_REPORTED,
          tabpage = ref.tabpage,
          terminal_id = ref.terminal_id,
          payload = { cwd = cwd },
        }, { defer_refresh = true })
      end

      if code == "A" then
        M.dispatch({
          type = types.SHELL_INTEGRATION_DETECTED,
          tabpage = ref.tabpage,
          terminal_id = ref.terminal_id,
          payload = { integration = "prompt_only" },
        }, { defer_refresh = true })
        M.dispatch({
          type = types.SHELL_PROMPT_STARTED,
          tabpage = ref.tabpage,
          terminal_id = ref.terminal_id,
        }, { defer_refresh = true })
      elseif code == "B" then
        M.dispatch({
          type = types.SHELL_COMMAND_INPUT_STARTED,
          tabpage = ref.tabpage,
          terminal_id = ref.terminal_id,
        }, { defer_refresh = true })
      elseif code == "C" then
        M.dispatch({
          type = types.SHELL_INTEGRATION_DETECTED,
          tabpage = ref.tabpage,
          terminal_id = ref.terminal_id,
          payload = { integration = "rich" },
        }, { defer_refresh = true })
        M.dispatch({
          type = types.SHELL_COMMAND_EXECUTED,
          tabpage = ref.tabpage,
          terminal_id = ref.terminal_id,
        }, { defer_refresh = true })
      elseif code == "D" and exit_code ~= nil then
        M.dispatch({
          type = types.SHELL_INTEGRATION_DETECTED,
          tabpage = ref.tabpage,
          terminal_id = ref.terminal_id,
          payload = { integration = "rich" },
        }, { defer_refresh = true })
        M.dispatch({
          type = types.SHELL_COMMAND_FINISHED,
          tabpage = ref.tabpage,
          terminal_id = ref.terminal_id,
          payload = { code = exit_code },
        }, { defer_refresh = true })
      elseif code == "D" then
        M.dispatch({
          type = types.SHELL_COMMAND_ABORTED,
          tabpage = ref.tabpage,
          terminal_id = ref.terminal_id,
        }, { defer_refresh = true })
      end
    end,
  })

  vim.api.nvim_create_autocmd("WinClosed", {
    group = state.augroup,
    callback = function(ev)
      local winid = tonumber(ev.match)
      if not winid or state.suppress_winclosed[winid] then
        return
      end

      for tabpage, workspace in pairs(state.workspaces_by_tab) do
        if workspace.runtime.sidebar.winid == winid then
          if state.is_autoclose_suspended(tabpage) then
            return
          end
          M.dispatch({ type = types.SIDEBAR_WINDOW_CLOSED_EXTERNALLY, tabpage = tabpage })
          return
        end
        if workspace.runtime.panel.winid == winid then
          if state.is_autoclose_suspended(tabpage) then
            return
          end
          local active_id = workspace.active_terminal_id
          local active = active_id and workspace.terminals_by_id[active_id] or nil
          if active and active.spec.kind == "shell" then
            vim.schedule(function()
              local latest = state.get_workspace(tabpage, false)
              local terminal = latest and active_id and latest.terminals_by_id[active_id] or nil
              local bufnr = terminal and terminal.runtime.bufnr or nil
              if terminal and (not bufnr or not vim.api.nvim_buf_is_valid(bufnr)) then
                schedule_shell_dispose(latest, terminal, {
                  tabpage = tabpage,
                  terminal_id = active_id,
                })
                return
              end

              M.dispatch({ type = types.PANEL_WINDOW_CLOSED_EXTERNALLY, tabpage = tabpage })
            end)
          else
            M.dispatch({ type = types.PANEL_WINDOW_CLOSED_EXTERNALLY, tabpage = tabpage })
          end
          return
        end
      end
    end,
  })

  vim.api.nvim_create_autocmd({ "BufWipeout", "BufDelete" }, {
    group = state.augroup,
    callback = function(ev)
      if state.suppress_bufdelete[ev.buf] then
        return
      end
      local ref = state.lookup_buffer(ev.buf)
      if ref then
        local workspace = state.get_workspace(ref.tabpage, false)
        local terminal = workspace and workspace.terminals_by_id[ref.terminal_id] or nil
        if terminal and terminal.spec.kind == "shell" then
          schedule_shell_dispose(workspace, terminal, ref)
          return
        end
        M.dispatch({
          type = types.TERMINAL_BUFFER_WIPED_EXTERNALLY,
          tabpage = ref.tabpage,
          terminal_id = ref.terminal_id,
        })
      end
    end,
  })

  vim.api.nvim_create_autocmd("TabClosed", {
    group = state.augroup,
    callback = function()
      for tabpage in pairs(state.workspaces_by_tab) do
        if not vim.api.nvim_tabpage_is_valid(tabpage) then
          M.dispatch({ type = types.TABPAGE_CLOSED, tabpage = tabpage })
        end
      end
    end,
  })

  vim.api.nvim_create_autocmd("ColorScheme", {
    group = state.augroup,
    callback = function()
      ui.setup_highlights()
    end,
  })

  vim.api.nvim_create_autocmd("VimResized", {
    group = state.augroup,
    callback = function()
      vim.schedule(function()
        for _, workspace in pairs(state.workspaces_by_tab) do
          if workspace.runtime.visible then
            ui.relayout(workspace)
            reconcile.workspace(workspace)
            ui.refresh(workspace)
          end
        end
      end)
    end,
  })

  vim.api.nvim_create_autocmd("WinEnter", {
    group = state.augroup,
    callback = function()
      local current_win = vim.api.nvim_get_current_win()
      local current_tabpage = state.current_tabpage()
      vim.schedule(function()
        if state.is_autoclose_suspended(current_tabpage) then
          return
        end

        local workspace = state.get_workspace(current_tabpage, false)
        if workspace and workspace.runtime.visible then
          local in_tabterm = current_win == workspace.runtime.sidebar.winid or current_win == workspace.runtime.panel.winid
          if not in_tabterm then
            M.dispatch({ type = types.WORKSPACE_CLOSE_REQUESTED, tabpage = current_tabpage })
          end
        end
      end)
    end,
  })

  vim.api.nvim_create_autocmd("CursorMoved", {
    group = state.augroup,
    callback = function(ev)
      if vim.bo[ev.buf].filetype ~= "tabterm-sidebar" then
        return
      end
      vim.schedule(function()
        local ok, tabterm = pcall(require, "tabterm")
        if ok then
          tabterm.sync_sidebar_cursor()
        end
      end)
    end,
  })
end

return M
