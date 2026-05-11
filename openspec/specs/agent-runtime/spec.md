## Purpose

Define the expected agent discovery, main-agent runtime, subagent orchestration, scheduling, and identity behavior for the Pi agent permission framework.

## Requirements

### Requirement: Agent definitions are discoverable from user and project scopes
The framework MUST discover agent definitions from user-level and project-level agent directories. Each discovered definition SHALL include an agent name, kind (`main` or `subagent`), description, prompt body, optional model/thinking settings, optional runtime settings, and optional OpenCode-style permission policy. Project-level definitions SHALL override user-level definitions with the same name only when project-local agents are enabled and trusted for the current session. Legacy explicit tool declarations MAY be accepted only as a migration input that is converted into permission rules; new agent definitions SHALL use `permission` as the source of tool availability.

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

#### Scenario: Legacy tool declarations are migrated to permissions
- **WHEN** an agent definition still contains a legacy explicit tool list
- **THEN** the framework MAY convert that list into equivalent `permission.tools` allow and deny rules for compatibility
- **AND** the framework SHALL treat the normalized permission policy as the authoritative runtime policy

### Requirement: Main agents are first-class selectable runtime profiles
The framework MUST provide first-class main agents that can be selected before or during a Pi session. Selecting a main agent SHALL establish the root runtime identity and apply that agent's prompt, model, thinking level, runtime settings, permission policy, and permission-derived active tool set as one coherent profile.

#### Scenario: Start session with selected main agent
- **WHEN** Pi starts with a configured main-agent selection
- **THEN** the framework SHALL set that main agent as the root runtime identity
- **AND** the session SHALL use the selected agent's prompt and runtime settings for subsequent agent turns
- **AND** the active tool set SHALL be derived from the selected agent's effective permissions

#### Scenario: Switch main agent during a session
- **WHEN** the user switches to another main agent through the framework UI or command
- **THEN** subsequent agent turns SHALL use the new main agent identity and runtime profile
- **AND** prior session history SHALL remain intact
- **AND** active tools SHALL be recomputed from the new main agent's effective permissions

#### Scenario: Built-in main agents exist without explicit tool declarations
- **WHEN** the framework is installed without custom main-agent definitions
- **THEN** `plan`, `build`, and `ask` SHALL be available as built-in main-agent profiles
- **AND** those built-in profiles SHALL rely on `permission` rather than explicit tool lists to determine available tools

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
The framework MUST pass the delegated identity and effective runtime configuration into subagent child sessions. A child session SHALL enforce the identity, OpenCode-layered effective policy, and permission-derived active tool set assigned at launch rather than inferring its agent name or permissions from prompt text.

#### Scenario: Child subagent starts with assigned identity
- **WHEN** the framework creates a subagent SDK child session
- **THEN** the child session SHALL receive the assigned subagent identity and effective policy before its first model turn
- **AND** the child session SHALL use that identity for permission checks and audit records
- **AND** the child session's active tools SHALL be derived from that effective policy

#### Scenario: Prompt customization does not change identity
- **WHEN** a subagent prompt is customized, appended, compacted, or translated
- **THEN** the subagent runtime identity SHALL remain the explicitly assigned identity
- **AND** prompt customization SHALL NOT change the permission policy except through the explicit agent definition and runtime options

### Requirement: Active tools are derived from effective permissions
The framework MUST derive active tool registration from the available Pi tool registry and the active identity's effective permission policy. A tool SHALL remain active when its effective `permission.tools` decision can resolve to `allow` or `ask` for any supported input. A tool SHALL be omitted from the active tool set only when its effective permissions are categorically `deny` for all inputs. Pre-execution permission enforcement SHALL remain authoritative for all active tools.

#### Scenario: Categorically denied tool is omitted
- **WHEN** an active agent's effective `permission.tools` policy resolves a tool to `deny` for all possible inputs
- **THEN** the framework SHALL omit that tool from the active tool set for that agent identity

