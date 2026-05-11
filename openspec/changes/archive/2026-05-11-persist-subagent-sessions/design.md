## Context

The agent permission framework currently stores subagent lifecycle state in `SubagentRegistry` and persists public run snapshots into the parent Pi session through `SUBAGENT_RUN_ENTRY`. The child SDK session itself is created with `SessionManager.inMemory(run.cwd)`, so the complete child conversation, tool results, and custom entries disappear when the run ends or when Pi reloads.

Normal Pi sessions are append-only JSONL files managed by `SessionManager`. They contain a `session` header followed by standard entry types such as `message`, `custom`, `custom_message`, `session_info`, model changes, and thinking-level changes. This change should reuse that format for subagents instead of introducing a second session serialization format.

## Goals / Non-Goals

**Goals:**

- Persist every subagent child session using Pi's standard SessionManager JSONL format.
- Store subagent sessions separately from top-level interactive sessions so ordinary session pickers are not polluted by child runs.
- Link each parent run record to its durable child session id and JSONL file path.
- Restore completed subagent metadata and allow explicit continuation from interrupted saved child sessions.
- Make interrupted/resumable state visible in `get_subagent_result`, foreground progress, and the subagent widget without treating it as an active live run.
- Scope interactive permission approval serialization to the parent-visible approval context instead of one module-global queue.

**Non-Goals:**

- Automatically restart background subagents after Pi restarts or `/reload`.
- Invent a new JSONL schema for subagent sessions.
- Change the public orchestration tool names.
- Persist or replay OS-level process state, pending provider requests, in-flight permission prompts, or in-flight tool executions across process restarts.
- Expose the full parent UI context to restored child sessions.

## Decisions

### Store durable child sessions under a subagent namespace

Subagent sessions will be stored under:

```text
~/.pi/agent/subagent-sessions/--cwd--/
  <parentSessionId>/
    <runId>_<sessionId>.jsonl
```

The `--cwd--` encoding should match Pi's default session directory encoding so project scoping is predictable. `<parentSessionId>` groups child sessions by the parent session that launched them. `<runId>` keeps the framework run id visible in the filename, and `<sessionId>` preserves the normal Pi session identity.

Alternative considered: store child sessions in the normal `sessions/--cwd--` directory. That would maximize discoverability through existing session tooling, but it would mix implementation-detail child sessions with user-facing interactive sessions.

### Use SessionManager JSONL semantics for child histories

`executeSubagentRun()` should stop using `SessionManager.inMemory(run.cwd)` for ordinary subagent launches. Instead, it should create or open a persistent SessionManager rooted at the subagent session path and pass it into `createAgentSession()`.

The child session header should keep the subagent cwd and should link back to the parent session file when available through the standard `parentSession` header field. A `session_info` entry should label the session with the subagent type, description, and run id so manual inspection remains understandable.

Alternative considered: keep in-memory child sessions and append all child events into parent custom entries. That would preserve data, but it would not be a normal Pi session and would make resume/open tooling harder to reuse.

### Keep parent run records as indexes, not full transcripts

`SubagentRunRecord` should be extended with durable child-session metadata, for example:

```ts
childSessionId?: string;
childSessionFile?: string;
parentSessionId?: string;
parentSessionFile?: string;
resumable?: boolean;
resumedFromRunId?: string;
```

The run record remains the lightweight status/index object used by widgets and result tools. The full transcript lives in the child JSONL file. Terminal run summaries should still cache `output`, `error`, counters, and timing for fast display.

### Introduce an interrupted resumable state

On parent session restore, a previously `queued` or `running` run no longer has a live child process. If the restored run has a durable child session file, the registry should mark it as `interrupted` with `resumable: true` rather than `aborted`. A durable child session file is usable only when it is a regular file with a standard Pi JSONL `session` header whose session id and cwd match the restored run metadata when that metadata is available. If there is no usable child session file, the existing fail-closed behavior remains appropriate: mark it `aborted` and explain that no live session can continue.

`interrupted` means: the old live process is gone, but the child session history is available and may be explicitly continued. It should not consume a concurrency slot and should not be counted as running/queued.

