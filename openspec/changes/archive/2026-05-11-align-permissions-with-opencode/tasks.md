## 1. Permission Model and Parsing

- [x] 1.1 Replace the current `PermissionPolicy`/`PatternRuleSet` public model with OpenCode-style action and ordered rule-object types for `tools`, `bash`, `subagents`, and top-level `external_directory`.
- [x] 1.2 Update agent frontmatter parsing to accept `permission: allow|ask|deny` and object-form `permission` with `*`, `tools`, `bash`, `subagents`, and `external_directory`.
- [x] 1.3 Reject unsupported top-level permission categories, including `mcp`, `files`, `agents`, and `skills`, with clear invalid-configuration diagnostics.
- [x] 1.4 Add a temporary migration path that converts legacy explicit tool declarations or `disallowed_tools` into equivalent `permission.tools` rules when encountered.

## 2. Policy Evaluation and Enforcement

- [x] 2.1 Implement ordered wildcard matching with OpenCode last-match-wins semantics for rule objects.
- [x] 2.2 Update `evaluateToolPermission`, `evaluateBashPermission`, external-directory checks, and delegation checks to use the new normalized policy model.
- [x] 2.3 Replace `files` policy enforcement with path-sensitive `permission.tools` rules plus the top-level `permission.external_directory` guard.
- [x] 2.4 Replace `agents` delegation enforcement with `permission.subagents` rules while preserving pre-launch delegation checks.
- [x] 2.5 Change policy layering/composition so framework defaults, parent defaults, and agent-local policies use OpenCode override semantics instead of restrictive parent/child intersection.
- [x] 2.6 Keep per-action guard combination fail-safe by applying `deny > ask > allow` across independently resolved guards for the same tool call.

## 3. Runtime Tool Registration and Built-ins

- [x] 3.1 Remove explicit `tools` arrays from built-in `plan`, `build`, and `ask` agent definitions.
- [x] 3.2 Rewrite built-in agent permissions to the new `tools`, `bash`, `subagents`, and `external_directory` shape.
- [x] 3.3 Add active-tool derivation for main-agent activation from the current Pi tool registry and the active identity's effective permissions.
- [x] 3.4 Add equivalent permission-derived active-tool derivation for subagent child sessions after child tools are known.
- [x] 3.5 Ensure categorically denied tools are hidden, while `ask` tools and input-sensitive tools with possible `allow`/`ask` rules remain registered.

## 4. Tests, Documentation, and Validation

- [x] 4.1 Update policy tests for scalar permissions, supported/unsupported categories, ordered last-match-wins rules, and OpenCode override layering.
- [x] 4.2 Update enforcement tests for bash command rules, file tool input rules, top-level `external_directory`, and `subagents` delegation rules.
- [x] 4.3 Update discovery/runtime/subagent tests for legacy migration, built-in agents without tool lists, and permission-derived active tool sets.
- [x] 4.4 Update package README/docs/examples to show the new permission syntax and note that `mcp` is not supported yet.
- [x] 4.5 Run `npm test` in `agents/pi/packages/agent-permission-framework` and fix any regressions.
- [x] 4.6 Run OpenSpec validation for `align-permissions-with-opencode` and fix any artifact issues.
