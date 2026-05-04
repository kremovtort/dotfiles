## ADDED Requirements

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
