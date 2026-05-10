## Context

Pi can implement this as an extension package rather than a core fork: extensions can register tools and commands, change the active tool set, inject system prompt/context, prompt the user, persist session state, and block tool calls through `tool_call` hooks. Pi packages can distribute extensions and companion resources through npm/git/local package sources.

The two source plugins already cover important halves of the problem. `tintinweb/pi-subagents` provides Claude Code-style `Agent`, `get_subagent_result`, and `steer_subagent` tools, isolated child Pi sessions, background execution, and `.pi/agents/*.md` / `~/.pi/agent/agents/*.md` agent discovery. `MasuRii/pi-permission-system` provides deterministic permission gates for tools, bash, skills, MCP, and special operations, including agent-local `permission:` frontmatter. This change should reuse/adapt both concepts and code while replacing the split model with a single agent identity + permission framework.

Current permission systems are incomplete when agent identity is inferred indirectly from prompts or when subagent launches bypass the parent policy. The new framework treats the active main agent and every delegated subagent as explicit runtime identities whose policies are composed before any action executes.

## Goals / Non-Goals

**Goals:**
- Provide one Pi package/extension that owns agent declaration, agent selection/delegation, and permission enforcement.
- Support first-class main agents such as `plan`, `build`, and `ask`, each with its own prompt, model/thinking defaults, tool set, and permissions.
- Support subagents with isolated contexts and Claude Code-style tool names/calling conventions compatible with existing `pi-subagents` workflows.
- Evaluate tool calls, bash commands, file operations, skill actions, and subagent delegation against the active agent identity.
- Compose policies across global defaults, project/user agent definitions, main agents, delegated subagents, and temporary user approvals.
- Fail closed for non-interactive or ambiguous permission decisions.
- Keep project-local agent execution explicit and trust-aware.

**Non-Goals:**
- Replacing OS-level sandboxing; this framework controls Pi actions, not arbitrary external process behavior after approval.
- Requiring upstream Pi core changes for the first implementation unless an extension API gap blocks enforcement.
- Guaranteeing exact compatibility with every Claude Code or OpenCode permission syntax on day one.
- Automatically wiring the new package into this dotfiles repository before the plugin is implemented and validated.

## Decisions

### 1) Ship as a single Pi extension package

- Decision: create one package that registers the agent runtime tools/commands and the permission hooks from one extension entry point.
- Rationale: Pi extension hooks already cover the required runtime surfaces (`before_agent_start`, `tool_call`, tool registration, commands, UI prompts, session state), and a package keeps installation/removal reversible.
- Alternative considered: fork Pi or maintain two cooperating extensions.
- Why not: a fork increases maintenance cost; two independent extensions leave ordering, identity propagation, and policy composition ambiguous.

### 2) Use agent markdown as the primary declaration format

- Decision: keep the existing `~/.pi/agent/agents/*.md` and `.pi/agents/*.md` discovery model, but extend frontmatter with `kind: main|subagent` and `permission:` fields. Project agents override user agents by name only after project-agent trust checks pass.
- Rationale: this reuses the strongest user-facing convention from `pi-subagents` and the agent-local permission placement from `pi-permission-system`.
- Alternative considered: a separate JSON-only configuration file.
- Why not: it separates prompts from the permissions that govern them and makes review harder.

Example shape:

```yaml
---
name: build
kind: main
description: Implementation agent
model: anthropic/claude-sonnet-4-5
thinking: high
tools: read,bash,edit,write,subagent,get_subagent_result,steer_subagent
permission:
  tools:
    read: allow
    grep: allow
    find: allow
    edit: ask
    write: ask
  bash:
    default: ask
    allow:
      - "^just (test|build|switch)( .*)?$"
    deny:
      - "\\brm\\s+-rf\\b"
      - "\\bsudo\\b"
  files:
    deny:
      - "secrets/**"
      - ".git/**"
  agents:
    scout: allow
    docs-digger: allow
    codemodder: ask
---
System prompt for the build agent.
```

### 3) Represent active execution as an explicit identity stack

