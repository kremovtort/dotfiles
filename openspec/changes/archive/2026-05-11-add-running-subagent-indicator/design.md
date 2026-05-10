## Context

The local framework already owns subagent lifecycle state in `agents/pi/packages/agent-permission-framework/`, including queued/running/completed run records and permission-aware delegation. `tintinweb/pi-subagents` also has a persistent in-session widget/status indicator that shows active agents above the editor and in the status bar. This change should copy that visual behavior exactly, while adapting data sources to the local `SubagentRunRecord`/registry model and keeping code vendored or adapted rather than imported at runtime.

## Goals / Non-Goals

**Goals:**

- Fully copy the `pi-subagents` running-agent indicator appearance for the local framework: same widget placement, heading, tree layout, icons, spinner frames, colors, status-bar wording, running/queued/finished grouping, activity line shape, truncation behavior, and overflow behavior where applicable.
- Wire the copied/adapted indicator to local subagent lifecycle transitions so currently running subagents are visible in the parent session without polling result tools.
- Preserve the local framework's lowercase `subagent` tool naming, permission enforcement, identity stack, and SDK-based subagent execution.
- Vendor/adapt the required UI code from `tintinweb/pi-subagents` into `agents/pi/packages/agent-permission-framework/` instead of adding a runtime dependency.

**Non-Goals:**

- Reintroducing upstream `Agent` tool naming or importing `tintinweb/pi-subagents` as a dependency.
- Changing subagent scheduling, result retrieval, steering semantics, permission policy, or concurrency behavior beyond the UI state needed by the indicator.
- Adding a new user-configurable theme; the indicator should rely on Pi theme keys the same way `pi-subagents` does.

## Decisions

1. **Copy the upstream widget appearance rather than designing a new UI.**

   The implementation will vendor/adapt the relevant `pi-subagents` `AgentWidget` behavior. The desired output is appearance compatibility, not merely similar information. This means preserving the visible grammar:

   - status key `subagents` with text like `1 running agent`, `2 running, 1 queued agents`;
   - widget key/heading shape `● Agents` while active and `○ Agents` for lingered finished-only state;
   - placement above the editor;
   - tree connectors `├─` / `└─` and running activity continuation lines;
   - running spinner frames `⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏`;
   - queued marker `◦ N queued`;
   - finished icons `✓`, `■`, `✗` with the same success/warning/dim/error intent;
   - activity suffix format `  ⎿  <activity>`;
   - max visible line/overflow behavior matching upstream as closely as local data allows.

   Alternative considered: update only `ctx.ui.setStatus`. This was rejected because the user explicitly requested copying the indicator appearance from `pi-subagents`, which includes the above-editor widget, not just a status-bar counter.

2. **Adapt the upstream widget data adapter to local run records.**

   The copied widget will read from the local subagent registry/list API instead of `pi-subagents` `AgentManager`. A thin adapter will map local records to the fields the widget needs: id, agent type/name, description, status, started/completed timestamps, tool use count, turn count/max turns, output/error-derived activity, queued state, and any available session/usage metadata. Missing upstream-only fields such as model token lifetime usage may be omitted from the stats list rather than changing the visual layout.

   Alternative considered: change the local registry to mimic upstream `AgentManager` exactly. This was rejected to keep execution/permission internals stable and avoid broad runtime refactoring.

3. **Drive updates from lifecycle hooks plus a lightweight animation timer.**

   The indicator should update when runs are created, queued, promoted, started, report progress, complete, fail, abort, or are steered. While at least one active or lingered finished run exists, a short interval should advance the spinner and request widget rerenders, matching upstream behavior. The timer must stop and the widget/status must be cleared when there is nothing to show.

   Alternative considered: update only when `get_subagent_result` is called. This was rejected because the purpose is live in-session visibility without polling.

4. **Keep finished-run linger behavior compatible with upstream.**

   Finished successful runs should linger briefly so the user sees completion, while error/aborted/steered/stopped runs should linger longer, following the upstream turn-aging behavior. In the local framework this can be implemented by aging finished run IDs on parent turn/tool-start boundaries and filtering them from the widget after the copied thresholds.

   Alternative considered: clear completed runs immediately. This was rejected because it would not fully copy the upstream appearance/behavior.

## Risks / Trade-offs

- **Upstream visual code depends on data the local framework does not currently track** → Use an adapter and omit only unavailable stat fragments, while preserving line shape, icons, colors, and ordering.
- **Pi UI APIs may differ across versions** → Keep usage aligned with the upstream `setWidget` callback form and `setStatus` calls already proven by `pi-subagents`.
- **Animation timer could leak after session end** → Add explicit disposal/cleanup on extension shutdown and when no active or lingered runs remain.
- **Vendored code can drift from upstream** → Copy the appearance-critical constants and rendering helpers into a dedicated local UI module with comments identifying the upstream source.
