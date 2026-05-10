## 1. Queue and Launch Robustness

- [x] 1.1 Inspect `SubagentRegistry` launch, `active` accounting, restore, and `pump()` behavior for paths that can leave capacity stuck.
- [x] 1.2 Ensure each background `subagent` tool call synchronously stores and returns a stable run ID with explicit `running` or `queued` status.
- [x] 1.3 Ensure terminal paths for completed, failed, aborted, and child-session setup failures release active capacity and pump queued runs.
- [x] 1.4 Ensure restored queued/running records without live sessions do not consume active capacity or block new launches.
- [x] 1.5 Update `get_subagent_result` and progress text to report queued state explicitly instead of saying the agent is running.

## 2. Regression Coverage

- [x] 2.1 Add deterministic unit tests for parallel background run registration, capacity release, and queued promotion.
- [x] 2.2 Add or update scripted smoke checks for three reviewer-style parallel background subagents and result retrieval for all returned IDs.
- [x] 2.3 Run package tests, strict OpenSpec validation, and the parallel `pi -p` smoke scenario.
  - Package tests and strict OpenSpec validation passed.
  - Parallel `pi -p` smoke passed using a temporary agent dir that symlinked the real `auth.json` and loaded the local `agent-permission-framework` package.
- [x] 2.4 Fix interactive parallel `subagent` permission preflight so all approved calls reach execution and render run IDs.
  - Top-level `tool_call` preflight now enforces only the `subagent` tool permission; delegation-specific approval is handled inside `subagent.execute`.
  - Interactive approval prompts are serialized so parallel `ask` decisions cannot race/cancel sibling tool calls.
