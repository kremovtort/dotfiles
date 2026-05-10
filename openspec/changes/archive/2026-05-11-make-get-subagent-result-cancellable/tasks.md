## 1. Investigation

- [x] 1.1 Confirm Pi tool cancellation behavior for `execute(toolCallId, params, signal, onUpdate)` and decide whether a cancelled wait should return a structured tool result or throw the SDK's expected abort/cancel error.
- [x] 1.2 Identify the current `get_subagent_result(wait: true)` polling path in `agents/pi/packages/agent-permission-framework/src/subagents.ts` and any existing result-rendering/status conventions that cancelled waits must preserve.

## 2. Implementation

- [x] 2.1 Add an abort-aware wait helper for queued/running subagent runs that emits progress, clears timers/listeners on every exit path, and settles promptly when the parent tool-call `AbortSignal` aborts.
- [x] 2.2 Wire `get_subagent_result` to pass its executor `AbortSignal` into the wait helper instead of ignoring it.
- [x] 2.3 Ensure cancelling `get_subagent_result(wait: true)` only cancels the result wait and does not mark the background subagent run as completed, failed, or aborted.
- [x] 2.4 Return or propagate a clear cancelled-wait outcome that distinguishes parent wait cancellation from subagent failure/abort and leaves the run retrievable later.

## 3. Tests

- [x] 3.1 Add a unit test that starts a running background subagent, calls the result-wait path with `wait: true`, aborts the parent signal, and verifies the wait settles before the background run completes.
- [x] 3.2 Add assertions that the background run remains queued/running after wait cancellation and can still be retrieved or completed normally later.
- [x] 3.3 Add a regression check that normal `get_subagent_result(wait: true)` still waits until completion when the signal is not aborted.
- [x] 3.4 Add a regression check that `get_subagent_result(wait: false)` and already-terminal runs are unaffected by the cancellation helper.

## 4. Verification

- [x] 4.1 Run `npm test` in `agents/pi/packages/agent-permission-framework`.
- [x] 4.2 Manually reload or restart Pi, start a long-running background subagent, call `get_subagent_result` with `wait: true`, press Escape, and verify the original session accepts a new user message before the subagent finishes.
- [x] 4.3 After the manual cancellation, call `get_subagent_result` again for the same run and verify it still reports the current or completed background subagent result.
