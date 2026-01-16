-- Helpers for lualine (replacement for LazyVim.lualine.*).

local M = {}

local function bufname()
  local name = vim.api.nvim_buf_get_name(0)
  if name == "" then
    return nil
  end
  return name
end

function M.root_dir()
  return function()
    local root = vim.fs.root(0, { ".git" }) or vim.uv.cwd()
    if not root or root == "" then
      return ""
    end
    return vim.fn.fnamemodify(root, ":t")
  end
end

function M.pretty_path()
  return function()
    local name = bufname()
    if not name then
      return "[No Name]"
    end

    local root = vim.fs.root(0, { ".git" }) or vim.uv.cwd() or ""
    local rel = name
    if root ~= "" and name:sub(1, #root + 1) == root .. "/" then
      rel = name:sub(#root + 2)
    else
      rel = vim.fn.fnamemodify(name, ":~")
    end

    rel = vim.fn.pathshorten(rel)
    if vim.bo.modified then
      rel = rel .. " [+]"
    end
    return rel
  end
end

return M

