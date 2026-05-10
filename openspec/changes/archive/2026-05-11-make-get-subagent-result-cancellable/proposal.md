## Why

`get_subagent_result` with `wait: true` can currently keep waiting even after the user presses Escape to cancel the tool call. This makes the Pi UI feel stuck and inconsistent with normal cancellable tool-call behavior, especially when a background subagent is long-running or stalled.

## What Changes

- Make `get_subagent_result` honor tool-call cancellation while it is waiting for a queued or running subagent result.
- Ensure cancellation releases the parent Pi session promptly so the user can send new messages after Escape/cancellation, without corrupting the tracked background subagent run state.
- Preserve existing non-waiting result lookup behavior and background subagent execution semantics.
- Report cancellation in a clear way that distinguishes user-cancelled waiting from subagent completion, failure, or abort.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `agent-runtime`: `get_subagent_result` waiting behavior must become cancellable by the parent tool-call abort signal.

## Impact

- Affected package: `agents/pi/packages/agent-permission-framework`.
- Affected implementation areas: subagent orchestration tools, result polling/wait loops, parent turn/session unblocking, and cancellation/abort handling.
- Affected users: Pi sessions using background subagents and `get_subagent_result` with `wait: true`.
