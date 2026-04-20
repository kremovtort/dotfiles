local reconcile = require("tabterm.reconcile")
local reducer = require("tabterm.reducer")
local state = require("tabterm.state")
local types = require("tabterm.types")
local ui = require("tabterm.ui")

local M = {
  types = types,
}

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

local function tracked_terminal_from_buffer(bufnr)
  local ref = state.lookup_buffer(bufnr)
  if not ref then
    return nil, nil, nil
  end

  local workspace = state.get_workspace(ref.tabpage, false)
  local terminal = workspace and workspace.terminals_by_id[ref.terminal_id] or nil
  return workspace, terminal, ref
end

local function last_meaningful_line(bufnr)
  if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
    return nil
  end

  local lines = vim.api.nvim_buf_get_lines(bufnr, math.max(0, vim.api.nvim_buf_line_count(bufnr) - 20), -1, false)
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
    on_lines = function()
      local workspace = state.get_workspace(tabpage, false)
      local terminal = workspace and workspace.terminals_by_id[terminal_id] or nil
      if not workspace or not terminal then
        return true
      end

      sync_title(workspace, terminal, { defer_refresh = true })

      local detail = last_meaningful_line(bufnr)
      if detail then
        local should_track = terminal.spec.kind == "cmd" or terminal.runtime.command.phase == "running"
        if should_track then
          M.dispatch({
            type = types.TERMINAL_OUTPUT_UPDATED,
            tabpage = tabpage,
            terminal_id = terminal_id,
            payload = { last_meaningful_line = detail },
          }, { defer_refresh = true })
        elseif terminal.spec.kind == "shell" and terminal.runtime.command.phase == "prompt" then
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
      if state.lookup_buffer(bufnr) then
        M.dispatch({
          type = types.TERMINAL_BUFFER_WIPED_EXTERNALLY,
          tabpage = tabpage,
          terminal_id = terminal_id,
        }, { defer_refresh = true })
      end
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
      local bufnr, channel_id = ui.start_terminal(workspace, terminal)
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
      local ref = state.lookup_buffer(ev.buf)
      if not ref then
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
          M.dispatch({ type = types.SIDEBAR_WINDOW_CLOSED_EXTERNALLY, tabpage = tabpage })
          return
        end
        if workspace.runtime.panel.winid == winid then
          M.dispatch({ type = types.PANEL_WINDOW_CLOSED_EXTERNALLY, tabpage = tabpage })
          return
        end
      end
    end,
  })

  vim.api.nvim_create_autocmd({ "BufWipeout", "BufDelete" }, {
    group = state.augroup,
    callback = function(ev)
      local ref = state.lookup_buffer(ev.buf)
      if ref then
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
      vim.schedule(function()
        for tabpage, workspace in pairs(state.workspaces_by_tab) do
          if workspace.runtime.visible then
            local in_tabterm = current_win == workspace.runtime.sidebar.winid or current_win == workspace.runtime.panel.winid
            if not in_tabterm then
              M.dispatch({ type = types.WORKSPACE_CLOSE_REQUESTED, tabpage = tabpage })
            end
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
