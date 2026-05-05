---
name: openspec-review
description: Review an OpenSpec change by asking where the implementation changes live, running three reviewer subagents in parallel, verifying their findings, prioritizing confirmed issues, and offering to plan fixes.
---

# OpenSpec Review

Review an OpenSpec change and its implementation with three independent reviewer subagents.

## Required First Step

Before reading diffs or launching reviewers, explicitly ask where the implementation changes are located.

Ask an open-ended question such as:

> Where are the implementation changes for this OpenSpec change? Examples: current working copy, current jj change, jj revset/bookmark, git branch, git commit/range, GitHub PR URL/number, Arc review/branch, patch file, or a custom read-only diff command.

Do not infer this silently from the current branch/bookmark. The user must confirm the review location.

## Inputs

The user may provide:

- OpenSpec change name.
- Implementation location.
- Optional review focus.

If the OpenSpec change name is missing or ambiguous, select it after the location question:

- If conversation context names exactly one change, use it.
- Otherwise run `openspec list --json` and ask the user to choose.
- Do not guess among multiple active changes.

## Workflow

1. **Ask for implementation location**

   Use the question above. Capture the answer as `location.kind` and `location.value`.

2. **Detect VCS before VCS commands**

   Load and follow `vcs-detect` before any VCS command.

   Support:
   - Git working copy, branch, commit, range, or PR.
   - Jujutsu working copy, revset, bookmark, or colocated Git repo.
   - Arc or monorepo review locations when the user provides the command/location.
   - Patch files and custom read-only diff commands.

3. **Load OpenSpec artifacts**

   Run:

   ```bash
   openspec status --change "<name>" --json
   openspec instructions apply --change "<name>" --json
   ```

   Read every artifact path listed in `contextFiles`, including proposal, design, specs, and tasks when present.

4. **Collect read-only diff context**

   Use the confirmed location and detected VCS.

   Prefer read-only commands:
   - Git: `git status`, `git diff`, `git show`, `git log`.
   - jj: `jj status`, `jj diff`, `jj show`, `jj log`.
   - GitHub PR: use `gh pr view` and read-only diff/status commands.
   - Arc/custom: use the exact read-only location or command the user provided.

   Never mutate VCS state. Do not commit, push, reset, checkout/restore, abandon, rebase, squash, split, submit, or land.

5. **Run three reviewers in parallel**

   In one assistant tool-use message, launch these subagents concurrently with the same JSON payload:

   - `openspec-reviewer-gpt`
   - `openspec-reviewer-glm`
   - `openspec-reviewer-kimi`

   Payload shape:

   ```json
   {
     "change": "<change-name>",
     "location": {
       "kind": "<kind>",
       "value": "<user answer>"
     },
     "artifacts": {
       "proposal": ["<paths>"],
       "design": ["<paths>"],
       "specs": ["<paths>"],
       "tasks": ["<paths>"]
     },
     "diff_context": "<concise read-only diff/scope summary>",
     "focus": "<optional focus>"
   }
   ```

   Reviewer results are evidence, not final truth.

6. **Verify reviewer findings**

   For every substantive finding:

   - Re-read the cited code and OpenSpec artifact lines.
   - Confirm the finding against actual diff/scope and project patterns.
   - Deduplicate overlapping findings across reviewers.
   - Reject false positives explicitly.
   - Downgrade uncertain claims instead of overstating them.

   Use `scout` yourself if you need extra project-pattern discovery to validate a finding. Use `docs-digger` only for source-backed external facts.

7. **Prioritize confirmed findings**

   Use these priorities:

   - `P0 Blocker`: unsafe to accept; severe correctness, security, data-loss, build, or spec contradiction.
   - `P1 Must Fix`: required behavior missing/wrong, spec/design violation, or material unrelated code in scope.
   - `P2 Should Fix`: important maintainability, test, convention, or reuse issue with concrete evidence.
   - `P3 Nice To Have`: low-risk cleanup or clarity improvement.

8. **Offer next step**

   End by offering to plan fixes/refactoring with `openspec-review-plan`.

## Output Format

Return Markdown with these sections:

```markdown
## Confirmed Findings

### P1 Must Fix: <title>

- Source reviewers: <gpt|glm|kimi>
- Evidence: `<path>:<line>` and/or OpenSpec artifact reference.
- Why it matters: <impact>.
- Recommended fix: <minimal fix>.
- Confidence: high|medium|low.

## Needs Clarification

- <claims that could not be confirmed without user input>

## Rejected Reviewer Findings

- <false positive and why it was rejected>

## Coverage

- OpenSpec change: `<name>`
- Implementation location: `<kind>: <value>`
- Reviewers run: GPT, GLM, Kimi
- Limitations: <missing data/tools, if any>

## Next Step

I can now plan fixes and refactoring with `openspec-review-plan`.
```

If there are no confirmed findings, say so explicitly and still include coverage and rejected/limitation notes.

## Guardrails

- Do not edit files during review.
- Do not run destructive commands.
- Do not commit or push.
- Do not treat reviewer output as authoritative without local verification.
- Do not report unrelated code unless it is actually inside the reviewed location/diff.
