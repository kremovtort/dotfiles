local M = {}

function M.valid_buf(bufnr)
  return bufnr and bufnr > 0 and vim.api.nvim_buf_is_valid(bufnr)
end

function M.valid_win(winid)
  return winid and winid > 0 and vim.api.nvim_win_is_valid(winid)
end

return M