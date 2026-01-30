{
  extraConfigLuaPre = ''
    -- Work around haskell-tools.nvim v6.2.1 + Neovim's `vim.lsp.config()` defaulting
    -- `config.name` to the config key ("haskell-tools").
    --
    -- haskell-tools.nvim starts two separate HLS clients by intent:
    --   - haskell-tools.nvim (for haskell/lhaskell)
    --   - haskell-tools.nvim (cabal) (for cabal/cabalproject)
    --
    -- But because haskell-tools merges `vim.lsp.config['haskell-tools']` into its
    -- start opts, the default `name = 'haskell-tools'` overwrites the intended
    -- per-filetype client names, collapsing both into a single client.
    -- That breaks cabal-specific capability fixes and causes HLS plugin errors
    -- like: "No plugins are available to handle ... documentHighlight ... cabal".
    do
      if not vim.g._kremovtort_ht_fix_lsp_start then
        vim.g._kremovtort_ht_fix_lsp_start = true
        local orig = vim.lsp.start
        vim.lsp.start = function(config, ...)
          if type(config) == 'table'
            and config.name == 'haskell-tools'
            and type(config.cmd) == 'table'
            and type(config.cmd[1]) == 'string'
            and config.cmd[1]:match('haskell%-language%-server')
            and type(config.filetypes) == 'table'
          then
            local ft = {}
            for _, v in ipairs(config.filetypes) do
              ft[v] = true
            end
            if ft.cabal or ft.cabalproject then
              config = vim.tbl_deep_extend('force', {}, config, { name = 'haskell-tools.nvim (cabal)' })
            elseif ft.haskell or ft.lhaskell then
              config = vim.tbl_deep_extend('force', {}, config, { name = 'haskell-tools.nvim' })
            end
          end
          return orig(config, ...)
        end
      end
    end
  '';

  plugins."haskell-tools" = {
    enable = true;
    autoLoad = true;
    hlsPackage = null;
  };

  plugins."haskell-scope-highlighting".enable = false;
}