Alternative considered: reuse `aborted` plus `resumable: true`. That is ambiguous in the UI because `aborted` reads like a final terminal failure.

### Resume is explicit and creates a new live child session from the saved JSONL

A resumed run should be launched only when the parent invokes the existing `subagent` workflow with `resume: <runId>` and a prompt/steering message. The framework should open the saved child session file, restore the child context through `SessionManager.open(...)`, attach the same child identity/effective policy shape, and continue with a new model turn.

The resumed run can either keep the same run id when the previous record is `interrupted`, or create a new run record linked by `resumedFromRunId`. The implementation should prefer stable parent-facing behavior: the original run id remains retrievable, and verbose output identifies the child session file and any resume lineage. If the saved child session file becomes unusable before explicit resume, the framework should fail closed instead of silently creating a fresh child session.

Auto-resume on startup is intentionally out of scope because it could unexpectedly execute tools after a restart.

### Scope permission approval queues to the parent-visible approval context

Current enforcement serializes all `ask` approvals through a single module-level queue. That prevents overlapping prompts, but it also creates hidden head-of-line blocking between unrelated parent sessions, restored contexts, and child sessions. Durable child sessions make this coupling more visible because resumable child runs can outlive the original live session that created a prompt.

The approval queue should move out of module-global state and into the parent-visible approval context, preferably as part of the `PermissionApprovalBroker` created for a parent `ExtensionContext` or a small approval coordinator owned by that context. Main-agent approvals and subagent approvals that route through the same parent UI should share one queue, preserving the current no-overlapping-prompts UX. Independent parent sessions or approval brokers should not block each other.

Subagent child enforcement should continue to set `allowContextUI: false` and use only the narrow parent-visible broker. When an interrupted subagent is restored, any previous pending approval should be treated as gone with the old live process; explicit resume receives a fresh broker and a fresh scoped queue.

Alternative considered: make queues per subagent run. That maximizes concurrency but can produce simultaneous permission prompts against the same parent UI, which is confusing and likely unsupported. Another alternative is keeping the current module-global queue, but that over-serializes unrelated approval contexts.

### UI behavior for interrupted runs

On restore, the UI should notify the user when interrupted resumable runs are found. This is a user-facing notification, so it should not name model-callable tools such as `get_subagent_result` or `subagent` as if the user can invoke them directly:

```text
2 subagent runs were interrupted and can be resumed.
Ask the agent to inspect or resume an interrupted subagent run by ID.
```

The subagent widget may show interrupted runs briefly using the same finished-run linger behavior, for example:

```text
Agents
├─ ⚠ scout  Trace session storage  interrupted · resumable
│  ⎿ ask the agent to inspect or resume this run
```

Interrupted runs should not remain in the active status bar indefinitely and should not be described as thinking or running.

Agent-facing tool results may still mention the underlying tool workflow. `get_subagent_result({ verbose: true })` should include the child session file path and a concrete resume hint for the assistant to relay. `steer_subagent` should reject interrupted runs with guidance that the assistant must resume rather than steer because there is no live session handle.

## Risks / Trade-offs

- **Session file creation timing** → Pi's SessionManager normally avoids materializing sessions with no assistant response. The implementation must either accept that pre-assistant interruptions are not resumable or deliberately materialize a compatible session file without corrupting normal append behavior.
- **Filename/session-id coordination** → The desired `<runId>_<sessionId>.jsonl` filename requires creating or assigning the child session id before finalizing the file path. Implement this through a small helper so the behavior is tested in one place.
- **Policy drift on resume** → Agent definitions and framework defaults may change between the original launch and resume. Persist enough policy/identity metadata to explain the original run, but evaluate explicit resume through the current parent delegation policy before creating a new live child turn.
- **Unexpected execution after restart** → Do not auto-run interrupted sessions. Require an explicit resume call.
- **Approval prompt concurrency** → Scope queues per parent-visible approval context, not per child run, so one UI cannot receive overlapping prompts while unrelated sessions avoid global head-of-line blocking.
- **Widget noise** → Interrupted runs should be visible enough to discover but should age out like finished runs rather than permanently occupying the active subagent indicator.
