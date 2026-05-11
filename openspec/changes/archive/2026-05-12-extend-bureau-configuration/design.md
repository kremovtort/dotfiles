## Context

`agent-permission-framework` is becoming bureau, but the current implementation is still configured through built-in TypeScript defaults plus Markdown files discovered from `~/.pi/agent/agents/*.md` and trusted project `.pi/agents/*.md`. Markdown is good for prompt-heavy agent definitions, but it is awkward for small global/project overrides such as “deny this new tool everywhere” or “allow this path for build”.

The current code paths are already centralized enough to extend: agent discovery and Markdown parsing live in `src/agents.ts`, policy normalization/merge lives in `src/policy.ts`, runtime loading and project trust are wired in `src/index.ts`, and docs/tests already cover discovery, frontmatter, and policy behavior. The design should add a structured bureau config layer without replacing Markdown agents or weakening project-local trust boundaries.

## Goals / Non-Goals

**Goals:**

- Keep existing user and project Markdown agent files supported.
- Add user and project bureau config files in JSON, JSONC, YAML, and YML formats.
- Let bureau config add new agents and patch existing agents by name.
- Let bureau config define global permission layers that apply across agents.
- Make source precedence deterministic and aligned with the requested order:
  1. project `.pi/bureau.(json|jsonc|yaml|yml)`
  2. project `.pi/agents/*.md`
  3. user `~/.pi/agent/bureau.(json|jsonc|yaml|yml)`
  4. user `~/.pi/agent/agents/*.md`
  5. built-in bureau defaults
- Gate project-local bureau config with the same trust mechanism as project-local Markdown agents.
- Report invalid config clearly without silently falling back to unsafe behavior.

**Non-Goals:**

- Do not remove Markdown agent definitions.
- Do not add new permission categories beyond the bureau/OpenCode-style permission model.
- Do not make project-local config trusted by default.
- Do not change subagent session storage, approval bridging, or scheduling behavior except where effective policies are recomputed from new config layers.
- Do not implement runtime hot-reload beyond the existing session-start and command-triggered agent reload behavior.

## Decisions

### 1. Introduce a bureau config loader next to Markdown discovery

Add a small config-loading module, likely `src/bureau-config.ts`, that discovers and parses config files for two scopes:

- user scope under the Pi agent directory: `~/.pi/agent/bureau.json`, `.jsonc`, `.yaml`, `.yml`
- project scope at the nearest project config location: `.pi/bureau.json`, `.jsonc`, `.yaml`, `.yml`

The loader returns normalized source layers instead of mutating agent definitions directly:

```ts
interface BureauConfigLayer {
  source: "user" | "project";
  filePath: string;
  agents: Map<string, PartialAgentConfig>;
  permission?: PermissionPolicy;
  warnings: string[];
}
```

Within one scope, only one bureau config file should be active. Discovery should use a deterministic extension order and warn if multiple files are present in the same directory. The recommended order is `bureau.jsonc`, `bureau.json`, `bureau.yaml`, `bureau.yml` so comment-capable config wins when both JSON and JSONC are present.

Rationale: separating config loading from agent merging keeps `src/agents.ts` responsible for discovery semantics while making parser-specific behavior easy to test.

Alternative considered: extend Markdown frontmatter parsing to parse standalone YAML. This was rejected because the current custom parser is intentionally small and does not support YAML features needed by the requested example, such as block scalars for `prompt: |`.

### 2. Use real JSONC and YAML parsers

Add explicit parsing support instead of expanding the existing frontmatter subset parser:

- `json` and `jsonc`: parse with a JSONC parser so comments/trailing commas can be accepted for `.jsonc` and ordinary JSON remains strict enough to produce useful diagnostics.
- `yaml` and `yml`: parse with a YAML parser that supports nested objects, quoted wildcard keys, and block scalar prompts.

Parser errors should include the config file path and enough location/detail text for `/agent` reload warnings or startup notifications. An invalid user config should not crash Pi; invalid layers should be ignored with warnings. An invalid project config should be ignored unless project config is trusted, and then reported as trusted project config failure.

Rationale: bureau config becomes a user-facing file format, so partial YAML support would be surprising and would fail on the documented example.

### 3. Model source precedence as ordered layers

Build the final agent registry by applying layers from lowest to highest precedence:

1. built-in bureau defaults
2. user Markdown agents
3. user bureau config
4. trusted project Markdown agents
5. trusted project bureau config

This is the inverse application order of the requested priority list. Later layers override earlier layers.

For each layer:

- Markdown agent files contribute complete agent definitions.
- `agent.<name>` entries in bureau config patch or create that named agent.
- Top-level `permission` in bureau config contributes a global permission layer.

Project Markdown and project bureau layers are both loaded only when project agents/config are trusted for the current session through `--project-agents` or `/agent-trust-project`.

Rationale: applying layers low-to-high gives deterministic override behavior while preserving the exact user-facing priority order.

### 4. Treat `agent.<name>` as patch-or-create

The `agent` object in a bureau config is a map keyed by agent name:

```yaml
agent:
  build:
    permission:
      tools:
        read:
          /opt/homebrew/**: allow
  my-new-agent:
    kind: main
    description: Custom build profile
    model: openai-codex/gpt-5.5
    thinking: xhigh
    prompt: |
      You are a powerful coding assistant.
```

For an existing agent, the entry patches selected fields. Omitted fields keep the previous effective value. For a new agent, the entry must provide enough fields to create a valid `AgentDefinition`; at minimum `description` and `prompt` are required, while `kind` defaults to `subagent` for compatibility with Markdown parsing.

