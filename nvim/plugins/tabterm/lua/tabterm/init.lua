local config = require("tabterm.config")
local events = require("tabterm.events")
local model = require("tabterm.model")
local state = require("tabterm.state")
local types = require("tabterm.types")
local ui = require("tabterm.ui")

local M = {}

local function current_workspace(create)
  return state.get_workspace(state.current_tabpage(), create)
end

local function dispatch(event)
  M.ensure_setup()
  return events.dispatch(event)
end

local function default_shell_spec(spec)
  return vim.tbl_extend("force", {
    kind = "shell",
    cmd = vim.env.SHELL or vim.o.shell or "sh",
    cwd = (vim.uv or vim.loop).cwd() or vim.fn.getcwd(),
  }, spec or {})
end

local function open_workspace_ui(workspace)
  dispatch({
    type = types.WORKSPACE_OPEN_REQUESTED,
    tabpage = workspace.runtime.tabpage,
    payload = { winid = vim.api.nvim_get_current_win() },
  })
end

local function create_and_start(tabpage, spec, opts)
  dispatch({
    type = types.TERMINAL_CREATE_REQUESTED,
    tabpage = tabpage,
    payload = {
      spec = spec,
      to_index = opts and opts.to_index or nil,
    },
  })

  local workspace = state.get_workspace(tabpage, true)
  if workspace and workspace.active_terminal_id then
    dispatch({
      type = types.TERMINAL_START_REQUESTED,
      tabpage = tabpage,
      terminal_id = workspace.active_terminal_id,
    })
  end
end

local sidebar_terminal_id

local function terminal_index(workspace, terminal_id)
  if not workspace or not terminal_id then
    return nil
  end

  for index, id in ipairs(workspace.terminal_order) do
    if id == terminal_id then
      return index
    end
  end

  return nil
end

local function insertion_index(workspace, placement)
  if not workspace then
    return 1
  end

  if placement == "first" then
    return 1
  end

  if placement == "last" or #workspace.terminal_order == 0 then
    return #workspace.terminal_order + 1
  end

  local anchor = sidebar_terminal_id(workspace) or workspace.active_terminal_id
  local index = terminal_index(workspace, anchor) or #workspace.terminal_order

  if placement == "before" then
    return index
  end

  if placement == "after" then
    return index + 1
  end

  return #workspace.terminal_order + 1
end

local function create_at(workspace, spec, placement)
  open_workspace_ui(workspace)
  create_and_start(workspace.runtime.tabpage, spec, { to_index = insertion_index(workspace, placement) })
  M.focus_panel()
end

local function preserve_tabterm_focus_after_delete(workspace)
  if not workspace or not workspace.runtime.visible or #workspace.terminal_order == 0 then
    state.set_autoclose_suspended(workspace and workspace.runtime and workspace.runtime.tabpage or nil, false)
    return
  end

  vim.defer_fn(function()
    local latest = current_workspace(false)
    if latest and #latest.terminal_order > 0 then
      if not latest.runtime.visible then
        open_workspace_ui(latest)
      end
      M.focus_sidebar()
    end
    state.set_autoclose_suspended(workspace.runtime.tabpage, false)
  end, 20)
end

local function move_focus_to_sidebar_before_delete(workspace)
  if not workspace or not workspace.runtime.visible then
    return
  end

  local sidebar_win = workspace.runtime.sidebar.winid
  if sidebar_win and vim.api.nvim_win_is_valid(sidebar_win) and vim.api.nvim_get_current_win() ~= sidebar_win then
    vim.api.nvim_set_current_win(sidebar_win)
  end
end

local function stabilize_panel_before_delete(workspace)
  if not workspace or not workspace.runtime.visible then
    return
  end

  local panel_win = workspace.runtime.panel.winid
  if not panel_win or not vim.api.nvim_win_is_valid(panel_win) then
    return
  end

  local scratch = vim.api.nvim_create_buf(false, true)
  vim.bo[scratch].buftype = "nofile"
  vim.bo[scratch].bufhidden = "wipe"
  vim.bo[scratch].swapfile = false
  vim.bo[scratch].modifiable = false
  pcall(vim.api.nvim_win_set_buf, panel_win, scratch)
