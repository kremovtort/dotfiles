## Context

`agent-permission-framework` asks for interactive approval when an action resolves to `ask`. The current select-based prompt builds each approval choice by appending the same multi-line permission details to every option, so the shared context appears under each answer instead of under the request title.

The relevant implementation is the interactive approval path in `agents/pi/packages/agent-permission-framework/src/enforcement.ts`, where a `message` is built from the active agent identity, action fingerprint, decision reason, and matched rule, then duplicated into the select options.

## Goals / Non-Goals

**Goals:**

- Present detailed permission context once as part of the permission request prompt/body.
- Keep all select choices concise and decision-only, for example `Allow once`, `Allow for this session`, and `Deny`.
- Apply the behavior consistently for every select option.
- Preserve existing approval scope behavior, decision fingerprints, auditing, and fail-closed non-interactive handling.

**Non-Goals:**

- Redesign the permission policy model or enforcement precedence.
- Change which actions require approval.
- Add new approval scopes or alter how temporary approvals are persisted.
- Change non-interactive behavior.

## Decisions

1. **Move context into the select prompt rather than option labels.**
   - Build a request-level prompt string that contains the existing title plus the multi-line permission details.
   - Pass concise labels as select options.
   - Rationale: the permission details describe the action being decided and are common to all responses; duplicating them in each option is a presentation bug.
   - Alternative considered: keep the prompt title unchanged and shorten only the session option. Rejected because the issue affects all choices and would leave the detailed context in the wrong UI layer.

2. **Reuse the existing permission detail content.**
   - Keep the current agent identity, action summary, decision reason, and matched rule fields.
   - Rationale: the required context is already assembled correctly; only its placement in the dialog is wrong.
   - Alternative considered: introduce a new formatter with renamed fields. Rejected as unnecessary for this narrow UI fix.

3. **Do not alter confirm fallback semantics.**
   - The confirm-based path already presents the details in the prompt body/message rather than duplicating them across multiple response labels.
   - Rationale: the requested fix is about option text in dialogs with multiple answers; changing fallback behavior risks unrelated UX changes.

## Risks / Trade-offs

- **Pi `ctx.ui.select` rendering may vary by prompt string shape** → Keep the implementation simple: include the same detail lines in the prompt argument and verify manually after `/reload` or Pi restart.
- **Automated tests may not cover UI rendering** → Add or update a focused unit test around the strings passed to `ctx.ui.select`, ensuring details are present in the prompt and absent from each option.
- **Existing users may be accustomed to details in options** → This is an intentional cleanup; decision labels become easier to scan while preserving all context in the request.
