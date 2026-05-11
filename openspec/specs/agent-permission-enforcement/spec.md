## Purpose

Define the expected permission policy, enforcement, approval, and audit behavior for the Pi agent permission framework.

## Requirements

### Requirement: Permission policies are normalized from agent and framework configuration
The framework MUST parse permission policies from agent definitions and framework-level defaults into a single normalized policy model. The normalized model SHALL support `allow`, `ask`, and `deny` decisions for tool calls, bash commands, file operations, subagent delegation, and skill usage. MCP access and Pi-specific special operations are deferred to a future change.

#### Scenario: Agent-local permission frontmatter is parsed
- **WHEN** an agent definition contains a `permission:` frontmatter block
- **THEN** the framework SHALL parse that block into the normalized policy model for that agent identity

#### Scenario: Framework defaults apply when agent policy is incomplete
- **WHEN** an agent policy omits a permission category or action
- **THEN** the framework SHALL apply the configured framework default for that category or action

#### Scenario: Unsupported action category fails closed
- **WHEN** an action category cannot be enforced by the currently available Pi extension hooks
- **THEN** the framework SHALL deny high-risk actions in that category unless an explicit safe fallback rule exists

### Requirement: Policy decisions use deterministic precedence
The framework MUST evaluate policy rules deterministically. A matching `deny` rule SHALL override matching `ask` and `allow` rules. A matching `ask` rule SHALL override matching `allow` rules. Unknown actions SHALL resolve to the configured default decision, and absent defaults SHALL resolve to `ask` in interactive mode and `deny` in non-interactive mode.

#### Scenario: Deny overrides allow
- **WHEN** an action matches both an allow rule and a deny rule
- **THEN** the framework SHALL deny the action
- **AND** the denial reason SHALL identify the matched deny rule when available

#### Scenario: Ask overrides allow
- **WHEN** an action matches both an allow rule and an ask rule but no deny rule
- **THEN** the framework SHALL request approval before allowing the action

#### Scenario: Non-interactive unknown action is denied
- **WHEN** an action has no matching rule and no configured default
- **AND** the session has no interactive UI
- **THEN** the framework SHALL deny the action

### Requirement: Tool calls are enforced against the active agent identity
The framework MUST evaluate every model-requested tool call against the active runtime identity before execution. Denied tool calls SHALL be blocked. Approval-required tool calls SHALL execute only after an approval is granted for the active identity and action fingerprint. Interactive approval prompts SHALL present shared permission details as request-level prompt content and SHALL keep response choices as concise decision labels.

#### Scenario: Allowed tool call executes
- **WHEN** the active agent requests a tool call that its effective policy allows
- **THEN** the framework SHALL allow the tool call to execute

#### Scenario: Denied tool call is blocked
- **WHEN** the active agent requests a tool call that its effective policy denies
- **THEN** the framework SHALL block the tool call before execution
- **AND** the tool result SHALL communicate that the action was denied by policy

#### Scenario: Approval-required tool call prompts user
- **WHEN** the active agent requests a tool call that resolves to `ask`
- **AND** an interactive UI is available
- **THEN** the framework SHALL prompt the user with the agent identity, action summary, matched rule, and approval scope as request-level permission details
- **AND** each response choice SHALL contain only the decision label for that choice
- **AND** the tool call SHALL execute only if the user approves it

#### Scenario: Approval-required tool call fails closed without UI
- **WHEN** the active agent requests a tool call that resolves to `ask`
- **AND** no interactive UI is available
- **THEN** the framework SHALL deny the tool call before execution

### Requirement: Bash commands are classified and permissioned separately from the bash tool name
The framework MUST evaluate bash command content, working directory, and relevant execution metadata in addition to the generic `bash` tool permission. Bash policies SHALL support allow and deny patterns, restrictive read-only command profiles, and a default decision for commands that do not match explicit patterns.

#### Scenario: Read-only main agent allows safe inspection command
- **WHEN** a read-only main agent requests a bash command that matches its safe inspection allowlist
- **THEN** the framework SHALL allow that command to execute

