---
name: openspec-review-apply-fixes
description: Apply an approved OpenSpec review fix plan, keeping changes scoped to confirmed findings and related refactoring.
---

# Apply OpenSpec Review Fixes

Implement an approved fix/refactoring plan produced by `openspec-review-plan`.

## Required Inputs

Before editing, ensure you have:

- OpenSpec change name.
- Implementation location/scope.
- Approved fix plan.
- Confirmed findings to address.

If the plan is not clearly approved, stop and ask the user to approve or adjust it.

## Workflow

1. **Load context**

   Read the approved plan and confirmed review findings from the conversation or provided file.

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

   If unrelated changes touch the same files and conflict with the approved plan, ask how to proceed.

4. **Apply fixes in priority order**

   - Fix P0/P1 issues first.
   - Keep each change minimal and tied to a confirmed finding.
   - Reuse existing project abstractions before adding new helpers.
   - Avoid unrelated cleanup.
   - Update OpenSpec artifacts/tasks only when the approved plan requires it or implementation reality must be synchronized.

5. **Refactor only inside scope**

   Perform refactors only when they directly address confirmed findings, reduce duplicated/reinvented code, or are necessary to keep the fix coherent.

6. **Validate**

   Run checks from the approved plan when feasible:

   - OpenSpec commands.
   - Project tests/build/lint.
   - Targeted commands for changed components.

   If a check cannot be run, report why.

7. **Report result**

   Summarize:

   - Findings fixed.
   - Files changed.
   - Validation run and result.
   - Remaining findings or follow-ups.

## Guardrails

- Do not edit without an approved plan.
- Do not broaden scope beyond confirmed findings and approved refactors.
- Do not discard unrelated changes.
- Do not use destructive VCS commands.
- Do not commit or push unless the user explicitly asks.
- Prefer the smallest correct change.
