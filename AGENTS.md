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
│   ├── paneru.nix            # Paneru service
│   ├── sops.nix              # Secrets (age/sops)
│   ├── starship.nix          # Starship prompt config
│   ├── tmux.nix              # Tmux configuration
│   ├── zellij.nix            # Zellij terminal multiplexer
│   └── zsh.nix               # Zsh shell configuration
├── nvim/                     # Neovim configuration (NixVim-based, separate flake)
│   ├── flake.nix             # Neovim flake entry point
│   ├── module.nix            # Main NixVim configuration
│   ├── plugins.nix           # Plugin configurations (plus `nvim/plugins/`)
│   ├── keymaps.nix           # Key mappings
│   ├── autoCmd.nix           # Autocommands
│   ├── icons.nix             # Icons and UI helpers
│   ├── vscode.nix            # VSCode-focused nvim build
│   └── opencode/             # opencode.nvim providers and shared config
├── agents/                   # AI agent configs (OpenCode/Cursor, skills, tools)
│   ├── flake.nix             # Agents flake entry point
│   ├── opencode.nix          # OpenCode home-manager module (installs rules/agents)
│   └── cursor.nix            # Cursor module/rules
├── secrets/                  # Encrypted secrets (sops-nix)
│   └── secrets.yaml          # Encrypted API keys
├── catppuccin/               # Theme assets (Ghostty/OpenCode)
├── atuin/                    # Atuin shell history config
├── clickhouse-client/        # ClickHouse client config
├── ov.yaml                   # OpenCode configuration
├── uv-tools.sh               # uv helpers
├── starship.toml             # Starship prompt config (legacy / direct)
└── wezterm.lua               # WezTerm terminal config
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
- Plugin configs in `nvim/plugins.nix`
- Key mappings in `nvim/keymaps.nix`
- Core options in `nvim/module.nix`
- Autocmds in `nvim/autoCmd.nix`
- Extra per-plugin configs in `nvim/plugins/`
- Russian keyboard layout support via `langmap`
- AI integration via **opencode.nvim**

#### Adding Neovim Plugins

For plugins with NixVim modules, add to `nvim/plugins.nix`:

```nix
plugins.<name> = {
  enable = true;
  settings = { ... };
};
```

For plugins without NixVim modules, use `extraPlugins` in `module.nix`:

```nix
extraPlugins = [
  (pkgs.vimUtils.buildVimPlugin {
    name = "plugin-name";
    src = inputs.plugins-plugin-name;
    dependencies = with pkgs.vimPlugins; [ ... ];
  })
];
```

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

## Important Notes

1. **Do not edit** `flake.lock` manually — use `nix flake update`
2. **Neovim config** is built via NixVim in `nvim/` (not symlinked)
3. **Starship config** is at `starship.toml` (symlinked to `~/.config/`)
4. **Catppuccin** is the primary theme family (Mocha in most tools; Espresso is used in some terminal/OpenCode assets)
5. This repo is typically used with **Jujutsu (`jj`) on top of Git**; detect VCS before running VCS commands
6. **Touch ID for sudo** is enabled via PAM configuration

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
| `paneru` | Custom service |
| `nvim` | Neovim configuration (separate local flake) |
| `agents` | AI agent tooling (local flake) |
| `openspec` | OpenSpec tool |
