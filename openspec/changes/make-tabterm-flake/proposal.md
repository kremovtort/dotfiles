## Why

`tabterm` currently lives inside the Neovim configuration tree as local plugin code, which makes its NixVim integration harder to reuse, test, and evolve independently from this dotfiles flake. Turning `nvim/plugins/tabterm/` into a small flake that exports a NixVim module gives the plugin a clearer package boundary while preserving its existing Neovim behavior.

## What Changes

- Add a flake entry point under `nvim/plugins/tabterm/`.
- Export a NixVim module for configuring the local tabterm plugin.
- Use NixVim's `mkNeovimPlugin` helper for the module interface instead of hand-rolled plugin wiring.
- Update the parent Neovim configuration to consume tabterm through the exported module.
- Keep the existing Lua/plugin/shell runtime behavior unchanged unless required for packaging.

## Capabilities

### New Capabilities

- `tabterm-nixvim-flake`: Defines how the local tabterm plugin is exposed as a reusable Nix flake and configurable NixVim module.

### Modified Capabilities

- None.

## Impact

- Affects `nvim/plugins/tabterm/` by adding flake/module packaging around the existing plugin sources.
- Affects the parent `nvim` flake and NixVim plugin imports that currently wire tabterm directly.
- May update lock files through normal `nix flake` commands if local flake inputs change.
- Does not intentionally change tabterm's user-facing terminal workspace behavior.
