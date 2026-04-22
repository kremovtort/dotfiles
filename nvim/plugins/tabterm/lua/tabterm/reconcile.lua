local model = require("tabterm.model")
local ui_state = require("tabterm.ui_state")
local util = require("tabterm.util")

local M = {}

local function can_mount_in_panel(terminal)
  if not terminal then
    return false
  end
  local bufnr = ui_state.get_terminal_bufnr(terminal.id)
  if not util.valid_buf(bufnr) then
    return false
  end
  if terminal.runtime.phase == "live" then
    return true
  end
  return terminal.runtime.phase == "exited"
end

-- Reconcile is allowed to repair structural invariants before rendering,
-- but behavioral runtime transitions must still flow through the reducer.
local function sanitize_workspace(workspace)
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
end

function M.derive(tabpage, workspace)
  if not workspace then
    return {}
  end

  sanitize_workspace(workspace)

  local ui = ui_state.get(tabpage)
  local has_windows = util.valid_win(ui.backdrop.winid)
    and util.valid_win(ui.sidebar.winid)
    and util.valid_win(ui.panel.winid)

  local commands = {}

  if not workspace.runtime.visible then
    if has_windows then
      table.insert(commands, { "UNMOUNT", { tabpage = tabpage } })
    end
    return commands
  end

  if not has_windows then
    table.insert(commands, { "MOUNT", { tabpage = tabpage } })
  else
    table.insert(commands, { "RELAYOUT", { tabpage = tabpage } })
  end

  table.insert(commands, { "RENDER_SIDEBAR", { tabpage = tabpage, workspace = workspace } })

  local active = workspace.active_terminal_id and workspace.terminals_by_id[workspace.active_terminal_id] or nil
  if not can_mount_in_panel(active) then
    table.insert(commands, { "RENDER_PLACEHOLDER", { tabpage = tabpage, workspace = workspace } })
  else
    local bufnr = ui_state.get_terminal_bufnr(active.id)
    table.insert(commands, {
      "MOUNT_TERMINAL",
      {
        tabpage = tabpage,
        terminal_id = active.id,
        terminal = active,
        bufnr = bufnr,
      },
    })
  end

  return commands
end

return M
