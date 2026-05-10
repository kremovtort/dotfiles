## Context

The agent permission framework creates subagents with Pi SDK `createAgentSession()` and installs an inline child-session `tool_call` hook that uses the delegated child identity and composed effective policy. Some subagents, such as `scout`, set `extensions: true` in their agent frontmatter so they can inherit extension tools when needed.

When extension inheritance is enabled, the child resource loader can load the framework package itself again from Pi settings. That recursive framework instance owns a fresh runtime state, does not know the delegated child identity/policy, and can add a second `tool_call` hook that denies read-only tools by default. This breaks legitimate read-only subagents under an active `build` parent.

## Goals / Non-Goals

**Goals:**

- Preserve `inherit_extensions` for non-framework extensions.
- Ensure the framework's own permission enforcement is installed exactly once for child sessions, using the delegated child runtime state.
- Keep fail-closed behavior for genuinely missing or invalid child policy state.
- Add regression coverage or scripted smoke checks for an `extensions: true` read-only subagent using repository read/search tools.

**Non-Goals:**

- Implementing a general extension sandbox or full per-extension policy system.
- Changing user-facing agent frontmatter such as `extensions: true` on existing subagents.
- Disabling all inherited extensions for subagents.

## Decisions

### 1) Treat the framework as a non-recursive runtime extension

The child session should continue to install the framework's child permission hook through the explicit `extensionFactories` path, not by reloading the package from settings. This keeps the active identity and policy source unambiguous.

Alternative considered: let the framework reload recursively and pass child state through environment or files. This is more complex, easier to desynchronize, and reintroduces duplicate hooks.

### 2) Filter only the framework from inherited package extensions

When a subagent requests extension inheritance, the resource loading path should exclude the agent permission framework itself while preserving other extensions. If the current Pi SDK does not expose a package-level filter, use the narrowest available approach and document any remaining limitation.

Alternative considered: set `noExtensions: true` for every child session. This fixes the denial but breaks subagents that need other extension tools.

### 3) Add a regression smoke check for read-only inherited-extension subagents

The regression check should run through `pi -p` where possible and prove that a `scout` subagent with extension inheritance can call `find`/`grep`/`read` successfully instead of receiving `resolved to deny` for all read-only tools.

## Risks / Trade-offs

- [Risk] Pi's current resource loader may not support filtering one package extension. → Mitigation: implement the closest narrow filter available; if necessary, add a framework child-mode guard so recursive instances no-op their permission hook.
- [Risk] Avoiding recursive framework load could hide future framework-provided child-session utilities. → Mitigation: keep child enforcement setup explicit in the parent-created `extensionFactories` path.
- [Risk] Smoke tests using `pi -p` depend on model/provider availability. → Mitigation: keep unit tests for deterministic pieces and use smoke checks only for live integration behavior.
