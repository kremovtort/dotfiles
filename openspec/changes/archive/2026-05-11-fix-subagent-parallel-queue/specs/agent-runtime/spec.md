## MODIFIED Requirements

### Requirement: Subagent runs preserve configured runtime and scheduling behavior
The framework MUST support subagent runtime options for foreground/background execution, maximum turns, context inheritance, and extension/skill inheritance. The framework SHALL apply concurrency limits to background runs and SHALL report queued, running, completed, failed, and aborted states. Parallel background launches SHALL each return a stable run identifier and SHALL NOT leave queued runs stuck when execution capacity is available.

#### Scenario: Background runs obey concurrency limit
- **WHEN** more background subagent runs are requested than the configured concurrency limit allows
- **THEN** the framework SHALL queue excess runs instead of starting all runs immediately
- **AND** queued runs SHALL start when earlier runs leave the running state

#### Scenario: Parallel background launches return independent run identifiers
- **WHEN** the active agent requests multiple background subagents in one tool-call batch
- **THEN** each launch SHALL return its own stable subagent run identifier
- **AND** each returned identifier SHALL be retrievable through `get_subagent_result`

#### Scenario: Parallel background launches survive interactive delegation approval
- **WHEN** multiple background subagent launches in one tool-call batch require interactive delegation approval
- **AND** the user approves those delegations
- **THEN** each approved launch SHALL proceed to execution
- **AND** each approved launch SHALL render or return its stable subagent run identifier independently

#### Scenario: Queued runs promote after active runs finish or fail
- **WHEN** a background subagent leaves the running state because it completed, failed, or was aborted during setup
- **THEN** the framework SHALL release that active execution slot
- **AND** queued runs SHALL be promoted while capacity remains available

#### Scenario: Queued status is explicit
- **WHEN** `get_subagent_result` is called for a queued run
- **THEN** the framework SHALL report that the run is queued rather than describing it as running
- **AND** the response SHALL include enough status information to distinguish a healthy queued run from a stale or stuck run
