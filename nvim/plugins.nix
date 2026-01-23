# NixVim plugins configuration
{ pkgs, nvimInputs, ... }:
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
  programs.nixvim = {
    extraPlugins = [
      pkgs.vimPlugins.nvim-scrollbar
      vcsignsVclib
      vcsigns
    ];

    extraConfigLua = ''
      require("scrollbar").setup()

      require("vcsigns").setup({
        target_commit = 1,
      })
    '';

    plugins = {
      auto-save = {
        enable = true;
        autoLoad = true;
      };

      # Treesitter
      treesitter = {
        enable = true;
        settings = {
          highlight.enable = true;
          indent.enable = true;
        };
      };

      # Completion
      supermaven = {
        enable = true;
        autoLoad = true;
        settings = {
          disable_inline_completion = true;
          disable_keymaps = true;
        };
      };

      blink-cmp = {
        enable = true;
        settings = {
          snippets.preset = "default";
          appearance = {
            use_nvim_cmp_as_default = false;
            nerd_font_variant = "mono";
          };
          completion = {
            accept.auto_brackets.enabled = true;
            menu.draw.treesitter = [ "lsp" ];
            documentation = {
              auto_show = true;
              auto_show_delay_ms = 200;
            };
          };
          sources = {
            default = [
              "lsp"
              "supermaven"
              "path"
              "snippets"
              "buffer"
            ];
            providers = {
              supermaven = {
                name = "supermaven";
                module = "blink.compat.source";
                score_offset = 100;
              };
            };
          };
          cmdline = {
            enabled = true;
            keymap.preset = "cmdline";
            completion = {
              list.selection.preselect = false;
              menu.auto_show.__raw = ''
                function()
                  return vim.fn.getcmdtype() == ":"
                end
              '';
              ghost_text.enabled = true;
            };
          };
          keymap = {
            preset = "enter";
            "<C-y>" = [ "select_and_accept" ];
          };
        };
      };

      # which-key
      which-key = {
        enable = true;
        settings = {
          preset = "helix";
          spec = [
            {
              __unkeyed-1 = "<leader><tab>";
              group = "tabs";
            }
            {
              __unkeyed-1 = "<leader>a";
              group = "agent";
              icon = "";
            }
            {
              __unkeyed-1 = "<leader>at";
              group = "toggle";
              icon = "";
            }
            {
              __unkeyed-1 = "<leader>aP";
              group = "permissions";
            }
            {
              __unkeyed-1 = "<leader>ar";
              group = "revert";
            }
            {
              __unkeyed-1 = "<leader>b";
              group = "buffers";
            }
            {
              __unkeyed-1 = "<leader>c";
              group = "code";
            }
            {
              __unkeyed-1 = "<leader>d";
              group = "debug";
            }
            {
              __unkeyed-1 = "<leader>dp";
              group = "profiler";
            }
            {
              __unkeyed-1 = "<leader>f";
              group = "file/find";
            }
            {
              __unkeyed-1 = "<leader>g";
              group = "git";
            }
            {
              __unkeyed-1 = "<leader>j";
              group = "vcs";
              icon = "";
            }
            {
              __unkeyed-1 = "<leader>gh";
              group = "hunks";
            }
            {
              __unkeyed-1 = "<leader>q";
              group = "quit/session";
            }
            {
              __unkeyed-1 = "<leader>s";
              group = "search";
            }
            {
              __unkeyed-1 = "<leader>sn";
              group = "noice";
            }
            {
              __unkeyed-1 = "<leader>u";
              group = "ui";
            }
            {
              __unkeyed-1 = "<leader>x";
              group = "diagnostics/quickfix";
            }
            {
              __unkeyed-1 = "[";
              group = "prev";
            }
            {
              __unkeyed-1 = "]";
              group = "next";
            }
            {
              __unkeyed-1 = "g";
              group = "goto";
            }
            {
              __unkeyed-1 = "gz";
              group = "surround";
            }
            {
              __unkeyed-1 = "z";
              group = "fold";
            }
            {
              __unkeyed-1 = "gx";
              desc = "Open with system app";
            }
          ];
        };
      };

      # noice
      noice = {
        enable = true;
        settings = {
          lsp.override = {
            "vim.lsp.util.convert_input_to_markdown_lines" = true;
            "vim.lsp.util.stylize_markdown" = true;
            "cmp.entry.get_documentation" = true;
          };
          routes = [
            {
              filter = {
                event = "msg_show";
                any = [
                  { find = "%d+L, %d+B"; }
                  { find = "; after #%d+"; }
                  { find = "; before #%d+"; }
                ];
              };
              view = "mini";
            }
          ];
          presets = {
            bottom_search = true;
            command_palette = true;
            long_message_to_split = true;
          };
        };
      };

      # notify
      notify = {
        enable = true;
      };

      # Mini plugins
      mini-icons = {
        enable = true;
        autoLoad = true;
        settings = {
          file = {
            ".keep" = {
              glyph = "󰊢";
              hl = "MiniIconsGrey";
            };
            "devcontainer.json" = {
              glyph = "";
              hl = "MiniIconsAzure";
            };
          };
          filetype = {
            dotenv = {
              glyph = "";
              hl = "MiniIconsYellow";
            };
          };
        };
      };

      mini-pairs = {
        enable = true;
        autoLoad = true;
        settings = {
          modes = {
            insert = true;
            command = true;
            terminal = false;
          };
        };
      };

      mini-ai = {
        enable = true;
        autoLoad = true;
        settings = {
          n_lines = 500;
        };
      };

      mini-diff = {
        enable = false;
        autoLoad = true;
      };

      mini-surround = {
        enable = true;
        autoLoad = true;
        settings = {
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

      web-devicons.enable = true;

      # Leap
      leap.enable = true;

      # Flit (f/t motions with leap)
      flit = {
        enable = true;
        settings.labeled_modes = "nx";
      };

      # Hunk (diff editing)
      hunk = {
        enable = true;
        settings = {
          keys = {
            global = {
              quit = [ "q" ];
              accept = [ "<leader><Cr>" ];
              focus_tree = [ "<leader>e" ];
            };
            tree = {
              expand_node = [
                "l"
                "<Right>"
              ];
              collapse_node = [
                "h"
                "<Left>"
              ];
              open_file = [ "<Cr>" ];
              toggle_file = [ "a" ];
            };
            diff = {
              toggle_hunk = [ "A" ];
              toggle_line = [ "a" ];
              toggle_line_pair = [ "s" ];
              prev_hunk = [ "[h" ];
              next_hunk = [ "]h" ];
              toggle_focus = [ "<Tab>" ];
            };
          };
          ui = {
            tree = {
              mode = "nested";
              width = 35;
            };
            layout = "vertical";
          };
          icons = {
            enable_file_icons = true;
            selected = "󰡖";
            deselected = "";
            partially_selected = "󰛲";
            folder_open = "";
            folder_closed = "";
            expanded = "";
            collapsed = "";
          };
        };
      };

      # ts-comments
      ts-context-commentstring.enable = true;

      # grug-far
      grug-far = {
        enable = true;
        settings = {
          headerMaxWidth = 80;
        };
      };

      # snacks
      snacks = {
        enable = true;
        settings = {
          bigfile.enabled = true;
          dashboard = {
            enabled = true;

            # Dashboard-local keybindings (no <leader>)
            preset.keys = [
              {
                icon = " ";
                key = "n";
                desc = "New File";
                action = ":ene | startinsert";
              }
              {
                icon = " ";
                key = "p";
                desc = "Projects";
                action = ":lua Snacks.picker.projects()";
              }
              {
                icon = " ";
                key = "r";
                desc = "Recent Files";
                action = ":lua Snacks.dashboard.pick('oldfiles')";
              }
              {
                icon = " ";
                key = "s";
                desc = "Restore Session";
                action = ":AutoSession restore";
              }
              {
                icon = " ";
                key = "q";
                desc = "Quit";
                action = ":qa";
              }
            ];

            sections = [
              { section = "header"; }
              {
                section = "keys";
                gap = 1;
                padding = 1;
              }
              {
                icon = " ";
                title = "Recent Files";
                section = "recent_files";
                indent = 2;
                padding = 1;
              }
              {
                icon = " ";
                title = "Projects";
                section = "projects";
                indent = 2;
                padding = 1;
              }
            ];
          };
          indent.enabled = true;
          input.enabled = true;
          notifier.enabled = true;
          quickfile.enabled = true;
          picker = {
            enabled = true;
            win.input.keys = {
              "<a-c>" = {
                __unkeyed-1 = "toggle_cwd";
                mode = [
                  "n"
                  "i"
                ];
              };
            };
            actions.toggle_cwd.__raw = ''
              function(p)
                local root = vim.fs.root(p.input.filter.current_buf, { ".git", ".jj" })
                  or vim.fs.normalize((vim.uv or vim.loop).cwd() or ".")
                local cwd = vim.fs.normalize((vim.uv or vim.loop).cwd() or ".")
                local current = p:cwd()
                p:set_cwd(current == root and cwd or root)
                p:find()
              end
            '';
          };
          scope.enabled = true;
          scroll.enabled = false;
          statuscolumn.enabled = false;
          words.enabled = true;
          terminal.win.keys = { };
        };
      };

      # render-markdown
      render-markdown = {
        enable = true;
        settings = {
          anti_conceal.enabled = false;
          file_types = [
            "markdown"
            "opencode_output"
          ];
        };
      };

      # Haskell tools
      haskell-tools = {
        enable = true;
        settings = {
          hls = {
            default_settings.haskell = {
              formatting_provider = "fourmolu";
            };
          };
        };
        autoLoad = true;
      };

      haskell-scope-highlighting.enable = false;

      # edgy
      edgy = {
        enable = false;
        autoLoad = true;
        settings = {
          animate.enabled = false;
          bottom.__raw = ''
            {
              {
                ft = "toggleterm",
                size = { height = 0.4 },
                wo = { winhighlight = "Normal:Normal,NormalNC:Normal", winblend = 0 },
                filter = function(_, win)
                  return vim.api.nvim_win_get_config(win).relative == ""
                end,
              },
              {
                ft = "noice",
                size = { height = 0.4 },
                filter = function(_, win)
                  return vim.api.nvim_win_get_config(win).relative == ""
                end,
              },
              "Trouble",
              { ft = "qf", title = "QuickFix" },
              {
                ft = "help",
                size = { height = 20 },
                filter = function(buf)
                  return vim.bo[buf].buftype == "help"
                end,
              },
              { title = "Neotest Output", ft = "neotest-output-panel", size = { height = 15 } },
            }
          '';
          left.__raw = ''
            {
              { title = "Explorer", ft = "neo-tree" },
              { title = "Test Summary", ft = "neotest-summary" },
            }
          '';
          right.__raw = ''
            {
              { title = "Grug Far", ft = "grug-far", size = { width = 0.4 } },
              { 
                title = "Opencode",
                ft = "opencode_output",
                size = { width = 0.4 },
                wo = {
                  winhighlight = "Normal:Normal,NormalNC:Normal",
                  winblend = 0
                }
              },
              { 
                title = "Opencode",
                ft = "opencode",
                size = { width = 0.4, height = 8 },
                wo = {
                  winhighlight = "Normal:Normal,NormalNC:Normal",
                  winblend = 0
                }
              },
            }
          '';
          keys.__raw = ''
            {
              ["<c-Right>"] = function(win) win:resize("width", 2) end,
              ["<c-Left>"] = function(win) win:resize("width", -2) end,
              ["<c-Up>"] = function(win) win:resize("height", 2) end,
              ["<c-Down>"] = function(win) win:resize("height", -2) end,
            }
          '';
        };
        luaConfig.post = ''
          -- Add trouble and snacks_terminal windows dynamically
          local edgy_config = require("edgy.config")
          for _, pos in ipairs({ "top", "bottom", "left", "right" }) do
            edgy_config.options[pos] = edgy_config.options[pos] or {}
            -- trouble windows
            table.insert(edgy_config.options[pos], {
              ft = "trouble",
              filter = function(_, win)
                return vim.w[win].trouble
                  and vim.w[win].trouble.position == pos
                  and vim.w[win].trouble.type == "split"
                  and vim.w[win].trouble.relative == "editor"
                  and not vim.w[win].trouble_preview
              end,
            })
            -- snacks terminal windows
            table.insert(edgy_config.options[pos], {
              ft = "snacks_terminal",
              size = { height = 0.4 },
              title = "%{b:snacks_terminal.id}: %{b:term_title}",
              filter = function(_, win)
                return vim.w[win].snacks_win
                  and vim.w[win].snacks_win.position == pos
                  and vim.w[win].snacks_win.relative == "editor"
                  and not vim.w[win].trouble_preview
              end,
            })
          end
        '';
      };

      neo-tree = {
        enable = true;
        settings = {
          filesystem.follow_current_file.enabled = true;
          window = {
            mappings = {
              h = "close_node";
              l = "open";
            };
          };
          default_component_configs = {
            indent = {
              with_expanders = true;
              expander_collapsed = "";
              expander_expanded = "";
              expander_highlight = "NeoTreeExpander";
            };
          };
          git_status = {
            symbols = {
              unstaged = "󰄱";
              staged = "󰱒";
            };
          };
        };
      };

      # Toggleterm
      toggleterm = {
        enable = true;
        settings = {
          direction = "float";
          open_mapping = null; # We'll use custom keymaps
          shade_terminals = false;
          highlights = {
            Normal = {
              link = "Normal";
            };
            NormalFloat = {
              link = "NormalFloat";
            };
            FloatBorder = {
              link = "FloatBorder";
            };
          };
        };
      };

      repeat.enable = true;
      friendly-snippets.enable = true;
      blink-compat.enable = true;

      auto-session = {
        enable = true;
        settings = {
          auto_restore = false;
          auto_save = true;
          bypass_save_filetypes = [
            "snacks_dashboard"
            "dashboard"
            "alpha"
          ];
          suppressed_dirs = [
            "~/"
            "~/Projects"
            "~/Downloads"
            "/"
          ];
          args_allow_single_directory = true;
          args_allow_files_auto_save = false;
        };
      };

      yanky = {
        enable = true;
        autoLoad = true;
      };

      # OpenCode plugin selection lives in `nvim/opencode/*` provider modules.
      # UI helpers for OpenCode remain configured above (edgy panes, render-markdown filetypes).

    };
  };
}
