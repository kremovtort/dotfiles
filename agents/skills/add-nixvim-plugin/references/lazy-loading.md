# Lazy Loading Custom Plugins with lz.n

This reference provides detailed patterns for lazy loading custom NixVim plugins added via `extraPlugins`.

## Basic Lazy Loading Pattern

To lazy-load a custom plugin:

```nix
{pkgs, ...}: {
  extraPlugins = [
    {
      plugin = pkgs.vimUtils.buildVimPlugin {
        name = "plugin-name";
        src = pkgs.fetchFromGitHub {
          owner = "github-username";
          repo = "repo-name";
          rev = "commit-hash";
          sha256 = "sha256-hash";
        };
      };
      optional = true;  # REQUIRED for lazy loading
    }
  ];

  extraConfigLua = ''
    require("lz.n").load({
      "plugin-name",
      cmd = "PluginCommand",
      after = function()
        require("plugin-name").setup({
          -- plugin configuration here
        })
      end,
    })
  '';
}
```

## Loading Triggers

### Command Trigger (`cmd`)
Load when a specific command is executed:

```lua
cmd = "CommandName"           -- Single command
cmd = {"Cmd1", "Cmd2"}       -- Multiple commands
```

### Keymap Trigger (`keys`)
Load when a keymap is pressed:

```lua
keys = "<leader>key"          -- Single key
keys = {"<leader>k1", "<leader>k2"}  -- Multiple keys
```

### Event Trigger (`event`)
Load on Neovim autocmd events:

```lua
event = "BufEnter"            -- Single event
event = {"BufEnter", "InsertEnter"}  -- Multiple events
```

Common events:
- `BufEnter` - Entering a buffer
- `BufRead` - Reading a buffer
- `InsertEnter` - Entering insert mode
- `VeryLazy` - After startup, deferred

### Filetype Trigger (`ft`)
Load for specific filetypes:

```lua
ft = "python"                 -- Single filetype
ft = {"python", "lua"}       -- Multiple filetypes
```

## Complete Example

```nix
{pkgs, ...}: {
  extraPlugins = [
    {
      plugin = pkgs.vimUtils.buildVimPlugin {
        name = "focus.nvim";
        src = pkgs.fetchFromGitHub {
          owner = "nvim-focus";
          repo = "focus.nvim";
          rev = "26a755c363284547196ceb258a83f92608d7979b";
          sha256 = "sha256-u5/kP3b3txEyyPPu3MTKpINDXhQPuC3/HK2aqste1sw=";
        };
      };
      optional = true;
    }
  ];

  extraConfigLua = ''
    require("lz.n").load({
      "focus.nvim",
      cmd = {"FocusToggle", "FocusEqualise", "FocusMaximise"},
      keys = {"<leader>uf"},
      after = function()
        require("focus").setup({
          enable = true,
          commands = true,
          autoresize = {
            enable = true,
            height_quickfix = 10,
          },
          ui = {
            cursorline = true,
            signcolumn = true,
          }
        })
      end,
    })
  '';
}
```

## Important Notes

1. **`optional = true` is required** - Without this flag, the plugin will not be marked as optional and lazy loading will fail
2. **Multiple triggers** - A plugin can have multiple triggers (`cmd`, `keys`, `event`, `ft`) and will load when any trigger fires
3. **Setup in `after` function** - Always call the plugin's setup inside the `after` function to ensure it runs after the plugin is loaded
4. **lz.n must be enabled** - Ensure `plugins.lz-n.enable = true;` in your config (already enabled in this NixVim config via `config/plugins/lazyload/lz-n.nix`)

## Resources

- [NixVim lz-n Documentation](https://nix-community.github.io/nixvim/plugins/lz-n/index.html)
- [lz.n GitHub Repository](https://github.com/nvim-neorocks/lz.n)
- [NixVim Lazy Loading Guide](https://nix-community.github.io/nixvim/user-guide/lazy-loading)
