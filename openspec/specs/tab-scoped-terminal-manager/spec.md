## Purpose

Define the expected behavior for the local tab-scoped floating terminal manager used in Neovim.

## Requirements

### Requirement: Tab-scoped terminal workspaces
The plugin SHALL maintain an independent terminal workspace for each Neovim tabpage. Each workspace SHALL track its own terminal ordering, active terminal selection, and floating UI visibility without mutating the terminal collections of other tabpages.

#### Scenario: Terminal lists stay isolated per tabpage
- **WHEN** the user creates terminals in two different tabpages
- **THEN** each tabpage SHALL show only its own terminals in the sidebar
- **AND** changing the active terminal in one tabpage SHALL NOT change the active terminal in another tabpage

#### Scenario: Closing one workspace UI does not delete another workspace
- **WHEN** the user closes the floating terminal UI in the current tabpage
- **THEN** the UI for that tabpage SHALL be marked closed
- **AND** terminals tracked by other tabpages SHALL remain unchanged

### Requirement: Sidebar rendering and derived terminal naming
The plugin SHALL render a sidebar for an open workspace and SHALL support `compact` and `detailed` display modes for terminal entries. Each terminal entry SHALL use a user-provided name when present and SHALL otherwise derive a display name from the last known cwd, terminal title, or command.

#### Scenario: Compact mode shows a concise terminal list
- **WHEN** the sidebar is configured for compact mode
- **THEN** each terminal entry SHALL render a single concise row suitable for navigation
- **AND** the entry SHALL still use the user override name when one exists

#### Scenario: Detailed mode shows terminal summary data
- **WHEN** the sidebar is configured for detailed mode
- **THEN** each terminal entry SHALL render a first line with the entry number and derived display name
- **AND** the entry SHALL render a second line with the terminal status and the last recorded output summary

### Requirement: Manual restore and placeholder-driven restart
The plugin SHALL restore terminal entries from saved session data without automatically restarting their processes. Restored or newly created dormant terminals SHALL render through a placeholder panel until the user explicitly starts them.

#### Scenario: Restored terminals remain dormant after session load
- **WHEN** the plugin restores a workspace from saved session data
- **THEN** restored terminal entries SHALL appear in the sidebar
- **AND** their processes SHALL remain stopped until the user explicitly starts one

#### Scenario: Placeholder panel is shown for a dormant terminal
- **WHEN** the active terminal exists but its runtime phase is dormant
- **THEN** the panel SHALL show a placeholder card instead of a terminal buffer
- **AND** the placeholder SHALL expose a start action for that terminal

### Requirement: Runtime state tracking and status summaries
The plugin SHALL track runtime terminal state, last known cwd, last known title, last result, and the last recorded output summary for each terminal. It SHALL report a waiting state only while a tracked command is actively running, and it SHALL preserve the last known result for dormant or exited terminals.

#### Scenario: Command terminal stores result and output summary on exit
- **WHEN** a tracked command terminal exits with a process status
- **THEN** the plugin SHALL store a success or error result with the exit code source marked as process-derived
- **AND** it SHALL store the last recorded output summary for sidebar and placeholder rendering

#### Scenario: Shell terminal updates command status from shell integration
- **WHEN** shell integration reports command execution and command finish events
- **THEN** the plugin SHALL mark the terminal as waiting only during command execution
- **AND** after command completion it SHALL store the reported success or error result with the source marked as shell-derived

### Requirement: Exited and externally closed UI states resolve predictably
The plugin SHALL collapse the panel to a placeholder when the active terminal exits, and it SHALL treat external closure of the sidebar or panel windows as closure of the entire workspace UI.

#### Scenario: Active exited terminal switches panel to placeholder
- **WHEN** the active terminal process exits while the workspace UI is open
- **THEN** the panel SHALL stop showing the terminal buffer
- **AND** the workspace SHALL render the placeholder card for the active terminal

#### Scenario: External window closure closes the workspace UI atomically
- **WHEN** the sidebar or panel window is closed outside the plugin's normal close action
- **THEN** the workspace SHALL mark its floating UI as closed
- **AND** the plugin SHALL clear the mounted sidebar and panel runtime handles for that workspace
