## ADDED Requirements

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
