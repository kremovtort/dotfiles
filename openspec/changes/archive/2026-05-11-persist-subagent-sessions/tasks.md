## 1. Durable Session Metadata

- [x] 1.1 Add subagent session metadata fields to `SubagentRunRecord` and internal run records, including child session id, child session file, parent session id/file, resumable flag, and resume lineage as needed.
- [x] 1.2 Add an `interrupted` run status and update status mapping, terminal-state helpers, result details, and any type unions that currently enumerate subagent statuses.
- [x] 1.3 Implement a subagent session path helper that mirrors Pi's cwd encoding and produces `subagent-sessions/--cwd--/<parentSessionId>/<runId>_<sessionId>.jsonl` paths.
- [x] 1.4 Add tests for path generation, metadata serialization through `publicRun()`, and exclusion of live-only fields from persisted run records.

## 2. Persistent Child Session Creation

- [x] 2.1 Replace `SessionManager.inMemory(run.cwd)` in subagent execution with a persistent SessionManager rooted in the subagent session namespace.
- [x] 2.2 Record child session id and file path on the run as soon as the SessionManager is created or opened.
- [x] 2.3 Link child sessions to parent session metadata when the parent session id/file is available.
- [x] 2.4 Add a `session_info` label or equivalent standard session metadata that identifies subagent type, description, and run id.
- [x] 2.5 Add tests or a focused integration fixture proving subagent user/assistant/tool messages are written as standard SessionManager JSONL entries.

## 3. Restore and Explicit Resume

- [x] 3.1 Update `SubagentRegistry.restore()` so restored `queued` or `running` records with usable child session files become `interrupted` and resumable without consuming queue capacity.
- [x] 3.2 Preserve the existing aborted behavior for restored non-live runs that have no usable child session file.
- [x] 3.3 Extend the `subagent` resume path to allow explicit continuation from an interrupted resumable run by opening the saved child session file.
- [x] 3.4 Re-run delegation permission checks before resuming and leave the interrupted run unchanged when resume is denied.
- [x] 3.5 Add tests for restored interrupted runs, restored aborted fallback, explicit resume from saved session, and denied resume behavior.

## 4. Result, Steering, and UI Behavior

- [x] 4.1 Update `get_subagent_result` so interrupted runs report `interrupted` status and verbose output includes child session id, child session file, and resume guidance.
- [x] 4.2 Update `steer_subagent` so interrupted runs are rejected with guidance to use explicit resume instead of live steering.
- [x] 4.3 Update foreground progress formatting and result details to understand interrupted/resumable metadata.
- [x] 4.4 Update the subagent widget to render interrupted resumable runs as warning-style finished/linger entries rather than active running entries.
- [x] 4.5 Add a restore-time user notification for interrupted resumable runs that tells the user to ask the agent to inspect/resume by id, without presenting model-callable tool names as direct user commands.
- [x] 4.6 Ensure the status bar does not count interrupted resumable runs as running or queued.
- [x] 4.7 Add tests for interrupted result formatting, steering rejection, widget rendering, user-facing notification wording, and status text counts.

## 5. Permission Approval Queue Scoping

- [x] 5.1 Replace the module-level approval serialization queue with a scoped approval queue owned by the parent-visible approval context or approval broker.
- [x] 5.2 Ensure main-agent approvals and subagent approvals using the same parent UI remain serialized in request order.
- [x] 5.3 Ensure independent parent sessions or approval brokers do not block each other through global approval queue state.
- [x] 5.4 Clear restored interrupted runs' pending permission metadata and ensure explicit resume uses a fresh approval broker/queue.
- [x] 5.5 Add tests for same-context serialization, independent-context non-blocking behavior, missing-broker fail-closed behavior, and restored pending approval clearing.

## 6. Verification

- [x] 6.1 Run the package test suite for `agents/pi/packages/agent-permission-framework`.
- [x] 6.2 Run OpenSpec validation for `persist-subagent-sessions`.
- [x] 6.3 Manually smoke-test a background subagent after `/reload` or Pi restart to confirm child JSONL persistence, interrupted restore display, explicit resume guidance, and scoped permission approval prompts.
