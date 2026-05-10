## 1. Implementation

- [x] 1.1 Update the interactive select approval path in `agents/pi/packages/agent-permission-framework/src/enforcement.ts` so the permission detail message is included in the request-level prompt content.
- [x] 1.2 Replace multi-line approval choices with concise decision-only labels for every select option, including allow-once, allow-for-session, and deny choices.
- [x] 1.3 Preserve existing scope mapping so the concise allow-once choice still returns `once`, the concise allow-for-session choice still returns `session`, and denial still returns no scope.
- [x] 1.4 Keep the non-interactive fail-closed path and confirm fallback behavior unchanged.

## 2. Tests and Validation

- [x] 2.1 Add or update a focused test in `agents/pi/packages/agent-permission-framework/tests/enforcement.test.ts` verifying that `ctx.ui.select` receives permission details in the prompt argument and not in any option label.
- [x] 2.2 Verify the test covers all select options, not only the session approval option.
- [x] 2.3 Run `npm test` in `agents/pi/packages/agent-permission-framework`.
- [x] 2.4 Run `openspec validate fix-permission-dialog-details --strict`.
