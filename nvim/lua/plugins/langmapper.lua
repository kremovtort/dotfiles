return {
  {
    'Wansmer/langmapper.nvim',
    lazy = false,
    priority = 1000,
    vscode = true,
    config = function()
      require('langmapper').setup({})
    end,
  }
}
