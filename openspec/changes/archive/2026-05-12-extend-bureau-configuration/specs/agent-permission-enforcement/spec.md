## ADDED Requirements

### Requirement: Bureau global permissions compose into effective agent policies
The framework MUST support top-level `permission` in bureau config files as a global permission layer. A bureau global permission layer SHALL apply to every effective agent policy at that source's precedence position. Agent-local permission policies from Markdown agent definitions and bureau `agent.<name>.permission` entries SHALL compose with global bureau permission layers using OpenCode override semantics.

#### Scenario: User bureau global permission applies to all user-visible agents
- **WHEN** user bureau config contains `permission.tools.new-tool: deny`
- **AND** an effective agent does not define a higher-precedence rule for `new-tool`
- **THEN** the effective policy for that agent SHALL deny `new-tool`

#### Scenario: Agent-local bureau permission specializes same-file global permission
- **WHEN** a bureau config contains a top-level global permission rule
- **AND** the same bureau config contains `agent.build.permission` with a more specific rule for the same permission target
- **THEN** the framework SHALL apply the top-level global permission layer before the `build` agent-local permission patch
- **AND** the `build` agent-local rule SHALL be able to specialize the global rule according to OpenCode last-match-wins composition

#### Scenario: Higher-precedence project global permission overrides lower-precedence user agent permission
- **WHEN** user Markdown or user bureau agent-local permission allows a tool
- **AND** trusted project bureau config contains top-level `permission.tools` rules that deny the same tool
- **THEN** the effective policy SHALL use the trusted project bureau global deny rule

#### Scenario: Lower-precedence global permission remains effective when higher layers are silent
- **WHEN** user bureau config contains a top-level permission rule
- **AND** trusted project Markdown and trusted project bureau config do not define a matching higher-precedence rule
- **THEN** the user bureau global permission rule SHALL remain part of the effective policy

### Requirement: Bureau config permission schema uses explicit supported keys
Bureau config permission objects MUST use the same supported permission categories as the normalized permission model: `*`, `tools`, `bash`, `subagents`, and `external_directory`. Tool-specific rules in bureau global permissions SHALL be written under `permission.tools`. Unknown top-level keys in a bureau config `permission` object SHALL be invalid configuration rather than shorthand for tool names.

#### Scenario: Global tool rule uses tools object
- **WHEN** a bureau config contains `permission.tools.new-tool: deny`
- **THEN** the framework SHALL normalize that rule as a tool permission rule for `new-tool`
- **AND** tool-call enforcement SHALL evaluate requests for `new-tool` against that rule

#### Scenario: Global tool shorthand is rejected
- **WHEN** a bureau config contains `permission.new-tool: deny`
- **THEN** the framework SHALL report `new-tool` as an unsupported top-level permission key
- **AND** the framework SHALL NOT normalize that key as `permission.tools.new-tool`

#### Scenario: Unsupported permission categories are rejected
- **WHEN** a bureau config permission object contains `mcp`, `files`, `agents`, or `skills` as a top-level category
- **THEN** the framework SHALL report the category as invalid configuration
- **AND** it SHALL NOT silently treat that category as an allowed permission rule

### Requirement: Bureau agent-local permissions use canonical configuration fields
The framework MUST accept agent-local permission policy from bureau config only through `agent.<name>.permission`. Bureau config SHALL NOT support `agent.<name>.permissions` as an alias and SHALL NOT support legacy `agent.<name>.tools` or `agent.<name>.disallowed_tools` migration fields.

#### Scenario: Plural permissions field is rejected
- **WHEN** a bureau config contains `agent.build.permissions`
- **THEN** the framework SHALL report `permissions` as an unsupported bureau agent config field
- **AND** the framework SHALL NOT use that value as the `build` agent-local permission policy

#### Scenario: Legacy tools field is rejected in bureau config
- **WHEN** a bureau config contains `agent.build.tools`
- **THEN** the framework SHALL report `tools` as an unsupported bureau agent config field
- **AND** the framework SHALL NOT convert that field into `permission.tools` rules

#### Scenario: Legacy disallowed tools field is rejected in bureau config
- **WHEN** a bureau config contains `agent.build.disallowed_tools`
- **THEN** the framework SHALL report `disallowed_tools` as an unsupported bureau agent config field
- **AND** the framework SHALL NOT convert that field into deny rules

### Requirement: Effective policy audits identify bureau-derived policy layers
The framework MUST include bureau-derived policy layers in effective policy hashes and audit metadata. Permission decisions influenced by bureau config SHALL remain explainable through the same audit and explanation paths used for Markdown and built-in policies.

#### Scenario: Bureau policy changes effective policy hash
- **WHEN** a bureau config global permission or agent-local permission patch changes an agent's effective policy
- **THEN** the framework SHALL compute a policy hash that reflects the bureau-derived rules
- **AND** subsequent audit records for that agent identity SHALL reference that effective policy hash

#### Scenario: Bureau-derived denial is explainable
- **WHEN** a tool call is denied by a rule loaded from bureau config
- **THEN** the audit record SHALL identify the matched rule or default decision
- **AND** the explanation output SHALL provide enough policy context to distinguish a bureau-derived denial from an unrelated built-in default
