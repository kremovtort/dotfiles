-- Plugin specs for vscode-neovim.
-- Keep this intentionally minimal to avoid loading UI-heavy plugins inside VSCode.
return {
  { import = "plugins.leap" },
  { import = "plugins.mini-ai" },
  { import = "plugins.mini-pairs" },
  { import = "plugins.mini-surround" },
  { import = "plugins.flit" },
  { import = "plugins.repeat" },
}

