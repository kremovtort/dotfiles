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

### Requirement: Sidebar keymaps scroll the panel
When the floating UI is open and the sidebar is focused, the plugin SHALL provide sidebar normal-mode mappings for `<C-d>`, `<C-u>`, `<C-f>`, and `<C-b>`. These mappings SHALL scroll the currently visible panel window using the equivalent panel normal-mode scroll commands and SHALL keep focus in the sidebar after the scroll action.

#### Scenario: Sidebar half-page scrolls panel down
- **WHEN** the floating UI is open with a valid panel window and the user presses `<C-d>` in the sidebar
- **THEN** the plugin SHALL scroll the panel as if `<C-d>` were pressed in that panel's normal mode
- **AND** focus SHALL remain in the sidebar

#### Scenario: Sidebar half-page scrolls panel up
- **WHEN** the floating UI is open with a valid panel window and the user presses `<C-u>` in the sidebar
- **THEN** the plugin SHALL scroll the panel as if `<C-u>` were pressed in that panel's normal mode
- **AND** focus SHALL remain in the sidebar

#### Scenario: Sidebar full-page scrolls panel down
- **WHEN** the floating UI is open with a valid panel window and the user presses `<C-f>` in the sidebar
- **THEN** the plugin SHALL scroll the panel as if `<C-f>` were pressed in that panel's normal mode
- **AND** focus SHALL remain in the sidebar

#### Scenario: Sidebar full-page scrolls panel up
- **WHEN** the floating UI is open with a valid panel window and the user presses `<C-b>` in the sidebar
- **THEN** the plugin SHALL scroll the panel as if `<C-b>` were pressed in that panel's normal mode
- **AND** focus SHALL remain in the sidebar

#### Scenario: Panel kind does not gate sidebar scrolling
- **WHEN** the floating UI is open with a valid panel window that contains either terminal or placeholder content
- **THEN** the sidebar panel-scroll mappings SHALL attempt to scroll that panel window without checking the panel kind

### Requirement: Configurable floating UI border styles
The plugin SHALL support `single`, `double`, `round`, and `none` as floating UI border style values. The plugin SHALL keep boolean border compatibility by treating `true` as `single` and `false` as `none`.

#### Scenario: Supported border style configures workspace floats
- **WHEN** the user configures the tabterm UI border as `single`, `double`, or `round`
- **THEN** the sidebar and panel windows SHALL use the configured border style
- **AND** the workspace layout SHALL reserve border space consistently for both windows

#### Scenario: Borderless style removes float borders
- **WHEN** the user configures the tabterm UI border as `none`
- **THEN** the sidebar and panel windows SHALL render without float borders
- **AND** the workspace layout SHALL NOT reserve border space between the sidebar and panel windows
- **AND** the panel window SHALL reserve one column of left padding before terminal content

#### Scenario: Boolean border input remains supported
- **WHEN** the user configures the tabterm UI border as `true` or `false`
- **THEN** `true` SHALL behave as the `single` border style
- **AND** `false` SHALL behave as the `none` border style

### Requirement: Borderless sidebar background distinction
When the floating UI border style is `none`, the plugin SHALL render the sidebar and panel with distinct effective backgrounds based on their roles, independent of which window is selected. This distinction SHALL be scoped to the borderless layout and SHALL be exposed through tabterm-owned highlight groups.

#### Scenario: Borderless sidebar remains visually distinct
- **WHEN** the user configures the tabterm UI border as `none`
- **THEN** the sidebar window SHALL always use `TabtermSidebar`, based on `Normal` by default
- **AND** the panel window SHALL always use `TabtermPanel`, based on `NormalFloat` by default
- **AND** focusing either window SHALL NOT swap those effective backgrounds between roles

#### Scenario: Bordered layouts keep existing background behavior
- **WHEN** the user configures the tabterm UI border as `single`, `double`, or `round`
- **THEN** the sidebar and panel windows SHALL use the same `TabtermPanel` effective floating background mapping
- **AND** the plugin SHALL NOT apply the borderless-only sidebar `TabtermSidebar` and panel `TabtermPanel` split
- **AND** the panel window SHALL NOT reserve borderless-only left padding

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

### Requirement: Tabterm panel focus respects terminal mode intent
When the floating UI is open, the plugin SHALL manage Terminal-mode entry for tabterm panel buffers according to terminal kind and remembered mode intent. Shell terminal panels SHALL default to insert mode when there is no remembered normal-mode intent. The plugin SHALL NOT automatically re-enter Terminal-mode for a panel terminal after the user manually leaves Terminal-mode or after the user scrolls that panel from the sidebar.

