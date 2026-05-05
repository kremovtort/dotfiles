## Why

The current subagent set keeps discovery, docs, and runner logs out of the parent context, but it does not provide a dedicated path for repetitive large-scale mechanical edits. A focused codemod subagent is needed to make refactor-heavy changes safer, more deterministic, and less noisy.

## What Changes

- Add a new `codemodder` subagent for repetitive, deterministic refactor edits across many files.
- Define a strict two-phase workflow: `plan` (dry-run preview) and `apply` (controlled execution).
- Define explicit JSON input/output contracts for delegation, result reporting, and follow-up handling.
- Add safety guardrails: include/exclude scope, edit/file limits, ambiguity handling, and idempotency checks.
- Integrate the new role into OpenCode delegation guidance and local agent installation.

## Capabilities

### New Capabilities
- `codemodder-subagent`: deterministic mechanical code transformations with plan/apply execution and structured safety reporting.

### Modified Capabilities
- None.

## Impact

- Affected code: `agents/opencode/agents/`, `agents/opencode/_AGENTS.md`, and `agents/opencode.nix`.
- New contract surface: codemod task request/response JSON schema for parent-to-subagent handoff.
- Workflow impact: large repetitive refactors can be delegated without polluting parent context.
