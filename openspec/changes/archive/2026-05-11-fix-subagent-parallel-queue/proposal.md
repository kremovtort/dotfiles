## Why

Parallel background subagent launches can leave only one reviewer visibly started while sibling runs remain queued indefinitely or do not render their run IDs. This breaks OpenSpec review workflows that rely on launching GPT/GLM/Kimi reviewers concurrently and makes queued state difficult to diagnose.

## What Changes

- Make parallel `subagent` tool calls robust when multiple background runs are launched in one assistant tool batch.
- Ensure every background `subagent` invocation returns a stable run ID and explicit `running` or `queued` state.
- Prevent stale active-slot accounting from blocking queued runs forever after failures, reloads, or abnormal child-session termination.
- Improve queued-state reporting so `get_subagent_result` distinguishes queued from running.
- Add regression coverage or scripted smoke checks for reviewer-style parallel background launches.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `agent-runtime`: Tighten background subagent scheduling requirements so parallel launches, queued promotion, and queued status reporting are reliable and observable.

## Impact

- Affects `agents/pi/packages/agent-permission-framework` subagent registry, queue pumping, background launch result rendering, and runtime diagnostics.
- Adds tests or smoke checks for multiple parallel background subagents.
- Improves reliability of OpenSpec review workflows that launch multiple reviewer subagents concurrently.
