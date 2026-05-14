## 1. Tabterm Flake Module

- [x] 1.1 Add `nvim/plugins/tabterm/flake.nix` with `nixpkgs` and `nixvim` inputs.
- [x] 1.2 Package the local tabterm source tree with `pkgs.vimUtils.buildVimPlugin` so `lua/`, `plugin/`, and `shell/` are included in the runtime path.
- [x] 1.3 Export `nixvimModules.default` using `lib.nixvim.plugins.mkNeovimPlugin` for the `plugins.tabterm` option namespace.
- [x] 1.4 Configure the exported module to use `moduleName = "tabterm"` and the packaged tabterm derivation.

## 2. Parent Neovim Integration

- [x] 2.1 Add the local tabterm flake as an input in `nvim/flake.nix`, following parent `nixpkgs` and `nixvim` inputs where applicable.
- [x] 2.2 Import `inputs.tabterm.nixvimModules.default` into the parent NixVim module list.
- [x] 2.3 Replace `nvim/plugins/tabterm.nix` direct `extraFiles` and `extraConfigLua` wiring with `plugins.tabterm.enable = true` and the existing tabterm settings.
- [x] 2.4 Preserve the existing `<C-/>` keymap that calls `require("tabterm").toggle()`.

## 3. Locks And Verification

- [x] 3.1 Update `nvim/flake.lock` after adding the local tabterm input.
- [x] 3.2 Update the root `flake.lock` so the root `nvim` path input points at the updated subflake state.
- [x] 3.3 Verify the parent Neovim package evaluates or builds successfully.
- [x] 3.4 Verify the generated Neovim runtime can load `tabterm`, register `:Tabterm`, and keep the configured setup values.
