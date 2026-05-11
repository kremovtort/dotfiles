## Purpose

Define the expected permission policy, enforcement, approval, and audit behavior for the Pi agent permission framework.

## Requirements

### Requirement: Permission policies are normalized from agent and framework configuration
The framework MUST parse OpenCode-compatible permission policies from agent definitions and framework-level defaults into a single normalized policy model. The normalized model SHALL support `allow`, `ask`, and `deny` decisions for the `tools`, `bash`, `subagents`, and top-level `external_directory` permission entries. A `permission` value MAY be a single decision string that applies as the default for the policy, or an object containing supported permission entries and a `*` default rule. MCP access, skill-specific permissions, and Pi-specific special operations are deferred to future changes unless they are represented as ordinary tool permissions under `tools`.

#### Scenario: Agent-local permission frontmatter is parsed
- **WHEN** an agent definition contains an OpenCode-style `permission:` frontmatter block
- **THEN** the framework SHALL parse that block into the normalized policy model for that agent identity
- **AND** the parsed policy SHALL preserve object rule declaration order for later evaluation

#### Scenario: Scalar permission frontmatter becomes default policy
- **WHEN** an agent definition contains `permission: allow`, `permission: ask`, or `permission: deny`
- **THEN** the framework SHALL treat that value as the default permission decision for that agent identity

#### Scenario: Supported permission categories are parsed
- **WHEN** a permission object contains `tools`, `bash`, `subagents`, or `external_directory`
- **THEN** the framework SHALL parse those entries into the normalized policy model
- **AND** it SHALL NOT require or accept the previous `files`, `agents`, or `skills` categories as first-class permission categories

#### Scenario: Framework defaults apply when agent policy is incomplete
- **WHEN** an agent policy omits a permission entry or a matching rule
- **THEN** the framework SHALL apply the configured framework default for that entry or rule scope before falling back to the interactive/non-interactive default decision

#### Scenario: Unsupported permission category is rejected
- **WHEN** a permission object contains an unsupported top-level category such as `mcp`
- **THEN** the framework SHALL report the unsupported category as invalid configuration
- **AND** it SHALL NOT silently treat that category as an allowed permission rule

### Requirement: Policy decisions use deterministic precedence
The framework MUST evaluate policy rules deterministically. Within a single OpenCode-style rule object, matching SHALL use simple wildcard patterns and the last matching rule SHALL determine that object's decision. Across independent guards that apply to the same requested action, the framework SHALL combine resolved guard decisions with safety precedence: `deny` overrides `ask` and `allow`, and `ask` overrides `allow`. Unknown actions SHALL resolve to the configured default decision, and absent defaults SHALL resolve to `ask` in interactive mode and `deny` in non-interactive mode.

#### Scenario: Last matching rule wins within a rule object
- **WHEN** a rule object contains multiple patterns that match the same target
- **THEN** the framework SHALL use the decision from the matching pattern that appears last in declaration order
- **AND** the denial or approval reason SHALL identify that matched rule when available

#### Scenario: Specific later rule overrides catch-all
- **WHEN** a rule object contains `"*": "ask"` followed by `"git status*": "allow"`
- **AND** the requested target is `git status --short`
- **THEN** the framework SHALL resolve that rule object to `allow`

#### Scenario: Independent guard deny overrides tool allow
- **WHEN** a tool call matches a `tools` rule that resolves to `allow`
- **AND** the same tool call touches an external path whose `external_directory` rule resolves to `deny`
- **THEN** the framework SHALL deny the tool call before execution

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
The framework MUST evaluate bash command content, working directory, and relevant execution metadata in addition to the generic `bash` tool permission. Bash policies SHALL use the OpenCode-style `bash` entry, where the entry is either a direct permission action or an ordered object of command-pattern rules. Commands that do not match explicit bash rules SHALL resolve using the effective bash default decision.

#### Scenario: Safe inspection command matches allow rule
- **WHEN** a main agent requests a bash command that matches an effective `bash` allow pattern such as `git status*`
- **THEN** the framework SHALL allow that command to execute