#### Scenario: Dangerous command is denied despite generic bash access
- **WHEN** an agent has generic access to the bash tool
- **AND** the requested command matches a configured bash deny pattern
- **THEN** the framework SHALL deny the command before execution

#### Scenario: Unknown bash command uses default bash decision
- **WHEN** a requested bash command matches no allow or deny pattern
- **THEN** the framework SHALL resolve the command using the effective bash default decision for the active identity

### Requirement: File operations are permissioned by operation and path
The framework MUST evaluate file-related tool calls using the requested operation and normalized path. File policy SHALL distinguish read, write, edit, and external-directory access when the tool input exposes that information.

#### Scenario: Protected path write is denied
- **WHEN** an agent requests a write or edit operation on a path denied by its effective file policy
- **THEN** the framework SHALL block the operation before the file is modified

#### Scenario: Allowed read proceeds for permitted path
- **WHEN** an agent requests a read operation on a path allowed by its effective file policy
- **THEN** the framework SHALL allow the read operation to execute

#### Scenario: External directory access requires explicit permission
- **WHEN** an agent requests file access outside the current project boundary
- **THEN** the framework SHALL resolve the request against the effective external-directory policy before execution

### Requirement: Subagent delegation is permissioned before launch
The framework MUST evaluate subagent delegation requests before creating any child session or background run. Delegation policy SHALL consider the requested subagent name, source scope, run mode, model override, tool override, context inheritance, extension/skill inheritance, and working directory when those values are present.

#### Scenario: Allowed delegation launches subagent
- **WHEN** the active parent agent requests a subagent delegation that its effective policy allows
- **THEN** the framework SHALL launch the requested subagent with the approved runtime options

#### Scenario: Denied delegation does not launch subagent
- **WHEN** the active parent agent requests a subagent delegation that its effective policy denies
- **THEN** the framework SHALL block the delegation before any child session is created

#### Scenario: Project-local subagent requires trust approval
- **WHEN** a delegation request targets a project-local subagent definition
- **AND** project-local agents have not been approved for the current session
- **THEN** the framework SHALL require explicit user approval before launching that subagent
- **AND** the framework SHALL deny the launch without UI unless policy explicitly allows trusted project agents

### Requirement: Subagent effective policy cannot exceed parent delegation grant
The framework MUST compose a subagent's effective policy from the parent delegation grant and the subagent's own policy. The composed policy SHALL allow the subagent to narrow permissions, but it SHALL NOT grant permissions broader than the parent identity was permitted to delegate unless an explicit escalation rule is approved by the user.

#### Scenario: Child policy is narrower than parent grant
- **WHEN** a parent delegates to a subagent whose own policy denies a tool that the parent grant allowed
- **THEN** the subagent effective policy SHALL deny that tool

#### Scenario: Child policy cannot broaden parent grant
- **WHEN** a parent delegates to a subagent whose own policy allows an action outside the parent delegation grant
- **THEN** the subagent effective policy SHALL deny or ask for escalation according to the parent policy

#### Scenario: Approved escalation is scoped
- **WHEN** the user approves an explicit subagent permission escalation
- **THEN** the approval SHALL apply only to the specified subagent identity, action fingerprint, and approval scope

### Requirement: Temporary approvals are scoped and persisted
The framework MUST scope temporary approvals to the active agent identity, action fingerprint, and selected approval scope. Persisted session approvals SHALL be reconstructable on session resume and SHALL NOT apply to unrelated agents or different action fingerprints.

#### Scenario: Approval is reused for matching action
- **WHEN** the user approves an action with a reusable scope
- **AND** the same agent identity requests the same action fingerprint within that scope
- **THEN** the framework SHALL allow the action without prompting again

#### Scenario: Approval does not cross identities
- **WHEN** one agent identity has an approval for an action fingerprint
- **AND** a different agent identity requests the same action fingerprint
- **THEN** the framework SHALL evaluate the request independently of the other identity's approval

#### Scenario: Session resume restores unexpired approvals
- **WHEN** a session is resumed with persisted unexpired approvals
- **THEN** the framework SHALL restore those approvals before evaluating new actions

