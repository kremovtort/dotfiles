## Context

`agent-permission-framework` currently defines a framework-specific permission model in TypeScript (`PermissionPolicy` with `tools`, `bash`, `files`, `agents`, and `skills`) and its built-in agents also carry explicit `tools` arrays that shape the active tool set. This diverges from OpenCode's `permission` config, where permissions are expressed as action strings or ordered pattern-rule objects, and where the legacy tool list is deprecated in favor of permission-derived behavior.

The new model should keep Pi's enforceable boundaries explicit while adopting OpenCode-style syntax and matching semantics. The supported permission keys for this change are `tools`, `bash`, `subagents`, and the top-level safety guard `external_directory`. MCP permissions remain out of scope until the framework has an enforceable MCP access path.

## Goals / Non-Goals

**Goals:**

- Accept an OpenCode-style `permission` value: either a single action string (`allow`, `ask`, `deny`) or an object containing permission entries.
- Replace the current category model with `tools`, `bash`, `subagents`, and top-level `external_directory`.
- Use OpenCode-style ordered wildcard rule objects where the last matching pattern wins.
- Preserve framework safety invariants: pre-execution enforcement remains authoritative, `ask` fails closed without UI or broker, and subagent policy layering follows OpenCode override semantics.
- Remove explicit built-in agent tool declarations; active tools should be derived from the available tool registry and the effective permission policy.
- Provide a clear migration path for existing built-in policies and existing custom agent frontmatter.

**Non-Goals:**

- Do not add an `mcp` permission category in this change.
- Do not implement OpenCode's full permission catalog as top-level keys such as `read`, `edit`, `grep`, or `task`; Pi-specific tool permissions are nested under `tools`.
- Do not change the parent-visible approval bridge or audit persistence model except where decision metadata must reflect the new policy shape.
- Do not change the requirement that subagent delegation is permissioned before launch; only the post-launch effective-policy merge semantics change.

## Decisions

### 1. Normalize to an OpenCode-style permission AST

Represent parsed permissions as a small AST instead of the current `PatternRuleSet` shape:

```ts
type PermissionAction = "allow" | "ask" | "deny";
type OrderedRuleObject = Array<{ pattern: string; decision: PermissionAction }>;

type PermissionRule =
  | { kind: "action"; decision: PermissionAction }
  | { kind: "rules"; rules: OrderedRuleObject };

interface NormalizedPermissionPolicy {
  default?: PermissionAction;
  tools?: ToolPermissionRules;
  bash?: PermissionRule;
  subagents?: PermissionRule;
  external_directory?: PermissionRule;
}
```

Rationale: OpenCode rule objects are order-sensitive (`last matching rule wins`), while the current model groups rules by decision and then applies deny/ask/allow precedence. Keeping ordered rules in the normalized form avoids losing semantic information from YAML/JSON frontmatter.

Alternative considered: translate OpenCode objects into the existing `allow`/`ask`/`deny` arrays. This was rejected because it cannot preserve last-match-wins behavior.

### 2. Use nested `tools` rules for Pi tool names and tool inputs

The top-level `permission` object accepts only these supported entries for this change:

```yaml
permission:
  "*": ask
  tools:
    "*": ask
    read:
      "*": allow
      "*.env": deny
      "*.env.example": allow
    edit: deny
    web_fetch: allow
  bash:
    "*": ask
    "git status*": allow
    "rm *": deny
  subagents:
    "*": ask
    scout: allow
    docs-digger: allow
  external_directory:
    "~/projects/personal/**": allow
```

`permission: allow` is equivalent to setting the default decision to `allow`. In object form, `permission["*"]` is the global default. Unsupported top-level categories, including `mcp`, should be rejected or reported as invalid configuration rather than silently treated as allow rules.

`tools` is a map over Pi tool names or tool-name wildcard patterns. Each matching tool entry may be a direct action or an ordered input-rule object. For input-rule objects, the evaluator matches against the tool's primary target:

- file path for file-oriented tools such as `read`, `write`, and `edit`;
- query/pattern for search-like tools such as `grep` and `find` when no more specific file target is available;
- URL/query for web tools;
- stable serialized input as a fallback for tools without a known target extractor.

Rationale: This keeps the user-facing categories to `tools`, `bash`, and `subagents`, while preserving path-sensitive file restrictions that were previously expressed through `files.read`, `files.write`, and `files.edit`.

Alternative considered: keep `files` as an internal or user-facing category. This was rejected because the requested model explicitly limits categories and moves external-directory handling to a top-level permission key.

### 3. Evaluate each tool call as a combination of guards

For every model-requested tool call, enforcement evaluates all applicable decisions and combines them with the framework's safety ordering (`deny` > `ask` > `allow`):

1. `tools` decision for the tool name and tool primary target.
2. `bash` decision when the tool call executes a shell command.
3. `subagents` decision when the tool call launches, resumes, waits for, or steers a subagent; target matching uses the subagent name/type when available and the run identifier for run-specific operations.
4. `external_directory` decision for each detected path outside the project boundary.

Within each individual rule object, OpenCode last-match-wins semantics apply. Across independent guards for one action, the strictest decision wins so that a path guard or subagent guard can still require approval or block an otherwise allowed tool.

Rationale: OpenCode rule syntax should control how a category resolves, but Pi still needs multiple enforceable guards per tool call. Combining resolved guards with the existing strictest-decision ordering preserves fail-closed behavior.

Alternative considered: let the last matching rule across all categories win. This was rejected because it would allow a broad `tools: allow` rule to bypass `external_directory: ask` or `subagents: deny`.

