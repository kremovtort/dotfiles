## Why

`agent-permission-framework` currently uses a permission description model that diverges from OpenCode, making agent definitions harder to share, reason about, and document. Aligning the model with OpenCode removes this mismatch while preserving Pi-specific enforcement categories that the framework can actually enforce.

## What Changes

- **BREAKING** Replace the current agent permission declaration shape with an OpenCode-compatible `permission` model using `allow`, `ask`, and `deny` actions.
- Support OpenCode-style rule values where each permission entry can be either a direct action string or an object of pattern rules.
- Keep the framework's enforceable permission categories scoped to `tools`, `bash`, and `subagents`; MCP permissions remain deferred for now.
- Move `external_directory` to the top level of `permission`, matching OpenCode, instead of modeling it as a nested file/external category.
- Remove the need to declare an explicit tool list in built-in agent definitions; agents should register every available tool except tools whose permission resolves to `deny`.
- Keep pre-execution permission enforcement authoritative, so registered `ask` tools still require approval and denied actions remain blocked.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `agent-permission-enforcement`: Change the permission policy schema, parsing, normalization, matching, and external-directory semantics to align with OpenCode while retaining `tools`, `bash`, and `subagents` categories.
- `agent-runtime`: Change agent runtime tool registration so agent profiles no longer need explicit tool declarations and active tools are derived from permission decisions, excluding tools resolved to `deny`.

## Impact

- Affected package: `agents/pi/packages/agent-permission-framework`.
- Affected areas: agent definition parsing, built-in agent profiles, permission normalization/evaluation, active tool registration, documentation/examples, and tests.
- Existing agent definitions using the old permission shape will need migration.
- No new runtime dependencies are expected.
