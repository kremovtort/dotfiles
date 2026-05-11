# Bureau and Agent Configuration Format

Bureau supports two configuration surfaces:

- Markdown agent files for prompt-heavy agent definitions.
- `bureau.{json,jsonc,yaml,yml}` files for structured user/project overrides, agent patches, and global permission layers.

## Locations and precedence

Markdown agent files:

- User scope: `~/.pi/agent/agents/*.md`
- Project scope: nearest `.pi/agents/*.md`, enabled only after `/agent-trust-project` or `--project-agents`

Bureau config files:

- User scope: `~/.pi/agent/bureau.json`, `~/.pi/agent/bureau.jsonc`, `~/.pi/agent/bureau.yaml`, `~/.pi/agent/bureau.yml`
- Project scope: nearest `.pi/bureau.json`, `.pi/bureau.jsonc`, `.pi/bureau.yaml`, `.pi/bureau.yml`, enabled only after `/agent-trust-project` or `--project-agents`

Within one user or project scope, bureau selects the first existing file in this order and warns about ignored siblings:

1. `bureau.jsonc`
2. `bureau.json`
3. `bureau.yaml`
4. `bureau.yml`

Overall source precedence from highest to lowest:

1. trusted project `.pi/bureau.{json,jsonc,yaml,yml}`
2. trusted project `.pi/agents/*.md`
3. user `~/.pi/agent/bureau.{json,jsonc,yaml,yml}`
4. user `~/.pi/agent/agents/*.md`
5. built-in bureau defaults

Project Markdown agents and project bureau config are repository-controlled prompts and permissions. They are not loaded until project agents/config are trusted for the current session.

## Markdown agents

Agents are Markdown files with YAML-like frontmatter followed by a prompt body.

Required fields:

- `name`
- `kind`: `main` or `subagent` (`subagent` is used as a compatibility default)
- `description`
- prompt body below frontmatter

Common optional fields:

- `model`: provider/model id
- `thinking`: `off|minimal|low|medium|high|xhigh`
- `max_turns`: maximum agentic turns; `0` or omitted means unlimited. The SDK runner steers the subagent to wrap up at the limit and aborts after five grace turns.
- `prompt_mode`: `replace` or `append`
- `inherit_context`, `inherit_extensions`, `inherit_skills`
- `run_in_background`
- `enabled: false`
- `permission:` OpenCode-style nested policy block

Legacy Markdown-only fields:

- `tools`: comma-separated tool names; migrated to `permission.tools` rules for compatibility.
- `disallowed_tools`: comma-separated deny-list; migrated to `permission.tools` deny rules for compatibility.

New agent definitions should use `permission` as the source of tool availability. Built-in `plan`, `build`, and `ask` set `permission.tools.*` to `allow`, so newly registered/unknown tools are available unless explicitly denied.

## Bureau config files

A bureau config file is a JSON, JSONC, YAML, or YML object with these top-level fields only:

- `agent`: map of agent names to agent patches or new agent definitions.
- `permission`: global permission layer applied to every effective agent at this source's precedence position.

Example:

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

`agent.<name>` patch entries support these fields:

- `kind`
- `description`
- `model`
- `thinking`
- `max_turns`
- `prompt_mode`
- `inherit_context`
- `inherit_extensions`
- `inherit_skills`
- `run_in_background`
- `enabled`
- `prompt`
- `permission`

For an existing agent, omitted fields keep their previous effective value. For a new agent, `description` and `prompt` are required; `kind` defaults to `subagent` when omitted.

Bureau config uses canonical `permission` only. It does not support `permissions` as an alias and does not support agent-local legacy `tools` or `disallowed_tools` migration fields. Tool rules must be written under `permission.tools`, for example:

```yaml
permission:
  tools:
    new-tool: deny
```

`permission.new-tool: deny` is invalid and is not treated as shorthand.

## Permissions

Decision states are `allow`, `ask`, and `deny`.

`permission` can be a scalar action:

```yaml
permission: ask
```

or an object with these supported entries:

- `*`: default decision for unspecified permissions
- `tools`: Pi tool-name rules, optionally with per-tool input/path rules
- `bash`: shell command rules
- `subagents`: subagent launch/delegation rules
- `external_directory`: paths outside the session working directory

`mcp`, `files`, `agents`, and `skills` are not supported permission categories in this model. Represent skill-like behavior as ordinary tool rules under `tools` until a future category is added.

Rule objects use OpenCode-style wildcard matching. Within one rule object, the last matching pattern wins:

```yaml
permission:
  *: ask
  tools:
    read:
      *: allow
      "*.env": deny
      "*.env.example": allow
    edit: ask
    write: ask
  bash:
    *: ask
    "git status*": allow
    "rm *": deny
  subagents:
    *: ask
    scout: allow
    docs-digger: allow
    "source:project": ask
    "override:model": ask
  external_directory:
    *: ask
    "~/projects/personal/**": allow
```

`subagents` rules match the subagent name plus supported delegation metadata markers such as `source:project`, `background`, and `override:model`. Tool override markers are not supported.

Across independent guards for one concrete tool call, safety precedence still applies: `deny` wins over `ask`, and `ask` wins over `allow`. For example, a `tools.read: allow` decision does not bypass `external_directory: ask` for a path outside the workspace.
