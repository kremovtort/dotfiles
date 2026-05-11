## Why

Bureau currently configures agents primarily through built-in defaults and Markdown agent files, which makes simple global/project-wide overrides verbose and splits agent selection from global permission policy. Users need a compact config-file surface that can add or override agents and permissions while preserving the existing user/project Markdown workflow and trust model.

## What Changes

- Add bureau configuration files in JSON, JSONC, YAML, and YML formats:
  - user scope: `~/.pi/agent/bureau.json`, `~/.pi/agent/bureau.jsonc`, `~/.pi/agent/bureau.yaml`, `~/.pi/agent/bureau.yml`
  - project scope: nearest `.pi/bureau.json`, `.pi/bureau.jsonc`, `.pi/bureau.yaml`, `.pi/bureau.yml`
- Support top-level `agent` entries for adding new agents or overriding existing agents by name.
- Support top-level `permission` entries for global permission overrides shared across applicable agents.
- Preserve existing Markdown agent discovery from `~/.pi/agent/agents/*.md` and trust-gated project `.pi/agents/*.md`.
- Define source precedence from highest to lowest:
  1. project `.pi/bureau.(json|jsonc|yaml|yml)`
  2. project `.pi/agents/*.md`
  3. user `~/.pi/agent/bureau.(json|jsonc|yaml|yml)`
  4. user `~/.pi/agent/agents/*.md`
  5. built-in bureau defaults
- Treat project-local bureau files as project-controlled configuration and gate them with the same project-agent trust boundary as project Markdown agents.
- Update user-facing docs to describe bureau naming, config file formats, merge/override behavior, and precedence.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `agent-runtime`: Add requirements for bureau config discovery, supported file formats, agent additions/overrides, project trust gating, and configuration source precedence.
- `agent-permission-enforcement`: Add requirements for global `permission` overrides from bureau config files and their interaction with agent-specific permission policies.

## Impact

- Affected package: `agents/pi/packages/agent-permission-framework` (bureau).
- Affected areas: agent discovery/parsing, runtime activation, permission policy composition, docs, and tests.
- New parsing support may require adding or reusing JSONC/YAML parsing dependencies.
- Existing Markdown agent files remain supported; existing behavior should remain compatible unless explicitly overridden by bureau config files.
