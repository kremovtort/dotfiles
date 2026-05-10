## MODIFIED Requirements

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
