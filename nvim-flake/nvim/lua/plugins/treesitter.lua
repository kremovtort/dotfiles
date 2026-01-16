return {
  {
    -- packadd name must match nixCats opt dir (`nvim-treesitter`).
    "nvim-treesitter",
    cmd = { "TSInstall", "TSInstallFromGrammar", "TSUpdate", "TSUninstall" },
    on_require = { "nvim-treesitter" },
  },
}

