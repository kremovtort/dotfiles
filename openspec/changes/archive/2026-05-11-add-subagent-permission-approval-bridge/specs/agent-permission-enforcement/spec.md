## ADDED Requirements

### Requirement: Subagent approval requests are parent-mediated
The framework MUST route approval-required tool calls from delegated subagents through a parent-visible permission approval bridge. The bridge SHALL request only the permission decision from the parent UI and SHALL NOT expose the full parent extension UI surface to the child session.

#### Scenario: Child ask prompts in parent-visible UI
- **WHEN** a running subagent requests a tool call that resolves to `ask` under its effective policy
- **AND** a parent-visible interactive UI is available
- **THEN** the framework SHALL present a permission prompt in the parent-visible UI before executing the tool call
- **AND** the prompt SHALL identify the subagent runtime identity, action fingerprint, action summary, matched rule when available, and approval scope choices
- **AND** the child tool call SHALL execute only if the user approves the request

#### Scenario: Child approval remains scoped to child identity
- **WHEN** the user approves a subagent permission request through the parent-visible bridge
- **THEN** the framework SHALL persist the approval against the subagent runtime identity and action fingerprint
- **AND** the approval SHALL NOT apply to the parent main agent, sibling subagents, or different action fingerprints

#### Scenario: Child ask denies without parent-visible approval path
- **WHEN** a running subagent requests a tool call that resolves to `ask`
- **AND** no parent-visible approval path is available
- **THEN** the framework SHALL deny the tool call before execution
- **AND** the denial reason SHALL state that interactive approval is unavailable for the subagent request

#### Scenario: Child ask denies on approval timeout or abort
- **WHEN** a running subagent permission request is waiting for user approval
- **AND** the approval timeout expires or the relevant abort signal is cancelled before the user approves
- **THEN** the framework SHALL deny the child tool call before execution
- **AND** the denial reason SHALL identify timeout or abort as the reason

### Requirement: Subagent permission waits are auditable
The framework MUST record subagent permission approval waits and their final outcomes in session-persistent audit data. Audit records SHALL be sufficient to distinguish an allowed, user-denied, timeout-denied, abort-denied, and UI-unavailable subagent request.

#### Scenario: Pending child approval records audit context
- **WHEN** a subagent tool call enters a pending approval wait
- **THEN** the framework SHALL record audit data containing the subagent identity, action fingerprint, action summary, matched rule when available, and pending approval state

#### Scenario: Resolved child approval records final outcome
- **WHEN** a pending subagent permission request resolves
- **THEN** the framework SHALL record whether the request was approved or denied
- **AND** the record SHALL include the approval scope or denial reason used for the decision
