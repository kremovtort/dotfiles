## Why

Tabterm currently depends on Home Manager zsh configuration to emit shell integration events, so the plugin behavior is coupled to a user-specific shell setup outside Neovim. Moving bash and zsh integration into tabterm itself makes command state tracking portable while keeping integration configurable.

## What Changes

- Add plugin-owned shell integration for interactive `bash` and `zsh` shells started by tabterm.
- Add a tabterm setting that enables or disables shell integration injection.
- Ensure injected shell integration emits the terminal sequences tabterm already consumes for prompt, command start, command finish, title, and cwd updates.
- Keep shell integration optional so users can run tabterm shells without modifying shell startup behavior.
- Remove the need for tabterm-specific zsh hook code in `home-manager/zsh.nix` when the plugin setting is enabled.

## Capabilities

### New Capabilities

### Modified Capabilities

- `tab-scoped-terminal-manager`: Shell terminal integration requirements will cover optional plugin-owned injection for bash and zsh shells.

## Impact

- Affected code: `nvim/plugins/tabterm/lua/tabterm/*`, `nvim/plugins/tabterm/plugin/*`, and tabterm configuration wiring.
- Affected configuration: `nvim/plugins/tabterm.nix` or the local plugin setup options, plus removal or reduction of tabterm-specific shell hooks from `home-manager/zsh.nix` during implementation.
- Affected behavior: tabterm-created interactive shells can report command lifecycle, cwd, and title without global shell configuration, when enabled.
