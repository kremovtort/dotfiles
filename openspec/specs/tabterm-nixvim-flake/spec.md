## Purpose

Define expected flake packaging and NixVim module integration behavior for the local tabterm Neovim plugin.

## Requirements

### Requirement: Tabterm exports a NixVim module from its flake
The tabterm plugin SHALL provide a flake at `nvim/plugins/tabterm/` that exports a reusable NixVim module through `nixvimModules.default`. The exported module SHALL define the `plugins.tabterm` option namespace using NixVim's `lib.nixvim.plugins.mkNeovimPlugin` helper.

#### Scenario: Consumer imports the exported module
- **WHEN** a NixVim configuration imports the tabterm flake's `nixvimModules.default`
- **THEN** the configuration SHALL expose a `plugins.tabterm.enable` option
- **AND** enabling `plugins.tabterm` SHALL add the packaged tabterm plugin to the generated Neovim runtime

#### Scenario: Settings generate tabterm setup
- **WHEN** a consumer enables `plugins.tabterm` and provides `plugins.tabterm.settings`
- **THEN** the generated Neovim Lua configuration SHALL pass those settings to `require("tabterm").setup(...)`

### Requirement: Tabterm flake packages the local runtime sources
The tabterm flake SHALL package the local plugin source tree as a Vim plugin derivation that includes the existing `lua/`, `plugin/`, and `shell/` runtime paths.

#### Scenario: Runtime files are available from the plugin package
- **WHEN** the tabterm plugin package is included in a NixVim build
- **THEN** Neovim SHALL be able to load the `tabterm` Lua module from the packaged `lua/` directory
- **AND** Neovim SHALL load the `plugin/tabterm.lua` command registration file from the package runtime path
- **AND** tabterm SHALL be able to reference its packaged shell integration files from the `shell/` runtime path

### Requirement: Dotfiles Neovim configuration consumes tabterm as a flake module
The parent `nvim` flake SHALL consume the local tabterm flake as an input and import its exported NixVim module instead of manually mapping tabterm runtime files through parent-level `extraFiles`.

#### Scenario: Existing user configuration is preserved
- **WHEN** the dotfiles Neovim package is built after the migration
- **THEN** tabterm SHALL remain enabled in the dotfiles configuration
- **AND** the current tabterm UI settings for border, sidebar width, and float dimensions SHALL remain configured through `plugins.tabterm.settings`
- **AND** the existing `<C-/>` keymap SHALL continue to call `require("tabterm").toggle()`

#### Scenario: Parent configuration no longer owns tabterm packaging details
- **WHEN** the parent `nvim/plugins/tabterm.nix` module configures tabterm after the migration
- **THEN** it SHALL use the `plugins.tabterm` option namespace for enablement and settings
- **AND** it SHALL NOT enumerate tabterm's Lua, plugin, or shell files through parent-level `extraFiles`

### Requirement: Local flake locks stay coherent for installed Neovim
Changes that add or update the local tabterm flake input SHALL keep the parent `nvim` flake lock and the root flake lock coherent so direct `nvim` builds and installed home-manager builds consume the same tabterm module version.

#### Scenario: Local tabterm input changes are lock-synchronized
- **WHEN** the tabterm flake input is added or updated in `nvim/flake.nix`
- **THEN** `nvim/flake.lock` SHALL record the local tabterm input
- **AND** the root `flake.lock` SHALL update its locked local `nvim` input snapshot so `pkgs.nvim` from home-manager uses the updated subflake
