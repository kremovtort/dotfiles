# Neovim flake (NixVim)

This flake builds Neovim as a standalone `nixvim` derivation and supports
project-specific extensions.

## Outputs

- `packages.<system>.default` (alias: `packages.<system>.nvim`)
- `packages.<system>.nvim4vscode`
- `lib.mkNvim` (base config + `extraModules`)

## Use as a package

Build:

```bash
nix build .#default
```

Install via Home Manager:

```nix
{ inputs, pkgs, ... }:
{
  home.packages = [
    inputs.nvim.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}
```

## Extend per-project

Option A: extend the derivation:

```nix
packages.${system}.nvim-project =
  inputs.nvim.packages.${system}.default.extend ({ ... }: {
    plugins.lsp.servers.ts_ls.enable = true;
  });
```

Option B: compose modules:

```nix
# nvim/project.nix
{ ... }:
{
  plugins.lsp.servers.ts_ls.enable = true;
}
```

```nix
packages.${system}.nvim-project = inputs.nvim.lib.mkNvim {
  inherit system pkgs;
  extraModules = [ ./nvim/project.nix ];
};
```
