---
name: openspec-review-plan
description: Plan fixes and refactoring for an OpenSpec change from confirmed reviewer findings without editing code.
---

# OpenSpec Review Fix Plan

Create a repair and refactoring plan from confirmed `openspec-review` findings.

This skill plans only. Do not edit files.

## Inputs

Use the current conversation's review report when available.

If any required input is missing, ask one concise question:

- OpenSpec change name.
- Implementation location.
- Confirmed review findings.
- Whether the user wants all priorities or only selected priorities.

Do not plan from unverified reviewer claims unless the user explicitly asks for a speculative plan.

## Workflow

1. **Load review context**

   Identify confirmed findings, priorities, evidence, and rejected false positives from the latest `openspec-review` result.

2. **Reload OpenSpec artifacts when needed**

   If artifact context is stale or missing, run:

   ```bash
   openspec status --change "<name>" --json
   openspec instructions apply --change "<name>" --json
   ```

   Read the relevant proposal, design, specs, and tasks files.

3. **Detect VCS before VCS commands**

   Load and follow `vcs-detect` before any VCS command.

   Use only read-only commands while planning.

4. **Build a minimal fix plan**

   Preserve reviewer priorities and separate work into:

   - Artifact updates: proposal/design/spec/tasks changes needed to resolve contradictions or sync reality.
   - Code fixes: direct behavior/spec/design fixes.
   - Refactors: scoped reuse or simplification required by the review.
   - Scope cleanup: unrelated code to remove from the reviewed change, if any.
   - Validation: tests, builds, linters, OpenSpec checks, or manual checks.

5. **Order work safely**

   Prefer this order:

   - P0/P1 correctness fixes.
   - Required artifact sync.
   - Reuse/refactor work that reduces duplicate code.
   - Tests/validation.
   - P2/P3 cleanup.

6. **Use active planning UI when available**

   If actively planning with the user, present the plan via `submit_plan`.

## Output Requirements

The plan must include:

- Goals and non-goals.
- Ordered implementation steps.
- Mapping from each step to review finding IDs/priorities.
- Files likely to change.
- Validation commands/checks.
- Risks or questions, only if they affect implementation.

End by asking whether to apply the plan with `openspec-review-apply-fixes`.

## Guardrails

- Do not edit files.
- Do not expand scope beyond confirmed findings unless explicitly requested.
- Prefer the smallest correct fix.
- Prefer reusing existing project code over adding new abstractions.
- Do not plan commits or pushes unless the user explicitly asks.
