## 1. Configuration

- [x] 1.1 Add `shell_integration` defaults to `nvim/plugins/tabterm/lua/tabterm/config.lua` with `enabled = true` and per-shell `bash`/`zsh` allowlist entries enabled by default.
- [x] 1.2 Normalize partial `shell_integration` user config so missing nested values fall back to defaults.
- [x] 1.3 Update the local Nix tabterm setup only if it needs explicit overrides or documentation of the default behavior.

## 2. Shell Integration Scripts

- [x] 2.1 Add a plugin-owned zsh integration script that emits the existing OSC 133, OSC 7, and OSC 2 sequences using `precmd` and `preexec` hooks.
- [x] 2.2 Add a plugin-owned bash integration script that emits the existing OSC 133, OSC 7, and OSC 2 sequences using `PROMPT_COMMAND` and a guarded `DEBUG` trap.
- [x] 2.3 Make integration scripts safe to source more than once in the same shell session where practical.

## 3. Shell Startup Injection

- [x] 3.1 Add Lua helpers to detect the shell basename from `terminal.spec.cmd` and decide whether integration is enabled for that shell.
- [x] 3.2 Implement bash startup wrapping so tabterm starts interactive bash with a generated rcfile that sources the user's normal bash startup file before the plugin integration script.
- [x] 3.3 Implement zsh startup wrapping with a generated `ZDOTDIR` and wrapper `.zshrc` that restores the original `ZDOTDIR`, sources the user's normal `.zshrc`, then sources the plugin integration script.
- [x] 3.4 Update terminal `jobstart()` options to pass wrapper commands and environment only for supported, enabled shell terminals.
- [x] 3.5 Ensure unsupported shells, disabled global integration, disabled per-shell integration, and command terminals continue to start without injection.

## 4. Cleanup And Verification

- [x] 4.1 Remove the tabterm-specific OSC hook implementation from `home-manager/zsh.nix` once plugin-owned zsh integration covers the same behavior.
- [x] 4.2 Verify zsh shell terminals report prompt, command start, command finish, cwd, and title updates through tabterm.
- [x] 4.3 Verify bash shell terminals report prompt, command start, command finish, cwd, and title updates through tabterm.
- [x] 4.4 Verify global disable and per-shell disable settings bypass injection while leaving shell startup functional.
- [x] 4.5 Run the repository's relevant formatting/check command for the touched Nix and Lua files.
