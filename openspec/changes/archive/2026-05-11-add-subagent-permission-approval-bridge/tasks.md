## 1. Approval Broker Model

- [x] 1.1 Add a narrow permission approval broker type and result model for `once`, `session`, denied, timeout, and abort outcomes.
- [x] 1.2 Refactor `enforceDecision` to use an optional broker for `ask` decisions while preserving existing main-session UI behavior.
- [x] 1.3 Add explicit pending and resolved audit records for approval-required decisions, including identity, fingerprint, matched rule, scope, and denial reason.
- [x] 1.4 Add timeout and abort handling for approval waits, with fail-closed denial reasons.

## 2. Subagent Bridge Integration

- [x] 2.1 Create a parent-visible approval broker when launching a subagent from an interactive parent context.
- [x] 2.2 Pass the broker into child tool-call enforcement without calling `session.bindExtensions` with the full parent UI context.
- [x] 2.3 Ensure approvals granted through the bridge are stored in the child runtime and scoped to the child identity and action fingerprint.
- [x] 2.4 Preserve headless fail-closed behavior with explicit reasons when no parent-visible broker is available.

## 3. Pending Permission Run State

- [x] 3.1 Add transient pending permission metadata to subagent run records and public run serialization.
- [x] 3.2 Set pending permission metadata before an approval prompt starts and clear it on approval, denial, timeout, or abort.
- [x] 3.3 Update foreground subagent progress text to show permission-waiting activity with the pending action fingerprint.
- [x] 3.4 Update the subagent widget activity rendering to distinguish permission waits from thinking and ordinary tool execution.

## 4. Tests and Verification

- [x] 4.1 Add enforcement tests for broker-approved child `ask` decisions and child-scoped approval reuse.
- [x] 4.2 Add enforcement tests for no broker, timeout, abort, and user denial fail-closed paths.
- [x] 4.3 Add subagent tests proving the child session does not receive the full parent UI context for permission prompting.
- [x] 4.4 Add registry/widget tests for pending permission metadata visibility and clearing.
- [x] 4.5 Run the agent-permission-framework test suite and fix regressions.