- Decision: maintain an `AgentIdentity` stack in extension state and session entries. The root identity is the selected main agent; every subagent run records `parentId`, `source`, `agentName`, `kind`, `session/run id`, and effective policy.
- Rationale: permission decisions must not depend on brittle prompt-name inference. Explicit identity also enables auditing, subagent result routing, and parent/child policy composition.
- Alternative considered: infer the agent from system prompt text like existing permission experiments.
- Why not: prompt inference breaks when prompts are customized, appended, compacted, or translated.

Subagent SDK sessions receive identity through explicit in-memory runtime state plus a hidden system/context message. The framework constructs the child session with the assigned identity and precomputed effective policy before the first model turn.

### 4) Reuse `pi-subagents` execution semantics for delegation

- Decision: expose the public tools `subagent`, `get_subagent_result`, and `steer_subagent`, including foreground/background runs, configurable concurrency, resume/steer behavior, custom agent frontmatter, and isolated SDK sessions.
- Rationale: this preserves the already-familiar Claude Code-style UX and avoids redesigning scheduling/session plumbing.
- Alternative considered: expose only slash commands for delegation.
- Why not: delegation must be model-callable, composable in plans, and enforceable as a permissioned tool call.

The `subagent` tool itself is permissioned. Before creating a child SDK session, the framework checks whether the active parent identity may delegate to the requested agent, with the requested model/tools/background options included in the decision input.

### 5) Normalize permissions into a deterministic policy engine

- Decision: parse all policy sources into one internal model with `allow`, `ask`, and `deny` outcomes. Deny wins over ask, ask wins over allow, and unknown actions default to the configured default outcome or `ask`/`deny` depending on mode.
- Rationale: deterministic precedence is required for security review and predictable behavior across main agents and subagents.
- Alternative considered: rely on `pi.setActiveTools()` only.
- Why not: active tools improve the prompt and reduce available calls, but `tool_call` remains the enforcement boundary.

Policy categories:
- `tools`: built-in and extension tool names.
- `bash`: command regex/AST-ish classifiers, command cwd/env restrictions, and read-only allowlists for plan/ask agents.
- `files`: path and operation rules for reads, writes, edits, and external-directory access.
- `agents`: delegation targets plus constraints on background execution, inheritance, and model/tool overrides.
- `skills`: skill-command expansion and skill-specific use.

MCP proxy targets and Pi-specific special operations are deferred to a future change when the desired hook coverage is clearer.

### 6) Compose parent and child policy by restriction, not escalation

- Decision: effective subagent policy is the intersection of the parent delegation grant and the subagent's own policy. A subagent can narrow permissions freely, but cannot broaden permissions beyond what the parent identity was allowed to delegate unless an explicit parent policy rule permits escalation and the user approves it.
- Rationale: otherwise a permissive subagent definition could bypass a restrictive main agent.
- Alternative considered: child agent policy replaces parent policy.
- Why not: replacement is convenient but unsafe because delegation becomes a privilege escalation path.

Temporary approvals are scoped to `(agent identity, action fingerprint, approval scope)`. They are persisted with `pi.appendEntry()` so resumed sessions preserve intended approvals without granting unrelated future actions.

### 7) Enforce at multiple layers but treat `tool_call` as authoritative

- Decision: use `before_agent_start` to set the active tools and inject agent-specific instructions, then use `tool_call` to make the final allow/ask/deny decision immediately before execution.
- Rationale: prompt/tool shaping reduces invalid attempts, while pre-execution enforcement protects against prompt injection, stale context, or model mistakes.
- Alternative considered: only override built-in tools.
- Why not: Pi extensions and skill tools are dynamic; a central `tool_call` gate covers more surface and composes better with third-party tools.

For `ask` decisions, interactive sessions use `ctx.ui.confirm()`/`ctx.ui.select()` with a concise explanation of the agent, action, matched rule, and scope of approval. In print/JSON/no-UI modes, `ask` defaults to deny unless the policy explicitly marks a safe non-interactive fallback.

### 8) Add main-agent selection as presets with identity

- Decision: provide `/agent` and `--agent` to select main agents, plus optional shortcuts/status UI. Selecting a main agent applies model, thinking level, active tools, system prompt additions/replacements, and root permissions together.
- Rationale: Pi's existing preset/plan-mode examples prove the mechanics, but this framework needs identity and permission semantics in addition to model/tool presets.
- Alternative considered: keep main agents as aliases for prompt templates.
- Why not: aliases cannot reliably enforce permissions or track runtime identity.

