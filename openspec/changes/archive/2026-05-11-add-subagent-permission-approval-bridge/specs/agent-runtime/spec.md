## ADDED Requirements

### Requirement: Child sessions receive a narrow permission approval bridge
The framework MUST pass a narrow permission approval bridge into subagent child enforcement when a parent-visible approval path exists. The child session SHALL remain headless for general extension UI and SHALL use the bridge only to resolve permission `ask` decisions for the assigned child runtime identity.

#### Scenario: Child enforcement uses assigned approval bridge
- **WHEN** the framework creates a subagent SDK child session
- **AND** parent-visible permission approval is available
- **THEN** the child tool-call enforcement path SHALL receive an approval bridge before the first child model turn
- **AND** approval decisions obtained through that bridge SHALL be evaluated for the assigned subagent identity and effective policy

#### Scenario: Full parent UI is not bound into child session
- **WHEN** a subagent child session is created with a permission approval bridge
- **THEN** the framework SHALL NOT bind the full parent `ExtensionUIContext` into the child session solely to support permission prompts
- **AND** inherited child extensions SHALL NOT gain parent editor, widget, status, header, footer, autocomplete, or custom UI mutation access through the permission bridge

#### Scenario: Headless child denies ask without bridge
- **WHEN** a subagent child session has no parent-visible approval bridge
- **AND** a child tool call resolves to `ask`
- **THEN** the child enforcement path SHALL fail closed with an explicit denial instead of waiting on a hidden or no-op child UI prompt

### Requirement: Subagent runs expose pending permission state
The framework MUST represent an in-flight subagent permission approval request as visible run metadata while preserving the run lifecycle as queued, running, completed, failed, aborted, or steered. The pending permission metadata SHALL be updated when approval starts and cleared when approval resolves.

#### Scenario: Foreground subagent progress shows permission wait
- **WHEN** a foreground subagent is waiting for permission approval
- **THEN** foreground tool progress SHALL show that the subagent is waiting for permission
- **AND** the progress text SHALL include enough action information to distinguish the pending request from ordinary thinking or tool execution

#### Scenario: Subagent widget shows permission wait
- **WHEN** a displayed subagent run is waiting for permission approval
- **THEN** the in-session subagent indicator SHALL render the run as active with a permission-waiting activity line
- **AND** the status SHALL NOT incorrectly imply that the run is merely thinking or has completed

#### Scenario: Pending permission clears after resolution
- **WHEN** a subagent permission request is approved, denied, timed out, or aborted
- **THEN** the framework SHALL clear the pending permission metadata for that run
- **AND** subsequent progress and widget updates SHALL reflect the run's current lifecycle and latest activity
