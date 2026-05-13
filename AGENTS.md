# AGENTS.md

This document provides guidance for AI agents working with this dotfiles repository.

## Repository Overview

This is a **Nix-based dotfiles** repository for macOS (aarch64-darwin) and Linux systems. It uses:

- **Nix Flakes** for reproducible package management
- **nix-darwin** for macOS system configuration
- **home-manager** for user environment management
- **NixVim** for declarative Neovim configuration
- **sops-nix** for secrets management
- **OpenSpec** for structured feature/change workflows
- **OpenCode** and **Pi** agent configuration under `agents/`

### Owner

- Username: `kremovtort`
- Name: Alexander Makarov
- Email: i@kremovtort.ru

## Project Structure

```text
.
├── flake.nix                 # Main flake entry point
├── flake.lock                # Locked root dependencies
├── init.sh                   # Bootstrap script (installs Nix, runs switch)
├── justfile                  # Task runner commands
├── darwin/                   # macOS system configuration (nix-darwin)
│   ├── configuration.nix     # System settings, keyboard, PAM/TouchID
│   ├── homebrew.nix          # Homebrew taps/brews
│   └── paneru.nix            # Paneru macOS window-management module
├── home-manager/             # User environment configuration
│   ├── home.nix              # Main home-manager config
│   ├── karabiner.nix         # Keyboard remapping
│   ├── sops.nix              # Secrets (age/sops)
│   ├── starship.nix          # Starship prompt config
│   ├── wezterm.nix           # WezTerm terminal config
│   ├── wezterm/              # WezTerm Lua modules
│   └── zsh.nix               # Zsh shell configuration
├── nvim/                     # Neovim configuration (NixVim, separate flake)
│   ├── flake.nix             # Neovim flake entry point
│   ├── flake.lock            # Locked Neovim flake inputs
│   ├── config.nix            # Base config module (imports `nvim/config/*`)
│   ├── config/               # Core options, keymaps, autocmds, colors, clipboard
│   ├── plugins.nix           # Plugin module aggregator (imports `nvim/plugins/*`)
│   ├── plugins/              # Per-plugin modules and local plugin assets
│   │   ├── opencode/         # opencode.nvim provider modules (frontend disabled)
│   │   ├── tabterm/          # Local tabterm plugin flake and shell integration
│   │   └── lualine/          # Lua helpers for lualine
│   ├── vscode.nix            # VSCode-focused nvim build
│   └── README.md             # Neovim flake docs
├── agents/                   # AI agent configs (OpenCode, Pi, skills, commands)
│   ├── flake.nix             # Agents flake entry point
│   ├── flake.lock            # Agents flake lock
│   ├── opencode.nix          # OpenCode home-manager module
│   ├── pi.nix                # Pi home-manager module
│   ├── opencode/             # OpenCode agents and shared instructions
│   ├── pi/                   # Pi settings, agent definitions, package overrides
│   ├── skills/               # Shared custom skills
│   └── commands/             # Custom OpenCode commands
├── .pi/                      # Local/ignored Pi project skills and runtime state
├── openspec/                 # OpenSpec workflow artifacts
│   ├── config.yaml
│   ├── changes/              # Active/archived changes
│   └── specs/                # Main specs
├── secrets/                  # Encrypted secrets (sops-nix)
├── catppuccin/               # Theme assets (Ghostty/OpenCode/Pi)
├── atuin/                    # Atuin config asset
├── clickhouse-client/        # ClickHouse client config
└── ov.yaml                   # `ov` pager config
```

## Key Commands

All commands are run via `just` (task runner):

| Command | Description |
|---------|-------------|
| `just switch` | Apply all configurations (`darwin` + `home-manager` on macOS; `home-manager` + shell setup on Linux) |
| `just switch home` | Apply only home-manager configuration (macOS target dispatch) |
| `just switch darwin` | Apply only darwin/system configuration (macOS target dispatch) |
| `just upgrade` | Update flake inputs and apply changes (plus `brew update` / `brew upgrade` on macOS) |
| `just darwin-rebuild-switch` | Low-level: `sudo nix run .#darwin-rebuild -- switch --flake .` |
| `just home-manager-switch` | Low-level: `nix run .#home-manager -- switch --flake .` |
| `just setup-shell` | Ensure the Nix profile `zsh` is a valid login shell on non-NixOS Linux |

### Bootstrap (Fresh Install)

```bash
./init.sh
```

This script:

1. Installs Nix via the Determinate Systems installer
2. Runs `just switch` to apply configurations

## Configuration Guidelines

### Nix Files

- Use **nixpkgs-unstable** channel.
- Follow existing patterns in `home-manager/home.nix` for adding user packages.
- Platform-specific packages use the existing `isDarwin` / `lib.mkIf` style.
- Do not edit lock files manually. Use `nix flake update` or targeted flake update commands.
- Root overlays expose `pkgs.nvim`, `pkgs.nvim4vscode`, and `pkgs.jj-starship` from local flake inputs.

### Adding Packages

1. **System-wide (macOS only)**: edit `darwin/configuration.nix`.
2. **User packages**: edit `home-manager/home.nix` → `home.packages`.
3. **Homebrew packages/taps (macOS)**: edit `darwin/homebrew.nix`.
4. **Agent/Pi/OpenCode packages or settings**: edit files under `agents/` and apply via home-manager.

### Adding Programs with Options

For programs with home-manager modules, add to `home-manager/home.nix` or a focused imported module:

```nix
programs.<name> = {
  enable = true;
  enableZshIntegration = true;  # if applicable
  # ... other options
};
```

### Neovim Configuration

- Based on **NixVim** (declarative Neovim configuration via Nix).
- Self-contained flake in `nvim/`.
- Base config is composed in `nvim/config.nix` (imports `nvim/config/*`).
- Plugin config is composed in `nvim/plugins.nix` (imports `nvim/plugins/*`).
- Global (non-plugin) keymaps live in `nvim/config/keymaps.nix`.
- Plugin-specific keymaps live next to the plugin config in `nvim/plugins/*.nix`.
- Autocmds live in `nvim/config/autoCmd.nix`.
- Russian keyboard layout support (`langmap` + langmapper.nvim) lives in `nvim/plugins/langmapper.nix`.
- Icons are provided via `_module.args.icons` from `nvim/plugins/icons.nix` (avoid `vim.g` globals).
- Current plugin modules include `cursortab`, `direnv`, `sidekick`, `tabterm`, `zoxide`, and the existing LSP/UI/editing modules imported from `nvim/plugins.nix`.
- `nvim/plugins/tabterm/` is a local plugin flake used through the `tabterm` input in `nvim/flake.nix`.
- `nvim/plugins/opencode/` keeps opencode.nvim provider modules, but the frontend imports are currently disabled in `nvim/plugins.nix`; standalone OpenCode is configured under `agents/`.
- Changing inputs in `nvim/` normally requires updating both `nvim/flake.lock` and the root `flake.lock` path input used by `pkgs.nvim`.

#### Adding Neovim Plugins

Prefer creating or adjusting a per-plugin module in `nvim/plugins/<plugin>.nix` and importing it from `nvim/plugins.nix`.

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
    src = nvimInputs.plugins-plugin-name;
    dependencies = with pkgs.vimPlugins; [ ... ];
  })
];
```

External plugin sources are usually declared in `nvim/flake.nix` as `flake = false` inputs.

### AI Agent Configuration

- `agents/flake.nix` provides the home-manager module imported by the root flake and depends on `llm-agents.nix`.
- `agents/opencode.nix` configures OpenCode, plugins, MCP servers, provider API key paths, shared instructions, commands, skills, agents, and TUI keybindings.
- `agents/pi.nix` installs Pi from `llm-agents.nix` and symlinks Pi settings, theme, agents, skills, and magic-context config into `~/.pi/agent`.
- Shared base instructions live in `agents/opencode/instructions/`; `agents/pi.nix` concatenates them into Pi's global `AGENTS.md`.
- OpenCode subagents live in `agents/opencode/agents/`: `codemodder`, `researcher`, `scout`, and `openspec-reviewer-{gpt,glm,kimi}`.
- Pi subagents live in `agents/pi/agents/` with matching custom agents plus exact-name disabled overrides for upstream `Explore`, `Plan`, and `general-purpose`.
- Shared skills live in `agents/skills/`: `add-nixvim-plugin`, `jujutsu`, `vcs-detect`, and OpenSpec review skills.
- Local project Pi OpenSpec workflow skills live under `.pi/skills/` when present (the `.pi/` directory is ignored by git).
- Pi packages are listed in `agents/pi/settings.json` (subagents, Plannotator, Tavily web search, magic context, processes, smart fetch, hashline readmap, Mermaid, MCP adapter, ask-user).
- After changing agent configs, run `just switch home`; restart or reload the relevant OpenCode/Pi session before manual testing.

### OpenSpec Workflow

- OpenSpec config lives in `openspec/config.yaml`.
- Active changes live under `openspec/changes/<change-name>/` with `proposal.md`, `design.md`, `tasks.md`, optional `.openspec.yaml`, and delta specs as needed.
- Main specs live under `openspec/specs/`.
- Use OpenSpec skills for new changes, continuing changes, verification, review, syncing, and archiving.

### Secrets Management

Secrets are encrypted with **sops-nix** using age keys derived from SSH:

```bash
# Edit secrets
sops secrets/secrets.yaml

# Add new secret reference in home-manager/sops.nix
sops.secrets.<secret-name> = {};
```

## Development Environment

Enter the dev shell with LSP/formatting support:

```bash
nix develop
```

Provides:

- `nixd` (Nix LSP)
- `lua`
- `lua-language-server`
- `bash-language-server`
- `nixfmt`
- `statix` (Nix linter)
- `shellcheck`
- `stylua`
- `just`

## Important Notes

1. **Do not edit** `flake.lock`, `nvim/flake.lock`, or `agents/flake.lock` manually — use flake update commands.
2. **Neovim config** is built via NixVim in `nvim/` (not symlinked).
3. **Starship** and **WezTerm** are configured through `home-manager/starship.nix` and `home-manager/wezterm.nix`.
4. **Catppuccin** is the primary theme family (Mocha in most tools; Espresso is used for OpenCode/Pi/Ghostty assets).
5. This repo is typically used with **Jujutsu (`jj`) on top of Git**; detect VCS before running VCS commands.
6. **Touch ID for sudo** is enabled via nix-darwin PAM configuration.
7. **OpenSpec** workflow lives in `openspec/` and is used for structured feature development.
8. Do not run broad recursive searches over Arcadia roots (`~/arcadia`, `/codenv/arcadia`) or parent directories; search this repo or a specific known subdirectory only.
9. Use `process`/background-process tooling for long-running dev servers, watchers, or noisy test loops.

## External Dependencies

- **Homebrew**: managed via nix-darwin; currently used for `arc-launcher` and `macism`.
- **Yandex Arc**: internal VCS tooling, tapped from the Yandex Homebrew tap.
- **Paneru**: macOS window-management flake input imported by `darwin/paneru.nix`.
- **Node/Bun/npx**: used by OpenCode/Pi plugins and MCP servers.

## Testing Changes

1. Make changes to Nix/config files.
2. Format/lint when appropriate (`nixfmt`, `statix`, `stylua`, `shellcheck`).
3. Apply with the narrowest relevant command:
   - `just switch home` for home-manager/user/agent changes.
   - `just switch darwin` for macOS system changes.
   - `just switch` for full configuration application.
4. For Neovim-only changes, build/apply the `nvim` flake or run `just switch home`, then restart Neovim.
5. For OpenCode/Pi changes, run `just switch home`, then restart/reload the affected agent UI.
6. Check terminal output for errors.

## Flake Inputs

Root `flake.nix` inputs:

| Input | Purpose |
|-------|---------|
| `nixpkgs` | Package repository (unstable) |
| `flake-parts` | Flake structure helper |
| `karabinix` | Karabiner-Elements Nix module |
| `jj-starship` | Starship integration for Jujutsu |
| `paneru` | macOS window-management configuration |
| `nix-darwin` | macOS system management |
| `home-manager` | User environment management |
| `sops-nix` | Secrets management |
| `nvim` | Neovim configuration (local separate flake) |
| `agents` | AI agent tooling (local separate flake) |

Nested flakes:

- `nvim/flake.nix` uses `nixvim`, local `tabterm`, and external plugin source inputs such as `plugins-opencode-nvim`, `plugins-vcsigns-nvim`, `plugins-vclib-nvim`, `plugins-async-nvim`, `plugins-virtual-types-nvim`, `plugins-seeker-nvim`, `plugins-direnv-nvim`, and `plugins-cursortab-nvim`.
- `agents/flake.nix` uses `llm-agents`, `anthropicSkills`, and `astGrepClaudeSkill`.