end

local function confirm_delete_terminal(terminal)
  if not terminal or not model.is_waiting(terminal) then
    return true
  end

  local label = model.command_label(terminal)
  local choice = vim.fn.confirm(
    ("Delete running terminal '%s'?"):format(label),
    "&Delete\n&Cancel",
    2
  )

  return choice == 1
end

local function delete_terminal(workspace, terminal_id)
  if not workspace or not terminal_id then
    return
  end

  local terminal = workspace.terminals_by_id[terminal_id]
  if not terminal or not confirm_delete_terminal(terminal) then
    return
  end

  local should_preserve_focus = workspace.runtime.visible
    and terminal_id == workspace.active_terminal_id
    and #workspace.terminal_order > 1

  if should_preserve_focus then
    state.set_autoclose_suspended(workspace.runtime.tabpage, true)
    move_focus_to_sidebar_before_delete(workspace)
    stabilize_panel_before_delete(workspace)
  end

  dispatch({
    type = types.TERMINAL_DELETE_REQUESTED,
    tabpage = workspace.runtime.tabpage,
    terminal_id = terminal_id,
  })

  local latest = state.get_workspace(workspace.runtime.tabpage, false)
  if latest and #latest.terminal_order == 0 and latest.runtime.visible then
    dispatch({
      type = types.WORKSPACE_CLOSE_REQUESTED,
      tabpage = latest.runtime.tabpage,
    })
    return
  end

  if should_preserve_focus then
    preserve_tabterm_focus_after_delete(workspace)
  end
end

sidebar_terminal_id = function(workspace)
  if not workspace or not workspace.runtime.visible or not workspace.runtime.sidebar.winid then
    return nil
  end

  local row = vim.api.nvim_win_get_cursor(workspace.runtime.sidebar.winid)[1]
  return workspace.runtime.sidebar.line_map[row] or nil
end

local function sidebar_row_for_terminal(workspace, terminal_id)
  if not workspace or not terminal_id then
    return nil
  end

  for row, id in ipairs(workspace.runtime.sidebar.line_map or {}) do
    if id == terminal_id then
      return row
    end
  end

  return nil
end

local function sidebar_target_row(workspace, delta)
  if not workspace or not workspace.runtime.visible or not workspace.runtime.sidebar.winid then
    return nil
  end

  local line_map = workspace.runtime.sidebar.line_map or {}
  local row = vim.api.nvim_win_get_cursor(workspace.runtime.sidebar.winid)[1]
  local current_id = line_map[row]
  if not current_id then
    return nil
  end

  if delta > 0 then
    for index = row + 1, #line_map do
      if line_map[index] and line_map[index] ~= current_id then
        return index
      end
    end
  else
    for index = row - 1, 1, -1 do
      if line_map[index] and line_map[index] ~= current_id then
        local target_id = line_map[index]
        while index > 1 and line_map[index - 1] == target_id do
          index = index - 1
        end
        return index
      end
    end
  end

  return row
end

function M.setup(opts)
  state.config = config.merge(opts)
  ui.setup_highlights()

  if not state.initialized then
    events.setup_autocmds()
    state.initialized = true
  end

  return M
end

function M.ensure_setup()
  if not state.initialized then
    M.setup({})
  end
end

function M.open()
  local workspace = current_workspace(true)
  open_workspace_ui(workspace)
  if #workspace.terminal_order == 0 then
    create_and_start(workspace.runtime.tabpage, default_shell_spec())
  end
  M.focus_panel()
end

function M.close()
  local workspace = current_workspace(false)
  if not workspace then
    return
  end
  dispatch({ type = types.WORKSPACE_CLOSE_REQUESTED, tabpage = workspace.runtime.tabpage })
end

