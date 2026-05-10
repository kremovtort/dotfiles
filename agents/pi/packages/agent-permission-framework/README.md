# pi-agent-permission-framework

Local Pi package that combines first-class main/subagent identities with an OpenCode-like permission system.

## Package location

This package lives at:

```text
agents/pi/packages/agent-permission-framework
```

The package name is `pi-agent-permission-framework`. It is intentionally local until the framework is validated.

## Capabilities

- Main agents: `plan`, `build`, and `ask` are built in.
- Agent markdown discovery: user agents from `~/.pi/agent/agents/*.md`; project agents from nearest `.pi/agents/*.md` after explicit trust.
- Agent frontmatter supports `kind: main|subagent`, model/thinking/tool runtime options, and `permission:` policy blocks.
- Tools: `subagent`, `get_subagent_result`, and `steer_subagent` provide a Claude Code-style subagent surface modeled after `pi-subagents` (`prompt`, `description`, `subagent_type`, `model`, `thinking`, `max_turns`, `run_in_background`, `resume`, and `inherit_context`).
- Foreground subagent calls stream periodic progress so the parent session shows queued/running state, session id, elapsed time, turn count, latest output, or latest error instead of appearing frozen.
- Subagents run through Pi SDK `createAgentSession()`. Agent `max_turns` is enforced by counting `turn_end`, steering the subagent to wrap up at the soft limit, and aborting after five grace turns.
- Permission enforcement: `tool_call` is the authoritative pre-execution gate for tool, bash, file, skill, and delegation decisions.
- Audit: decisions and runtime state are persisted as Pi custom session entries and can be inspected with `/agent-permissions` or `/agent-explain`.
- Runtime smoke checks for foreground/background/result/steering/queue behavior live in `docs/runtime-checks.md`.

## Agent definition example

```md
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
System prompt goes here.
```

## Commands

- `/agent` — select an active main agent.
- `/agent <name>` — activate a main agent directly.
- `/agent-trust-project` — allow project-local `.pi/agents` for this session.
- `/agent-permissions` — show active identity and recent decisions.
- `/agent-explain <audit-id-or-fingerprint>` — explain a prior permission decision.

## Non-interactive behavior

`ask` decisions fail closed when no interactive UI is available unless a policy explicitly provides a safe non-interactive fallback.

## Current implementation note

Subagents are in-process SDK sessions. `steer_subagent` records steering for queued runs before start and delivers live steering to running subagent sessions through `AgentSession.steer()`. Foreground runs emit progress while waiting and are aborted when the parent tool call is cancelled.
