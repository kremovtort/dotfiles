local disabled_plugins = {
  "akinsho/bufferline.nvim",
  "jay-babu/mason-nvim-dap.nvim",
  "williamboman/mason-lspconfig.nvim",
  "williamboman/mason.nvim",
}

local M = {}

for _, disabled_plugin in ipairs(disabled_plugins) do
  table.insert(M, { disabled_plugin, enabled = false })
end

return M
