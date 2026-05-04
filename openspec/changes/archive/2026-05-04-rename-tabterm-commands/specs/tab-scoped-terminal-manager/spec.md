## ADDED Requirements

### Requirement: Unified Tabterm user command API
The plugin SHALL expose tabterm actions through a single `:Tabterm` user command with lowercase subcommands, and SHALL NOT register the previous top-level `Tabterm*` action commands.

#### Scenario: Existing actions dispatch through subcommands
- **WHEN** the user invokes `:Tabterm toggle`, `:Tabterm open`, `:Tabterm close`, `:Tabterm start`, `:Tabterm rename`, `:Tabterm delete`, `:Tabterm next`, or `:Tabterm prev`
- **THEN** the plugin SHALL execute the same action previously exposed by the corresponding `TabtermToggle`, `TabtermOpen`, `TabtermClose`, `TabtermStart`, `TabtermRename`, `TabtermDelete`, `TabtermNext`, or `TabtermPrev` command

#### Scenario: New command creation uses command subcommand
- **WHEN** the user invokes `:Tabterm command` with or without trailing command text
- **THEN** the plugin SHALL create a command terminal using the same behavior previously exposed by `TabtermNewCommand`
- **AND** the plugin SHALL pass trailing command text as the optional command value when it is present

#### Scenario: New shell creation uses shell subcommand
- **WHEN** the user invokes `:Tabterm shell`
- **THEN** the plugin SHALL create an interactive shell terminal using the same behavior previously exposed by `TabtermNewShell`

#### Scenario: Subcommand completion lists supported actions
- **WHEN** the user requests command-line completion for `:Tabterm `
- **THEN** the plugin SHALL offer the supported subcommands `toggle`, `open`, `close`, `shell`, `command`, `start`, `rename`, `delete`, `next`, and `prev`
