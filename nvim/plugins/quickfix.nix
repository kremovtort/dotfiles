{ ... }:
{
  plugins.nvim-bqf = {
    enable = true;
    settings = {
      auto_resize_height = true;
    };
  };

  plugins.quicker = {
    enable = true;
    autoLoad = true;
    settings = {
      use_default_opts = true;
      on_qf.__raw = ''
        function(bufnr)
          vim.keymap.set("n", "q", "<cmd>close<cr>", {
            buffer = bufnr,
            silent = true,
            nowait = true,
            desc = "Close quickfix",
          })
        end
      '';
    };
  };
}