#### Scenario: Shell panel defaults to insert mode without normal-mode intent
- **WHEN** the floating UI is open with a live shell terminal panel
- **AND** there is no remembered normal-mode intent for that shell terminal
- **WHEN** the user moves focus from the sidebar to the panel
- **THEN** the plugin SHALL enter Terminal-mode for that shell terminal

#### Scenario: Manual normal-mode exit is preserved for shell panel focus
- **WHEN** the floating UI is open with a live shell terminal panel
- **AND** the user manually leaves Terminal-mode for that shell terminal
- **WHEN** the user moves focus away from the panel and then focuses the panel again from the sidebar
- **THEN** the plugin SHALL NOT automatically re-enter Terminal-mode

#### Scenario: Sidebar panel scroll is preserved for later shell panel focus
- **WHEN** the floating UI is open with a live shell terminal panel
- **AND** the user scrolls the panel from the sidebar
- **WHEN** the user later moves focus from the sidebar to the panel
- **THEN** the plugin SHALL NOT automatically re-enter Terminal-mode
- **AND** the user's panel scrollback interaction SHALL NOT be reset by implicit Terminal-mode entry

#### Scenario: Explicit terminal entry clears normal-mode intent
- **WHEN** the floating UI is open with a live shell terminal panel that has remembered normal-mode intent
- **AND** the user explicitly enters Terminal-mode for that shell terminal
- **WHEN** the user later focuses the panel from the sidebar
- **THEN** the plugin MAY enter Terminal-mode for that shell terminal by default

#### Scenario: Command panels do not auto-enter Terminal-mode
- **WHEN** the floating UI is open with a command terminal panel
- **WHEN** the user moves focus from the sidebar to the panel
- **THEN** the plugin SHALL NOT automatically enter Terminal-mode for that command terminal

#### Scenario: Exited command panel defensively leaves Terminal-mode
- **WHEN** the floating UI is open with a command terminal panel whose runtime phase is `exited`
- **WHEN** the user moves focus from the sidebar to the panel
- **THEN** the plugin SHALL ensure the panel is not left in Terminal-mode

### Requirement: Tabterm panel buffers are classified by filetype
The plugin SHALL assign role-specific filetypes to tabterm panel buffers. Shell terminal buffers SHALL use `tabterm-panel-shell`, command terminal buffers SHALL use `tabterm-panel-command`, and placeholder panel buffers SHALL use `tabterm-panel-placeholder`.

#### Scenario: Shell terminal panel has shell filetype
- **WHEN** the plugin creates a shell terminal buffer for the panel
- **THEN** that buffer's filetype SHALL be `tabterm-panel-shell`

#### Scenario: Command terminal panel has command filetype
- **WHEN** the plugin creates a command terminal buffer for the panel
- **THEN** that buffer's filetype SHALL be `tabterm-panel-command`

#### Scenario: Placeholder panel has placeholder filetype
- **WHEN** the plugin creates or renders a placeholder buffer for the panel
- **THEN** that buffer's filetype SHALL be `tabterm-panel-placeholder`

### Requirement: Global terminal auto-insert skips tabterm panel buffers
The global terminal `BufEnter` behavior SHALL preserve automatic insert-mode entry for non-tabterm terminal buffers while skipping tabterm panel terminal buffers. A terminal buffer whose filetype starts with `tabterm-panel-` SHALL NOT be auto-startinserted by the global `term://*` `BufEnter` autocmd.

#### Scenario: Non-tabterm terminal keeps global auto-insert
- **WHEN** the user enters a terminal buffer that is not a tabterm panel buffer
- **THEN** the global terminal `BufEnter` behavior SHALL continue to enter Terminal-mode automatically

#### Scenario: Tabterm panel terminal skips immediate auto-insert scheduling
- **WHEN** the user enters a terminal buffer whose filetype starts with `tabterm-panel-`
- **THEN** the global terminal `BufEnter` behavior SHALL NOT schedule automatic Terminal-mode entry for that buffer

#### Scenario: Tabterm panel terminal skips delayed auto-insert
- **WHEN** the global terminal `BufEnter` behavior has scheduled an automatic Terminal-mode entry callback
- **AND** the current buffer at callback time has a filetype starting with `tabterm-panel-`
- **THEN** the callback SHALL NOT enter Terminal-mode