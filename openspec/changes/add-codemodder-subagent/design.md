## Context

OpenCode currently has specialized subagents for discovery (`scout`), documentation (`docs-digger`), and command execution triage (`runner`). Large mechanical refactors are still handled by the parent agent or ad-hoc edits, which increases context noise and raises the chance of unsafe broad changes.

The proposed `codemodder` subagent fills this gap by handling repetitive, deterministic edits under explicit constraints while leaving architecture and product decisions with the parent agent.

## Goals / Non-Goals

**Goals:**
- Provide a specialized subagent for high-volume mechanical edits with deterministic behavior.
- Enforce a two-phase `plan` then `apply` workflow for safer rollout.
- Return machine-readable outputs that parent logic can use for orchestration and follow-up.
- Keep scope boundaries clear with existing subagents.

**Non-Goals:**
- Replacing parent-agent reasoning about architecture or API semantics.
- Running test/build/verification workflows (remains with `runner`).
- Performing open-ended discovery or documentation research.
- Handling destructive repository operations.

## Decisions

### 1) Add a dedicated `codemodder` subagent definition
- Decision: create `agents/opencode/agents/codemodder.md` with a strict mechanical-edit role.
- Rationale: naming and role boundaries reduce accidental delegation of non-mechanical tasks.
- Alternative considered: reuse a generic coding subagent.
- Why not: generic coding behavior is less predictable for wide mechanical rewrites.

### 2) Use explicit `plan` and `apply` execution modes
- Decision: require every request to specify `mode`.
- Rationale: `plan` provides non-mutating visibility before mass edits; `apply` executes only approved rules.
- Alternative considered: single apply-only mode.
- Why not: too risky for broad refactors and hard to review incrementally.

### 3) Define narrow edit primitives and strict execution scope
- Decision: support declared edit operations only (for example AST replace and bounded text/regex replacements), plus include/exclude path filters.
- Rationale: limiting primitives keeps behavior predictable and auditable.
- Alternative considered: free-form instruction-only edits.
- Why not: raises ambiguity and nondeterminism for large codebases.

### 4) Enforce safety guardrails as first-class contract fields
- Decision: include max-files, max-edits-per-file, ambiguity policy, and mutation constraints.
- Rationale: guardrails prevent runaway codemods and make failure modes explicit.
- Alternative considered: rely on prompt-only caution.
- Why not: soft guidance is insufficient for deterministic automation.

### 5) Return structured result payloads for orchestration
- Decision: require status + counts + changed/skipped/manual-followup arrays + idempotency indicator.
- Rationale: parent agent can make deterministic next-step decisions without parsing prose.
- Alternative considered: narrative-only output.
- Why not: brittle integration and harder tooling automation.

## Risks / Trade-offs

- [Risk] False-positive matches in broad text replacements -> Mitigation: prefer AST operations, require `plan` preview for large scopes, enforce strict include/exclude filters.
- [Risk] Overly strict guardrails block legitimate large migrations -> Mitigation: allow explicit limit tuning per request and return actionable blocked diagnostics.
- [Risk] Contract complexity slows adoption -> Mitigation: provide minimal required fields and sensible defaults in agent instructions.
- [Risk] Boundary overlap with `scout` and `runner` -> Mitigation: document delegation matrix in `_AGENTS.md` and keep codemodder non-executive for tests/builds.

## Migration Plan

1. Add `codemodder.md` under `agents/opencode/agents/` with input/output contracts and guardrails.
2. Register `codemodder` in `agents/opencode.nix` so it is installed to `~/.config/opencode/agents`.
3. Update `agents/opencode/_AGENTS.md` role list and delegation defaults.
4. Validate by issuing one `plan` request and one `apply` request on a safe mechanical change.
5. Rollback strategy: remove codemodder from `opencodeAgents`, delete agent file, and revert delegation docs.

## Open Questions

- Should `apply` be allowed when `idempotency_remaining_matches > 0` after first pass, or should that require explicit re-invocation?
- Should regex replacements be opt-in only (default disabled) to push users toward AST-first edits?
