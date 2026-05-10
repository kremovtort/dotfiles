## Why

Permission approval dialogs in `agent-permission-framework` currently attach the detailed permission description to each response option instead of the permission request itself. This makes every choice harder to scan and obscures the shared context the user is approving or denying.

## What Changes

- Move the detailed permission description from individual approval choices into the main permission prompt body.
- Keep approval/denial choices concise, so each option label contains only the decision text such as `Allow for current session`.
- Apply the same display behavior to all choices in the permission dialog, not only `Allow for current session`.
- Preserve the existing permission decision semantics, approval scopes, audit behavior, and fail-closed behavior.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `agent-permission-enforcement`: Permission prompts must present detailed permission context as request-level content, while dialog choices remain concise decision labels.

## Impact

- Affected code: `agents/pi/packages/agent-permission-framework/` permission prompt/UI formatting.
- Affected specs: `openspec/specs/agent-permission-enforcement/spec.md` via a delta spec for prompt presentation behavior.
- No expected changes to package dependencies, permission policy evaluation, or runtime enforcement semantics.
