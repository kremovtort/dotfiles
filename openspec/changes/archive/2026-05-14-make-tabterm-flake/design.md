## Context

`tabterm` is currently packaged by `nvim/plugins/tabterm.nix` with explicit `extraFiles` entries for every Lua, plugin, and shell integration file. The same module also calls `require("tabterm").setup(...)` through `extraConfigLua` and defines the `<C-/>` keymap.

The parent NixVim configuration imports `./plugins/tabterm.nix` from `nvim/plugins.nix`. The `nvim` flake does not currently have a dedicated tabterm flake input, so tabterm cannot expose its own NixVim module boundary or be consumed independently from the surrounding dotfiles configuration.

NixVim documents `lib.nixvim.plugins.mkNeovimPlugin` as the standard helper for Lua plugins configured through `require('<plugin>').setup({ ... })`. It generates the normal NixVim plugin option surface, including `plugins.<name>.enable`, package wiring, settings, and setup-call generation.

## Goals / Non-Goals

**Goals:**

- Make `nvim/plugins/tabterm/` a self-contained flake.
- Export a reusable NixVim module from that flake via `nixvimModules.default`.
- Use `lib.nixvim.plugins.mkNeovimPlugin` to define the `plugins.tabterm` module interface.
- Preserve the current user configuration: tabterm remains enabled, keeps the round border/sidebar/float settings, and keeps the `<C-/>` toggle keymap.
- Package the existing `lua/`, `plugin/`, and `shell/` files as a Vim plugin instead of listing each file through parent-level `extraFiles`.

**Non-Goals:**

- Changing tabterm's Lua runtime architecture or terminal behavior.
- Publishing tabterm outside this repository.
- Adding a broad typed option schema for all tabterm settings; `mkNeovimPlugin`'s freeform `settings` option is sufficient for this change.
- Reworking unrelated Neovim plugin modules.

## Decisions

1. Add `nvim/plugins/tabterm/flake.nix` as the package/module boundary.

   The tabterm directory already contains the plugin runtime sources, so the flake should live at that boundary and export `nixvimModules.default`. This keeps reusable packaging next to the code it packages.

   Alternative considered: keep all wiring in `nvim/plugins/tabterm.nix` and only reduce the `extraFiles` list. That would simplify the immediate diff but would not create the reusable flake/module boundary requested by the change.

2. Build the plugin package from the tabterm source tree.

   The flake module should create a Vim plugin derivation with `pkgs.vimUtils.buildVimPlugin`, using the tabterm flake source as `src`. The packaged runtime path should include the existing `lua/`, `plugin/`, and `shell/` directories so Lua modules, command registration, and shell integration assets remain available through Neovim runtime lookup.

   Alternative considered: continue using parent-level `extraFiles`. That preserves behavior but duplicates source mapping outside the plugin boundary and bypasses the package abstraction that `mkNeovimPlugin` expects.

3. Define the NixVim module with `lib.nixvim.plugins.mkNeovimPlugin`.

   The module should use `name = "tabterm"`, `moduleName = "tabterm"`, the local package derivation, and setup-call generation so `plugins.tabterm.settings` becomes the source for `require("tabterm").setup(...)`.

   Alternative considered: hand-write `options.plugins.tabterm` and emit Lua manually. That would recreate behavior already handled by NixVim and increase maintenance cost.

4. Keep repository-local configuration in the parent `nvim/plugins/tabterm.nix`.

   After the flake exports the module, the existing parent module should stop packaging files directly and should only enable/configure tabterm and define local keymaps. The parent `nvim` flake should import `inputs.tabterm.nixvimModules.default`, while `nvim/plugins/tabterm.nix` should set `plugins.tabterm.enable = true` and the current settings.

   Alternative considered: move all settings and keymaps into the tabterm flake's exported module. That would make every consumer inherit this user's dotfiles preferences and would make the module less reusable.

5. Add tabterm as a local flake input to the parent `nvim` flake.

   The parent `nvim/flake.nix` should add a local `tabterm` input pointing at `./plugins/tabterm`, with `nixpkgs` and `nixvim` following the parent inputs where possible. Because the root flake consumes the local `nvim` subflake, updating tabterm input locks requires updating both `nvim/flake.lock` and the root `flake.lock` path input for `nvim`.

   Alternative considered: import `./plugins/tabterm/flake.nix` outputs directly without declaring a flake input. That would avoid lock updates but would not model tabterm as a real flake dependency of the Neovim configuration.

## Risks / Trade-offs

- Local flake lock drift -> Mitigation: update `nvim/flake.lock` and the root `flake.lock` after adding the local input so the installed home-manager `pkgs.nvim` sees the same tabterm module as direct `nvim` builds.
- Runtime files omitted from the package -> Mitigation: package the whole tabterm source tree and verify that `lua/`, `plugin/`, and `shell/` paths are present in the Vim plugin derivation.
- Setup call ordering changes -> Mitigation: rely on `mkNeovimPlugin` setup generation and keep only the repository-local settings in `plugins.tabterm.settings`.
- Module naming mismatch -> Mitigation: use `plugins.tabterm` for the NixVim option path and `moduleName = "tabterm"` for `require("tabterm")`.

## Migration Plan

1. Add the tabterm flake and exported NixVim module.
2. Add the local tabterm flake input to `nvim/flake.nix` and import `inputs.tabterm.nixvimModules.default` into the NixVim module list.
3. Replace direct `extraFiles`/`extraConfigLua` packaging in `nvim/plugins/tabterm.nix` with `plugins.tabterm` settings plus the existing keymap.
4. Update the relevant flake locks through normal Nix flake commands.
5. Verify the Neovim package evaluates or builds.

Rollback is to remove the local flake input/import and restore the previous `extraFiles` plus `extraConfigLua` wiring in `nvim/plugins/tabterm.nix`.

## Open Questions

None.
