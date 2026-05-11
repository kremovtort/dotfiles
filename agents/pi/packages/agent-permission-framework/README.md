# pi-bureau

Local Pi package that combines first-class main/subagent identities, structured bureau configuration, and an OpenCode-like permission system.

## Package location

This package currently lives at:

```text
agents/pi/packages/agent-permission-framework
```

The package name is `pi-bureau`. The directory path remains `agent-permission-framework` for local compatibility while the user-facing framework name moves to bureau.

## Capabilities

- Main agents: `plan`, `build`, and `ask` are built in.
- Agent Markdown discovery: user agents from `~/.pi/agent/agents/*.md`; project agents from nearest `.pi/agents/*.md` after explicit trust.
- Bureau config discovery: user config from `~/.pi/agent/bureau.{json,jsonc,yaml,yml}`; project config from nearest `.pi/bureau.{json,jsonc,yaml,yml}` after explicit trust.
- Agent definitions support `kind: main|subagent`, model/thinking/runtime options, prompts, and OpenCode-style `permission:` policy blocks.
- Bureau config can add or patch agents under `agent.<name>` and add global permission layers under top-level `permission`.
- Active tools are derived from permissions: tools resolved categorically to `deny` are hidden, while `ask` tools and input-sensitive tools stay active for pre-execution enforcement.
- Tools: `subagent`, `get_subagent_result`, and `steer_subagent` provide a Claude Code-style subagent surface modeled after `pi-subagents` (`prompt`, `description`, `subagent_type`, `model`, `thinking`, `max_turns`, `run_in_background`, `resume`, and `inherit_context`).
- Foreground subagent calls stream periodic progress so the parent session shows queued/running state, session id, elapsed time, turn count, latest output, or latest error instead of appearing frozen.
- Subagents run through Pi SDK `createAgentSession()`. Agent `max_turns` is enforced by counting `turn_end`, steering the subagent to wrap up at the soft limit, and aborting after five grace turns.
- Permission enforcement: `tool_call` is the authoritative pre-execution gate for tool, bash, file/path, external-directory, and subagent delegation decisions.
- Audit: decisions and runtime state are persisted as Pi custom session entries and can be inspected with `/agent-permissions` or `/agent-explain`.
- Runtime smoke checks for foreground/background/result/steering/queue behavior live in `docs/runtime-checks.md`.

## Bureau config example

```yaml
agent:
  build:
    permission:
      tools:
        read:
          /opt/homebrew/**: allow
  my-new-agent:
    kind: main
    description: Custom coding assistant
    model: openai-codex/gpt-5.5
    thinking: xhigh
    prompt: |
      You are a powerful coding assistant. Help users with their programming tasks.

permission:
  tools:
    new-tool: deny
  subagents:
    "*": ask
```

Supported bureau config files are selected once per scope in this order: `bureau.jsonc`, `bureau.json`, `bureau.yaml`, `bureau.yml`. If multiple files exist in the same scope, the first one wins and the rest are reported as ignored.

Source precedence from highest to lowest:

1. trusted project `.pi/bureau.{json,jsonc,yaml,yml}`
2. trusted project `.pi/agents/*.md`
3. user `~/.pi/agent/bureau.{json,jsonc,yaml,yml}`
4. user `~/.pi/agent/agents/*.md`
5. built-in bureau defaults

Project `.pi/agents` and `.pi/bureau.*` are repository-controlled prompts and permissions. They load only after `--project-agents` or `/agent-trust-project` enables project agents/config for the session.

## Markdown agent definition example

```md
---
name: build
kind: main
description: Implementation agent
model: anthropic/claude-sonnet-4-5
thinking: high
permission:
  *: ask
  tools:
    *: allow
    read:
      *: allow
      "secrets/**": deny
      ".git/**": deny
    grep: allow
    find: allow
    edit: ask
    write: ask
    bash: allow
    subagent: allow
    get_subagent_result: allow
    steer_subagent: allow
  bash:
    *: ask
    "just test*": allow
    "just build*": allow
    "rm *": deny
    "sudo *": deny
  external_directory:
    *: ask
    "/nix/store/**": allow
  subagents:
    *: ask
    scout: allow
    docs-digger: allow
    codemodder: ask
    "override:model": ask
---
System prompt goes here.
```

Supported top-level permission entries are `*`, `tools`, `bash`, `subagents`, and `external_directory`. `mcp` is not supported yet; `files`, `agents`, and `skills` are legacy concepts and are not first-class categories in the new model.

Legacy `tools` and `disallowed_tools` frontmatter fields are accepted only in Markdown agent files as a compatibility migration path and are converted into `permission.tools` rules. Bureau config files do not support `permissions`, `tools`, or `disallowed_tools` as agent-local aliases; use canonical `agent.<name>.permission`.

## Commands

- `/agent` — select an active main agent.
- `/agent <name>` — activate a main agent directly.
- `/agent-trust-project` — allow project-local `.pi/agents` and `.pi/bureau.*` config for this session.
- `/agent-permissions` — show active identity, policy hash, config sources, and recent decisions.
- `/agent-explain <audit-id-or-fingerprint>` — explain a prior permission decision.

## Non-interactive behavior

`ask` decisions fail closed when no interactive UI is available unless a policy explicitly provides a safe non-interactive fallback or a delegated subagent has a parent-visible approval bridge.

## Current implementation note

Subagents are in-process SDK sessions. `steer_subagent` records steering for queued runs before start and delivers live steering to running subagent sessions through `AgentSession.steer()`. Foreground runs emit progress while waiting and are aborted when the parent tool call is cancelled.
