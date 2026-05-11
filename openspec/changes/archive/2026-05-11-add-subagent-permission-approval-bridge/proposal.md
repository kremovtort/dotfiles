## Why

Subagent tool calls that require permission approval currently run inside headless child sessions, so `ask` decisions fail closed without a parent-visible explanation. This makes long-running subagent work appear stalled or mysteriously failed, and prevents users from approving safe actions that are intentionally delegated as `ask`.

## What Changes

- Add a parent-mediated permission approval bridge for subagent tool calls that resolve to `ask`.
- Keep child sessions isolated/headless for general extension UI; bridge only permission approval requests to the parent-visible UI.
- Surface pending subagent permission requests in foreground progress and the subagent indicator so the user can see why a run is waiting.
- Fail closed with an explicit denial reason when no parent-visible UI is available, the parent tool call is aborted, or an approval request times out.
- Scope approvals to the subagent runtime identity and action fingerprint, preserving existing identity/audit semantics.

## Capabilities

### New Capabilities

- None.

### Modified Capabilities

- `agent-permission-enforcement`: Add explicit requirements for parent-mediated approval of subagent `ask` decisions, visible pending approval state, timeout/abort handling, and audit records.
- `agent-runtime`: Add runtime behavior for carrying a permission approval bridge into child enforcement without binding the full parent UI into the child session, plus subagent run display state for pending permission.

## Impact

- Affected package: `agents/pi/packages/agent-permission-framework`.
- Affected areas: permission enforcement, subagent execution, subagent registry/run state, widget/progress rendering, tests.
- No new runtime dependencies are expected.
