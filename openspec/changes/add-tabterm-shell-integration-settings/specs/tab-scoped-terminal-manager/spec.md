## ADDED Requirements

### Requirement: Configurable shell integration injection
The plugin SHALL provide shell integration injection for tabterm-created interactive shell terminals. Shell integration SHALL be enabled by default, SHALL support a per-shell allowlist for `bash` and `zsh`, and SHALL NOT be injected when the global setting or matching shell allowlist entry is disabled.

#### Scenario: Supported shell receives integration by default
- **WHEN** the user starts a tabterm shell terminal with `bash` or `zsh` and does not override shell integration settings
- **THEN** the plugin SHALL start the shell with plugin-owned shell integration loaded

#### Scenario: Global shell integration disable bypasses injection
- **WHEN** the user starts a tabterm shell terminal with shell integration globally disabled
- **THEN** the plugin SHALL start the configured shell without injecting plugin-owned shell integration

#### Scenario: Per-shell disable bypasses injection
- **WHEN** the user starts a tabterm shell terminal whose shell allowlist entry is disabled
- **THEN** the plugin SHALL start that shell without injecting plugin-owned shell integration

#### Scenario: Unsupported shell bypasses injection
- **WHEN** the user starts a tabterm shell terminal using a shell other than `bash` or `zsh`
- **THEN** the plugin SHALL start that shell without injecting plugin-owned shell integration

### Requirement: Bash and zsh integration events
Injected `bash` and `zsh` shell integration SHALL emit terminal sequences compatible with tabterm's existing terminal request handling for prompt start, command input start, command execution start, command finish with exit status, current working directory, and terminal title updates.

#### Scenario: Prompt reports cwd and readiness
- **WHEN** an injected shell displays a prompt
- **THEN** the shell integration SHALL emit a prompt-start event
- **AND** it SHALL report the current working directory
- **AND** it SHALL set the terminal title to the shell name

#### Scenario: Command lifecycle reports execution state
- **WHEN** the user runs a command in an injected shell
- **THEN** the shell integration SHALL emit command input and command execution events before the command runs
- **AND** it SHALL emit a command finish event with the command exit status before the next prompt

#### Scenario: User shell startup remains primary
- **WHEN** the plugin injects shell integration into `bash` or `zsh`
- **THEN** the user's normal shell startup file SHALL be sourced before the plugin-owned integration script
