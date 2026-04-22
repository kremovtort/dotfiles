local M = {}

M.defaults = {
  ui = {
    border = "single",
    sidebar_width = 30,
    float = {
      width = 0.70,
      height = 0.70,
    },
  },
}

function M.normalize(config)
  local normalized = vim.deepcopy(config or {})
  normalized.ui = normalized.ui or {}

  if normalized.ui.border == true then
    normalized.ui.border = "single"
  elseif normalized.ui.border == false then
    normalized.ui.border = "none"
  elseif normalized.ui.border == nil then
    normalized.ui.border = M.defaults.ui.border
  end

  normalized.ui.sidebar_width = math.max(20, tonumber(normalized.ui.sidebar_width) or M.defaults.ui.sidebar_width)

  normalized.ui.float = normalized.ui.float or {}
  normalized.ui.float.width = tonumber(normalized.ui.float.width) or M.defaults.ui.float.width
  normalized.ui.float.height = tonumber(normalized.ui.float.height) or M.defaults.ui.float.height

  return normalized
end

function M.merge(opts)
  return M.normalize(vim.tbl_deep_extend("force", vim.deepcopy(M.defaults), opts or {}))
end

return M
