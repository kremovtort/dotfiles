## 1. Package and Source Setup

- [x] 1.1 Choose the package name and repository/package location for the combined Pi agent-permission framework.
- [x] 1.2 Create the Pi package skeleton with `package.json`, extension entry point, source directory, and package manifest resource declarations.
- [x] 1.3 Verify licenses for `tintinweb/pi-subagents` and `MasuRii/pi-permission-system` and record required attribution in package metadata or source headers.
- [x] 1.4 Vendor/adapt the reusable source modules needed from `pi-subagents` and `pi-permission-system` into isolated internal modules.

## 2. Agent Definition and Discovery

- [x] 2.1 Implement agent definition parsing for markdown frontmatter and prompt body, including `name`, `kind`, `description`, model/thinking/tool settings, runtime settings, and `permission:` blocks.
- [x] 2.2 Implement user-level and project-level agent discovery with project definitions overriding user definitions only after project-agent trust is enabled.
- [x] 2.3 Add validation for disabled, malformed, or incomplete agent definitions so invalid agents are excluded from selection and delegation.
- [x] 2.4 Add built-in `plan`, `build`, and `ask` main-agent definitions with default prompts, tools, and permissions.

## 3. Main-Agent Runtime

- [x] 3.1 Implement root `AgentIdentity` state for the active main agent, including agent name, kind, source scope, run/session identifier, and effective-policy reference.
- [x] 3.2 Add `--agent` flag and `/agent` command for selecting and switching main agents.
- [x] 3.3 Apply selected main-agent model, thinking level, active tools, prompt behavior, and runtime settings as one profile.
- [x] 3.4 Persist main-agent activation events and restore active identity state on session resume or fork.
- [x] 3.5 Add status/UI feedback showing the currently active main agent.

## 4. Subagent Runtime

- [x] 4.1 Implement or adapt the `subagent` tool interface for foreground and background subagent execution.
- [x] 4.2 Implement or adapt `get_subagent_result` for retrieving queued, running, completed, failed, and aborted subagent runs.
- [x] 4.3 Implement or adapt `steer_subagent` for delivering steering messages to active background subagent runs.
- [x] 4.4 Implement subagent scheduling with configurable background concurrency and queued-run promotion.
- [x] 4.5 Pass explicit child identity and effective runtime configuration to subagent child sessions before their first model turn.
- [x] 4.6 Support configured runtime options for max turns, context inheritance, and extension/skill inheritance.
- [x] 4.7 Persist subagent lifecycle events and restore known subagent run state on session resume.

## 5. Permission Policy Engine

- [x] 5.1 Implement normalized policy types for `allow`, `ask`, and `deny` decisions across tools, bash, files, agents, and skills. Defer MCP and special-operation categories to a future change.
- [x] 5.2 Implement parsing of agent-local `permission:` frontmatter and framework-level default policies into the normalized model.
- [x] 5.3 Implement deterministic decision precedence where deny overrides ask, ask overrides allow, and unknown actions use configured defaults or fail closed.
- [x] 5.4 Implement action fingerprinting for tool calls, bash commands, file operations, delegation requests, and approval scopes.
- [x] 5.5 Implement policy explanation data that identifies matched rules or default reasons for each decision.

## 6. Permission Enforcement Hooks

- [x] 6.1 Wire `before_agent_start` to shape active tools and inject agent-specific runtime instructions without treating prompt shaping as authoritative security.
- [x] 6.2 Wire `tool_call` enforcement as the authoritative pre-execution gate for all model-requested tools.
- [x] 6.3 Implement bash command classification using command content, cwd, allow/deny patterns, read-only profiles, and bash defaults.
- [x] 6.4 Implement file operation enforcement by operation type and normalized path, including external-directory checks where inputs expose paths.
- [x] 6.5 Implement delegation enforcement before subagent launch, including requested agent name, source scope, run mode, model/tool overrides, inheritance, and cwd.
- [x] 6.6 Ensure `ask` decisions prompt in interactive mode and deny by default without UI unless an explicit safe non-interactive fallback exists.

## 7. Parent/Child Policy Composition and Approvals

- [x] 7.1 Implement effective subagent policy composition as an intersection of the parent delegation grant and the subagent's own policy.
- [x] 7.2 Prevent child policies from broadening parent-granted permissions unless an explicit escalation rule is approved by the user.
- [x] 7.3 Implement temporary approvals scoped to agent identity, action fingerprint, and approval scope.
- [x] 7.4 Persist unexpired approvals and restore them on session resume without applying them to unrelated identities or actions.

## 8. Audit and Debugging

- [x] 8.1 Persist audit entries for allowed, denied, prompted, and user-approved actions with active identity and policy context.
- [x] 8.2 Persist policy hashes for main-agent activations and subagent launches.
- [x] 8.3 Add an explain/debug command that reports why a prior permission decision was allowed, denied, or prompted.
- [x] 8.4 Add optional development logging that does not replace session-persistent audit state.

## 9. Tests and Validation

- [x] 9.1 Add fixtures for user-level agents, project-level agents, invalid agents, and project-overrides-user discovery.
- [x] 9.2 Add policy-engine tests for allow/ask/deny precedence, unknown-action defaults, and non-interactive fail-closed behavior.
- [x] 9.3 Add permission enforcement tests for tool calls, bash command rules, file path rules, and subagent delegation checks.
- [x] 9.4 Add parent/child composition tests proving subagents cannot exceed delegated parent permissions.
- [x] 9.5 Add runtime tests or scripted manual checks for foreground subagents, background subagents, result retrieval, steering, and queued execution.
- [x] 9.6 Run package typecheck/lint/test commands and fix failures.
- [x] 9.7 Run `openspec validate add-agent-permission-framework --type change --strict` after task updates.

## 10. Documentation and Dotfiles Integration

- [x] 10.1 Document agent markdown format, `kind: main|subagent`, permission frontmatter, and source discovery precedence.
- [x] 10.2 Document main-agent usage through `--agent` and `/agent` and provide examples for `plan`, `build`, and `ask`.
- [x] 10.3 Document subagent delegation tools and permission behavior for `subagent`, `get_subagent_result`, and `steer_subagent`.
- [x] 10.4 Document non-interactive fail-closed behavior, project-local agent trust prompts, and audit/explain workflows.
- [x] 10.5 Optionally wire the validated package into this dotfiles repository's Pi configuration while keeping existing plugins removable for rollback.
