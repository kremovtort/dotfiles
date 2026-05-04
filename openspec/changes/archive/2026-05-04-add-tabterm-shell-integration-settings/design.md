## Context

Tabterm already consumes OSC 133 and OSC 7 terminal sequences to update shell runtime state, command results, titles, and current working directories. Today those sequences are emitted by zsh hooks configured globally through Home Manager, which means tabterm shell behavior depends on a dotfiles-specific shell startup path rather than the plugin itself.

The plugin starts shell terminals itself through Neovim `jobstart()`, so it can influence the command and environment of tabterm-created interactive shells. Existing configuration flows through `require("tabterm").setup(...)` into `tabterm.config`, which is the right place to add an opt-in setting.

## Goals / Non-Goals

**Goals:**

- Provide plugin-owned shell integration for tabterm-created interactive `bash` and `zsh` shells.
- Make shell integration enabled by default for supported shells while allowing users to disable it globally or per shell.
- Preserve the existing OSC 133 and OSC 7 event contract already handled by tabterm.
- Avoid requiring tabterm-specific shell hooks in `home-manager/zsh.nix` when the setting is enabled.

**Non-Goals:**

- Inject integration into shells not started by tabterm.
- Support every possible shell in the first implementation.
- Replace user shell configuration or change behavior for normal terminal sessions outside tabterm.
- Add new terminal protocol semantics beyond the existing prompt, command, cwd, title, and exit-status events.

## Decisions

### Add a `shell_integration` config namespace with a per-shell allowlist

Add a config shape similar to:

```lua
shell_integration = {
  enabled = true,
  shells = {
    bash = true,
    zsh = true,
  },
}
```

This keeps integration enabled by default for supported shells while still allowing users to disable all injection or opt out per shell. The Nix setup can override these values by passing the option through the existing `require("tabterm").setup(...)` call.

Alternative considered: infer integration from a global environment variable. That would be harder to discover and would not fit the plugin's existing setup API.

### Inject only for supported interactive shell terminals

When `shell_integration.enabled` is true and `terminal.spec.kind == "shell"`, tabterm should detect whether the configured shell basename is `bash` or `zsh` and check that the matching allowlist entry is enabled. Supported and allowed shells should be started through a wrapper command or wrapper startup directory that sources plugin-owned integration scripts. Unsupported or disabled shells should start normally.

This limits behavior changes to tabterm-created interactive shells and avoids surprising users running command terminals.

Alternative considered: send `source <script>` into the pty after startup. That is fragile because it can race the prompt, appear in user input, and fail when the shell is already executing something.

### Use shell-native startup mechanics

For bash, start an interactive shell with a plugin-owned rcfile that sources the user's normal bash startup file and then the tabterm bash integration script.

For zsh, use a generated `ZDOTDIR` containing a wrapper `.zshrc` that restores the user's original `ZDOTDIR`, sources the user's normal `.zshrc`, and then sources the tabterm zsh integration script. This works around zsh not having a direct `--rcfile` equivalent.

Alternative considered: require users to source a plugin script from their own shell config. That is simpler to implement but keeps the existing global shell configuration coupling this change is intended to remove.

### Keep shell scripts plugin-owned and protocol-compatible

The bash and zsh integration scripts should live with the tabterm plugin and emit the same OSC sequences the Lua side already consumes:

- OSC 133 `A` for prompt start.
- OSC 133 `B` for command input start.
- OSC 133 `C` for command execution start.
- OSC 133 `D;<exit_code>` for command finish.
- OSC 7 for cwd reporting.
- OSC 2 for terminal title updates.

The zsh script can reuse the current `precmd` and `preexec` behavior. The bash script should use `PROMPT_COMMAND` and a `DEBUG` trap carefully so command execution events are emitted once per user command rather than for every internal prompt helper.

## Risks / Trade-offs

- Bash `DEBUG` trap behavior is easy to over-trigger -> Keep the bash integration minimal and guard command-active state explicitly.
- Wrapping shell startup can affect ordering of user shell initialization -> Source user startup files before tabterm integration so user configuration remains primary.
- Users may already have shell integration emitting OSC 133 globally -> Keep the setting configurable, allow disabling per shell, and make scripts idempotent where practical.
- zsh `ZDOTDIR` wrapping changes startup environment during shell initialization -> Restore the original `ZDOTDIR` before sourcing user config.
- Unsupported shells will not get rich command tracking -> Fall back to current normal shell launch without failing terminal creation.

## Migration Plan

- Add the config option with shell integration enabled by default for bash and zsh.
- Add plugin-owned bash and zsh integration scripts plus startup wrapper generation.
- Enable the setting in the local Nix tabterm setup.
- Remove the tabterm-specific OSC hook block from `home-manager/zsh.nix` after plugin-owned zsh integration works.
- Rollback by disabling `shell_integration.enabled` and restoring the Home Manager zsh hook block if needed.

## Open Questions

- None currently.
