## Context

`agent-permission-framework` exposes `get_subagent_result` for polling or waiting on background subagent runs. The current implementation handles `wait: true` by entering a timer-based loop while the run status is `queued` or `running`, but the tool executor ignores the parent tool-call `AbortSignal`. As a result, Escape/tool-call cancellation does not interrupt the wait loop even though regular Pi tool calls are expected to return control promptly when cancelled. Because the unresolved tool `execute` promise keeps the parent assistant turn active, the original Pi session can remain unavailable for new user messages until the background subagent eventually reaches a terminal state.

The background subagent run itself is independent from this retrieval call. Cancelling `get_subagent_result` should cancel only the caller's wait for a result, not abort or mutate the background run unless a separate cancellation feature is introduced later.

## Goals / Non-Goals

**Goals:**

- Make `get_subagent_result(wait: true)` observe the executor `AbortSignal` while waiting.
- Return control promptly when the tool call is cancelled by Escape or another parent abort source.
- Release the parent Pi session/turn promptly after cancellation so the user can send new messages without waiting for the background subagent to finish.
- Keep the background run's registry state intact when only the result wait is cancelled.
- Preserve existing behavior for `wait: false`, missing run IDs, completed runs, and normal wait completion.
- Surface a clear cancelled-wait result/error so users and parent agents can distinguish it from subagent failure or abort.

**Non-Goals:**

- Do not add a new API to abort a background subagent run.
- Do not change foreground `subagent` cancellation semantics.
- Do not change background scheduling, queue promotion, steering, or permission decisions.
- Do not introduce new runtime dependencies.

## Decisions

1. **Treat cancellation as cancelling the retrieval wait, not the subagent run.**
   - Rationale: `get_subagent_result` is a read/status tool; cancelling it should behave like stopping a blocking poll. The background run may still be useful and remains retrievable later.
   - Alternative considered: abort the background run when `get_subagent_result` is cancelled. This would be surprising because the API name is result retrieval, not run cancellation, and could destroy work unintentionally.

2. **Wire the existing tool executor `AbortSignal` into the `wait: true` loop.**
   - Rationale: Pi already passes cancellation through the tool executor signal. Observing it aligns `get_subagent_result` with other cancellable tool calls without changing public parameters.
   - Alternative considered: add a timeout parameter. Timeouts are useful but do not solve Escape cancellation directly and would expand the public API unnecessarily for this fix.

3. **Replace the uncancellable interval promise with an abort-aware wait helper.**
   - Rationale: a single helper can clear timers/listeners on every exit path and avoid leaking intervals after cancellation or completion.
   - Expected behavior: if the signal is already aborted, return/throw immediately; otherwise emit progress periodically until the run leaves `queued`/`running` or the signal aborts. On abort, the wait helper must settle the tool executor promise so Pi can end the active turn and accept new messages in the parent session.

4. **Report a cancelled wait distinctly from run terminal states.**
   - Rationale: users need to know that only the wait was cancelled and that the background run may still be running. The result should not claim the subagent completed, failed, or was aborted.
   - Preferred shape: return a tool result with status/details indicating cancellation of the wait and include the current public run snapshot when available.

## Risks / Trade-offs

- **Risk: leaking timers or abort listeners** → Mitigation: centralize cleanup in the abort-aware wait helper and cover both completion and cancellation tests.
- **Risk: parent session remains locked even after Escape** → Mitigation: test that aborting the wait settles the tool execution promise before the background run completes.
- **Risk: parent agent interprets cancellation as subagent failure** → Mitigation: use explicit wording such as `Result wait cancelled; agent is still <status>` and preserve the run status in details.
- **Risk: race between run completion and abort** → Mitigation: check run status before and after registering abort handling; if the run is already terminal, return the normal result.
- **Risk: Pi expects aborted tools to throw rather than return a result** → Mitigation: verify existing tool cancellation conventions in this package/Pi SDK and choose the behavior that actually releases the UI while preserving a clear message.