#### Scenario: Dangerous command is denied despite generic bash tool access
- **WHEN** an agent has access to the `bash` tool through `permission.tools`
- **AND** the requested command matches an effective `bash` deny pattern such as `rm *`
- **THEN** the framework SHALL deny the command before execution

#### Scenario: Later bash rule overrides earlier bash rule
- **WHEN** the effective `bash` rule object contains an earlier matching rule and a later matching rule for the requested command
- **THEN** the framework SHALL use the later matching rule's decision for the bash guard

#### Scenario: Unknown bash command uses default bash decision
- **WHEN** a requested bash command matches no explicit bash pattern
- **THEN** the framework SHALL resolve the command using the effective bash default decision for the active identity

### Requirement: File operations are permissioned by operation and path
The framework MUST evaluate file-related tool calls using the requested tool, operation, normalized path, and top-level `external_directory` guard when the tool input exposes that information. Path-sensitive read, write, and edit restrictions SHALL be expressed as input rules under `permission.tools` for the corresponding Pi tool names. External-directory access SHALL be expressed by the top-level `permission.external_directory` entry rather than by a nested file policy category.

#### Scenario: Protected path write is denied by tool input rule
- **WHEN** an agent requests a `write` or `edit` tool call on a path denied by the matching `permission.tools` rule
- **THEN** the framework SHALL block the operation before the file is modified

#### Scenario: Allowed read proceeds for permitted path
- **WHEN** an agent requests a `read` tool call on a path allowed by the matching `permission.tools` rule
- **THEN** the framework SHALL allow the read operation to execute

#### Scenario: External directory access uses top-level permission
- **WHEN** an agent requests file access outside the current project boundary
- **THEN** the framework SHALL resolve that path against the effective top-level `permission.external_directory` policy before execution
- **AND** the resulting external-directory guard decision SHALL be combined with the tool-specific decision for the same call

### Requirement: Subagent delegation is permissioned before launch
The framework MUST evaluate subagent delegation requests before creating any child session or background run. Delegation policy SHALL be expressed through the OpenCode-style `subagents` permission entry and SHALL consider the requested subagent name, source scope, run mode, the `override:model` marker for requested model overrides, context inheritance, extension/skill inheritance, and working directory when those values are present. Tool override markers SHALL NOT be part of the supported `subagents` matching targets.

#### Scenario: Allowed delegation launches subagent
- **WHEN** the active parent agent requests a subagent delegation that its effective `subagents` policy allows
- **THEN** the framework SHALL launch the requested subagent with the approved runtime options

#### Scenario: Denied delegation does not launch subagent
- **WHEN** the active parent agent requests a subagent delegation that its effective `subagents` policy denies
- **THEN** the framework SHALL block the delegation before any child session is created

#### Scenario: Project-local subagent requires trust approval
- **WHEN** a delegation request targets a project-local subagent definition
- **AND** project-local agents have not been approved for the current session
- **THEN** the framework SHALL require explicit user approval before launching that subagent
- **AND** the framework SHALL deny the launch without UI unless policy explicitly allows trusted project agents

### Requirement: Subagent effective policy uses OpenCode override layering
The framework MUST compose framework defaults, parent runtime defaults, and subagent-local permission policies using OpenCode override semantics. Broader policy layers SHALL be applied first, more specific agent-local layers SHALL be applied later, ordered rule objects SHALL be appended in layer order, and later matching rules SHALL take precedence within each permission entry. A subagent-local permission policy SHALL be able to narrow or broaden inherited defaults after the parent has allowed the delegation through the `subagents` permission entry.

#### Scenario: Child policy narrows inherited default
- **WHEN** a parent delegates to a subagent whose inherited policy would allow a tool
- **AND** the subagent-local `permission.tools` rule denies that tool
- **THEN** the subagent effective policy SHALL deny that tool

#### Scenario: Child policy broadens inherited default
- **WHEN** a parent delegates to a subagent whose inherited policy would ask for a tool
- **AND** the subagent-local `permission.tools` rule allows that tool
- **THEN** the subagent effective policy SHALL allow that tool after delegation has been approved

#### Scenario: Parent subagent policy still gates launch
- **WHEN** a parent policy denies delegation to a requested subagent through `permission.subagents`
- **THEN** the framework SHALL block the subagent launch before applying the child runtime policy

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

