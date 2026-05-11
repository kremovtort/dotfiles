## Why

Subagent runs currently keep their full Pi SDK session history only in memory, while the parent session stores only a compact run snapshot. This makes completed subagent work hard to inspect and makes interrupted live runs unrecoverable after Pi reloads, restarts, or session resume.

## What Changes

- Persist each subagent run as a durable child Pi session using the standard SessionManager JSONL session format.
- Store subagent session files under a separate subagent namespace:
  `~/.pi/agent/subagent-sessions/--cwd--/<parentSessionId>/<runId>_<sessionId>.jsonl`.
- Extend parent subagent run records with the child session id, child session file path, and resumability metadata.
- Restore known subagent run records on parent session resume without pretending that live child processes survived restart.
- Represent restored live runs with saved session files as `interrupted` and resumable, rather than final `aborted` runs.
- Allow explicit continuation from an interrupted child session through the existing subagent orchestration workflow.
- Scope interactive permission approval queues to the parent-visible approval context instead of using one process-global queue.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `agent-runtime`: Subagent orchestration must persist child session JSONL files, expose their paths through run metadata, restore interrupted resumable runs, and support explicit continuation from saved child sessions.
- `agent-permission-enforcement`: Permission approval waits must be serialized per parent-visible approval context rather than through a module-global queue, while preserving parent-mediated subagent approval behavior.

## Impact

- Affected package: `agents/pi/packages/agent-permission-framework`.
- Affected areas: subagent registry, subagent execution, session restore, result retrieval, steering/resume UX, run metadata types, permission approval queue scoping, tests, and runtime widget/status rendering.
- Uses Pi's existing SessionManager JSONL format instead of inventing a new session file format.
- No breaking changes to the model-callable tool names; existing `subagent`, `get_subagent_result`, and `steer_subagent` remain the workflow surface.
