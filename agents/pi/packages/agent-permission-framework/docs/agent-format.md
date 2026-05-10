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
- `tools`: comma-separated tool names
- `disallowed_tools`: comma-separated deny-list for adapters that support it
- `max_turns`: maximum agentic turns; `0` or omitted means unlimited. The SDK runner steers the subagent to wrap up at the limit and aborts after five grace turns.
- `prompt_mode`: `replace` or `append`
- `inherit_context`, `inherit_extensions`, `inherit_skills`
- `run_in_background`
- `enabled: false`
- `permission:` nested policy block

Permission policy categories:

- `tools`
- `bash`
- `files`
- `agents`
- `skills`

`mcp` and `special` policy categories are deferred from this change.

Decision states are `allow`, `ask`, and `deny`. Deny wins over ask; ask wins over allow.
