# Minimal NixVim configuration for VSCode integration
{ pkgs, ... }:
{
  # =========================================================================
  # Global variables
  # =========================================================================
  globals = {
    mapleader = " ";
    maplocalleader = "\\";
  };

  # =========================================================================
  # Options (minimal set for VSCode)
  # =========================================================================
  opts = {
    clipboard = "unnamedplus";
    ignorecase = true;
    smartcase = true;
    timeoutlen = 1000; # VSCode needs longer timeout
    undofile = true;
    undolevels = 10000;
  };

  # =========================================================================
  # Plugins (motion/text objects only)
  # =========================================================================
  plugins = {
    # Treesitter (needed for ts-context-commentstring)
    treesitter = {
      enable = true;
      settings = {
        highlight.enable = false; # VSCode handles highlighting
        indent.enable = false;
      };
    };

    # Leap (motion)
    leap.enable = true;

    # Flit (f/t with leap)
    flit = {
      enable = true;
      settings.labeled_modes = "nx";
    };

    # Mini plugins
    mini = {
      enable = true;
      modules = {
        ai.n_lines = 500;
        surround = {
          mappings = {
            add = "gza";
            delete = "gzd";
            find = "gzf";
            find_left = "gzF";
            highlight = "gzh";
            replace = "gzr";
            update_n_lines = "gzn";
          };
        };
      };
    };

    # ts-context-commentstring
    ts-context-commentstring.enable = true;

    # repeat.nvim
    repeat.enable = true;
  };

  # =========================================================================
  # Keymaps
  # =========================================================================
  keymaps = [
    # Leap motions
    {
      mode = [
        "n"
        "x"
        "o"
      ];
      key = "s";
      action = "<Plug>(leap-forward)";
      options.desc = "Leap forward";
    }
    {
      mode = [
        "n"
        "x"
        "o"
      ];
      key = "S";
      action = "<Plug>(leap-backward)";
      options.desc = "Leap backward";
    }
    # Russian layout
    {
      mode = [
        "n"
        "x"
        "o"
      ];
      key = "ы";
      action = "<Plug>(leap-forward)";
      options.desc = "Leap forward";
    }
    {
      mode = [
        "n"
        "x"
        "o"
      ];
      key = "Ы";
      action = "<Plug>(leap-backward)";
      options.desc = "Leap backward";
    }

    # Window navigation (Ctrl+hjkl) - VSCode commands
    {
      mode = [
        "n"
        "x"
      ];
      key = "<C-h>";
      action = "<Cmd>call VSCodeNotify('workbench.action.navigateLeft')<CR>";
      options.desc = "Navigate left";
    }
    {
      mode = [
        "n"
        "x"
      ];
      key = "<C-j>";
      action = "<Cmd>call VSCodeNotify('workbench.action.navigateDown')<CR>";
      options.desc = "Navigate down";
    }
    {
      mode = [
        "n"
        "x"
      ];
      key = "<C-k>";
      action = "<Cmd>call VSCodeNotify('workbench.action.navigateUp')<CR>";
      options.desc = "Navigate up";
    }
    {
      mode = [
        "n"
        "x"
      ];
      key = "<C-l>";
      action = "<Cmd>call VSCodeNotify('workbench.action.navigateRight')<CR>";
      options.desc = "Navigate right";
    }

    # VSCode folding
    {
      mode = "n";
      key = "zM";
      action = "<Cmd>call VSCodeNotify('editor.foldAll')<CR>";
      options = {
        noremap = true;
        silent = true;
        desc = "Fold all";
      };
    }
    {
      mode = "n";
      key = "zR";
      action = "<Cmd>call VSCodeNotify('editor.unfoldAll')<CR>";
      options = {
        noremap = true;
        silent = true;
        desc = "Unfold all";
      };
    }
    {
      mode = "n";
      key = "zc";
      action = "<Cmd>call VSCodeNotify('editor.fold')<CR>";
      options = {
        noremap = true;
        silent = true;
        desc = "Fold";
      };
    }
    {
      mode = "n";
      key = "zC";
      action = "<Cmd>call VSCodeNotify('editor.foldRecursively')<CR>";
      options = {
        noremap = true;
        silent = true;
        desc = "Fold recursively";
      };
    }
    {
      mode = "n";
      key = "zo";
      action = "<Cmd>call VSCodeNotify('editor.unfold')<CR>";
      options = {
        noremap = true;
        silent = true;
        desc = "Unfold";
      };
    }
    {
      mode = "n";
      key = "zO";
      action = "<Cmd>call VSCodeNotify('editor.unfoldRecursively')<CR>";
      options = {
        noremap = true;
        silent = true;
        desc = "Unfold recursively";
      };
    }
    {
      mode = "n";
      key = "za";
      action = "<Cmd>call VSCodeNotify('editor.toggleFold')<CR>";
      options = {
        noremap = true;
        silent = true;
        desc = "Toggle fold";
      };
    }

    # VSCode error navigation
    {
      mode = "n";
      key = "]e";
      action = "<Cmd>call VSCodeNotify('editor.action.marker.next')<CR>";
      options = {
        noremap = true;
        silent = true;
        desc = "Next error";
      };
    }
    {
      mode = "n";
      key = "[e";
      action = "<Cmd>call VSCodeNotify('editor.action.marker.prev')<CR>";
      options = {
        noremap = true;
        silent = true;
        desc = "Prev error";
      };
    }
    {
      mode = "n";
      key = "]E";
      action = "<Cmd>call VSCodeNotify('editor.action.marker.nextInFiles')<CR>";
      options = {
        noremap = true;
        silent = true;
        desc = "Next error in files";
      };
    }
    {
      mode = "n";
      key = "[E";
      action = "<Cmd>call VSCodeNotify('editor.action.marker.prevInFiles')<CR>";
      options = {
        noremap = true;
        silent = true;
        desc = "Prev error in files";
      };
    }

    # VSCode window/explorer
    {
      mode = "n";
      key = "<C-w>q";
      action = "<Cmd>call VSCodeNotify('workbench.action.closeEditorsInGroup')<CR>";
      options = {
        noremap = true;
        silent = true;
        desc = "Close editors in group";
      };
    }
    {
      mode = "n";
      key = "<leader>e";
      action = "<Cmd>call VSCodeNotify('workbench.files.action.focusFilesExplorer')<CR>";
      options = {
        noremap = true;
        silent = true;
        desc = "Focus file explorer";
      };
    }

    # VSCode go to
    {
      mode = "n";
      key = "gr";
      action = "<Cmd>call VSCodeNotify('editor.action.goToReferences')<CR>";
      options = {
        noremap = true;
        silent = true;
        desc = "Go to references";
      };
    }
    {
      mode = "n";
      key = "gi";
      action = "<Cmd>call VSCodeNotify('editor.action.goToImplementation')<CR>";
      options = {
        noremap = true;
        silent = true;
        desc = "Go to implementation";
      };
    }
    {
      mode = "n";
      key = "gt";
      action = "<Cmd>call VSCodeNotify('editor.action.goToTypeDefinition')<CR>";
      options = {
        noremap = true;
        silent = true;
        desc = "Go to type definition";
      };
    }

    # VSCode symbols
    {
      mode = "n";
      key = "<leader>m";
      action = "<Cmd>call VSCodeNotify('haskell-modules.search')<CR>";
      options = {
        noremap = true;
        silent = true;
        desc = "Haskell modules search";
      };
    }
    {
      mode = "n";
      key = "<leader>s";
      action = "<Cmd>call VSCodeNotify('workbench.action.gotoSymbol')<CR>";
      options = {
        noremap = true;
        silent = true;
        desc = "Go to symbol";
      };
    }
    {
      mode = "n";
      key = "<leader>S";
      action = "<Cmd>call VSCodeNotify('workbench.action.showAllSymbols')<CR>";
      options = {
        noremap = true;
        silent = true;
        desc = "Show all symbols";
      };
    }
  ];

  # =========================================================================
  # Extra Lua configuration
  # =========================================================================
  extraConfigLuaPre = ''
    -- Russian keyboard layout support (langmap)
    local function escape(str)
      local escape_chars = [[;,."|\]]
      return vim.fn.escape(str, escape_chars)
    end

    local en = [[`qwertyuiop[]asdfghjkl;'zxcvbnm]]
    local ru = [[ёйцукенгшщзхъфывапролджэячсмить]]
    local en_shift = [[~QWERTYUIOP{}ASDFGHJKL:"ZXCVBNM<>]]
    local ru_shift = [[ËЙЦУКЕНГШЩЗХЪФЫВАПРОЛДЖЭЯЧСМИТЬБЮ]]

    vim.opt.langmap = vim.fn.join({
      escape(ru_shift) .. ";" .. escape(en_shift),
      escape(ru) .. ";" .. escape(en),
    }, ",")
  '';

}
