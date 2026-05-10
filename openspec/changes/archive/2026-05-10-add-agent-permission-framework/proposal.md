## Why

Pi currently has separate plugin-level experiments for Claude Code-style subagents and OpenCode-style permissions, but permissions cannot be complete or reliable unless every acting agent has a first-class identity and policy. Pi also lacks built-in main-agent profiles such as plan/build/ask that can carry their own permissions and delegation rules.

## What Changes

- Add a Pi plugin that provides an agent framework for declaring main agents and subagents, including their identity, purpose, prompts, runtime options, and allowed delegation patterns.
- Integrate agent identity with an OpenCode-like permission system so tool, command, file, and delegation requests are evaluated against the active agent's policy.
- Support permission composition across main agents and subagents, including explicit allow/deny/ask behavior, inheritance, and stricter subagent overrides.
- Provide configuration/discovery for user-level and project-level agent definitions and permission policies.
- Provide a unified replacement/integration path for the overlapping concepts from `pi-subagents` and `pi-permission-system`, avoiding two disconnected permission and delegation layers.
- Introduce first-class main-agent presets such as planning, building, and asking/research modes, each with independently configurable permissions.

## Capabilities

### New Capabilities

- `agent-runtime`: Defines how main agents and subagents are declared, discovered, selected, delegated to, and represented as active runtime identities.
- `agent-permission-enforcement`: Defines how agent-aware permission policies are declared, inherited, evaluated, prompted for approval, and enforced for actions requested by main agents or subagents.

### Modified Capabilities

- None.

## Impact

- Adds a new Pi plugin or plugin package that combines agent orchestration and permission enforcement concerns.
- Affects Pi agent configuration files, project/user discovery conventions, and runtime tool invocation paths.
- May reuse or adapt concepts and code from `tintinweb/pi-subagents` and `MasuRii/pi-permission-system`, but should expose one coherent framework to users.
- Does not intentionally change existing dotfiles-managed Neovim or OpenCode behavior until the new plugin is explicitly wired into those configurations.
