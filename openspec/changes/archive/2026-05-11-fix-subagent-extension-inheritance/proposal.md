## Why

Subagents that inherit extensions can recursively load the agent permission framework inside their child SDK session. That second framework instance has no delegated child runtime state and can fail closed, causing read-only tools such as `read`, `grep`, `find`, and `ls` to be denied even when the parent `build` agent is active and allows the delegation.

## What Changes

- Prevent inherited subagent extension loading from installing an independent, deny-by-default agent permission framework instance inside child SDK sessions.
- Preserve `inherit_extensions` support for other extensions that subagents need, such as web/search helpers.
- Ensure child sessions continue to enforce permissions through the already assigned delegated identity and effective policy.
- Add regression coverage or scripted checks proving read-only inherited-extension subagents can still read/search the repository.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `agent-runtime`: Clarify extension inheritance for delegated child sessions so the framework's own permission hook is not recursively duplicated without delegated runtime state.

## Impact

- Affects `agents/pi/packages/agent-permission-framework` child-session resource loading and runtime enforcement setup.
- May affect how inherited extensions are filtered or initialized for subagents.
- Adds tests or smoke checks for subagents with `extensions: true` and read-only tools.
