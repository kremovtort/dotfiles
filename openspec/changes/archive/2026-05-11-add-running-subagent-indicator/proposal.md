## Why

Long-running foreground and background subagent runs can make the parent Pi session feel idle or opaque, especially when several delegated runs are active at once. Showing the currently running subagents in-session makes delegation state visible without requiring the user or parent agent to poll `get_subagent_result`.

## What Changes

- Add an in-session indicator for currently running subagents to the local `agent-permission-framework` package.
- Fully match the running-subagent indicator appearance from `tintinweb/pi-subagents`, including the same in-session widget/status presentation, layout, icons, colors, spinner behavior, and visible wording; vendor or adapt the needed code rather than importing it as a runtime dependency.
- Display active subagent run information for this session, including enough identity/status detail to distinguish running work from queued or completed work.
- Keep the indicator synchronized with subagent lifecycle transitions so it appears when runs are active and clears when no subagents are running.
- Preserve existing subagent execution, permission enforcement, and result retrieval semantics.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `agent-runtime`: Add visible session-level reporting for currently running subagents as part of subagent orchestration and lifecycle behavior.

## Impact

- Affected code: `agents/pi/packages/agent-permission-framework/` runtime/session and UI integration code.
- Reference implementation: `tintinweb/pi-subagents` running-subagent indicator code may be copied or adapted.
- No breaking changes to the model-callable `subagent`, `get_subagent_result`, or `steer_subagent` tool contracts are expected.
