{ inputs, ... }:
let
  icons = import ./icons.nix;
  lib = inputs.nixvim.lib;
in
{ ... }:
{
  _module.args.nvimInputs = inputs;

  imports = [
    inputs.nixvim.homeModules.nixvim

    # OpenCode integration is split into provider modules.
    # Switch by swapping one import below.
    # ./opencode/provider-nickvandyke.nix
    ./opencode/provider-sudo-tee.nix

    ./plugins.nix
    ./plugins/langmapper.nix
    ./plugins/lualine.nix
    ./keymaps.nix
    ./autoCmd.nix
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
      maplocalleader = ",";
      icons.__raw = lib.nixvim.lua.toLuaObject icons;
    };

    # =========================================================================
    # Options (converted from lua/config/options.lua)
    # =========================================================================
    opts = {
      autoread = true;
      autowrite = true;
      clipboard.__raw = ''vim.env.SSH_CONNECTION and "" or "unnamedplus"'';
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
      sessionoptions = [
        "buffers"
        "curdir"
        "tabpages"
        "winsize"
        "help"
        "globals"
        "skiprtp"
        "folds"
      ];
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
        integrations = {
          blink_cmp = {
            enable = true;
          };
          neotree = true;
          leap = true;
        };
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
    # LSP servers
    # =========================================================================
    plugins.lsp = {
      enable = true;
      servers = {
        lua_ls = {
          enable = true;
          settings = {
            Lua = {
              telemetry.enabled = false;
              diagnostics.globals = [ "vim" ];

              # LazyVim-like defaults
              workspace.checkThirdParty = false;
              codeLens.enable = true;
              completion.callSnippet = "Replace";
              doc.privateName = [ "^_" ];
              hint = {
                enable = true;
                setType = false;
                paramType = true;
                paramName = "Disable";
                semicolon = "Disable";
                arrayIndex = "Disable";
              };
            };
          };
        };
        nixd.enable = true;
        bashls.enable = true;
      };
      # Adds to the generated `capabilities` table (for all servers)
      capabilities = ''
        capabilities.workspace = capabilities.workspace or {}
        capabilities.workspace.fileOperations = capabilities.workspace.fileOperations or {}
        capabilities.workspace.fileOperations.didRename = true
        capabilities.workspace.fileOperations.willRename = true
      '';

      # Runs for every buffer when a client attaches.
      # Args provided by nixvim: (client, bufnr)
      onAttach = ''
        -- LazyVim-like on_attach behavior
        if vim.bo[bufnr].buftype ~= "" then return end

        local inlay_hints_enabled = true
        local inlay_hints_exclude = { vue = true, haskell = true }
        local folds_enabled = true
        local codelens_enabled = false

        -- Inlay hints
        if inlay_hints_enabled
          and vim.lsp.inlay_hint
          and client.supports_method
          and client:supports_method("textDocument/inlayHint")
          and not inlay_hints_exclude[vim.bo[bufnr].filetype]
        then
          pcall(vim.lsp.inlay_hint.enable, true, { bufnr = bufnr })
        end

        -- Folds via LSP (foldmethod/foldexpr are window-local)
        if folds_enabled
          and client.supports_method
          and client:supports_method("textDocument/foldingRange")
        then
          local function apply_folds_to_windows()
            for _, win in ipairs(vim.fn.win_findbuf(bufnr)) do
              pcall(vim.api.nvim_set_option_value, "foldmethod", "expr", { win = win })
              pcall(vim.api.nvim_set_option_value, "foldexpr", "v:lua.vim.lsp.foldexpr()", { win = win })
            end
          end

          apply_folds_to_windows()

          vim.api.nvim_create_autocmd("BufWinEnter", {
            buffer = bufnr,
            callback = apply_folds_to_windows,
          })
        end

        -- Code lens
        if codelens_enabled
          and vim.lsp.codelens
          and client.supports_method
          and client:supports_method("textDocument/codeLens")
        then
          pcall(vim.lsp.codelens.refresh)
          vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "InsertLeave" }, {
            buffer = bufnr,
            callback = function()
              pcall(vim.lsp.codelens.refresh)
            end,
          })
        end
      '';

      luaConfig.post = ''
        -- Diagnostics (vim.diagnostic.config)
        do
          local diag = vim.g.icons.diagnostics

          vim.diagnostic.config({
            underline = true,
            update_in_insert = false,
            severity_sort = true,
            virtual_text = {
              spacing = 4,
              source = "if_many",
              prefix = "●",
            },
            signs = {
              text = {
                [vim.diagnostic.severity.ERROR] = diag.Error or "E",
                [vim.diagnostic.severity.WARN] = diag.Warn or "W",
                [vim.diagnostic.severity.HINT] = diag.Hint or "H",
                [vim.diagnostic.severity.INFO] = diag.Info or "I",
              },
            },
          })
        end
      '';
    };

    dependencies = {
      fd.enable = true;
      ripgrep.enable = true;
      tree-sitter.enable = true;
    };

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

      if vim.env.SSH_TTY or vim.env.SSH_CONNECTION then
        vim.o.clipboard = "unnamedplus"

        local function paste()
          return {
            vim.fn.split(vim.fn.getreg(""), "\n"),
            vim.fn.getregtype(""),
          }
        end

        vim.g.clipboard = {
          name = "OSC 52",
          copy = {
            ["+"] = require("vim.ui.clipboard.osc52").copy("+"),
            ["*"] = require("vim.ui.clipboard.osc52").copy("*"),
          },
          paste = {
            ["+"] = paste,
            ["*"] = paste,
          },
        }
      end
    '';
  };
}