### 4. Use OpenCode override semantics for policy layering

Framework defaults, main-agent permissions, and subagent-local permissions should all layer in the same OpenCode-compatible way:

- Broader/default policy layers are applied first.
- More specific agent-local layers are applied later and take precedence.
- Ordered rule objects are appended in layer order and still resolve with last-match-wins semantics.
- A scalar action in a later layer replaces the earlier default for that permission scope.

Subagent delegation remains permissioned before launch through the parent's `subagents` policy. After a subagent is allowed to launch, its runtime permission policy is the parent/default policy plus the subagent-local policy using OpenCode override semantics; the subagent-local policy may narrow or broaden inherited defaults. If a parent agent must prevent a subagent from receiving a capability, it should deny or ask for that delegation in `subagents` or delegate to a different subagent profile rather than relying on hidden post-launch intersection.

Rationale: This matches OpenCode's agent permission model, where agent permissions are merged with global config and agent rules take precedence. It also makes subagent definitions behave as explicit runtime profiles instead of unexpectedly losing permissions because of a parent-side intersection.

Alternative considered: keep the current restrictive parent/child intersection where the child can narrow but never broaden the parent grant. This was rejected because it diverges from OpenCode override semantics and makes permission outcomes harder to predict from the selected agent's own `permission` block.

### 5. Derive active tools from permissions instead of agent `tools` arrays

Built-in agents should no longer declare explicit `tools` arrays. At activation time, the framework derives active tools from the set of tools registered in the current Pi session:

- include a tool by default when its effective `tools` permission is `allow` or `ask`;
- exclude a tool only when it is categorically resolved to `deny` for all inputs;
- keep input-sensitive tools active when any `ask` or `allow` pattern could apply, even if the catch-all input rule is `deny`;
- continue to rely on pre-execution enforcement as the authoritative check for all active tools.

Subagent child sessions should use the same derivation after the child session is created and its inherited/available tools are known. `disallowed_tools` and old explicit `tools` frontmatter may be supported as a temporary migration layer by converting them into `permission.tools` rules, but built-ins and new examples should use only `permission`.

Rationale: This removes the fragile need to update every agent's explicit tool list when tools are added, while still hiding tools that are impossible for the agent to use.

Alternative considered: register every tool unconditionally and rely only on pre-execution blocking. This was rejected because hiding categorically denied tools improves model guidance and UX without weakening enforcement.

### 6. Migrate built-in policies to the new categories

Built-in policies should be rewritten mechanically:

- `permission.default` becomes top-level `permission["*"]` or `permission: <action>` where appropriate.
- `tools` named decisions become entries under `permission.tools`.
- `files.read/write/edit` path rules become input rules for the corresponding file tools under `permission.tools`.
- `files.external_directory` becomes top-level `permission.external_directory`.
- `agents` becomes `subagents`, including rules for `scout`, `docs-digger`, `codemodder`, project-local subagents, the `override:model` marker for requested model overrides, and inheritance controls where those controls remain enforceable. Tool override markers are not supported.
- `bash.readOnly` is removed from the public model and represented by explicit `bash` allow/deny patterns in built-in policies.
- `skills` is removed from the permission schema for this change; any skill-related enforcement remains out of scope unless represented as an ordinary tool permission.

Rationale: The built-ins become examples of the new authoring model and stop depending on framework-only permission properties.

Alternative considered: keep legacy fields internally while accepting new frontmatter. This was rejected for the public normalized model because it would keep two semantics alive and make policy explanations harder to audit.

## Risks / Trade-offs

- **Risk: Last-match-wins changes behavior for existing policies that relied on deny precedence.** → Mitigation: mark the change as breaking, migrate built-ins explicitly, and add tests for order-sensitive rules.
- **Risk: Active tool derivation can hide a tool that has a specific allowed pattern behind a denied catch-all.** → Mitigation: only hide tools that are categorically denied with no possible `ask`/`allow` input rule.
- **Risk: Tool input target extraction may be incomplete for custom or future tools.** → Mitigation: fall back to stable serialized input and keep pre-execution enforcement authoritative; add target extractors incrementally for known tools.
- **Risk: Rejecting unsupported categories may break user configs sooner than expected.** → Mitigation: report clear parse errors that name the unsupported key and suggest the supported `tools`, `bash`, `subagents`, and `external_directory` locations.
- **Risk: Removing `bash.readOnly` requires maintaining explicit command patterns.** → Mitigation: keep the current safe read-only command regexes as implementation constants used to generate built-in `bash` rules, not as user-facing schema.

## Migration Plan

1. Add the new permission AST/types and parser for `permission: <action>` plus object form with `*`, `tools`, `bash`, `subagents`, and `external_directory`.
2. Replace the current `PatternRuleSet` evaluators with ordered-rule evaluation and last-match-wins matching.
3. Add tool target extraction helpers for existing built-in tools and reuse path normalization for external-directory checks.
4. Rewrite built-in `plan`, `build`, and `ask` policies to the new shape and remove their explicit `tools` arrays.
5. Update main-agent activation and subagent child-session setup to derive active tools from effective permissions.
6. Update policy composition, approval prompt details, and audit matched-rule metadata to report the new rule paths.
7. Add migration tests for legacy built-in behavior, order-sensitive rules, external-directory checks, and derived active tool filtering.

Rollback is a code revert of the package changes plus restoring the old built-in policy declarations. Because this is a local framework package with no new persistence format besides policy/audit metadata, rollback does not require data migration.

## Open Questions

None. The category set for this change is fixed as `tools`, `bash`, `subagents`, and top-level `external_directory`; MCP remains deferred.
