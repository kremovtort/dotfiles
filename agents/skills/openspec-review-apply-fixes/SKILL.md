---
name: openspec-review-apply-fixes
description: Apply an approved OpenSpec review fix plan or directly apply confirmed recommended fixes, keeping changes scoped to review findings.
---

# Apply OpenSpec Review Fixes

Implement either an approved fix/refactoring plan produced by `openspec-review-plan` or the direct recommended fixes from a confirmed `openspec-review` result.

## Required Inputs

Before editing, ensure you have:

- OpenSpec change name.
- Implementation location/scope.
- Confirmed findings to address.
- One of:
  - Approved repair design and fix plan from `openspec-review-plan`.
  - Explicit user choice to apply the recommended fixes directly from the latest `openspec-review` result.

If neither an approved plan nor explicit direct-apply choice is present, stop and ask the user to choose either design-and-plan-first or direct recommended-fix application.

## Workflow

1. **Load context and mode**

   Determine which apply mode the user chose:

   - Planned mode: apply the approved repair design and fix plan from `openspec-review-plan`.
   - Direct mode: apply the latest `openspec-review` confirmed findings using each finding's recommended fix as the scope.

   Read the approved plan when in planned mode, or the latest confirmed review findings when in direct mode.

   Reload OpenSpec artifacts when needed:

   ```bash
   openspec status --change "<name>" --json
   openspec instructions apply --change "<name>" --json
   ```

2. **Detect VCS before VCS commands**

   Load and follow `vcs-detect` before any VCS command.

   Use VCS only for read-only inspection unless the user explicitly requests a commit or push.

3. **Inspect current scope**

   Re-check the current diff/location before editing so you do not overwrite unrelated user or agent changes.

   If unrelated changes touch the same files and conflict with the chosen scope, ask how to proceed.

4. **Apply fixes in priority order**

   - Fix P0/P1 issues first.
   - Keep each change minimal and tied to a confirmed finding.
   - In planned mode, follow the approved design and fix plan.
   - In direct mode, apply only the review report's recommended fixes and do not introduce new design/refactor work.
   - Reuse existing project abstractions before adding new helpers.
   - Avoid unrelated cleanup.
   - Update OpenSpec artifacts/tasks only when the planned scope requires it, the direct recommended fix explicitly calls for it, or implementation reality must be synchronized.

5. **Refactor only inside scope**

   Perform refactors only when they directly address confirmed findings, reduce duplicated/reinvented code, or are necessary to keep the fix coherent. In direct mode, refactor only when a recommended fix explicitly requires it.

6. **Validate**

   Run checks from the chosen scope when feasible:

   - OpenSpec commands.
   - Project tests/build/lint.
   - Targeted commands for changed components.

   If a check cannot be run, report why.

7. **Report result**

   Summarize:

   - Apply mode used: planned or direct.
   - Findings fixed.
   - Files changed.
   - Validation run and result.
   - Remaining findings or follow-ups.

## Guardrails

- Do not edit without either an approved plan or an explicit direct-apply choice.
- Do not broaden scope beyond confirmed findings and approved plan or direct recommended fixes.
- Do not discard unrelated changes.
- Do not use destructive VCS commands.
- Do not commit or push unless the user explicitly asks.
- Prefer the smallest correct change.
