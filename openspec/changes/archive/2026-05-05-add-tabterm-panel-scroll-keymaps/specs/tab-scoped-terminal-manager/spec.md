## ADDED Requirements

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
