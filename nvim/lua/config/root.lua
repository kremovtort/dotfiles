-- Project root detection (replacement for LazyVim.root()).
local M = {}

---@param bufnr? integer
---@return string
function M.get(bufnr)
  bufnr = bufnr or 0
  local root = vim.fs.root(bufnr, { ".git", ".jj" })
  root = root or (vim.uv or vim.loop).cwd() or "."
  return vim.fs.normalize(root)
end

return M