Initial built-in main agents:
- `plan`: read-only exploration and planning; allows safe reads/search and read-only shell commands; denies edits/writes by default.
- `build`: implementation mode; allows reads/search, asks for writes/edits/bash unless narrowed by project policy.
- `ask`: conversational/research mode; minimal local tool access, no file mutation by default.

### 9) Persist audit and runtime state in session entries

- Decision: record agent activation, subagent run lifecycle, permission decisions, denials, user approvals, and effective-policy hashes as custom session entries and/or tool result details.
- Rationale: permissions should be reviewable after the fact and reconstructable on resume/fork.
- Alternative considered: log only to files.
- Why not: file logs do not naturally follow Pi session branching and are easier to lose during reviews.

A separate optional debug log can still be written for development, but session state is the source of truth for runtime reconstruction.

### 10) Treat reused source code as vendored/adapted modules with license review

- Decision: vendor or adapt code from `tintinweb/pi-subagents` and `MasuRii/pi-permission-system` where it directly matches the design, especially agent discovery, subagent scheduling/session plumbing, permission parsing, matching, prompts, and audit helpers.
- Rationale: the proposal explicitly targets concepts and code reuse, and reusing tested behavior lowers implementation risk.
- Alternative considered: rewrite from scratch.
- Why not: it would delay the change and increase compatibility drift from the tools the user already wants to combine.

Before implementation, license compatibility and attribution requirements must be verified and captured in package metadata or source headers.

## Risks / Trade-offs

- [Risk] Pi extension hooks may not expose every action category needed for complete enforcement. -> Mitigation: enforce all available surfaces first, fail closed for unsupported high-risk categories, and document or upstream-request missing hooks.
- [Risk] Project-local agents are repo-controlled prompts that can be malicious. -> Mitigation: default to user agents only, require explicit project-agent approval, display source paths, and deny project-agent execution in non-interactive mode unless configured.
- [Risk] Bash command classification can be bypassed by shell syntax. -> Mitigation: default dangerous/unknown bash to `ask` or `deny`, prefer explicit allowlists for restrictive agents, and show the full command in prompts/audit entries.
- [Risk] `pi.setActiveTools()` and prompt instructions can create a false sense of security. -> Mitigation: document them as UX/prompt shaping only and keep `tool_call` enforcement authoritative.
- [Risk] Policy composition may feel complex. -> Mitigation: ship simple built-in main agents, provide explain/debug commands for matched rules, and keep frontmatter examples small.
- [Risk] Reusing code from two external plugins can introduce license or maintenance obligations. -> Mitigation: verify licenses before vendoring, preserve attribution, isolate adapted modules, and keep upstream references in comments/docs.
- [Risk] Background subagents may outlive parent context or policy changes. -> Mitigation: snapshot effective policy at launch, record a policy hash, and require explicit restart to adopt changed policy.

## Migration Plan

1. Create a standalone package skeleton for the combined extension with manifest entries for the extension and bundled default agent definitions.
2. Vendor/adapt `pi-subagents` agent discovery and SDK session execution semantics, preserving public tool names and core behavior.
3. Vendor/adapt `pi-permission-system` policy parsing and enforcement helpers into a normalized policy engine.
4. Add main-agent selection (`--agent`, `/agent`, status UI) and built-in `plan`, `build`, and `ask` definitions.
5. Wire `before_agent_start` and `tool_call` enforcement around the explicit identity stack.
6. Add subagent delegation policy checks before creating child SDK sessions and local child-session policy reconstruction at launch.
7. Add audit/session persistence and debug/explain commands.
8. Validate with fixture agents and policies covering allow/ask/deny, parent-child restriction, project-agent approval, background runs, and non-interactive fail-closed behavior.
9. Optionally wire the package into this dotfiles repo after validation; keep existing plugins removable until parity is confirmed.
10. Rollback strategy: remove the package from Pi settings and restore any previous `pi-subagents` / `pi-permission-system` package entries.

## Open Questions

- None for the design phase. Exact package naming and license attribution details should be resolved during implementation setup.
