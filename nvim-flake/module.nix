{ inputs, ... }:
let
  # Build opencode-nvim plugin from flake input
  mkOpencodePlugin = pkgs: pkgs.vimUtils.buildVimPlugin {
    name = "opencode-nvim";
    src = inputs.plugins-opencode-nvim;
    dependencies = with pkgs.vimPlugins; [
      plenary-nvim
      nui-nvim
    ];
  };
in
{ pkgs, ... }:
{
  imports = [
    inputs.nixvim.homeModules.nixvim
    ./plugins.nix
    ./keymaps.nix
  ];

  programs.nixvim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;

    # =========================================================================
    # Global variables
    # =========================================================================
    globals = {
      mapleader = " ";
      maplocalleader = "\\";
    };

    # =========================================================================
    # Options (converted from lua/config/options.lua)
    # =========================================================================
    opts = {
      autoread = true;
      autowrite = true;
      clipboard = {
        __raw = ''vim.env.SSH_CONNECTION and "" or "unnamedplus"'';
      };
      completeopt = "menu,menuone,noselect";
      conceallevel = 2;
      confirm = true;
      cursorline = true;
      expandtab = true;
      fillchars = "foldopen: ,foldclose: ,fold: ,foldsep: ,diff:╱,eob: ";
      foldlevel = 99;
      foldmethod = "indent";
      formatoptions = "jcroqlnt";
      grepformat = "%f:%l:%c:%m";
      grepprg = "rg --vimgrep";
      ignorecase = true;
      inccommand = "nosplit";
      jumpoptions = "view";
      laststatus = 3;
      linebreak = true;
      list = true;
      mouse = "a";
      number = true;
      pumblend = 10;
      pumheight = 10;
      relativenumber = true;
      ruler = false;
      scrolloff = 4;
      sessionoptions = [ "buffers" "curdir" "tabpages" "winsize" "help" "globals" "skiprtp" "folds" ];
      shiftround = true;
      shiftwidth = 2;
      showmode = false;
      sidescrolloff = 8;
      signcolumn = "yes";
      smartcase = true;
      smartindent = true;
      smoothscroll = true;
      spelllang = [ "en" ];
      spell = false;
      splitbelow = true;
      splitkeep = "screen";
      splitright = true;
      tabstop = 2;
      termguicolors = true;
      timeoutlen = 300;
      undofile = true;
      undolevels = 10000;
      updatetime = 200;
      virtualedit = "block";
      wildmode = "longest:full,full";
      winminwidth = 5;
      wrap = false;
      breakindent = true;
      breakindentopt = "shift:4";
    };

    # =========================================================================
    # Colorscheme
    # =========================================================================
    colorschemes.catppuccin = {
      enable = true;
      settings = {
        flavour = "mocha";
        color_overrides = {
          mocha = {
            base = "#1c1c1c";
            mantle = "#161616";
            crust = "#101010";
            surface0 = "#2c2c2c";
            surface1 = "#3c3c3c";
            surface2 = "#4c4c4c";
            overlay0 = "#606060";
            overlay1 = "#757575";
            overlay2 = "#8a8a8a";
          };
        };
      };
    };

    # =========================================================================
    # Autocommands
    # =========================================================================
    autoGroups.kremovtort_autocmds.clear = true;

    autoCmd = [
      {
        event = "TextYankPost";
        group = "kremovtort_autocmds";
        callback.__raw = ''
          function()
            vim.highlight.on_yank({ timeout = 200 })
          end
        '';
      }
      {
        event = "VimResized";
        group = "kremovtort_autocmds";
        callback.__raw = ''
          function()
            vim.cmd("tabdo wincmd =")
          end
        '';
      }
      # Terminal buffer settings
      {
        event = "TermOpen";
        group = "kremovtort_autocmds";
        callback.__raw = ''
          function()
            vim.opt_local.number = false
            vim.opt_local.relativenumber = false
            vim.opt_local.signcolumn = "no"
            vim.cmd("startinsert")
          end
        '';
      }
      {
        event = "BufEnter";
        group = "kremovtort_autocmds";
        pattern = "term://*";
        callback.__raw = ''
          function()
            vim.opt_local.number = false
            vim.opt_local.relativenumber = false
            vim.cmd("startinsert")
          end
        '';
      }
      # Cursor-agent buffer settings
      {
        event = "BufEnter";
        group = "kremovtort_autocmds";
        pattern = "term://*";
        callback.__raw = ''
          function()
            if vim.b.cursor_agent then
              vim.opt_local.scrolloff = 0
              vim.cmd("startinsert")
            end
          end
        '';
      }
    ];

    # =========================================================================
    # User commands
    # =========================================================================
    userCommands = {
      CursorAgent = {
        desc = "Open Cursor Agent in terminal buffer";
        command.__raw = ''
          function()
            vim.cmd("enew")
            vim.fn.termopen("cursor-agent")
            vim.opt_local.scrolloff = 0
            vim.b.cursor_agent = true
            vim.cmd("startinsert")
          end
        '';
      };
    };

    # =========================================================================
    # LSP servers
    # =========================================================================
    plugins.lsp = {
      enable = true;
      servers = {
        lua_ls = {
          enable = true;
          config = {
            Lua = {
              telemetry.enabled = false;
              diagnostics.globals = [ "vim" ];
            };
          };
        };
        nixd.enable = true;
        bashls.enable = true;
      };
    };

    # =========================================================================
    # Extra plugins (not in NixVim modules)
    # =========================================================================
    extraPlugins = [
      (mkOpencodePlugin pkgs)
    ];

    # =========================================================================
    # Runtime dependencies
    # =========================================================================
    extraPackages = with pkgs; [
      ripgrep
      fd
      tree-sitter
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

      -- shortmess append
      vim.opt.shortmess:append({ W = true, I = true, c = true, C = true })
    '';

    extraConfigLua = ''
      -- opencode.nvim
      require("opencode").setup({
        keymap_prefix = '<leader>a'
      })

      -- mini.icons mock for nvim-web-devicons
      require("mini.icons").mock_nvim_web_devicons()
    '';
  };
}
