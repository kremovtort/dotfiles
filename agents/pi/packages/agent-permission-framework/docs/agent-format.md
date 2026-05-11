# Agent Format

Agents are Markdown files with YAML-like frontmatter followed by a prompt body.

Locations:

- User scope: `~/.pi/agent/agents/*.md`
- Project scope: nearest `.pi/agents/*.md`, enabled only after `/agent-trust-project` or `--project-agents`

Project definitions override user definitions with the same name only when project-local agents are trusted.

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

Legacy fields:

- `tools`: comma-separated tool names; migrated to `permission.tools` rules for compatibility.
- `disallowed_tools`: comma-separated deny-list; migrated to `permission.tools` deny rules for compatibility.

New agent definitions should use `permission` as the source of tool availability. Built-in `plan`, `build`, and `ask` set `permission.tools.*` to `allow`, so newly registered/unknown tools are available unless explicitly denied.

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
