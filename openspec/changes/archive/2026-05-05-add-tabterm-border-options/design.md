## Context

Tabterm renders a floating workspace as separate sidebar and panel float windows. The current configuration already accepts boolean border input and stores a string border value, but the supported style contract is narrow and the windows do not explicitly separate sidebar and panel backgrounds when borders are disabled.

The proposal requires at least `single`, `double`, `round`, and `none`, and specifically calls out that `none` must keep the sidebar visually distinct from the terminal panel.

## Goals / Non-Goals

**Goals:**

- Define a small explicit set of supported border styles: `single`, `double`, `round`, and `none`.
- Keep existing boolean compatibility where `true` maps to `single` and `false` maps to `none`.
- Make borderless mode visually readable by assigning different background highlight groups to the sidebar and panel windows.
- Keep the visual decision local to tabterm so users can override it without changing global `Normal` or `NormalFloat` semantics.

**Non-Goals:**

- Add custom per-side border character arrays.
- Add per-window border style configuration.
- Change terminal workspace state, terminal lifecycle behavior, or `:Tabterm` command behavior.

## Decisions

### Normalize border styles to a fixed allowlist

`config.normalize()` will treat `single`, `double`, `round`, and `none` as valid border values. `true`, `false`, and `nil` keep their existing behavior. Unknown string values will fall back to the default `single` style instead of being passed through to `nvim_open_win()`.

Rationale: Neovim accepts multiple border forms, but this change is about exposing a predictable small config surface. A fixed allowlist prevents unsupported or misspelled values from reaching UI creation.

Alternatives considered:

- Pass arbitrary strings through to Neovim. This is more flexible but makes the plugin's supported behavior ambiguous.
- Support full border arrays now. This is useful eventually, but larger than the requested change.

### Use role-based tabterm highlight mappings

Tabterm will define `TabtermSidebar` and `TabtermPanel` highlight groups as the plugin-owned override points. `TabtermSidebar` will link to `Normal` by default, and `TabtermPanel` will link to `NormalFloat` by default.

Window-local `winhighlight` mappings will decide when those groups differ by role. In borderless mode, the sidebar window will map both `Normal` and `NormalFloat` to `TabtermSidebar`, and the panel/terminal window will map both to `TabtermPanel`. In bordered modes, both windows will map to `TabtermPanel` so their effective backgrounds remain the same.

Rationale: The intended distinction is structural: the sidebar is always the sidebar background, and the terminal panel is always the terminal background. Mapping both `Normal` and `NormalFloat` for each window avoids Neovim's active-window highlight behavior from moving the distinction between windows when focus changes, while keeping tabterm-owned groups available for user overrides.

Alternatives considered:

- Map directly to `Normal` and `NormalFloat` without tabterm-owned groups. This is simpler, but it removes the useful tabterm-specific override points.
- Generate a blended custom background from `Normal` and `NormalFloat`. This could improve themes where the groups are identical, but it is more complex and can produce surprising colors across colorschemes.

### Apply the sidebar/panel highlight split only to borderless mode

When `ui.border = "none"`, sidebar and panel windows will set different role-based mappings through `winhighlight`: sidebar to `TabtermSidebar`, panel to `TabtermPanel`. Bordered modes will set both windows to `TabtermPanel` so styles like `round` do not show different sidebar and panel backgrounds.

Rationale: The readability problem is specific to losing the visual separator created by borders. Bordered configurations already have a visible separator, so they must not also introduce sidebar/panel background contrast.

Alternatives considered:

- Leave bordered windows with empty `winhighlight`. This is closer to the prior implementation, but Neovim can make the selected float and unselected float use different effective backgrounds.

### Add a left inset to the borderless panel

When `ui.border = "none"`, the panel window will reserve one left padding column before terminal content. Bordered modes will not add this padding because the border already separates the panel from the sidebar.

Rationale: Removing borders makes terminal text start immediately next to the sidebar. A one-column inset restores breathing room without reintroducing a visible border or changing the sidebar width.

Alternatives considered:

- Add an external one-column gap between sidebar and panel. This separates the windows, but it creates empty editor background between them instead of padding the terminal panel itself.
- Prefix terminal lines with spaces. This would interfere with terminal content and is not robust for interactive terminal buffers.

## Risks / Trade-offs

- `Normal` and `NormalFloat` may be identical in some colorschemes, reducing the visible sidebar/panel distinction. → If needed later, a generated fallback color or explicit user-configured highlight groups can be added as a separate change.
- Falling back unknown border strings to `single` may hide configuration mistakes. → Keep the accepted values documented in the spec and type annotations; validation remains intentionally minimal for this local plugin.
- Applying `winhighlight` incorrectly could affect terminal buffer readability. → Scope the mappings to the tabterm float windows only and keep terminal buffer content mounted in the panel window.
- Using a window option for panel padding could interact with user expectations for terminal width. → Apply it only in borderless mode and remove it for bordered layouts.
