## ADDED Requirements

### Requirement: Child extension inheritance avoids recursive framework enforcement
When a delegated subagent inherits extensions, the framework MUST NOT install a second independent agent-permission-framework runtime in the child session without the delegated child identity and effective policy. The child session SHALL enforce permissions through the child runtime state assigned by the parent delegation.

#### Scenario: Read-only subagent with inherited extensions can inspect repository
- **WHEN** an active `build` main agent delegates to a read-only subagent whose definition enables extension inheritance
- **AND** the parent policy allows that delegation and read-only tools
- **THEN** the subagent SHALL be able to use allowed read-only repository tools such as `read`, `grep`, `find`, and `ls`
- **AND** those tools SHALL NOT be denied by a recursively loaded framework instance with missing child policy state

#### Scenario: Other inherited extensions remain available
- **WHEN** a subagent definition enables extension inheritance
- **THEN** the child session SHALL preserve non-framework inherited extensions according to the configured runtime options
- **AND** the framework SHALL still use the delegated child identity and effective policy for permission checks