### Requirement: Permission decisions are auditable
The framework MUST record permission decisions, denials, user approvals, subagent delegation checks, policy hashes, and active identity information in session-persistent audit data. Audit data SHALL be sufficient to explain why an action was allowed, denied, or prompted.

#### Scenario: Denied action records audit entry
- **WHEN** the framework denies an action
- **THEN** it SHALL record the agent identity, action summary, decision, and matched rule or default reason in audit data

#### Scenario: Approved action records approval scope
- **WHEN** the user approves an `ask` action
- **THEN** the framework SHALL record the approval scope and policy context used for that decision

#### Scenario: Explain command reports matched policy
- **WHEN** the user requests an explanation for a prior permission decision
- **THEN** the framework SHALL present the recorded identity, action fingerprint, decision, and matched rule or default reason

### Requirement: Prompt and active-tool shaping are advisory, not authoritative
The framework MUST use prompt injection and active-tool selection only as user-experience and model-guidance mechanisms. The pre-execution permission check SHALL remain the authoritative enforcement point for actions that reach tool execution.

#### Scenario: Inactive tool call is still checked if requested
- **WHEN** the model requests a tool call that was not included in the current active tool set
- **THEN** the framework SHALL still evaluate the call through the permission engine before any execution can occur

#### Scenario: Prompt instruction cannot bypass deny rule
- **WHEN** the prompt or conversation text instructs the agent to ignore permissions
- **AND** the requested action matches a deny rule
- **THEN** the framework SHALL deny the action

### Requirement: Subagent approval requests are parent-mediated
The framework MUST route approval-required tool calls from delegated subagents through a parent-visible permission approval bridge. The bridge SHALL request only the permission decision from the parent UI and SHALL NOT expose the full parent extension UI surface to the child session.

#### Scenario: Child ask prompts in parent-visible UI
- **WHEN** a running subagent requests a tool call that resolves to `ask` under its effective policy
- **AND** a parent-visible interactive UI is available
- **THEN** the framework SHALL present a permission prompt in the parent-visible UI before executing the tool call
- **AND** the prompt SHALL identify the subagent runtime identity, action fingerprint, action summary, matched rule when available, and approval scope choices
- **AND** the child tool call SHALL execute only if the user approves the request

#### Scenario: Child approval remains scoped to child identity
- **WHEN** the user approves a subagent permission request through the parent-visible bridge
- **THEN** the framework SHALL persist the approval against the subagent runtime identity and action fingerprint
- **AND** the approval SHALL NOT apply to the parent main agent, sibling subagents, or different action fingerprints

#### Scenario: Child ask denies without parent-visible approval path
- **WHEN** a running subagent requests a tool call that resolves to `ask`
- **AND** no parent-visible approval path is available
- **THEN** the framework SHALL deny the tool call before execution
- **AND** the denial reason SHALL state that interactive approval is unavailable for the subagent request

#### Scenario: Child ask denies on approval timeout or abort
- **WHEN** a running subagent permission request is waiting for user approval
- **AND** the approval timeout expires or the relevant abort signal is cancelled before the user approves
- **THEN** the framework SHALL deny the child tool call before execution
- **AND** the denial reason SHALL identify timeout or abort as the reason

### Requirement: Subagent permission waits are auditable
The framework MUST record subagent permission approval waits and their final outcomes in session-persistent audit data. Audit records SHALL be sufficient to distinguish an allowed, user-denied, timeout-denied, abort-denied, and UI-unavailable subagent request.

#### Scenario: Pending child approval records audit context
- **WHEN** a subagent tool call enters a pending approval wait
- **THEN** the framework SHALL record audit data containing the subagent identity, action fingerprint, action summary, matched rule when available, and pending approval state

#### Scenario: Resolved child approval records final outcome
- **WHEN** a pending subagent permission request resolves
- **THEN** the framework SHALL record whether the request was approved or denied
- **AND** the record SHALL include the approval scope or denial reason used for the decision
