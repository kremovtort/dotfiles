{
  pkgs,
  lib,
  nvimInputs,
  ...
}:
let
  vcsignsVclib = pkgs.vimUtils.buildVimPlugin {
    name = "vcsigns-vclib-nvim";
    src = nvimInputs.plugins-vclib-nvim;
  };

  vcsigns = pkgs.vimUtils.buildVimPlugin {
    name = "vcsigns-nvim";
    src = nvimInputs.plugins-vcsigns-nvim;
    dependencies = [ vcsignsVclib ];
  };
in
{
  extraPlugins = [
    vcsignsVclib
    vcsigns
  ];

  extraConfigLua = lib.mkAfter ''
    require("vcsigns").setup({
      target_commit = 1,
    })
  '';

  keymaps = [
    {
      mode = "n";
      key = "[h";
      action.__raw = ''function() require("vcsigns.actions").hunk_prev(0, vim.v.count1) end'';
      options.desc = "Prev hunk";
    }
    {
      mode = "n";
      key = "]h";
      action.__raw = ''function() require("vcsigns.actions").hunk_next(0, vim.v.count1) end'';
      options.desc = "Next hunk";
    }
    {
      mode = "n";
      key = "[H";
      action.__raw = ''function() require("vcsigns.actions").hunk_prev(0, 9999) end'';
      options.desc = "First hunk";
    }
    {
      mode = "n";
      key = "]H";
      action.__raw = ''function() require("vcsigns.actions").hunk_next(0, 9999) end'';
      options.desc = "Last hunk";
    }
    {
      mode = "n";
      key = "[r";
      action.__raw = ''function() require("vcsigns.actions").target_older_commit(0, vim.v.count1) end'';
      options.desc = "Target older revision";
    }
    {
      mode = "n";
      key = "]r";
      action.__raw = ''function() require("vcsigns.actions").target_newer_commit(0, vim.v.count1) end'';
      options.desc = "Target newer revision";
    }
    {
      mode = "n";
      key = "<leader>ju";
      action.__raw = ''function() require("vcsigns.actions").hunk_undo(0) end'';
      options.desc = "Undo hunks under cursor";
    }
    {
      mode = [ "v" ];
      key = "<leader>ju";
      action.__raw = ''function() require("vcsigns.actions").hunk_undo(0) end'';
      options.desc = "Undo hunks in range";
    }
    {
      mode = "n";
      key = "<leader>uj";
      action.__raw = ''function() require("vcsigns.actions").toggle_hunk_diff(0) end'';
      options.desc = "Toggle inline hunk diff";
    }
    {
      mode = "n";
      key = "<leader>jf";
      action.__raw = ''function() require("vcsigns.fold").toggle(0) end'';
      options.desc = "Fold outside hunks";
    }
  ];
}