function M.hide()
  local workspace = current_workspace(false)
  if not workspace then
    return
  end

  local restore_win = workspace.runtime.last_editor_winid
  M.close()

  if restore_win
    and vim.api.nvim_win_is_valid(restore_win)
    and restore_win ~= workspace.runtime.sidebar.winid
    and restore_win ~= workspace.runtime.panel.winid
    and restore_win ~= workspace.runtime.backdrop.winid
  then
    pcall(vim.api.nvim_set_current_win, restore_win)
  end
end

function M.toggle()
  local workspace = current_workspace(true)
  local was_visible = workspace.runtime.visible
  dispatch({
    type = types.WORKSPACE_TOGGLE_REQUESTED,
    tabpage = workspace.runtime.tabpage,
    payload = { winid = vim.api.nvim_get_current_win() },
  })
  if not was_visible then
    if #workspace.terminal_order == 0 then
      create_and_start(workspace.runtime.tabpage, default_shell_spec())
    end
    M.focus_panel()
  end
end

function M.new_shell(spec)
  local workspace = current_workspace(true)
  create_at(workspace, default_shell_spec(spec), "last")
end

function M.insert_shell(placement, spec)
  local workspace = current_workspace(true)
  create_at(workspace, default_shell_spec(spec), placement)
end

function M.new_command(cmd)
  return M.insert_command("last", cmd)
end

function M.insert_command(placement, cmd)
  local workspace = current_workspace(true)

  local create = function(value)
    value = tostring(value or "")
    if value == "" then
      return
    end

    create_at(workspace, {
      kind = "cmd",
      cmd = value,
      cwd = (vim.uv or vim.loop).cwd() or vim.fn.getcwd(),
    }, placement)
  end

  if cmd then
    create(cmd)
    return
  end

  vim.ui.input({ prompt = "Command: " }, create)
end

function M.start_active()
  local workspace = current_workspace(true)
  if not workspace.active_terminal_id then
    M.new_shell()
    return
  end

  open_workspace_ui(workspace)
  dispatch({
    type = types.TERMINAL_START_REQUESTED,
    tabpage = workspace.runtime.tabpage,
    terminal_id = workspace.active_terminal_id,
  })
  M.focus_panel()
end

function M.rename_active(name_override)
  local workspace = current_workspace(false)
  if not workspace or not workspace.active_terminal_id then
    return
  end

  local apply_name = function(value)
    dispatch({
      type = types.TERMINAL_RENAME_REQUESTED,
      tabpage = workspace.runtime.tabpage,
      terminal_id = workspace.active_terminal_id,
      payload = { name_override = value ~= "" and value or nil },
    })
  end

  if name_override ~= nil then
    apply_name(name_override)
    return
  end

  local terminal = workspace.terminals_by_id[workspace.active_terminal_id]
  vim.ui.input({ prompt = "Terminal name: ", default = terminal.spec.name_override or "" }, function(value)
    if value ~= nil then
      apply_name(value)
    end
  end)
end

function M.delete_active()
  local workspace = current_workspace(false)
  if not workspace or not workspace.active_terminal_id then
    return
  end

  delete_terminal(workspace, workspace.active_terminal_id)
end

function M.next_terminal()
  local workspace = current_workspace(false)
  if not workspace then
    return
  end
  M.open()
  dispatch({ type = types.TERMINAL_NEXT_REQUESTED, tabpage = workspace.runtime.tabpage })
end

function M.prev_terminal()
  local workspace = current_workspace(false)
  if not workspace then
    return
  end
  M.open()
  dispatch({ type = types.TERMINAL_PREV_REQUESTED, tabpage = workspace.runtime.tabpage })
end

function M.select_sidebar_cursor()
  local workspace = current_workspace(false)
  local terminal_id = sidebar_terminal_id(workspace)
  if not terminal_id then
    return
  end

  dispatch({
    type = types.TERMINAL_SELECT_REQUESTED,
    tabpage = workspace.runtime.tabpage,
    terminal_id = terminal_id,
  })
end

