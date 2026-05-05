## ADDED Requirements

### Requirement: Codemodder supports two-phase execution
The system MUST provide a codemod subagent that accepts mechanical edit requests with an explicit `mode` value of `plan` or `apply`.
In `plan` mode, the subagent SHALL analyze candidate matches and produce a preview report without modifying files.
In `apply` mode, the subagent SHALL execute only the declared edit rules and return a post-apply report.

#### Scenario: Plan mode preview is non-mutating
- **WHEN** the parent agent delegates a codemod request with `mode` set to `plan`
- **THEN** the subagent returns candidate/changed/skipped counts and does not modify any workspace file

#### Scenario: Apply mode executes declared rules
- **WHEN** the parent agent delegates a codemod request with `mode` set to `apply`
- **THEN** the subagent applies only edits specified in the request and reports changed files and applied edit counts

### Requirement: Codemodder enforces safety guardrails
The subagent MUST enforce guardrails from the request, including path scoping (`include`/`exclude`), file and edit limits, and ambiguity handling policy.
If guardrails are exceeded or an edit is ambiguous under strict mode, the subagent SHALL stop or skip according to policy and surface actionable reasons.

#### Scenario: Guardrail limit prevents runaway edits
- **WHEN** a codemod request would touch more files than `safety.max_files`
- **THEN** the subagent returns a blocked or partial result and includes the guardrail violation in the report

### Requirement: Codemodder returns structured machine-readable output
The subagent MUST return a structured result payload containing overall status, counts, changed paths, skipped items with reasons, and manual follow-ups.
The payload SHALL include an idempotency signal that indicates whether additional matches remain after the operation.

#### Scenario: Result payload enables parent orchestration
- **WHEN** a codemod request completes
- **THEN** the response includes `result`, aggregate counts, and per-path skip/follow-up details sufficient for parent-side routing and verification
