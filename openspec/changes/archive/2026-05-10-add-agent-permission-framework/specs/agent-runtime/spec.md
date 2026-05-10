## ADDED Requirements

### Requirement: Agent definitions are discoverable from user and project scopes
The framework MUST discover agent definitions from user-level and project-level agent directories. Each discovered definition SHALL include an agent name, kind (`main` or `subagent`), description, prompt body, optional model/thinking/tool settings, optional runtime settings, and optional permission policy. Project-level definitions SHALL override user-level definitions with the same name only when project-local agents are enabled and trusted for the current session.

#### Scenario: User-level agents are available by default
- **WHEN** the framework starts in a project without project-local agent approval
- **THEN** user-level agent definitions SHALL be available for selection and delegation
- **AND** project-level agent definitions SHALL NOT be executed implicitly

#### Scenario: Project-level agent overrides user-level agent after trust approval
- **WHEN** user-level and project-level definitions use the same agent name
- **AND** project-local agents are enabled and approved for the current session
- **THEN** the project-level definition SHALL be the effective definition for that agent name

#### Scenario: Disabled or invalid agent definitions are ignored
- **WHEN** an agent definition is disabled or lacks required identity fields
- **THEN** the framework SHALL exclude that definition from selectable main agents and delegation targets

### Requirement: Main agents are first-class selectable runtime profiles
The framework MUST provide first-class main agents that can be selected before or during a Pi session. Selecting a main agent SHALL establish the root runtime identity and apply that agent's prompt, model, thinking level, active tool set, runtime settings, and permissions as one coherent profile.

#### Scenario: Start session with selected main agent
- **WHEN** Pi starts with a configured main-agent selection
- **THEN** the framework SHALL set that main agent as the root runtime identity
- **AND** the session SHALL use the selected agent's prompt and runtime settings for subsequent agent turns

#### Scenario: Switch main agent during a session
- **WHEN** the user switches to another main agent through the framework UI or command
- **THEN** subsequent agent turns SHALL use the new main agent identity and runtime profile
- **AND** prior session history SHALL remain intact

#### Scenario: Built-in main agents exist
- **WHEN** the framework is installed without custom main-agent definitions
- **THEN** `plan`, `build`, and `ask` SHALL be available as built-in main-agent profiles

### Requirement: Subagent delegation tools provide Claude Code-style orchestration
The framework MUST expose model-callable subagent orchestration tools through the `subagent`, `get_subagent_result`, and `steer_subagent` workflow. Delegated subagents SHALL run in isolated Pi agent sessions with their own prompt, model, thinking level, active tools, runtime options, and identity.

#### Scenario: Foreground subagent returns result to parent
- **WHEN** the active agent invokes `subagent` for a foreground subagent task
- **THEN** the framework SHALL run the requested subagent in an isolated session
- **AND** the tool result SHALL return the subagent's final output to the parent agent

#### Scenario: Background subagent result is retrievable
- **WHEN** the active agent starts a background subagent task
- **THEN** the framework SHALL return a stable subagent run identifier
- **AND** a later `get_subagent_result` call with that identifier SHALL return the current or completed run result

#### Scenario: Running subagent can be steered
- **WHEN** a background subagent run is still active
- **AND** the active agent invokes `steer_subagent` with that run identifier
- **THEN** the framework SHALL deliver the steering message to the running subagent according to the subagent runtime's steering semantics

### Requirement: Subagent runs preserve configured runtime and scheduling behavior
The framework MUST support subagent runtime options for foreground/background execution, maximum turns, context inheritance, and extension/skill inheritance. The framework SHALL apply concurrency limits to background runs and SHALL report queued, running, completed, failed, and aborted states.

#### Scenario: Background runs obey concurrency limit
- **WHEN** more background subagent runs are requested than the configured concurrency limit allows
- **THEN** the framework SHALL queue excess runs instead of starting all runs immediately
- **AND** queued runs SHALL start when earlier runs leave the running state


### Requirement: Runtime identity is explicit and persistent
The framework MUST represent each active main agent and subagent run as an explicit runtime identity. An identity SHALL include at least agent name, kind, source scope, parent identity when present, run/session identifier, and an effective-policy reference. Identity activation and subagent lifecycle events SHALL be persisted so a resumed or forked session can reconstruct the active identity state.

#### Scenario: Main-agent activation records root identity
- **WHEN** a main agent becomes active
- **THEN** the framework SHALL persist a root identity activation event for that agent
- **AND** later permission checks SHALL reference that root identity

#### Scenario: Subagent identity references parent identity
- **WHEN** a subagent run is created by a parent agent
- **THEN** the subagent identity SHALL reference the parent identity that requested the delegation
- **AND** subagent lifecycle records SHALL include the subagent run identifier

#### Scenario: Session resume reconstructs identity
- **WHEN** a Pi session is resumed after framework state was persisted
- **THEN** the framework SHALL reconstruct the active identity and known subagent run state before enforcing new actions

### Requirement: Child sessions receive their effective runtime identity
The framework MUST pass the delegated identity and effective runtime configuration into subagent child sessions. A child session SHALL enforce the identity and effective policy assigned at launch rather than inferring its agent name from prompt text.

#### Scenario: Child subagent starts with assigned identity
- **WHEN** the framework creates a subagent SDK child session
- **THEN** the child session SHALL receive the assigned subagent identity and effective policy before its first model turn
- **AND** the child session SHALL use that identity for permission checks and audit records

#### Scenario: Prompt customization does not change identity
- **WHEN** a subagent prompt is customized, appended, compacted, or translated
- **THEN** the subagent runtime identity SHALL remain the explicitly assigned identity
