## Context

Subagent runs are created as isolated Pi SDK child sessions. The current implementation installs a child `tool_call` hook that enforces the delegated effective policy, but it does not bind the parent TUI `uiContext` into the child session. As a result, child enforcement sees no interactive UI and converts `ask` decisions into denied tool calls. This preserves isolation, but users cannot approve subagent actions that are intentionally configured as `ask`, and the parent UI has no explicit pending-permission state to explain what the subagent is doing.

The change needs to preserve the existing security model: subagent effective policy remains the intersection of the parent delegation grant and the subagent policy, approvals remain scoped to the child identity and action fingerprint, and general child extension UI must not be allowed to mutate parent widgets/status/editor state.

## Goals / Non-Goals

**Goals:**

- Route subagent permission `ask` decisions to a parent-visible approval prompt without binding the full parent UI into the child session.
- Show a clear pending permission state for foreground progress and the subagent indicator while a child tool call waits for approval.
- Fail closed with explicit reasons when approval cannot be obtained because UI is unavailable, the run/tool call is aborted, or an approval timeout expires.
- Preserve existing policy composition, approval scoping, and audit identity semantics.

**Non-Goals:**

- Do not expose the full parent `ExtensionUIContext` to child sessions.
- Do not allow subagents to modify parent editor text, widgets, status entries, headers, footers, or autocomplete providers through inherited UI APIs.
- Do not change the core policy precedence model (`deny > ask > allow`).
- Do not introduce persistent global approvals that cross agent identities.

## Decisions

### Use a narrow permission approval broker instead of binding parent UI to child sessions

Introduce a small approval abstraction used by enforcement, for example `PermissionApprovalBroker`, with a method that accepts the active identity, decision, optional abort signal, timeout, and request metadata, and returns an approval scope (`once` or `session`) or denial. The main session can use a UI-backed broker that calls `ctx.ui.select`; subagent enforcement receives a parent-backed broker that calls the parent-visible UI captured at launch time.

Alternative considered: call `session.bindExtensions({ uiContext: ctx.ui })` on the child session. This is simpler, but it gives the child session the full extension UI surface and can let inherited extensions alter parent UI state. A narrow broker keeps child sessions headless except for permission approval.

### Keep approvals stored in the runtime that owns the active identity

When a parent-visible prompt approves a child request, `enforceDecision` still records the approval in the child `AgentRuntimeState`. The broker only obtains the user decision; it does not own approval persistence. This keeps approval matching tied to the subagent identity and fingerprint.

Alternative considered: store subagent approvals in the parent runtime. That would simplify persistence through parent session entries, but risks accidental cross-identity reuse and makes `runtime.hasApproval()` semantics less local.

### Represent pending permission as run metadata, not a terminal status

Add transient metadata to each subagent run, such as `pendingPermission`, while keeping the lifecycle status `running`. Foreground progress and the widget can then render `waiting for permission: <fingerprint>` without disrupting queued/running/completed/failed/aborted transitions.

Alternative considered: add a new lifecycle status like `waiting_for_permission`. That makes display logic direct, but complicates queue capacity handling because the run still occupies an execution slot and can resume after approval.

### Fail closed on unavailable or abandoned approval

Approval requests must be denied with explicit reasons when no parent-visible UI is available, when the run/tool-call signal aborts, or when a configurable timeout expires. The denial reason should be returned to the child tool result and recorded in audit data.

Alternative considered: wait indefinitely for user response. This recreates the original unexplained hang risk and is not acceptable for long-running subagent sessions.

## Risks / Trade-offs

- Parent UI prompt could appear while the foreground `subagent` tool is already rendering progress → serialize approval prompts and make progress show pending permission until the prompt resolves.
- Background subagents may request approval when the user is not actively watching → use a timeout and clear denial message; future work can add notifications or deferred approval queues.
- Timeout values may be too aggressive or too lax → make the timeout configurable with a conservative default, and cover timeout behavior in tests.
- Child audit persistence is currently forwarded through subagent helper audit hooks → ensure pending/approved/denied audit entries are forwarded to the parent session entries consistently.
