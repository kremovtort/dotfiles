local model = require("tabterm.model")

local M = {}

local function valid_buf(bufnr)
  return bufnr and bufnr > 0 and vim.api.nvim_buf_is_valid(bufnr)
end

local function valid_win(winid)
  return winid and winid > 0 and vim.api.nvim_win_is_valid(winid)
end

function M.workspace(workspace)
  if not workspace then
    return nil
  end

  local ordered = {}
  local seen = {}
  for _, id in ipairs(workspace.terminal_order) do
    if workspace.terminals_by_id[id] and not seen[id] then
      table.insert(ordered, id)
      seen[id] = true
    end
  end
  for id, terminal in pairs(workspace.terminals_by_id) do
    workspace.terminals_by_id[id] = model.ensure_terminal_shape(id, terminal)
    if not seen[id] then
      table.insert(ordered, id)
      seen[id] = true
    end
  end
  workspace.terminal_order = ordered

  if #workspace.terminal_order == 0 then
    workspace.active_terminal_id = nil
  elseif not workspace.active_terminal_id or not workspace.terminals_by_id[workspace.active_terminal_id] then
    workspace.active_terminal_id = workspace.terminal_order[1]
  end

  for _, terminal in pairs(workspace.terminals_by_id) do
    if (terminal.runtime.phase == "starting" or terminal.runtime.phase == "live") and not valid_buf(terminal.runtime.bufnr) then
      terminal.runtime.phase = "dormant"
      terminal.runtime.bufnr = nil
      terminal.runtime.channel_id = nil
      terminal.runtime.command.phase = "unknown"
      terminal.runtime.command.output_tail = nil
    end
  end

  if not workspace.runtime.visible then
    workspace.runtime.backdrop.bufnr = nil
    workspace.runtime.backdrop.winid = nil
    workspace.runtime.sidebar.bufnr = nil
    workspace.runtime.sidebar.winid = nil
    workspace.runtime.sidebar.line_map = {}
    workspace.runtime.panel.bufnr = nil
    workspace.runtime.panel.winid = nil
    workspace.runtime.panel.kind = "placeholder"
    for _, terminal in pairs(workspace.terminals_by_id) do
      terminal.runtime.winid = nil
    end
    return workspace
  end

  if not valid_win(workspace.runtime.backdrop.winid) or not valid_win(workspace.runtime.sidebar.winid) or not valid_win(workspace.runtime.panel.winid) then
    workspace.runtime.visible = false
    workspace.runtime.backdrop.bufnr = nil
    workspace.runtime.backdrop.winid = nil
    workspace.runtime.sidebar.bufnr = nil
    workspace.runtime.sidebar.winid = nil
    workspace.runtime.sidebar.line_map = {}
    workspace.runtime.panel.bufnr = nil
    workspace.runtime.panel.winid = nil
    workspace.runtime.panel.kind = "placeholder"
    for _, terminal in pairs(workspace.terminals_by_id) do
      terminal.runtime.winid = nil
    end
    return workspace
  end

  for id, terminal in pairs(workspace.terminals_by_id) do
    if id ~= workspace.active_terminal_id or terminal.runtime.phase ~= "live" then
      terminal.runtime.winid = nil
    end
  end

  local active = workspace.active_terminal_id and workspace.terminals_by_id[workspace.active_terminal_id] or nil
  if not active or active.runtime.phase ~= "live" or not valid_buf(active.runtime.bufnr) then
    workspace.runtime.panel.kind = "placeholder"
    return workspace
  end

  workspace.runtime.panel.kind = "terminal"
  workspace.runtime.panel.bufnr = active.runtime.bufnr
  active.runtime.winid = workspace.runtime.panel.winid

  return workspace
end

return M