function M.rename_sidebar_cursor()
  local workspace = current_workspace(false)
  local terminal_id = sidebar_terminal_id(workspace)
  if not terminal_id then
    return
  end
  dispatch({
    type = types.TERMINAL_SELECT_REQUESTED,
    tabpage = workspace.runtime.tabpage,
    terminal_id = terminal_id,
  })
  M.rename_active()
end

function M.delete_sidebar_cursor()
  local workspace = current_workspace(false)
  local terminal_id = sidebar_terminal_id(workspace)
  if not terminal_id then
    return
  end

  delete_terminal(workspace, terminal_id)
end

function M.move_sidebar_cursor(delta)
  local workspace = current_workspace(false)
  local terminal_id = sidebar_terminal_id(workspace)
  if not terminal_id then
    return
  end

  local current_index = 1
  for index, id in ipairs(workspace.terminal_order) do
    if id == terminal_id then
      current_index = index
      break
    end
  end

  dispatch({
    type = types.TERMINAL_MOVE_REQUESTED,
    tabpage = workspace.runtime.tabpage,
    terminal_id = terminal_id,
    payload = { to_index = current_index + delta },
  })
end

function M.sidebar_step(delta)
  local workspace = current_workspace(false)
  local row = sidebar_target_row(workspace, delta)
  if not workspace or not row or not vim.api.nvim_win_is_valid(workspace.runtime.sidebar.winid) then
    return
  end

  vim.api.nvim_win_set_cursor(workspace.runtime.sidebar.winid, { row, 0 })
end

function M.sidebar_goto(index)
  local workspace = current_workspace(false)
  if not workspace or not workspace.runtime.visible or not vim.api.nvim_win_is_valid(workspace.runtime.sidebar.winid) then
    return
  end

  if #workspace.terminal_order == 0 then
    return
  end

  index = math.max(1, math.min(#workspace.terminal_order, tonumber(index) or 1))
  local terminal_id = workspace.terminal_order[index]
  local row = sidebar_row_for_terminal(workspace, terminal_id)
  if not row then
    return
  end

  vim.api.nvim_win_set_cursor(workspace.runtime.sidebar.winid, { row, 0 })

  if workspace.active_terminal_id ~= terminal_id then
    dispatch({
      type = types.TERMINAL_SELECT_REQUESTED,
      tabpage = workspace.runtime.tabpage,
      terminal_id = terminal_id,
    })
  end
end

function M.sync_sidebar_cursor()
  local workspace = current_workspace(false)
  local terminal_id = sidebar_terminal_id(workspace)
  if not workspace or not terminal_id or workspace.active_terminal_id == terminal_id then
    return
  end

  dispatch({
    type = types.TERMINAL_SELECT_REQUESTED,
    tabpage = workspace.runtime.tabpage,
    terminal_id = terminal_id,
  })
end

function M.focus_sidebar()
  local workspace = current_workspace(false)
  if not workspace or not workspace.runtime.visible or not workspace.runtime.sidebar.winid then
    return
  end

  if vim.api.nvim_win_is_valid(workspace.runtime.sidebar.winid) then
    local row = sidebar_row_for_terminal(workspace, workspace.active_terminal_id)
    if row then
      vim.api.nvim_win_set_cursor(workspace.runtime.sidebar.winid, { row, 0 })
    end
    vim.api.nvim_set_current_win(workspace.runtime.sidebar.winid)
  end
end

function M.focus_panel()
  local workspace = current_workspace(false)
  if not workspace or not workspace.runtime.visible or not workspace.runtime.panel.winid then
    return
  end

  local terminal = workspace.active_terminal_id and workspace.terminals_by_id[workspace.active_terminal_id] or nil
  if terminal then
    terminal.snapshot.notification.unread = false
  end

  if vim.api.nvim_win_is_valid(workspace.runtime.panel.winid) then
    vim.api.nvim_set_current_win(workspace.runtime.panel.winid)

    if workspace.runtime.panel.kind == "terminal" and terminal and terminal.runtime.phase == "live" then
      vim.cmd("startinsert")
    end
  end
end

return M
