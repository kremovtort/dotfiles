local model = require("tabterm.model")
local util = require("tabterm.util")

local M = {}



local function can_mount_in_panel(terminal)
  if not terminal or not util.valid_buf(terminal.runtime.bufnr) then
    return false
  end

  if terminal.runtime.phase == "live" then
    return true
  end

  return terminal.runtime.phase == "exited"
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
    if (terminal.runtime.phase == "starting" or terminal.runtime.phase == "live") and not util.valid_buf(terminal.runtime.bufnr) then
      terminal.runtime.phase = "stopped"
      terminal.runtime.bufnr = nil
      terminal.runtime.channel_id = nil
      terminal.runtime.command.phase = "unknown"
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

  if not util.valid_win(workspace.runtime.backdrop.winid) or not util.valid_win(workspace.runtime.sidebar.winid) or not util.valid_win(workspace.runtime.panel.winid) then
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
    if id ~= workspace.active_terminal_id or not can_mount_in_panel(terminal) then
      terminal.runtime.winid = nil
    end
  end

  local active = workspace.active_terminal_id and workspace.terminals_by_id[workspace.active_terminal_id] or nil
  if not can_mount_in_panel(active) then
    workspace.runtime.panel.kind = "placeholder"
    workspace.runtime.panel.bufnr = nil
    return workspace
  end

  workspace.runtime.panel.kind = "terminal"
  workspace.runtime.panel.bufnr = active.runtime.bufnr
  active.runtime.winid = workspace.runtime.panel.winid

  return workspace
end

return M
