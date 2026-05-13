## MODIFIED Requirements

### Requirement: File operations are permissioned by operation and path
The framework MUST evaluate file-related tool calls using the requested tool, operation, normalized path, and top-level `external_directory` guard when the tool input exposes that information. Path-sensitive read, write, and edit restrictions SHALL be expressed as input rules under `permission.tools` for the corresponding Pi tool names. External-directory access SHALL be expressed by the top-level `permission.external_directory` entry rather than by a nested file policy category. External-directory policy matching SHALL remain based on the normalized external path, while the approval action fingerprint, approval reuse, audit summary, and user-facing approval prompt SHALL identify the concrete file tool/operation and normalized external path.

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
- **AND** `permission.external_directory` rules SHALL match the normalized external path without requiring a tool-name prefix

#### Scenario: External directory prompt identifies concrete file action
- **WHEN** an agent requests a file-related tool call that touches an external path and resolves to `ask`
- **THEN** the approval prompt SHALL display the concrete requested file tool or operation
- **AND** the approval prompt SHALL display the normalized external path or primary path argument for that tool call
- **AND** the prompt SHALL NOT describe the request only as a generic `file external_directory` action

#### Scenario: External directory approvals are scoped by file operation and path
- **WHEN** the user approves external access for a file-related tool call with reusable scope
- **THEN** the stored approval fingerprint SHALL include both the concrete file tool or operation and the normalized external path
- **AND** a later request by the same agent identity for the same operation and path SHALL reuse that approval within its scope
- **AND** a later request by the same agent identity for a different file operation on the same path SHALL require independent policy evaluation and approval
