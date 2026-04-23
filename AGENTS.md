# AGENTS.md

This document provides guidance for AI agents working with this dotfiles repository.

## Repository Overview

This is a **Nix-based dotfiles** repository for macOS (aarch64-darwin) and Linux systems. It uses:

- **Nix Flakes** for reproducible package management
- **nix-darwin** for macOS system configuration
- **home-manager** for user environment management
- **sops-nix** for secrets management

### Owner

- Username: `kremovtort`
- Name: Alexander Makarov
- Email: i@kremovtort.ru

## Project Structure

```
.
├── flake.nix                 # Main flake entry point
├── flake.lock                # Locked dependencies
├── init.sh                   # Bootstrap script (installs Nix, runs switch)
├── justfile                  # Task runner commands
├── darwin/                   # macOS system configuration (nix-darwin)
│   ├── configuration.nix     # System settings, keyboard, PAM/TouchID
│   └── homebrew.nix          # Homebrew packages
├── home-manager/             # User environment configuration
│   ├── home.nix              # Main home-manager config
│   ├── karabiner.nix         # Keyboard remapping
│   ├── sops.nix              # Secrets (age/sops)
│   ├── starship.nix          # Starship prompt config
│   ├── wezterm.nix           # WezTerm terminal config
│   ├── wezterm/              # WezTerm Lua modules
│   │   └── init.lua
│   └── zsh.nix               # Zsh shell configuration
├── nvim/                     # Neovim configuration (NixVim-based, separate flake)
│   ├── flake.nix             # Neovim flake entry point
│   ├── flake.lock            # Locked Neovim flake inputs
│   ├── config.nix            # Base config module (imports `nvim/config/*`)
│   ├── config/               # Core config split into modules
│   │   ├── options.nix       # Neovim options
│   │   ├── keymaps.nix       # Global (non-plugin) keymaps
│   │   ├── autoCmd.nix       # Autocommands
│   │   ├── colorscheme.nix   # Colorscheme setup
│   │   └── clipboard.nix     # Clipboard/OSC52 handling
│   ├── plugins.nix           # Plugin module aggregator (imports `nvim/plugins/*`)
│   ├── plugins/              # Per-plugin modules (+ plugin-specific keymaps)
│   │   ├── auto-save.nix
│   │   ├── auto-session.nix
│   │   ├── blink-cmp.nix
│   │   ├── dropbar.nix
│   │   ├── floaterm.nix
│   │   ├── grug-far.nix
│   │   ├── haskell.nix
│   │   ├── hunk.nix
│   │   ├── icons.nix
│   │   ├── langmapper.nix
│   │   ├── leap.nix
│   │   ├── lsp.nix
│   │   ├── lualine.nix
│   │   ├── mini-ai.nix
│   │   ├── mini-diff.nix
│   │   ├── mini-pairs.nix
│   │   ├── mini-surround.nix
│   │   ├── noice.nix
│   │   ├── notify.nix
│   │   ├── opencode/         # OpenCode providers and shared config
│   │   ├── origami.nix
│   │   ├── overseer.nix
│   │   ├── quickfix.nix
│   │   ├── render-markdown.nix
│   │   ├── repeat.nix
│   │   ├── scrollbar.nix
│   │   ├── seeker.nix
│   │   ├── snacks.nix
│   │   ├── supermaven.nix
│   │   ├── tabby.nix
│   │   ├── tabterm.nix
│   │   ├── treesitter.nix
│   │   ├── trouble.nix
│   │   ├── vcsigns.nix
│   │   ├── which-key.nix
│   │   └── yanky.nix
│   ├── vscode.nix            # VSCode-focused nvim build
│   └── README.md             # Neovim flake docs
├── agents/                   # AI agent configs (OpenCode, skills, tools)
│   ├── flake.nix             # Agents flake entry point
│   ├── flake.lock            # Agents flake lock
│   ├── opencode.nix          # OpenCode home-manager module
│   ├── opencode/
│   │   ├── agents/           # Subagent definitions
│   │   │   ├── codemodder.md
│   │   │   ├── docs-digger.md
│   │   │   ├── runner.md
│   │   │   └── scout.md
│   │   └── instructions/     # Agent instructions
│   │       ├── base.md
│   │       └── subagent-json-format.md
│   ├── skills/               # Custom OpenCode skills
│   │   ├── add-nixvim-plugin/
│   │   ├── jujutsu/
│   │   └── vcs-detect/
│   └── commands/             # Custom OpenCode commands
│       ├── plannotator-annotate.md
│       ├── plannotator-last.md
│       ├── plannotator-review.md
│       ├── rmslop.md
│       └── spellcheck.md
├── openspec/                 # OpenSpec workflow (experimental)
│   ├── config.yaml
│   ├── changes/              # Active and archived changes
│   └── specs/                # Main specs
├── secrets/                  # Encrypted secrets (sops-nix)
│   └── secrets.yaml          # Encrypted API keys
├── catppuccin/               # Theme assets (Ghostty/OpenCode)
├── atuin/                    # Atuin shell history config
├── clickhouse-client/        # ClickHouse client config
├── ov.yaml                   # OpenCode configuration
├── starship.toml             # Starship prompt config (legacy / direct)
└── wezterm.lua               # WezTerm terminal config (legacy)
```

## Key Commands

All commands are run via `just` (task runner):

| Command | Description |
|---------|-------------|
| `just switch` | Apply all configurations (darwin + home-manager on macOS; home-manager on Linux) |
| `just switch home` | Apply only home-manager configuration |
| `just switch darwin` | Apply only darwin (system) configuration |
| `just upgrade` | Update flake inputs and apply changes (plus `brew update/upgrade` on macOS) |
| `just darwin-rebuild-switch` | Low-level: `nix run .#darwin-rebuild -- switch --flake .` |
| `just home-manager-switch` | Low-level: `nix run .#home-manager -- switch --flake .` |
| `just setup-shell` | Ensure nix profile `zsh` is a valid login shell |

### Bootstrap (Fresh Install)

```bash
./init.sh
```

This script:
1. Installs Nix via Determinate Systems installer
2. Runs `just switch` to apply configurations

## Configuration Guidelines

### Nix Files

- Use **nixpkgs-unstable** channel
- Follow existing patterns in `home.nix` for adding packages
- Platform-specific packages: use `lib.mkIf isDarwin` pattern
- Secrets: add to `secrets/secrets.yaml` and reference in `sops.nix`

### Adding Packages

1. **System-wide (macOS only)**: Edit `darwin/configuration.nix`
2. **User packages**: Edit `home-manager/home.nix` → `home.packages`
3. **Homebrew (macOS)**: Edit `darwin/homebrew.nix`

### Adding Programs with Options

For programs with home-manager modules, add to `home.nix`:

```nix
programs.<name> = {
  enable = true;
  enableZshIntegration = true;  # if applicable
  # ... other options
};
```

### Neovim Configuration

- Based on **NixVim** (declarative Neovim configuration via Nix)
- Self-contained flake in `nvim/` directory
- Base config is composed in `nvim/config.nix` (imports `nvim/config/*`)
- Plugin config is composed in `nvim/plugins.nix` (imports `nvim/plugins/*`)
- Global (non-plugin) keymaps live in `nvim/config/keymaps.nix`
- Plugin-specific keymaps live next to the plugin config in `nvim/plugins/*.nix`
- Autocmds live in `nvim/config/autoCmd.nix`
- Russian keyboard layout support (`langmap` + langmapper.nvim) lives in `nvim/plugins/langmapper.nix`
- Icons are provided via `_module.args.icons` from `nvim/plugins/icons.nix` (avoid `vim.g` globals)
- OpenCode integration modules live in `nvim/plugins/opencode/`

#### Adding Neovim Plugins

Prefer creating/adjusting a per-plugin module in `nvim/plugins/<plugin>.nix` and importing it from `nvim/plugins.nix`.

For plugins with NixVim modules, set options inside the plugin module:

```nix
{ ... }:
{
  plugins.<name> = {
    enable = true;
    settings = { ... };
  };

  # If the plugin needs keymaps, keep them here too.
  keymaps = [
    # ...
  ];
}
```

For plugins without NixVim modules, use `extraPlugins` inside the relevant plugin module (or, if truly shared, in `nvim/plugins.nix`):

```nix
extraPlugins = [
  (pkgs.vimUtils.buildVimPlugin {
    name = "plugin-name";
    src = inputs.plugins-plugin-name;
    dependencies = with pkgs.vimPlugins; [ ... ];
  })
];
```

Some plugins are fetched as external flake inputs in `nvim/flake.nix` (e.g., `plugins-opencode-nvim`, `plugins-vcsigns-nvim`, `plugins-seeker-nvim`, etc.).

### Secrets Management

Secrets are encrypted with **sops-nix** using age keys derived from SSH:

```bash
# Edit secrets
sops secrets/secrets.yaml

# Add new secret reference in sops.nix
sops.secrets.<secret-name> = {};
```

## Development Environment

Enter dev shell with LSP support:

```bash
nix develop
```

Provides:
- `nixd` (Nix LSP)
- `lua-language-server`
- `bash-language-server`
- `nixfmt`
- `statix` (Nix linter)
- `shellcheck`
- `stylua`
- `just`

## Important Notes

1. **Do not edit** `flake.lock` / `nvim/flake.lock` / `agents/flake.lock` manually — use `nix flake update`
2. **Neovim config** is built via NixVim in `nvim/` (not symlinked)
3. **Starship config** is at `starship.toml` (symlinked to `~/.config/`)
4. **Catppuccin** is the primary theme family (Mocha in most tools; Espresso is used in some terminal/OpenCode assets)
5. This repo is typically used with **Jujutsu (`jj`) on top of Git**; detect VCS before running VCS commands
6. **Touch ID for sudo** is enabled via PAM configuration
7. **OpenSpec** workflow lives in `openspec/` and is used for structured feature development

## External Dependencies

- **Homebrew**: Managed via nix-darwin, used for `arc-launcher`
- **Yandex Arc**: Internal VCS tool (tapped from yandex repo)

## Testing Changes

1. Make changes to Nix files
2. Run `just switch` to apply
3. For nvim changes: restart nvim (configuration is built via Nix)
4. Check for errors in terminal output

## Flake Inputs

| Input | Purpose |
|-------|---------|
| `nixpkgs` | Package repository (unstable) |
| `flake-parts` | Flake structure helper |
| `nix-darwin` | macOS system management |
| `home-manager` | User environment management |
| `sops-nix` | Secrets management |
| `karabinix` | Karabiner-Elements Nix module |
| `jj-starship` | Starship integration for Jujutsu |
| `nvim` | Neovim configuration (separate local flake) |
| `agents` | AI agent tooling (local flake) |
