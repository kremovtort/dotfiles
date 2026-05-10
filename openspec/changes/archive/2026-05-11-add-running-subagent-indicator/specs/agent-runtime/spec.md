## ADDED Requirements

### Requirement: Runtime displays active subagent indicator matching pi-subagents
The framework MUST display an in-session indicator for subagent runs using the same visible appearance as `tintinweb/pi-subagents`. The indicator SHALL include the same status-bar text grammar, above-editor `Agents` widget presentation, tree layout, connector characters, icons, spinner frames, color intent, activity line format, queued summary format, finished-run rendering, truncation behavior, and overflow behavior as the upstream running-subagent indicator.

#### Scenario: Running subagent appears in copied widget style
- **WHEN** a subagent run is running in the current Pi session
- **THEN** the framework SHALL show an above-editor widget with the `pi-subagents` `Agents` heading style
- **AND** the running subagent SHALL be rendered with the upstream spinner frames, tree connector layout, display name, description, stats suffix, and `⎿` activity line format
- **AND** the status bar SHALL show the upstream `subagents` status wording for the number of running agents

#### Scenario: Queued subagents appear with upstream queued summary
- **WHEN** one or more subagent runs are queued for an execution slot
- **THEN** the widget SHALL render the queued summary using the same queued marker and wording as `pi-subagents`
- **AND** the status bar SHALL include queued counts using the same status wording as `pi-subagents`

#### Scenario: Completed and failed subagents linger like upstream
- **WHEN** a displayed subagent run completes, is steered to wrap up, stops, fails, or aborts
- **THEN** the widget SHALL render the finished run with the same completion, stopped, warning, or error icon style as `pi-subagents`
- **AND** the finished run SHALL remain visible for the same turn-linger behavior used by `pi-subagents` before being removed from the widget

#### Scenario: Indicator clears when no runs are visible
- **WHEN** there are no running or queued subagent runs
- **AND** no finished subagent run is still within its linger window
- **THEN** the framework SHALL remove the above-editor `Agents` widget
- **AND** the framework SHALL clear the `subagents` status-bar entry

#### Scenario: Indicator updates without result polling
- **WHEN** subagent lifecycle state changes because a run is created, queued, promoted, starts, records activity, completes, fails, aborts, or is steered
- **THEN** the indicator SHALL update without requiring `get_subagent_result` to be called
