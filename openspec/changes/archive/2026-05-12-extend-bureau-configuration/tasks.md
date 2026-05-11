## 1. Config Parsing

- [x] 1.1 Add JSONC and YAML parser dependencies to `agents/pi/packages/agent-permission-framework/package.json`.
- [x] 1.2 Create a bureau config parser/loader module that reads `.json`, `.jsonc`, `.yaml`, and `.yml` files and reports file-specific parse errors.
- [x] 1.3 Implement deterministic same-scope file selection for `bureau.jsonc`, `bureau.json`, `bureau.yaml`, and `bureau.yml`, including warnings for ignored duplicates.
- [x] 1.4 Validate bureau config shape with only top-level `agent` and `permission` entries, preserving clear warnings for unsupported fields.

## 2. Agent Discovery and Precedence

- [x] 2.1 Extend agent discovery to load user bureau config from `~/.pi/agent/bureau.(json|jsonc|yaml|yml)`.
- [x] 2.2 Extend trusted project discovery to load nearest `.pi/bureau.(json|jsonc|yaml|yml)` only when project agents/config are trusted.
- [x] 2.3 Apply configuration layers in precedence order: built-ins, user Markdown agents, user bureau config, trusted project Markdown agents, trusted project bureau config.
- [x] 2.4 Implement bureau `agent.<name>` patch-or-create behavior for supported scalar/runtime fields and `prompt`.
- [x] 2.5 Reject bureau `agent.<name>.permissions`, `agent.<name>.tools`, and `agent.<name>.disallowed_tools` with warnings instead of normalizing them.
- [x] 2.6 Ensure disabled bureau agent entries remove agents at that layer and can be superseded by later higher-precedence layers.

## 3. Permission Composition

- [x] 3.1 Apply top-level bureau `permission` as a global permission layer for every effective agent policy.
- [x] 3.2 Compose global bureau permissions before same-file `agent.<name>.permission` patches so agent-local config can specialize global rules.
- [x] 3.3 Require tool-specific global permission rules under `permission.tools` and reject top-level tool shorthand such as `permission.new-tool`.
- [x] 3.4 Include bureau-derived permission rules in effective policy hashes and audit/explain metadata.
- [x] 3.5 Verify active-tool derivation, main-agent activation, and subagent effective-policy composition all use the final bureau-composed policy.

## 4. Trust Flow and UX

- [x] 4.1 Update `--project-agents` and `/agent-trust-project` descriptions/prompts to mention project agents/config or project bureau config.
- [x] 4.2 Surface bureau config parse, validation, and duplicate-file warnings during startup and `/agent` reload without crashing the session.
- [x] 4.3 Update status/audit-facing messages where needed so bureau-derived agent or policy sources are identifiable by file path.

## 5. Documentation and Naming

- [x] 5.1 Update README and docs to describe bureau config files, supported formats, source precedence, trust gating, and examples.
- [x] 5.2 Update examples to use canonical `permission` and `permission.tools.new-tool`, with no `permissions` alias or legacy `tools`/`disallowed_tools` in bureau config.
- [x] 5.3 Rename user-facing wording from `agent-permission-framework` toward `bureau` where appropriate while preserving local package path compatibility.

## 6. Tests and Validation

- [x] 6.1 Add parser tests for JSON, JSONC, YAML, YML, YAML block scalar prompts, invalid syntax, and duplicate same-scope config files.
- [x] 6.2 Add discovery tests for user bureau config, trusted project bureau config, untrusted project bureau config, and full precedence order.
- [x] 6.3 Add agent patch/create tests for existing agent overrides, new agent creation, invalid new agents, disabled agents, and unsupported bureau agent fields.
- [x] 6.4 Add permission tests for global bureau permission layers, same-file agent-local specialization, project-over-user overrides, rejected shorthand, and rejected unsupported categories.
- [x] 6.5 Run `npm test` in `agents/pi/packages/agent-permission-framework`.
- [x] 6.6 Run `openspec validate extend-bureau-configuration --strict`.
