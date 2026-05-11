## ADDED Requirements

### Requirement: Subagent runs persist durable child session files
The framework MUST create a durable child session for each delegated subagent using Pi's standard SessionManager JSONL session format. Child session files SHALL be stored separately from normal interactive sessions under `subagent-sessions/--cwd--/<parentSessionId>/` and SHALL be linked from the parent subagent run record.

#### Scenario: Subagent launch creates child session metadata
- **WHEN** the active agent launches a foreground or background subagent
- **THEN** the framework SHALL create the subagent with a persistent SessionManager rather than an in-memory SessionManager
- **AND** the subagent run record SHALL include the child session id and child session file path when they are available
- **AND** the child session file path SHALL be under `subagent-sessions/--cwd--/<parentSessionId>/`

#### Scenario: Child session uses standard JSONL format
- **WHEN** a subagent child session is persisted
- **THEN** the session file SHALL contain the standard Pi JSONL session header and append-only session entries
- **AND** the framework SHALL NOT store the child transcript in a custom non-SessionManager transcript format

#### Scenario: Child session links to parent session
- **WHEN** the parent Pi session has a persisted session identifier or session file path
- **THEN** the child session SHALL record the parent relationship in standard session metadata
- **AND** the parent subagent run record SHALL retain enough metadata to locate the child session later

#### Scenario: Parent run remains a lightweight index
- **WHEN** a subagent produces assistant messages and tool results
- **THEN** the full child transcript SHALL be written to the child session file
- **AND** the parent run record SHALL store only status, summary output, error, counters, identity, and child-session metadata needed for retrieval and display

### Requirement: Restored non-live subagent runs become interrupted when resumable
The framework MUST distinguish a restored non-live subagent run with a durable child session from a permanently aborted run. A restored `queued` or `running` run that no longer has a live SDK session but has a child session file SHALL be represented as `interrupted` and resumable.

#### Scenario: Running run restored with child session becomes interrupted
- **WHEN** a parent Pi session is resumed after a subagent run was previously `running`
- **AND** the restored run record contains a usable child session file that can be located and validated as a standard Pi session JSONL file
- **THEN** the framework SHALL restore the run with status `interrupted`
- **AND** the run SHALL be marked resumable
- **AND** the run SHALL NOT consume a background execution slot

#### Scenario: Queued run restored with child session becomes interrupted
- **WHEN** a parent Pi session is resumed after a subagent run was previously `queued`
- **AND** the restored run record contains a usable child session file that can be located and validated as a standard Pi session JSONL file
- **THEN** the framework SHALL restore the run with status `interrupted`
- **AND** the result output SHALL explain that the queued live run did not survive restart and may be explicitly resumed

#### Scenario: Restored run without child session remains aborted
- **WHEN** a parent Pi session is resumed after a subagent run was previously `queued` or `running`
- **AND** the restored run record has no usable child session file, including when the path is missing, not a regular file, malformed, or mismatched with the recorded session id or cwd
- **THEN** the framework SHALL mark the run as `aborted`
- **AND** the error SHALL explain that no live session or durable child session is available to continue

#### Scenario: Result retrieval reports interrupted state
- **WHEN** `get_subagent_result` is called for an interrupted resumable subagent run
- **THEN** the tool result SHALL report status `interrupted`
- **AND** verbose output SHALL include the child session id, child session file path, and resume guidance

### Requirement: Interrupted subagent sessions resume only by explicit request
The framework MUST NOT automatically restart interrupted subagent runs on session restore. Continuing an interrupted subagent SHALL require an explicit `subagent` resume request and SHALL append new turns to the saved child session history using the same runtime identity and effective permission model assigned for the resumed run.

#### Scenario: Startup does not auto-resume interrupted run
- **WHEN** a parent Pi session is resumed and contains interrupted resumable subagent runs
- **THEN** the framework SHALL NOT start model turns or tool execution for those subagents automatically
- **AND** the runs SHALL remain retrievable through `get_subagent_result`

#### Scenario: Explicit resume opens saved child session
- **WHEN** the active agent invokes `subagent` with `resume` set to an interrupted resumable run identifier
- **AND** the delegation permission check allows the resume request
- **THEN** the framework SHALL open the saved child session file through SessionManager-compatible resume semantics
- **AND** the next child model turn SHALL continue from the saved child session context
- **AND** new child messages and tool results SHALL append to a durable child session file

#### Scenario: Resume is denied when delegation is not allowed
- **WHEN** the active agent invokes `subagent` with `resume` set to an interrupted resumable run identifier
- **AND** the current parent policy denies the delegation or requested runtime options
- **THEN** the framework SHALL block the resume before creating a live child session
- **AND** the interrupted run SHALL remain interrupted and resumable

#### Scenario: Interrupted run cannot be steered directly
- **WHEN** the active agent invokes `steer_subagent` for an interrupted run
- **THEN** the framework SHALL reject the steering request
- **AND** the tool result SHALL explain that the run is not live and must be resumed explicitly

### Requirement: Runtime displays interrupted resumable subagents distinctly
The framework MUST surface interrupted resumable subagent runs as recoverable historical runs, not as active running agents. User-facing UI SHALL provide enough information to ask the agent to inspect or resume the run without presenting model-callable tool names as direct user commands.

#### Scenario: Restore notifies about resumable interrupted runs
- **WHEN** a parent session restore finds one or more interrupted resumable subagent runs
- **THEN** the framework SHALL notify the user that interrupted subagent runs can be resumed
- **AND** the notification SHALL instruct the user to ask the agent to inspect or resume an interrupted run by id
- **AND** the notification SHALL NOT present model-callable tool names as direct user commands

#### Scenario: Widget shows interrupted run as warning linger
- **WHEN** a displayed subagent run is restored as interrupted and resumable
- **THEN** the subagent widget SHALL render the run with a warning-style finished line
- **AND** the activity text SHALL indicate that the run is interrupted and resumable
- **AND** the run SHALL follow finished-run linger behavior rather than active running behavior

#### Scenario: Status bar excludes interrupted runs from active counts
- **WHEN** there are interrupted resumable subagent runs but no queued or running subagent runs
- **THEN** the `subagents` status-bar entry SHALL NOT describe those interrupted runs as running or queued
- **AND** the active subagent indicator SHALL clear after the interrupted-run linger window expires
