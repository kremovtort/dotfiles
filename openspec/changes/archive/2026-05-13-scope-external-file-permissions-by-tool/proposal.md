## Why

External-file permission prompts currently collapse path access into a generic `file external_directory` action, so users cannot tell whether the agent is about to read, write, edit, or otherwise operate on the external path. This also makes reusable approvals too broad: approving one external path action can unintentionally cover a later operation with a different file tool on the same path.

## What Changes

- Display the concrete file-related tool name in external-directory approval prompts, alongside the normalized external path or primary path argument.
- Scope external-directory approval fingerprints by the requesting tool/operation and path, so approving `read /outside/file` does not approve `write /outside/file` or `edit /outside/file`.
- Keep `permission.external_directory` rule matching path-based, so existing bureau configuration continues to authorize or deny external paths without needing tool-prefixed patterns.
- Preserve auditability by recording the full tool-aware fingerprint and showing bounded summaries that include the tool and path.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `agent-permission-enforcement`: external-directory approval prompts and reusable approvals become tool-aware while policy matching remains path-based.

## Impact

- Affected package: `agents/pi/packages/agent-permission-framework`.
- Affected areas: permission policy evaluation, action fingerprint construction, approval reuse, approval UI/fallback display, audit summaries, and related tests.
- Existing `permission.external_directory` configuration remains valid; approval reuse becomes narrower for safety.
