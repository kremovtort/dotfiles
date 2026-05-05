## ADDED Requirements

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
