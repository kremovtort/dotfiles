## 1. Upstream UI Extraction

- [x] 1.1 Inspect `tintinweb/pi-subagents` `AgentWidget` and related helpers to identify all appearance-critical constants, rendering helpers, status text, linger behavior, and widget lifecycle code.
- [x] 1.2 Add a vendored/adapted local UI module under `agents/pi/packages/agent-permission-framework/src/` with source comments referencing the upstream implementation and without adding `pi-subagents` as a runtime dependency.

## 2. Local Runtime Integration

- [x] 2.1 Add a local adapter that maps `SubagentRunRecord` registry state to the fields required by the copied widget renderer: id, display name, description, status, timestamps, tool uses, turn/max-turn counts, activity text, queued count, and errors.
- [x] 2.2 Wire the indicator to subagent lifecycle transitions so it updates on queued, running, promoted, activity/progress, completed, failed, aborted, and steered states without requiring `get_subagent_result` polling.
- [x] 2.3 Implement copied `pi-subagents` status-bar behavior for the `subagents` status key, including running/queued count wording and clearing when nothing is visible.
- [x] 2.4 Implement copied above-editor `Agents` widget behavior, including heading, tree connectors, spinner frames, icons, colors, activity line format, queued summary, finished-run linger, truncation, overflow, and cleanup timer behavior.

## 3. Verification

- [x] 3.1 Add or update unit tests for adapter/status behavior covering running, queued, completed, failed/aborted, and clear states.
- [x] 3.2 Add or update renderer-focused tests or snapshots that verify the copied visible strings/icons/layout for running, queued, finished, and overflow cases.
- [x] 3.3 Run the agent-permission-framework test suite and type/build checks for the package.
- [x] 3.4 Manually test in Pi after `/reload` or restart by launching foreground and background subagents and comparing the indicator appearance against `pi-subagents`.