#### Scenario: Ask tool remains active
- **WHEN** an active agent's effective `permission.tools` policy resolves a tool to `ask`
- **THEN** the framework SHALL keep that tool in the active tool set
- **AND** a requested call to that tool SHALL still require approval before execution

#### Scenario: Input-sensitive denied default keeps tool active when allow can match
- **WHEN** an active agent's effective `permission.tools` policy denies a tool by catch-all rule
- **AND** a more specific input rule for that tool can resolve to `allow` or `ask`
- **THEN** the framework SHALL keep that tool in the active tool set
- **AND** the pre-execution permission check SHALL decide each concrete call from its actual input

#### Scenario: New registered tool is available unless denied
- **WHEN** Pi exposes a tool that is not explicitly named in an agent definition
- **AND** the active agent's effective permissions do not categorically deny that tool
- **THEN** the framework SHALL include that tool in the permission-derived active tool set

#### Scenario: Built-in agents allow unknown tools by default
- **WHEN** the active main agent is the built-in `plan`, `build`, or `ask` profile
- **AND** Pi exposes a tool that is not explicitly named by that built-in profile's `permission.tools` rules
- **THEN** the framework SHALL include that tool in the permission-derived active tool set
- **AND** the tool SHALL resolve to `allow` unless another guard for the concrete request resolves to `ask` or `deny`

### Requirement: Child extension inheritance avoids recursive framework enforcement
When a delegated subagent inherits extensions, the framework MUST NOT install a second independent agent-permission-framework runtime in the child session without the delegated child identity and effective policy. The child session SHALL enforce permissions through the child runtime state assigned by the parent delegation.

#### Scenario: Read-only subagent with inherited extensions can inspect repository
- **WHEN** an active `build` main agent delegates to a read-only subagent whose definition enables extension inheritance
- **AND** the parent policy allows that delegation and read-only tools
- **THEN** the subagent SHALL be able to use allowed read-only repository tools such as `read`, `grep`, `find`, and `ls`
- **AND** those tools SHALL NOT be denied by a recursively loaded framework instance with missing child policy state

#### Scenario: Other inherited extensions remain available
- **WHEN** a subagent definition enables extension inheritance
- **THEN** the child session SHALL preserve non-framework inherited extensions according to the configured runtime options
- **AND** the framework SHALL still use the delegated child identity and effective policy for permission checks

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

### Requirement: Bureau config files are discoverable from user and project scopes
The framework MUST discover bureau configuration files from user-level and project-level locations. User-level bureau config files SHALL be available by default from `~/.pi/agent/bureau.json`, `~/.pi/agent/bureau.jsonc`, `~/.pi/agent/bureau.yaml`, or `~/.pi/agent/bureau.yml`. Project-level bureau config files SHALL be discovered from the nearest `.pi/bureau.json`, `.pi/bureau.jsonc`, `.pi/bureau.yaml`, or `.pi/bureau.yml` and SHALL be loaded only when project-local agents/config are trusted for the current session.

#### Scenario: User-level bureau config is available by default
- **WHEN** the framework starts with a user-level `~/.pi/agent/bureau.yaml` file
- **THEN** the framework SHALL load that bureau config without requiring project trust
- **AND** agent definitions and global permissions from that config SHALL participate in effective runtime configuration

#### Scenario: Project-level bureau config is ignored before trust approval
- **WHEN** the framework starts in a project containing `.pi/bureau.yaml`
- **AND** project-local agents/config have not been enabled for the current session
- **THEN** the framework SHALL NOT load the project-level bureau config
- **AND** the project-level bureau config SHALL NOT add agents, patch agents, or change permissions

#### Scenario: Project-level bureau config loads after trust approval
- **WHEN** the framework starts in a project containing `.pi/bureau.yaml`
- **AND** project-local agents/config are enabled through startup flags or an explicit trust command
- **THEN** the framework SHALL load the project-level bureau config
- **AND** agent definitions and global permissions from that config SHALL participate in effective runtime configuration

