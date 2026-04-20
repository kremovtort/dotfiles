local model = require("tabterm.model")
local state = require("tabterm.state")

local M = {}

local function encode(value)
  if vim.json and vim.json.encode then
    return vim.json.encode(value)
  end
  return vim.fn.json_encode(value)
end

local function decode(value)
  if vim.json and vim.json.decode then
    return vim.json.decode(value)
  end
  return vim.fn.json_decode(value)
end

function M.capture()
  local tabs = vim.api.nvim_list_tabpages()
  local workspaces = {}
  local has_data = false

  for index, tabpage in ipairs(tabs) do
    local workspace = state.get_workspace(tabpage, false)
    local snapshot = {
      active_terminal_id = workspace and workspace.active_terminal_id or nil,
      terminal_order = workspace and vim.deepcopy(workspace.terminal_order) or {},
      terminals = {},
    }

    if workspace then
      for id, terminal in pairs(workspace.terminals_by_id) do
        snapshot.terminals[id] = {
          spec = vim.deepcopy(terminal.spec),
          snapshot = vim.deepcopy(terminal.snapshot),
        }
      end

      if next(snapshot.terminals) then
        has_data = true
      end
    end

    workspaces[index] = snapshot
  end

  if not has_data then
    return nil
  end

  return encode({
    version = 1,
    workspaces = workspaces,
  })
end

function M.restore(data)
  if not data or data == "" then
    return nil
  end

  local ok, snapshot = pcall(decode, data)
  if not ok or type(snapshot) ~= "table" then
    vim.notify("tabterm: failed to decode session data", vim.log.levels.WARN)
    return nil
  end

  return snapshot
end

function M.next_sequence(workspace)
  local max_id = 0
  for id in pairs(workspace.terminals_by_id) do
    local numeric = tonumber(tostring(id):match("^t(%d+)$")) or 0
    if numeric > max_id then
      max_id = numeric
    end
  end
  workspace.runtime.next_terminal_seq = max_id + 1
end

function M.restore_workspace_shape(workspace)
  for id, terminal in pairs(workspace.terminals_by_id) do
    workspace.terminals_by_id[id] = model.ensure_terminal_shape(id, terminal)
  end
  M.next_sequence(workspace)
end

return M
