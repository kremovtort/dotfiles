## Why

Tabterm's floating UI currently has an underspecified border configuration that does not expose the common Neovim border styles users expect. Adding explicit border style options makes the terminal workspace easier to tune visually while preserving a readable sidebar when borders are disabled.

## What Changes

- Extend the tabterm UI border configuration to support at least `single`, `double`, `round`, and `none`.
- Treat `none` as a borderless layout while keeping the sidebar visually distinct from the terminal panel.
- Ensure the sidebar uses a slightly different background from the terminal panel when borders are disabled.
- Preserve existing tabterm workspace behavior, terminal lifecycle behavior, and command APIs.
- No breaking changes are intended.

## Capabilities

### New Capabilities

- None.

### Modified Capabilities

- `tab-scoped-terminal-manager`: Extend sidebar/floating UI requirements to cover configurable border styles and the no-border sidebar background distinction.

## Impact

- Affected code: `nvim/plugins/tabterm/lua/tabterm/config.lua` and `nvim/plugins/tabterm/lua/tabterm/ui.lua`.
- Affected specs: `openspec/specs/tab-scoped-terminal-manager/spec.md` via a change-local delta spec.
- No new runtime dependencies are expected.
