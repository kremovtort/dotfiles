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

  vcsigns = (pkgs.vimUtils.buildVimPlugin {
    name = "vcsigns-nvim";
    src = nvimInputs.plugins-vcsigns-nvim;
    dependencies = [ vcsignsVclib ];
  }).overrideAttrs (old: {
    nvimSkipModules = [
      "vcsigns_tests"
      "vcrepo_tests"
      "vcsigns_tests.functional.test_git"
      "vcsigns_tests.functional.test_integration"
      "vcsigns_tests.functional.test_vcs_common"
      "vcsigns_tests.functional.test_jj"
      "vcsigns_tests.functional.test_hg"
    ];
  });
in
{
  extraPlugins = [
    vcsignsVclib
    vcsigns
  ];

  extraConfigLua = lib.mkAfter ''
    local common = require("vcrepo.common")
    local run = require("vclib.run")
    require("vcsigns.repo").register_vcs({
      name = "Arc",

      detect = function(dir)
        if vim.fn.executable "arc" == 0 then
          return nil
        end
        local cmd = {"arc", "root"}
        local out = run.run_with_timeout(cmd, {cwd = dir}):wait()
        if out.code ~= 0 or not out.stdout then
          return nil
        end
        return vim.trim(out.stdout)
      end,

      show = function(self, target, lines_cb)
        local cmd = {
          "arc",
          "show",
          string.format("HEAD~%d", target.commit) .. ":" .. target.file,
        }
        run.run_with_timeout(cmd, { cwd = self.root }, function(out)
          lines_cb(common.content_to_lines(out.stdout))
        end)
      end,

      blame = function(self, file, template, annotations_cb)
        assert(template == nil, "Arc blame does not support custom templates")

        local cmd = { "arc", "blame", "--json", "--", file }
        run.run_with_timeout(cmd, { cwd = self.root }, function(out)
          if out.code ~= 0 or not out.stdout or out.stdout == "" then
            annotations_cb(nil)
            return
          end

          local ok, payload = pcall(vim.json.decode, out.stdout)
          if not ok or type(payload) ~= "table" or type(payload.annotation) ~= "table" then
            annotations_cb(nil)
            return
          end

          local annotations = {}
          for _, entry in ipairs(payload.annotation) do
            if type(entry) == "table" and entry.line and entry.commit and entry.text then
              local content = entry.text
              if content:sub(-1) == "\n" then
                content = content:sub(1, -2)
              end

              table.insert(annotations, {
                line_num = entry.line,
                annotation = entry.commit:sub(1, 8),
                content = content,
              })
            end
          end

          table.sort(annotations, function(a, b)
            return a.line_num < b.line_num
          end)

          annotations_cb(annotations)
        end)
      end,
      needs_refresh = function(self, needs_refresh_cb)
        needs_refresh_cb(true)
      end,
      -- Rename resolution not implemented for git.
      resolve_rename = nil,
    })

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
