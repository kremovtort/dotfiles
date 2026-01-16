return {
  {
    "snacks.nvim",
    event = "DeferredUIEnter",
    -- stylua: ignore
    keys = {
      { "<leader>n", function() require("snacks").picker.notifications() end, desc = "Notification History" },
      { "<leader>un", function() require("snacks").notifier.hide() end, desc = "Dismiss All Notifications" },

      { "<leader>.",  function() require("snacks").scratch() end, desc = "Toggle Scratch Buffer" },
      { "<leader>S",  function() require("snacks").scratch.select() end, desc = "Select Scratch Buffer" },
      { "<leader>dps", function() require("snacks").profiler.scratch() end, desc = "Profiler Scratch Buffer" },

      -- picker
      { "<leader>,", function() require("snacks").picker.buffers() end, desc = "Buffers" },
      { "<leader>/", function() require("snacks").picker.grep({ cwd = require("config.root").get() }) end, desc = "Grep (Root Dir)" },
      { "<leader>:", function() require("snacks").picker.command_history() end, desc = "Command History" },
      { "<leader><space>", function() require("snacks").picker.files({ cwd = require("config.root").get() }) end, desc = "Find Files (Root Dir)" },

      -- find
      { "<leader>fb", function() require("snacks").picker.buffers() end, desc = "Buffers" },
      { "<leader>fB", function() require("snacks").picker.buffers({ hidden = true, nofile = true }) end, desc = "Buffers (all)" },
      { "<leader>fc", function() require("snacks").picker.files({ cwd = vim.fn.stdpath("config") }) end, desc = "Find Config File" },
      { "<leader>ff", function() require("snacks").picker.files({ cwd = require("config.root").get() }) end, desc = "Find Files (Root Dir)" },
      { "<leader>fF", function() require("snacks").picker.files({ cwd = (vim.uv or vim.loop).cwd() or "." }) end, desc = "Find Files (cwd)" },
      { "<leader>fg", function() require("snacks").picker.git_files() end, desc = "Find Files (git-files)" },
      { "<leader>fr", function() require("snacks").picker.recent() end, desc = "Recent" },
      { "<leader>fR", function() require("snacks").picker.recent({ filter = { cwd = true } }) end, desc = "Recent (cwd)" },
      { "<leader>fp", function() require("snacks").picker.projects() end, desc = "Projects" },

      -- git
      { "<leader>gd", function() require("snacks").picker.git_diff() end, desc = "Git Diff (hunks)" },
      { "<leader>gD", function() require("snacks").picker.git_diff({ base = "origin", group = true }) end, desc = "Git Diff (origin)" },
      { "<leader>gs", function() require("snacks").picker.git_status() end, desc = "Git Status" },
      { "<leader>gS", function() require("snacks").picker.git_stash() end, desc = "Git Stash" },
      { "<leader>gi", function() require("snacks").picker.gh_issue() end, desc = "GitHub Issues (open)" },
      { "<leader>gI", function() require("snacks").picker.gh_issue({ state = "all" }) end, desc = "GitHub Issues (all)" },
      { "<leader>gp", function() require("snacks").picker.gh_pr() end, desc = "GitHub Pull Requests (open)" },
      { "<leader>gP", function() require("snacks").picker.gh_pr({ state = "all" }) end, desc = "GitHub Pull Requests (all)" },

      -- grep
      { "<leader>sb", function() require("snacks").picker.lines() end, desc = "Buffer Lines" },
      { "<leader>sB", function() require("snacks").picker.grep_buffers() end, desc = "Grep Open Buffers" },
      { "<leader>sg", function() require("snacks").picker.grep({ cwd = require("config.root").get() }) end, desc = "Grep (Root Dir)" },
      { "<leader>sG", function() require("snacks").picker.grep({ cwd = (vim.uv or vim.loop).cwd() or "." }) end, desc = "Grep (cwd)" },
      { "<leader>sp", function() require("snacks").picker.lazy() end, desc = "Search for Plugin Spec" },
      { "<leader>sw", function() require("snacks").picker.grep_word({ cwd = require("config.root").get() }) end, desc = "Visual selection or word (Root Dir)", mode = { "n", "x" } },
      { "<leader>sW", function() require("snacks").picker.grep_word({ cwd = (vim.uv or vim.loop).cwd() or "." }) end, desc = "Visual selection or word (cwd)", mode = { "n", "x" } },

      -- search
      { '<leader>s"', function() require("snacks").picker.registers() end, desc = "Registers" },
      { '<leader>s/', function() require("snacks").picker.search_history() end, desc = "Search History" },
      { "<leader>sa", function() require("snacks").picker.autocmds() end, desc = "Autocmds" },
      { "<leader>sc", function() require("snacks").picker.command_history() end, desc = "Command History" },
      { "<leader>sC", function() require("snacks").picker.commands() end, desc = "Commands" },
      { "<leader>sd", function() require("snacks").picker.diagnostics() end, desc = "Diagnostics" },
      { "<leader>sD", function() require("snacks").picker.diagnostics_buffer() end, desc = "Buffer Diagnostics" },
      { "<leader>sh", function() require("snacks").picker.help() end, desc = "Help Pages" },
      { "<leader>sH", function() require("snacks").picker.highlights() end, desc = "Highlights" },
      { "<leader>si", function() require("snacks").picker.icons() end, desc = "Icons" },
      { "<leader>sj", function() require("snacks").picker.jumps() end, desc = "Jumps" },
      { "<leader>sk", function() require("snacks").picker.keymaps() end, desc = "Keymaps" },
      { "<leader>sl", function() require("snacks").picker.loclist() end, desc = "Location List" },
      { "<leader>sM", function() require("snacks").picker.man() end, desc = "Man Pages" },
      { "<leader>sm", function() require("snacks").picker.marks() end, desc = "Marks" },
      { "<leader>sR", function() require("snacks").picker.resume() end, desc = "Resume" },
      { "<leader>sq", function() require("snacks").picker.qflist() end, desc = "Quickfix List" },
      { "<leader>su", function() require("snacks").picker.undo() end, desc = "Undotree" },

      -- ui
      { "<leader>uC", function() require("snacks").picker.colorschemes() end, desc = "Colorschemes" },
    },
    after = function()
      require("snacks").setup({
        -- from your snippets (merged)
        bigfile = { enabled = true },
        dashboard = { enabled = false },
        indent = { enabled = true },
        input = { enabled = true },
        notifier = { enabled = true },
        quickfile = { enabled = true },
        picker = {
          enabled = true,
          win = {
            input = {
              keys = {
                ["<a-c>"] = { "toggle_cwd", mode = { "n", "i" } },
              },
            },
          },
          actions = {
            ---@param p snacks.Picker
            toggle_cwd = function(p)
              local root = require("config.root").get(p.input.filter.current_buf)
              local cwd = vim.fs.normalize((vim.uv or vim.loop).cwd() or ".")
              local current = p:cwd()
              p:set_cwd(current == root and cwd or root)
              p:find()
            end,
          },
        },
        scope = { enabled = true },
        scroll = { enabled = true },
        statuscolumn = { enabled = false }, -- we set this in options.lua
        words = { enabled = true },
        terminal = {
          win = {
            -- terminal nav keys are configured in `config/keymaps.lua`
            keys = {},
          },
        },
      })
    end,
  },
}