Supported agent config keys should mirror Markdown frontmatter where possible:

- identity/runtime: `kind`, `description`, `model`, `thinking`, `max_turns`, `prompt_mode`, `inherit_context`, `inherit_extensions`, `inherit_skills`, `run_in_background`, `enabled`
- prompt: `prompt`
- permission policy: canonical `permission` only

Patch semantics:

- Scalar fields replace previous values.
- `prompt` replaces the previous prompt unless `prompt_mode: append` is set for runtime prompt composition.
- Agent-local permission is composed with previous permission using existing OpenCode override semantics, rather than replacing the entire policy object.
- `enabled: false` disables the agent at that layer and removes it from selection/delegation unless a later higher-precedence layer re-enables or redefines it.

Rationale: patch-or-create allows compact overrides for built-ins while preserving full custom-agent creation.

### 5. Apply global bureau permissions as permission layers

Top-level `permission` in a bureau config is a global layer that is applied to all effective agent policies. Effective permission composition for a final agent should be:

1. built-in/framework policy defaults
2. lower-precedence global bureau permission layers
3. lower-precedence agent-local permissions from the current winning/patch chain
4. higher-precedence global bureau permission layers
5. higher-precedence agent-local permissions from bureau `agent.<name>` patches in the same or higher layer

Operationally this can be implemented by applying each source layer in order and, within a bureau config layer, composing top-level `permission` before composing any `agent.<name>.permission` patch. This means a project bureau global permission can override project Markdown agent permissions, while an agent-specific permission in the same project bureau file can still specialize that global rule.

The global permission object uses the normalized permission model and must spell tool-specific rules under `tools`:

```yaml
permission:
  tools:
    new-tool: deny
  subagents:
    "*": ask
```

Unknown top-level keys inside `permission` should be reported as invalid configuration unless they are supported permission entries (`*`, `tools`, `bash`, `subagents`, or `external_directory`). Known unsupported categories such as `mcp`, `files`, `agents`, and `skills` should likewise be reported as invalid first-class categories so users are not led to believe they are enforced categories.

Rationale: global permission layers give users one place to express cross-agent defaults and restrictions while keeping the permission schema explicit.

### 6. Keep project trust as the boundary for all project-controlled config

The existing `runtime.trustedProjectAgents`, `--project-agents`, and `/agent-trust-project` flow should become “project bureau config trust” in behavior, even if command names remain unchanged for compatibility. When not trusted:

- project `.pi/agents/*.md` are not loaded
- project `.pi/bureau.*` is not loaded
- user bureau config and user Markdown agents remain available

When trusted, both project source types participate in the ordered layers. Notifications should mention both project agents and project bureau config so the trust decision is clear.

Rationale: project bureau config can change prompts, models, tool availability, and permissions; it must be considered as sensitive as project agent Markdown.

### 7. Preserve auditability and explainability

Runtime identity and permission audit records should continue to reference the effective policy hash. The framework should also keep enough source metadata to explain where an agent or rule came from:

- agent source chain: built-in/user Markdown/user bureau/project Markdown/project bureau
- config file path for bureau layers
- warnings for ignored invalid files or duplicate same-scope config files

`/agent-permissions` and `/agent-explain` do not need a full new UI in this change, but their output should not obscure bureau-derived policy. At minimum, docs and warnings should identify bureau config files by path.

Rationale: adding config layers makes permission outcomes harder to debug unless source metadata is preserved.

## Risks / Trade-offs

- **Risk: Multiple files in the same scope create ambiguous configuration.** → Mitigation: choose a deterministic extension order and warn about ignored siblings.
- **Risk: Global permission layers unexpectedly override an agent’s local permissions.** → Mitigation: document layer order explicitly and apply agent-specific bureau permissions after global permissions within the same file.
- **Risk: New parser dependencies increase package surface area.** → Mitigation: use small, common parser packages and keep parsing isolated in one module with tests.
- **Risk: Invalid config could remove important built-in agents.** → Mitigation: ignore invalid layers with visible warnings instead of partially applying malformed config.
- **Risk: Project config can silently change permissions if trust wording remains “agents” only.** → Mitigation: update command descriptions and prompts to say project agents/config or project bureau config.

## Migration Plan

1. Add the bureau config parser/loader and tests for JSON, JSONC, YAML, YML, duplicate same-scope files, and invalid config diagnostics.
2. Extend agent discovery to build ordered layers: built-ins, user Markdown, user bureau, trusted project Markdown, trusted project bureau.
3. Implement `agent.<name>` patch-or-create behavior and normalize canonical `permission` entries through the same permission parser used by Markdown definitions.
4. Implement global bureau permission layers and ensure policy hashes, active-tool derivation, subagent effective policies, and audit records use the final composed policy.
5. Update `/agent-trust-project`, `--project-agents`, startup warnings, and docs to refer to project agents/config.
6. Rename user-facing docs and examples from `agent-permission-framework` toward bureau while keeping package paths/backward compatibility as needed.
7. Add regression tests for the full precedence order requested in the proposal.

Rollback is a code revert of the loader/layering changes plus removing parser dependencies. Existing Markdown agent files and built-in defaults remain compatible throughout the migration.

## Open Questions

None. The implementation should use canonical `permission` only for bureau config, require tool-specific global rules under `permission.tools`, and gate all project-local bureau config behind the existing project trust flow.
