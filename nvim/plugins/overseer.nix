{ pkgs, lib, ... }:
{
  extraPlugins = [ pkgs.vimPlugins.overseer-nvim ];

  extraConfigLua = lib.mkAfter ''
    require("overseer").setup({
      dap = false,
      task_list = {
        bindings = {
          ["<C-h>"] = false,
          ["<C-j>"] = false,
          ["<C-k>"] = false,
          ["<C-l>"] = false,
        },
      },
      form = {
        win_opts = {
          winblend = 0,
        },
      },
      confirm = {
        win_opts = {
          winblend = 0,
        },
      },
      task_win = {
        win_opts = {
          winblend = 0,
        },
      },
    })
  '';

  keymaps = [
    {
      mode = "n";
      key = "<leader>ow";
      action = "<cmd>OverseerToggle<cr>";
      options.desc = "Task list";
    }
    {
      mode = "n";
      key = "<leader>oo";
      action = "<cmd>OverseerRun<cr>";
      options.desc = "Run task";
    }
    {
      mode = "n";
      key = "<leader>oq";
      action = "<cmd>OverseerQuickAction<cr>";
      options.desc = "Action recent task";
    }
    {
      mode = "n";
      key = "<leader>oi";
      action = "<cmd>OverseerInfo<cr>";
      options.desc = "Overseer Info";
    }
    {
      mode = "n";
      key = "<leader>ob";
      action = "<cmd>OverseerBuild<cr>";
      options.desc = "Task builder";
    }
    {
      mode = "n";
      key = "<leader>ot";
      action = "<cmd>OverseerTaskAction<cr>";
      options.desc = "Task action";
    }
    {
      mode = "n";
      key = "<leader>oc";
      action = "<cmd>OverseerClearCache<cr>";
      options.desc = "Clear cache";
    }
  ];
}
