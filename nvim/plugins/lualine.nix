{ ... }:
let
  icons = import ../icons.nix;
in
{
  plugins.lualine = {
    enable = true;

    luaConfig.post = ''
      -- Lualine: nicer terminal buffer names + highlighting
      do
        local function set_lualine_term_hl()
          local function link(from, to)
            pcall(vim.api.nvim_set_hl, 0, from, { link = to, default = true })
          end

          link("LualineTermNumber", "Number")
          link("LualineTermCommand", "String")
          link("LualineTermCwd", "Directory")

          -- Make lualine_c separator slightly darker than normal text.
          -- Derive from existing lualine theme groups so it follows colorscheme.
          local ok, hls = pcall(vim.api.nvim_get_hl, 0, { name = "lualine_c_normal" })
          if ok and hls and hls.fg and hls.bg then
            local fg = hls.fg
            local bg = hls.bg
            local function mix(a, b, t)
              return math.floor(a + (b - a) * t + 0.5)
            end
            local function blend(c1, c2, t)
              return {
                r = mix(bit.rshift(c1, 16) % 256, bit.rshift(c2, 16) % 256, t),
                g = mix(bit.rshift(c1, 8) % 256, bit.rshift(c2, 8) % 256, t),
                b = mix(c1 % 256, c2 % 256, t),
              }
            end
            local blended = blend(fg, bg, 0.55)
            local hex = string.format("#%02x%02x%02x", blended.r, blended.g, blended.b)
            pcall(vim.api.nvim_set_hl, 0, "LualineCSeparator", { fg = hex, bg = hls.bg, default = true })
          else
            pcall(vim.api.nvim_set_hl, 0, "LualineCSeparator", { link = "Comment", default = true })
          end
        end

        local function trim(s)
          return (s or ""):gsub("^%s+", ""):gsub("%s+$", "")
        end

        local function update_lualine_jj_branch()
          local ok_jj, jj_root = pcall(vim.fs.root, 0, { ".jj" })
          if not (ok_jj and jj_root and jj_root ~= "") then
            vim.g.__lualine_jj_branch = nil
            pcall(require("lualine").refresh)
            return
          end

          local function run_async(cmd, cb)
            vim.system(cmd, { text = true, cwd = jj_root }, function(res)
              cb(trim(res.stdout), res.code)
            end)
          end

          run_async({
            "jj",
            "log",
            "-r",
            "heads(::@ & bookmarks())",
            "-T",
            "bookmarks.map(|b| b.name()).join('\\n')",
            "--no-graph",
            "-n",
            "1",
          }, function(bookmark, code)
            if code ~= 0 then
              vim.g.__lualine_jj_branch = "jj"
              return
            end

            if bookmark == "" then
              vim.g.__lualine_jj_branch = "jj"
              pcall(require("lualine").refresh)
              return
            end

            run_async({ "jj", "log", "--count", "-r", (bookmark .. "..@") }, function(count_str)
              local count = tonumber(count_str) or 0
              vim.g.__lualine_jj_branch = count > 0 and (bookmark .. "~" .. tostring(count)) or bookmark
              pcall(require("lualine").refresh)
            end)
          end)
        end

        local function schedule_update_lualine_jj_branch()
          if vim.g.__lualine_jj_branch_running then return end
          vim.g.__lualine_jj_branch_running = true
          vim.defer_fn(function()
            update_lualine_jj_branch()
            vim.g.__lualine_jj_branch_running = false
          end, 10)
        end

        vim.api.nvim_create_autocmd({ "BufEnter", "DirChanged", "VimEnter" }, {
          callback = schedule_update_lualine_jj_branch,
        })

        vim.api.nvim_create_autocmd("ColorScheme", {
          callback = function()
            set_lualine_term_hl()
            schedule_update_lualine_jj_branch()
          end,
        })

        set_lualine_term_hl()
        schedule_update_lualine_jj_branch()
      end
    '';

    settings = {
      options = {
        theme = "auto";
        globalstatus = true;
        disabled_filetypes.statusline = [
          "dashboard"
          "alpha"
          "ministarter"
          "snacks_dashboard"
        ];
      };

      sections = {
        lualine_a = [ "mode" ];
        lualine_b = [
          {
            __unkeyed-1.__raw = ''
              function()
                local branch = vim.g.__lualine_jj_branch or (vim.b.gitsigns_head or "")
                if branch == "" then
                  return ""
                end
                return " " .. branch
              end
            '';
          }
        ];
        lualine_c = [
          {
            __unkeyed-1.__raw = ''
              function()
                local root = vim.fs.root(0, { ".git" }) or vim.uv.cwd()
                if not root or root == "" then return "" end
                return vim.fn.fnamemodify(root, ":t")
              end
            '';
            separator = "%#LualineCSeparator#%*";
          }
          {
            __unkeyed-1 = "diagnostics";
            symbols = {
              error = icons.diagnostics.Error;
              warn = icons.diagnostics.Warn;
              info = icons.diagnostics.Info;
              hint = icons.diagnostics.Hint;
            };
            separator = "%#LualineCSeparator#%*";
          }
          {
            __unkeyed-1 = "filetype";
            icon_only = true;
            separator = "";
            padding = {
              left = 1;
              right = 0;
            };
          }
          {
            __unkeyed-1.__raw = ''
              function()
                if vim.bo.buftype == "terminal" then
                  local function stl_escape(text)
                    text = tostring(text or "")
                    text = text:gsub("%%", "%%%%")
                    text = text:gsub("[\r\n]", " ")
                    text = text:gsub("[%z\1-\31]", "")
                    return text
                  end

                  local function hl(group, text)
                    return ("%#" .. group .. "#" .. stl_escape(text) .. "%*")
                  end

                  local function tail(path)
                    if not path or path == "" then return "" end
                    return vim.fn.fnamemodify(path, ":t")
                  end

                  local bufname = vim.api.nvim_buf_get_name(0)
                  local cwd = bufname:match("^term://(.-)//%d+:")
                  local cmd = bufname:match("^term://.-//%d+:(.*)$")

                  local cwd_tail = tail(cwd)

                  local title = vim.b.term_title
                  if title == nil or title == "" then
                    title = cmd or ""
                  end

                  if cwd_tail ~= "" and (title == cwd_tail or title:find(cwd_tail, 1, true)) then
                    local shell = vim.env.SHELL or ""
                    title = tail(shell)
                  end

                  if title:sub(1, 5) == "/nix/" then
                    title = tail(title)
                  end

                  if title == "" then
                    title = "term"
                  end

                  local title_hl = hl("LualineTermCommand", title)
                  local cwd_hl = cwd_tail ~= "" and hl("LualineTermCwd", cwd_tail) or hl("LualineTermCwd", tail(vim.fn.getcwd()))

                  if vim.bo.filetype == "toggleterm" and vim.b.toggle_number then
                    local num_hl = hl("LualineTermNumber", tostring(vim.b.toggle_number))
                    return "term " .. num_hl .. " runs " .. title_hl .. " in " .. cwd_hl
                  end

                  return title_hl .. " in " .. cwd_hl
                end

                local name = vim.api.nvim_buf_get_name(0)
                if name == "" then return "[No Name]" end
                local root = vim.fs.root(0, { ".git" }) or vim.uv.cwd() or ""
                local rel = name
                if root ~= "" and name:sub(1, #root + 1) == root .. "/" then
                  rel = name:sub(#root + 2)
                else
                  rel = vim.fn.fnamemodify(name, ":~")
                end

                local suffix = vim.bo.modified and " [+]" or ""
                local columns = vim.o.columns or vim.fn.winwidth(0)
                local max_len = math.max(20, columns - 80)

                if vim.fn.strdisplaywidth(rel .. suffix) > max_len then
                  rel = vim.fn.pathshorten(rel)
                end

                return rel .. suffix
              end
            '';
            padding = {
              left = -1;
              right = 1;
            };
            separator = "%#LualineCSeparator#%*";
          }
          {
            __unkeyed-1 = "diff";
            symbols = {
              added = "+";
              modified = "~";
              removed = "-";
            };
            source.__raw = ''
              function()
                -- Prefer vcsigns stats (works for jj/git/hg). It stores a lualine-compatible table in b:vcsigns_stats.
                local stats = vim.b.vcsigns_stats
                if stats then
                  return stats
                end

                -- Fallback to gitsigns if present.
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

        lualine_x = [
          {
            __unkeyed-1 = "lsp_status";
            icon = ""; # f013
            symbols = {
              spinner = [
                "⠋"
                "⠙"
                "⠹"
                "⠸"
                "⠼"
                "⠴"
                "⠦"
                "⠧"
                "⠇"
                "⠏"
              ];
              done = "✓";
              separator = " ";
            };
            ignore_lsp = { };
            show_name = true;
          }
        ];

        lualine_y = [
          {
            __unkeyed-1 = "progress";
            separator = " ";
            padding = {
              left = 1;
              right = 0;
            };
          }
          {
            __unkeyed-1 = "location";
            padding = {
              left = 0;
              right = 1;
            };
          }
        ];

        lualine_z = [
          {
            __unkeyed-1.__raw = ''
              function()
                return " " .. os.date("%R")
              end
            '';
          }
        ];
      };

      extensions = [
        "neo-tree"
        "trouble"
      ];
    };
  };
}
