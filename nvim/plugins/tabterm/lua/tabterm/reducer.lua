local model = require("tabterm.model")
local state = require("tabterm.state")
local types = require("tabterm.types")

local M = {}

local function terminal_is_visible(workspace, terminal_id)
  return workspace
    and workspace.runtime.visible
    and workspace.active_terminal_id == terminal_id
    and workspace.runtime.panel.winid ~= nil
end

local function remove_from_order(order, id)
  for index = #order, 1, -1 do
    if order[index] == id then
      table.remove(order, index)
    end
  end
end

local function move_in_order(order, id, to_index)
  remove_from_order(order, id)
  to_index = math.max(1, math.min(#order + 1, to_index))
  table.insert(order, to_index, id)
end

local function next_id(workspace)
  local id = ("t%d"):format(workspace.runtime.next_terminal_seq)
  workspace.runtime.next_terminal_seq = workspace.runtime.next_terminal_seq + 1
  return id
end

local function delete_terminal_buffer(terminal)
  if not terminal or not terminal.runtime.bufnr then
    return
  end

  state.clear_buffer_index(terminal.runtime.bufnr)
  if vim.api.nvim_buf_is_valid(terminal.runtime.bufnr) then
    state.suppress_bufdelete[terminal.runtime.bufnr] = true
    pcall(vim.api.nvim_buf_delete, terminal.runtime.bufnr, { force = true })
    state.suppress_bufdelete[terminal.runtime.bufnr] = nil
  end
end

local function drop_terminal(workspace, terminal_id)
  local terminal = workspace and workspace.terminals_by_id[terminal_id] or nil
  if not terminal then
    return
  end

  delete_terminal_buffer(terminal)
  workspace.terminals_by_id[terminal_id] = nil
  remove_from_order(workspace.terminal_order, terminal_id)

  if workspace.active_terminal_id == terminal_id then
    workspace.active_terminal_id = workspace.terminal_order[1]
  end
end

local function prune_hidden_exited_cmds(workspace, visible_terminal_id)
  if not workspace then
    return
  end

  local ids = vim.deepcopy(workspace.terminal_order)
  for _, id in ipairs(ids) do
    local terminal = workspace.terminals_by_id[id]
    if terminal and terminal.spec.kind == "cmd" and terminal.runtime.phase == "exited" and id ~= visible_terminal_id then
      drop_terminal(workspace, id)
    end
  end
end

local function create_terminal(workspace, spec, to_index)
  local id = next_id(workspace)
  local terminal = model.new_terminal(id, spec)
  workspace.terminals_by_id[id] = terminal
  local index = tonumber(to_index) or (#workspace.terminal_order + 1)
  index = math.max(1, math.min(#workspace.terminal_order + 1, index))
  table.insert(workspace.terminal_order, index, id)
  workspace.active_terminal_id = id
  return terminal
end

function M.apply(event)
  local tabpage = event.tabpage or state.current_tabpage()
  local create_workspace = event.type ~= types.TABPAGE_CLOSED
  local workspace = state.get_workspace(tabpage, create_workspace)

  if event.type == types.WORKSPACE_OPEN_REQUESTED then
    workspace.runtime.visible = true
    workspace.runtime.last_editor_winid = event.payload and event.payload.winid or vim.api.nvim_get_current_win()
    return workspace
  end

  if event.type == types.WORKSPACE_CLOSE_REQUESTED or event.type == types.SIDEBAR_WINDOW_CLOSED_EXTERNALLY or event.type == types.PANEL_WINDOW_CLOSED_EXTERNALLY then
    if workspace then
      workspace.runtime.visible = false
      workspace.runtime.panel.kind = "placeholder"

      for _, terminal in pairs(workspace.terminals_by_id) do
        terminal.runtime.winid = nil
      end

      prune_hidden_exited_cmds(workspace, nil)
    end
    return workspace
  end

  if event.type == types.WORKSPACE_TOGGLE_REQUESTED then
    workspace.runtime.visible = not workspace.runtime.visible
    if workspace.runtime.visible then
      workspace.runtime.last_editor_winid = event.payload and event.payload.winid or vim.api.nvim_get_current_win()
    end
    return workspace
  end

  if event.type == types.TERMINAL_CREATE_REQUESTED then
    local payload = event.payload or {}
    local created = create_terminal(workspace, payload.spec or {}, payload.to_index)
    prune_hidden_exited_cmds(workspace, created and created.id or workspace.active_terminal_id)
    return workspace
  end

  local terminal_id = event.terminal_id or workspace and workspace.active_terminal_id
  local terminal = workspace and terminal_id and workspace.terminals_by_id[terminal_id] or nil

  if event.type == types.TERMINAL_DELETE_REQUESTED then
    if terminal then
      drop_terminal(workspace, terminal_id)
    end
    return workspace
  end

  if not terminal and event.type ~= types.TABPAGE_CLOSED then
    return workspace
  end

  if event.type == types.TERMINAL_RENAME_REQUESTED then
    terminal.spec.name_override = event.payload and event.payload.name_override or nil
    return workspace
  end

  if event.type == types.TERMINAL_SELECT_REQUESTED then
    workspace.active_terminal_id = terminal_id
    terminal.snapshot.notification.unread = false
    prune_hidden_exited_cmds(workspace, terminal_id)
    return workspace
  end

  if event.type == types.TERMINAL_NEXT_REQUESTED or event.type == types.TERMINAL_PREV_REQUESTED then
    if #workspace.terminal_order == 0 then
      workspace.active_terminal_id = nil
      return workspace
    end

    local current_index = 1
    for index, id in ipairs(workspace.terminal_order) do
      if id == workspace.active_terminal_id then
        current_index = index
        break
      end
    end

    local delta = event.type == types.TERMINAL_NEXT_REQUESTED and 1 or -1
    local next_index = ((current_index - 1 + delta) % #workspace.terminal_order) + 1
    workspace.active_terminal_id = workspace.terminal_order[next_index]
    prune_hidden_exited_cmds(workspace, workspace.active_terminal_id)
    return workspace
  end

  if event.type == types.TERMINAL_MOVE_REQUESTED then
    move_in_order(workspace.terminal_order, terminal_id, event.payload and event.payload.to_index or 1)
    return workspace
  end

  if event.type == types.TERMINAL_START_REQUESTED then
    if terminal.runtime.bufnr then
      state.clear_buffer_index(terminal.runtime.bufnr)
    end
    terminal.runtime.phase = "starting"
    terminal.runtime.bufnr = nil
    terminal.runtime.winid = nil
    terminal.runtime.channel_id = nil
    terminal.runtime.command.output_tail = nil
    terminal.runtime.command.phase = terminal.spec.kind == "cmd" and "running" or "unknown"
    return workspace
  end

  if event.type == types.TERMINAL_PROCESS_OPENED then
    terminal.runtime.phase = "live"
    terminal.runtime.bufnr = event.payload.bufnr
    terminal.runtime.channel_id = event.payload.channel_id
    return workspace
  end

  if event.type == types.TERMINAL_PROCESS_EXITED then
    terminal.runtime.phase = "exited"
    terminal.runtime.channel_id = nil
    terminal.runtime.winid = nil
    terminal.runtime.command.phase = "unknown"

    local source = event.payload and event.payload.source
    if not source then
      source = terminal.spec.kind == "cmd" and "process" or "unknown"
    end

    terminal.snapshot.last_result.kind = (event.payload and event.payload.code or 0) == 0 and "success" or "error"
    terminal.snapshot.last_result.code = event.payload and event.payload.code or 0
    terminal.snapshot.last_result.source = source
    terminal.snapshot.notification.unread = not terminal_is_visible(workspace, terminal_id)
    terminal.snapshot.notification.kind = terminal.snapshot.last_result.kind
    if terminal.runtime.command.output_tail and terminal.runtime.command.output_tail ~= "" then
      terminal.snapshot.last_output_line = terminal.runtime.command.output_tail
    end
    return workspace
  end

  if event.type == types.SHELL_INTEGRATION_DETECTED then
    terminal.runtime.command.integration = event.payload.integration
    return workspace
  end

  if event.type == types.SHELL_PROMPT_STARTED then
    terminal.runtime.command.phase = "prompt"
    return workspace
  end

  if event.type == types.SHELL_COMMAND_INPUT_STARTED then
    terminal.runtime.command.phase = "editing"
    return workspace
  end

  if event.type == types.SHELL_COMMAND_EXECUTED then
    terminal.runtime.command.phase = "running"
    terminal.runtime.command.output_tail = nil
    return workspace
  end

  if event.type == types.SHELL_COMMAND_FINISHED then
    terminal.runtime.command.phase = "prompt"
    terminal.snapshot.last_result.kind = (event.payload.code or 0) == 0 and "success" or "error"
    terminal.snapshot.last_result.code = event.payload.code or 0
    terminal.snapshot.last_result.source = "shell"
    terminal.snapshot.notification.unread = not terminal_is_visible(workspace, terminal_id)
    terminal.snapshot.notification.kind = terminal.snapshot.last_result.kind
    terminal.snapshot.notification.line = terminal.runtime.command.output_tail or terminal.snapshot.last_output_line
    if terminal.runtime.command.output_tail and terminal.runtime.command.output_tail ~= "" then
      terminal.snapshot.last_output_line = terminal.runtime.command.output_tail
    end
    return workspace
  end

  if event.type == types.SHELL_COMMAND_ABORTED then
    terminal.runtime.command.phase = "prompt"
    terminal.runtime.command.output_tail = nil
    return workspace
  end

  if event.type == types.TERMINAL_CWD_REPORTED then
    terminal.snapshot.cwd = event.payload.cwd
    return workspace
  end

  if event.type == types.TERMINAL_TITLE_UPDATED then
    terminal.snapshot.title = event.payload.title
    return workspace
  end

  if event.type == types.TERMINAL_OUTPUT_UPDATED then
    terminal.runtime.command.output_tail = event.payload.last_meaningful_line
    return workspace
  end

  if event.type == types.SHELL_BACKGROUND_JOB_NOTIFIED then
    local kind = event.payload and event.payload.kind or "unknown"
    local line = event.payload and event.payload.line or nil
    terminal.snapshot.notification.unread = true
    terminal.snapshot.notification.kind = kind
    terminal.snapshot.notification.line = line
    if line and line ~= "" then
      terminal.snapshot.last_output_line = line
    end
    return workspace
  end

  if event.type == types.TERMINAL_BUFFER_WIPED_EXTERNALLY then
    if terminal.runtime.bufnr then
      state.clear_buffer_index(terminal.runtime.bufnr)
    end
    terminal.runtime.phase = "stopped"
    terminal.runtime.bufnr = nil
    terminal.runtime.winid = nil
    terminal.runtime.channel_id = nil
    terminal.runtime.command.phase = "unknown"
    terminal.runtime.command.output_tail = nil
    return workspace
  end

  if event.type == types.TABPAGE_CLOSED then
    if workspace then
      for _, terminal in pairs(workspace.terminals_by_id) do
        delete_terminal_buffer(terminal)
      end
    end
    state.workspaces_by_tab[state.tab_key(tabpage)] = nil
    return nil
  end

  return workspace
end

return M
