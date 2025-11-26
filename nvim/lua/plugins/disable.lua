local disabled_plugins = {
  "akinsho/bufferline.nvim",
  "jay-babu/mason-nvim-dap.nvim",
  "mason-org/mason-lspconfig.nvim",
  "mason-org/mason.nvim",
  "mfussenegger/nvim-lint",
  "folke/neoconf.nvim",
}

local M = {}

for _, disabled_plugin in ipairs(disabled_plugins) do
  table.insert(M, { disabled_plugin, enabled = false })
end

return M
