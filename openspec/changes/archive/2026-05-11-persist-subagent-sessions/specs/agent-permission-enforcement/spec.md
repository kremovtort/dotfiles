## ADDED Requirements

### Requirement: Permission approval queues are scoped to parent-visible approval contexts
The framework MUST serialize interactive permission approval prompts per parent-visible approval context rather than through a single process-global queue. Approval requests that share the same parent UI context SHALL remain ordered to avoid overlapping prompts, while independent approval contexts SHALL NOT block each other through module-global state.

#### Scenario: Same parent context serializes main and child approvals
- **WHEN** a main agent permission request and a delegated subagent permission request both require interactive approval through the same parent-visible UI context
- **THEN** the framework SHALL present those approval prompts one at a time in deterministic request order
- **AND** the child request SHALL continue to use the narrow parent-visible approval broker rather than direct child UI access

#### Scenario: Independent approval contexts do not share a global queue
- **WHEN** two independent parent sessions or approval brokers each have a permission request pending
- **THEN** the framework SHALL NOT force one request to wait solely because another request is pending in a different approval context
- **AND** approval serialization SHALL NOT depend on a module-level singleton queue

#### Scenario: Missing approval context still fails closed
- **WHEN** a subagent tool call resolves to `ask`
- **AND** no parent-visible approval broker is available for that child session
- **THEN** the framework SHALL deny the tool call before execution
- **AND** it SHALL NOT enqueue the request on an unrelated approval context

#### Scenario: Interrupted pending approval is not restored as pending
- **WHEN** a subagent run is restored as interrupted and resumable after previously waiting for permission approval
- **THEN** the framework SHALL clear the pending permission metadata for that restored run
- **AND** an explicit resume SHALL use a fresh parent-visible approval context for any new permission requests
