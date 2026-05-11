## MODIFIED Requirements

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

## ADDED Requirements

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
