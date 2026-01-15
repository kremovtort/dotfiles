-- Entry point.
-- Plugins and runtime deps are provided via nixCats; lazy-loading is handled by lze.

require("config.options")
require("config.autocmds")
require("config.keymaps")
-- VSCode Neovim has its own LSP/UX. Keep our config minimal there.
if not vim.g.vscode then
  require("config.lsp")
end

-- lze will load plugin specs in the order you provide (and does not auto-import whole dirs).
-- We keep `lua/plugins/init.lua` as the ordered entry point.
-- For vscode-neovim we load an empty/minimal set to avoid unnecessary plugin overhead.
require("lze").load(vim.g.vscode and "plugins.vscode" or "plugins")
