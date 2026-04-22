local M = {
  initialized = false,
  config = nil,
  workspaces_by_tab = {},
  buf_index = {},
  suppress_winclosed = {},
  suppress_bufdelete = {},
  refresh_scheduled = {},
  suspend_autoclose = false,
  pending_shell_dispose = {},
}

function M.current_tabpage()
  return vim.api.nvim_get_current_tabpage()
end

function M.tab_key(tabpage)
  return tabpage or M.current_tabpage()
end

function M.get_workspace(tabpage, create)
  local key = M.tab_key(tabpage)
  local workspace = M.workspaces_by_tab[key]

  if not workspace and create then
    workspace = require("tabterm.model").new_workspace(key)
    M.workspaces_by_tab[key] = workspace
  end

  return workspace, key
end

function M.set_workspace(tabpage, workspace)
  M.workspaces_by_tab[M.tab_key(tabpage)] = workspace
end

function M.index_buffer(bufnr, tabpage, terminal_id)
  if bufnr and bufnr > 0 then
    M.buf_index[bufnr] = {
      tabpage = M.tab_key(tabpage),
      terminal_id = terminal_id,
    }
  end
end

function M.clear_buffer_index(bufnr)
  M.buf_index[bufnr] = nil
end

function M.lookup_buffer(bufnr)
  return M.buf_index[bufnr]
end

return M
