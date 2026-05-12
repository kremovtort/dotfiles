## Why

Permission approval prompts can become unusable when an `ask` action contains a large bash/python/node-style request: the full normalized action is rendered into the interactive form, pushing the decision choices off-screen and making the Pi session feel unresponsive. The UI needs a bounded, theme-aware preview that stays navigable while preserving exact permission identity for approval and audit.

## What Changes

- Replace unbounded permission prompt rendering with a custom bounded approval UI for interactive `ask` decisions.
- Show request metadata and a hash summary while keeping the full action fingerprint for approval reuse, auditing, and policy explanation.
- Render long action content in a scrollable preview pane with Pi theme colors and syntax highlighting where possible.
- Adapt the prompt layout by viewport width: decisions on the left and preview on the right for wide terminals; stacked summary, preview, and decisions for narrow terminals.
- Keep separators structural only: labels/headings are separate text, not embedded into borders or separator lines.
- Bound `/agent-permissions` and `/agent-explain` action display so those commands cannot flood notifications with full normalized actions.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `agent-permission-enforcement`: Interactive approval prompts must remain responsive for long actions by displaying bounded, theme-aware request previews while preserving full action identity for enforcement and audit.

## Impact

- Affected code: `agents/pi/packages/agent-permission-framework/src/enforcement.ts`, plus supporting formatter/UI modules and tests.
- Affected command output: `/agent-permissions` and `/agent-explain` summaries for long action fingerprints.
- Affected specs: `openspec/specs/agent-permission-enforcement/spec.md` via a delta spec for approval prompt presentation behavior.
- No expected changes to permission policy evaluation, approval scoping, stored fingerprints, or non-interactive fail-closed behavior.
