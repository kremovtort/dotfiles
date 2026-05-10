## Context

The framework's `SubagentRegistry` accepts model-callable background `subagent` requests, stores run records, limits concurrent SDK child sessions, and promotes queued runs as active runs finish. OpenSpec review depends on launching three reviewer subagents in parallel. A recent parallel reviewer attempt showed one call without a visible run ID and two runs stuck in `queued` with `Duration: 0ms`, indicating queue/active-slot state can become inconsistent or insufficiently observable.

## Goals / Non-Goals

**Goals:**

- Make multiple background `subagent` tool calls in one assistant tool batch return stable run IDs independently.
- Ensure queued runs are promoted whenever active capacity is available, including after errors or aborted child session setup.
- Make queued vs running status clear in `get_subagent_result` and progress output.
- Add diagnostics/tests/smoke checks that cover reviewer-style parallel launches.

**Non-Goals:**

- Changing the public `subagent` tool contract beyond clearer status text/details.
- Removing concurrency limits or forcing all background runs to execute at once.
- Replacing the SDK child-session execution model.

## Decisions

### 1) Treat run registration as synchronous and independent

Each background `subagent` invocation should create and store a run record before any asynchronous child-session startup work can fail. The tool result should be derived from that stored record and always include the run ID.

Alternative considered: wait for child session creation before returning an ID. This makes launch failures simpler but breaks the expected background contract and makes parallel launches feel sequential.

### 2) Make queue pumping self-healing

`active` accounting should be decremented in a `finally` path for every run that leaves the execution path, and `pump()` should be invoked after all terminal transitions. If a run is restored from session state as queued/running but has no live session or promise, it should not consume active capacity.

Alternative considered: clear the whole registry on every reload. This avoids stuck slots but loses useful run history and makes `get_subagent_result` less reliable.

### 3) Report queued state explicitly

`get_subagent_result` should distinguish `queued` from `running`, including queued position or an equivalent message when available. This makes capacity problems visible rather than reporting queued runs as if they were running.

### 4) Add reviewer-style regression coverage

The regression should launch three background subagents in one batch or as close as `pi -p` can express, then retrieve all three results. It should fail if fewer than three run IDs are returned or any run remains indefinitely queued.

## Risks / Trade-offs

- [Risk] Provider/model latency can make smoke tests flaky. → Mitigation: allow generous timeouts and use small prompts; keep deterministic unit tests around queue accounting where possible.
- [Risk] Queue recovery could accidentally start more runs than the concurrency limit. → Mitigation: test active count and queued promotion under controlled fake runs or script with observable run counts.
- [Risk] Persisted historical runs may be mistaken for live queued work. → Mitigation: restored non-terminal runs without live sessions should be marked stale/aborted or ignored for active capacity.
