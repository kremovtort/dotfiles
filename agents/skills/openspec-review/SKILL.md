---
name: openspec-review
description: Review an OpenSpec change by asking where the implementation changes live, running reviewer subagents in parallel, verifying findings, and offering either design/plan-first fixes or direct recommended-fix application.
---

# OpenSpec Review

Review an OpenSpec change and its implementation with independent reviewer subagents.

## Required First Steps

Before reading diffs, asking for the review location, or launching reviewers, load and follow `vcs-detect` using the current runtime context.

After VCS detection, explicitly ask where the implementation changes are located.

If the environment provides a built-in tool for asking the user a question, use that tool for this location prompt instead of asking only in plain assistant text.

Ask with awareness of the current context and detected VCS. If conversation context already mentions a likely implementation location, ask the user to confirm or correct it instead of ignoring that context. Otherwise ask an open-ended question such as:

> Where are the implementation changes for this OpenSpec change? Examples: current working copy, current jj change, jj revset/bookmark, git branch, git commit/range, GitHub PR URL/number, Arc review/branch, patch file, or a custom read-only diff command.

Do not infer this silently from the current branch/bookmark, detected VCS, or conversation context. The user must confirm the review location.

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

1. **Detect VCS before VCS commands or location prompt**

   Load and follow `vcs-detect` before any VCS command and before asking where the implementation changes are located.

   Use the detected VCS and the agent's current conversation/task context to make the location prompt specific and useful.

2. **Ask for implementation location**

   Use the question above. If the runtime exposes a dedicated ask-user/question tool, use it for this prompt. Capture the answer as `location.kind` and `location.value`.

   If the current context already names a likely location, include it as a suggested default and ask for confirmation or correction. If no likely location is present, ask the open-ended question with examples relevant to the detected VCS first.

3. **Respect detected VCS for later VCS commands**

   Continue using the `vcs-detect` result before running any VCS command.

   Support:
   - Git working copy, branch, commit, range, or PR.
   - Jujutsu working copy, revset, bookmark, or colocated Git repo.
   - Arc or monorepo review locations when the user provides the command/location.
   - Patch files and custom read-only diff commands.

4. **Prepare compact reviewer scope**

   Do not collect or inline OpenSpec artifact contents, status JSON, command output, or diffs into the reviewer payload.

   The reviewer subagents have read-only filesystem and VCS access. They must load the OpenSpec artifacts and inspect the requested diff/location themselves.

   Only pass the confirmed change name, the user-confirmed implementation location, and optional focus. If the user provided extra scope constraints, include them inside `location.value` instead of pasting command output.

   Never mutate VCS state. Do not commit, push, reset, checkout/restore, abandon, rebase, squash, split, submit, or land.

5. **Run reviewers in parallel**

   Launch all available reviewer subagents whose names match `openspec-reviewer-*` concurrently with the same compact JSON payload.

   Do not maintain a hard-coded reviewer list in this workflow. Use the runtime's available subagent list/configuration to identify every `openspec-reviewer-*` subagent, then run each one exactly once.

   Runtime notes:
   - OpenCode: use the subagent/task mechanism with the payload as the direct JSON object.
   - Do not add artifact lists, diff summaries, command output, or file contents to the payload.

   Payload shape:

   ```json
   {
     "change": "<change-name>",
     "location": {
       "kind": "<kind>",
       "value": "<user answer>"
     },
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

   Use `explore` yourself if you need extra project-pattern discovery to validate a finding. Use `researcher` only for source-backed external facts. In Pi, call them through `Agent` with the same JSON-payload-in-`prompt` convention.

7. **Prioritize confirmed findings**

   Use these priorities:
   - `P0 Blocker`: unsafe to accept; severe correctness, security, data-loss, build, or spec contradiction.
   - `P1 Must Fix`: required behavior missing/wrong, spec/design violation, or material unrelated code in scope.
   - `P2 Should Fix`: important maintainability, test, convention, or reuse issue with concrete evidence.
   - `P3 Nice To Have`: low-risk cleanup or clarity improvement.

8. **Offer next step branch**

   End by offering two explicit next-step choices:

   - Design and plan first: use `openspec-review-plan` to create the repair design and ordered fix plan, then apply that approved plan with `openspec-review-apply-fixes`.
   - Apply recommended fixes directly: use `openspec-review-apply-fixes` with this review's confirmed findings and recommended fixes as the scope, without a separate plan phase.

   If there are no confirmed findings, do not offer fix application unless the user explicitly asks for cleanup or follow-up work.

## Output Format

Return Markdown with these sections:

```markdown
## Confirmed Findings

### P1 Must Fix: <title>

- Source reviewers: <reviewer names>
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
- Reviewers run: <reviewer names>
- Limitations: <missing data/tools, if any>

## Next Step

Choose one next step:

1. Design and plan fixes with `openspec-review-plan`, then apply the approved plan.
2. Apply the recommended fixes directly with `openspec-review-apply-fixes`.
```

If there are no confirmed findings, say so explicitly and still include coverage and rejected/limitation notes.

## Guardrails

- Do not edit files during review.
- Do not run destructive commands.
- Do not commit or push.
- Do not treat reviewer output as authoritative without local verification.
- Do not report unrelated code unless it is actually inside the reviewed location/diff.