#### Scenario: Supported bureau config formats are parsed
- **WHEN** a discovered bureau config file uses the `.json`, `.jsonc`, `.yaml`, or `.yml` extension
- **THEN** the framework SHALL parse that file according to its format
- **AND** YAML block scalar prompts and nested permission objects SHALL be supported for YAML and YML files

#### Scenario: Duplicate bureau config files in one scope are deterministic
- **WHEN** more than one supported bureau config file exists in the same user or project scope
- **THEN** the framework SHALL choose one file using a deterministic documented extension order
- **AND** the framework SHALL report a warning for the ignored same-scope bureau config files

### Requirement: Bureau config agent entries add and patch agents
The framework MUST support a top-level `agent` object in bureau config files. Each key under `agent` SHALL name an agent to create or patch. Existing agents SHALL keep omitted fields when patched. New agents SHALL require enough information to form a valid agent definition, including a prompt and description, and SHALL default to `kind: subagent` when kind is omitted.

#### Scenario: Existing agent is patched by bureau config
- **WHEN** a bureau config contains `agent.build.permission.tools.read` rules
- **AND** the built-in `build` agent already exists
- **THEN** the framework SHALL keep the `build` agent's omitted prompt, kind, model, thinking, and runtime fields
- **AND** the framework SHALL compose the provided agent-local permission patch into the effective `build` policy

#### Scenario: New agent is created by bureau config
- **WHEN** a bureau config contains `agent.my-new-agent` with `description` and `prompt`
- **THEN** the framework SHALL create `my-new-agent` as a selectable or delegatable agent according to its `kind`
- **AND** the framework SHALL use `subagent` as the default kind when the config entry omits `kind`

#### Scenario: Invalid new agent entry is ignored
- **WHEN** a bureau config contains `agent.incomplete-agent` without a prompt or without a description
- **THEN** the framework SHALL ignore that agent entry
- **AND** the framework SHALL report a configuration warning identifying the invalid agent entry

#### Scenario: Bureau agent entries use canonical permission field
- **WHEN** a bureau config agent entry defines an agent-local permission policy
- **THEN** the framework SHALL read that policy only from the canonical `permission` field
- **AND** the framework SHALL NOT treat `permissions` as an alias for bureau config agent-local policy

### Requirement: Bureau configuration source precedence is deterministic
The framework MUST apply bureau and Markdown agent configuration with this precedence from highest to lowest: project `.pi/bureau.(json|jsonc|yaml|yml)`, project `.pi/agents/*.md`, user `~/.pi/agent/bureau.(json|jsonc|yaml|yml)`, user `~/.pi/agent/agents/*.md`, and built-in bureau defaults. Higher-precedence sources SHALL override or patch lower-precedence sources according to their source type.

#### Scenario: Project bureau config overrides project Markdown agent config
- **WHEN** a trusted project Markdown agent and trusted project bureau config both configure the same agent field or permission rule
- **THEN** the value or rule from project bureau config SHALL be effective

#### Scenario: Project Markdown agent overrides user bureau config
- **WHEN** a user bureau config and a trusted project Markdown agent both configure the same agent field or permission rule
- **THEN** the value or rule from the trusted project Markdown agent SHALL be effective

#### Scenario: User bureau config overrides user Markdown agent config
- **WHEN** a user Markdown agent and user bureau config both configure the same agent field or permission rule
- **THEN** the value or rule from user bureau config SHALL be effective

#### Scenario: Built-in defaults remain the fallback
- **WHEN** no user or trusted project source overrides a built-in agent field or permission rule
- **THEN** the framework SHALL use the built-in bureau default for that field or rule

### Requirement: Bureau config errors are reported without unsafe partial application
The framework MUST report parse, schema, and validation errors for bureau config files. A malformed bureau config layer SHALL NOT be partially applied in a way that changes agents or permissions unpredictably.

#### Scenario: Invalid bureau config file is ignored atomically
- **WHEN** a discovered bureau config file cannot be parsed or fails validation
- **THEN** the framework SHALL ignore that bureau config layer
- **AND** the framework SHALL keep using lower-precedence valid configuration sources
- **AND** the framework SHALL report a warning that identifies the invalid bureau config file
