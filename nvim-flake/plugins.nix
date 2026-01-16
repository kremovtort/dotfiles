# NixVim plugins configuration
{
  programs.nixvim.plugins = {
    # UI
    lualine = {
      enable = true;
      settings = {
        options = {
          theme = "auto";
          globalstatus = true;
          disabled_filetypes = {
            statusline = [ "dashboard" "alpha" "ministarter" "snacks_dashboard" ];
          };
        };
        sections = {
          lualine_a = [ "mode" ];
          lualine_b = [ "branch" ];
          lualine_c = [
            {
              __unkeyed-1.__raw = ''
                function()
                  local root = vim.fs.root(0, { ".git" }) or vim.uv.cwd()
                  if not root or root == "" then return "" end
                  return vim.fn.fnamemodify(root, ":t")
                end
              '';
            }
            {
              __unkeyed-1 = "diagnostics";
              symbols = {
                error = " ";
                warn = " ";
                info = " ";
                hint = " ";
              };
            }
            {
              __unkeyed-1 = "filetype";
              icon_only = true;
              separator = "";
              padding = { left = 1; right = 0; };
            }
            {
              __unkeyed-1.__raw = ''
                function()
                  local name = vim.api.nvim_buf_get_name(0)
                  if name == "" then return "[No Name]" end
                  local root = vim.fs.root(0, { ".git" }) or vim.uv.cwd() or ""
                  local rel = name
                  if root ~= "" and name:sub(1, #root + 1) == root .. "/" then
                    rel = name:sub(#root + 2)
                  else
                    rel = vim.fn.fnamemodify(name, ":~")
                  end
                  rel = vim.fn.pathshorten(rel)
                  if vim.bo.modified then rel = rel .. " [+]" end
                  return rel
                end
              '';
            }
          ];
          lualine_x = [
            {
              __unkeyed-1 = "diff";
              symbols = {
                added = " ";
                modified = " ";
                removed = " ";
              };
              source.__raw = ''
                function()
                  local gitsigns = vim.b.gitsigns_status_dict
                  if gitsigns then
                    return {
                      added = gitsigns.added,
                      modified = gitsigns.changed,
                      removed = gitsigns.removed,
                    }
                  end
                end
              '';
            }
          ];
          lualine_y = [
            { __unkeyed-1 = "progress"; separator = " "; padding = { left = 1; right = 0; }; }
            { __unkeyed-1 = "location"; padding = { left = 0; right = 1; }; }
          ];
          lualine_z = [
            {
              __unkeyed-1.__raw = ''
                function()
                  return " " .. os.date("%R")
                end
              '';
            }
          ];
        };
        extensions = [ "neo-tree" "lazy" "fzf" ];
      };
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
          default = [ "lsp" "path" "snippets" "buffer" ];
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
          { __unkeyed-1 = "<leader><tab>"; group = "tabs"; }
          { __unkeyed-1 = "<leader>c"; group = "code"; }
          { __unkeyed-1 = "<leader>d"; group = "debug"; }
          { __unkeyed-1 = "<leader>dp"; group = "profiler"; }
          { __unkeyed-1 = "<leader>f"; group = "file/find"; }
          { __unkeyed-1 = "<leader>g"; group = "git"; }
          { __unkeyed-1 = "<leader>gh"; group = "hunks"; }
          { __unkeyed-1 = "<leader>q"; group = "quit/session"; }
          { __unkeyed-1 = "<leader>s"; group = "search"; }
          { __unkeyed-1 = "<leader>sn"; group = "noice"; }
          { __unkeyed-1 = "<leader>u"; group = "ui"; }
          { __unkeyed-1 = "<leader>x"; group = "diagnostics/quickfix"; }
          { __unkeyed-1 = "["; group = "prev"; }
          { __unkeyed-1 = "]"; group = "next"; }
          { __unkeyed-1 = "g"; group = "goto"; }
          { __unkeyed-1 = "gz"; group = "surround"; }
          { __unkeyed-1 = "z"; group = "fold"; }
          { __unkeyed-1 = "gx"; desc = "Open with system app"; }
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
    mini = {
      enable = true;
      modules = {
        icons = {
          file = {
            ".keep" = { glyph = "󰊢"; hl = "MiniIconsGrey"; };
            "devcontainer.json" = { glyph = ""; hl = "MiniIconsAzure"; };
          };
          filetype = {
            dotenv = { glyph = ""; hl = "MiniIconsYellow"; };
          };
        };
        pairs = {
          modes = { insert = true; command = true; terminal = false; };
        };
        ai = {
          n_lines = 500;
        };
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
            expand_node = [ "l" "<Right>" ];
            collapse_node = [ "h" "<Left>" ];
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
          tree = { mode = "nested"; width = 35; };
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
        dashboard.enabled = false;
        indent.enabled = true;
        input.enabled = true;
        notifier.enabled = true;
        quickfile.enabled = true;
        picker = {
          enabled = true;
          win.input.keys = {
            "<a-c>" = {
              __unkeyed-1 = "toggle_cwd";
              mode = [ "n" "i" ];
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
        file_types = [ "markdown" "opencode_output" ];
      };
    };

    # Haskell tools
    haskell-tools = {
      enable = true;
      settings = {
        hls.settings.haskell.plugin.importLens.globalOn = false;
      };
    };

    # edgy
    edgy = {
      enable = true;
      autoLoad = true;
      settings = {
        animate.enabled = false;
        bottom.__raw = ''
          {
            {
              ft = "toggleterm",
              size = { height = 0.4 },
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
            { title = "Spectre", ft = "spectre_panel", size = { height = 0.4 } },
            { title = "Neotest Output", ft = "neotest-output-panel", size = { height = 15 } },
          }
        '';
        left.__raw = ''
          {
            { title = "Neotest Summary", ft = "neotest-summary" },
          }
        '';
        right.__raw = ''
          {
            { title = "Grug Far", ft = "grug-far", size = { width = 0.4 } },
            { title = "Opencode", ft = "opencode_output", size = { width = 0.4 } },
            { title = "Opencode", ft = "opencode", size = { width = 0.4 } },
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
        window = {
          mappings = {
            h = "close_node";
            l = "open";
          };
        };
      };
    };

    scrollbar = {
      enable = true;
    };
    repeat.enable = true;
    friendly-snippets.enable = true;
    blink-compat.enable = true;
  };
}
