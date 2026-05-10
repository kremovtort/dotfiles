## MODIFIED Requirements

### Requirement: Subagent delegation tools provide Claude Code-style orchestration
The framework MUST expose model-callable subagent orchestration tools through the `subagent`, `get_subagent_result`, and `steer_subagent` workflow. Delegated subagents SHALL run in isolated Pi agent sessions with their own prompt, model, thinking level, active tools, runtime options, and identity. Result retrieval that waits for a queued or running background subagent SHALL observe the parent tool-call cancellation signal and stop waiting promptly when that signal is cancelled, releasing the parent Pi session for new user messages without changing the background run's lifecycle state.

#### Scenario: Foreground subagent returns result to parent
- **WHEN** the active agent invokes `subagent` for a foreground subagent task
- **THEN** the framework SHALL run the requested subagent in an isolated session
- **AND** the tool result SHALL return the subagent's final output to the parent agent

#### Scenario: Background subagent result is retrievable
- **WHEN** the active agent starts a background subagent task
- **THEN** the framework SHALL return a stable subagent run identifier
- **AND** a later `get_subagent_result` call with that identifier SHALL return the current or completed run result

#### Scenario: Waiting for background subagent result can be cancelled
- **WHEN** the active agent invokes `get_subagent_result` with `wait: true` for a queued or running background subagent
- **AND** the parent tool call is cancelled before the background subagent reaches a terminal state
- **THEN** the framework SHALL stop waiting and return control promptly
- **AND** the parent Pi session SHALL be able to accept a new user message without waiting for the background subagent to reach a terminal state
- **AND** the framework SHALL NOT mark the background subagent run as completed, failed, or aborted solely because result waiting was cancelled
- **AND** a later `get_subagent_result` call with that run identifier SHALL still report the run's current or completed result

#### Scenario: Running subagent can be steered
- **WHEN** a background subagent run is still active
- **AND** the active agent invokes `steer_subagent` with that run identifier
- **THEN** the framework SHALL deliver the steering message to the running subagent according to the subagent runtime's steering semantics
