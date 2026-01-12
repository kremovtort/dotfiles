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
├── flake.nix              # Main flake entry point
├── flake.lock             # Locked dependencies
├── init.sh                # Bootstrap script (installs Nix, runs switch)
├── justfile               # Task runner commands
├── darwin/                # macOS system configuration (nix-darwin)
│   ├── configuration.nix  # System settings, keyboard, PAM/TouchID
│   └── homebrew.nix       # Homebrew packages (arc-launcher)
├── home-manager/          # User environment configuration
│   ├── home.nix           # Main home-manager config
│   ├── karabiner.nix      # Keyboard remapping
│   ├── opencode.nix       # OpenCode AI tool config
│   ├── paneru.nix         # Paneru service
│   ├── sops.nix           # Secrets (age/sops)
│   ├── tmux.nix           # Tmux configuration
│   ├── zellij.nix         # Zellij terminal multiplexer
│   └── zsh.nix            # Zsh shell configuration
├── nvim/                  # Neovim configuration (LazyVim-based)
│   ├── init.lua           # Entry point
│   └── lua/
│       ├── config/        # Core settings (options, keymaps, autocmds)
│       └── plugins/       # Plugin configurations
├── secrets/               # Encrypted secrets (sops-nix)
│   └── secrets.yaml       # Encrypted API keys
├── atuin/                 # Atuin shell history config
├── clickhouse-client/     # ClickHouse client config
├── starship.toml          # Starship prompt config
└── wezterm.lua            # WezTerm terminal config
```

## Key Commands

All commands are run via `just` (task runner):

| Command | Description |
|---------|-------------|
| `just switch` | Apply all configurations (darwin + home-manager) |
| `just switch home` | Apply only home-manager configuration |
| `just switch darwin` | Apply only darwin (system) configuration |
| `just upgrade` | Update flake inputs and apply changes |
| `just configure-nvim` | Open nvim with local config for testing |

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

- Based on **LazyVim** starter
- Plugin configs in `nvim/lua/plugins/`
- Core options in `nvim/lua/config/options.lua`
- Russian keyboard layout support via `langmap`
- AI integration via **avante.nvim** (OpenRouter provider)

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
- `statix` (Nix linter)
- `shellcheck`
- `stylua`

## Important Notes

1. **Do not edit** `flake.lock` manually — use `nix flake update`
2. **Neovim config** is symlinked from this repo via home-manager
3. **Starship config** is at `starship.toml` (symlinked to `~/.config/`)
4. **Catppuccin Mocha** is the primary color theme across tools
5. **Touch ID for sudo** is enabled via PAM configuration

## External Dependencies

- **Homebrew**: Managed via nix-darwin, used for `arc-launcher`
- **Yandex Arc**: Internal VCS tool (tapped from yandex repo)
- **OpenRouter**: AI API provider for avante.nvim

## Testing Changes

1. Make changes to Nix files
2. Run `just switch` to apply
3. For nvim changes: restart nvim or run `:Lazy sync`
4. Check for errors in terminal output

## Flake Inputs

| Input | Purpose |
|-------|---------|
| `nixpkgs` | Package repository (unstable) |
| `nix-darwin` | macOS system management |
| `home-manager` | User environment management |
| `sops-nix` | Secrets management |
| `paneru` | Custom service |
| `zjstatus` | Zellij status bar |
| `karabinix` | Karabiner-Elements Nix module |
| `openspec-flake` | Custom OpenSpec tool |
| `flake-parts` | Flake structure helper |
