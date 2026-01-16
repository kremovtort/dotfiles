-- Built-in Neovim LSP configuration (Neovim 0.11+).
-- This intentionally avoids nvim-lspconfig to keep startup clean on 0.11.

-- Basic server configs. Binaries are provided by nixCats `lspsAndRuntimeDeps`.
vim.lsp.config("lua_ls", {
  settings = {
    Lua = {
      telemetry = { enabled = false },
      diagnostics = {
        globals = { "vim" },
      },
    },
  },
})

vim.lsp.config("nixd", {})
vim.lsp.config("bashls", {})

vim.lsp.enable({ "lua_ls", "nixd", "bashls" })

