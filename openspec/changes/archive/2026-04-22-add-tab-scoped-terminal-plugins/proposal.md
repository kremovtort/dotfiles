## Why

The current Neovim setup relies on a third-party floating terminal plugin with a fixed global state model and limited configuration surface. A tab-scoped terminal manager is needed to match the existing workflow better, keep terminal groups aligned with tabpages, and support richer sidebar presentation and manual session restore semantics.

## What Changes

- Add a new local Neovim plugin that manages floating terminals per tabpage instead of globally.
- Render a persistent sidebar for terminal entries with compact and detailed display modes.
- Support manual restart semantics for restored terminals, so session restore recreates terminal entries without automatically starting their processes.
- Derive terminal names from user overrides or terminal metadata such as cwd, title, and command.
- Track terminal runtime state, last known result, and last output summary for sidebar and placeholder rendering.
- Package the plugin as a local `nvim/plugins/` module and wire it into the NixVim configuration through a dedicated plugin module.

## Capabilities

### New Capabilities
- `tab-scoped-terminal-manager`: A local Neovim terminal manager that provides tabpage-scoped floating terminals, sidebar navigation, detailed terminal state tracking, and manual restore behavior.

### Modified Capabilities

## Impact

- Affects `nvim/plugins.nix` and a new `nvim/plugins/*.nix` module used to install and configure the local plugin.
- Adds a new local plugin directory under `nvim/plugins/` for the Lua implementation.
- May replace or supersede the current `nvim/plugins/floaterm.nix` integration for the user workflow.
- Relies on Neovim terminal events, floating windows, and session-aware plugin state rather than upstream plugin state.
