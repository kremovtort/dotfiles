## Context

`pi-bureau` enforces permissions in `agents/pi/packages/agent-permission-framework/src/enforcement.ts`. When an action resolves to `ask`, the current interactive broker passes a permission message containing the full normalized action fingerprint into `ctx.ui.select()`. For large bash requests, especially heredoc scripts for Python or Node, that prompt can exceed the terminal height and make the decision choices unreachable or unresponsive.

The full normalized action is still the security identity: it is used for approval reuse, audit, and explanations. The bug is only in presentation. The UI must show a bounded summary/preview without weakening exact approval semantics.

## Goals / Non-Goals

**Goals:**

- Keep permission prompts responsive for arbitrarily long action text.
- Preserve exact action fingerprints for approval matching, audit records, and enforcement decisions.
- Show a bounded, syntax-highlighted preview for long request content using Pi theme colors.
- Use a minimal Pi-style layout: structural horizontal separators, standalone headings/metadata, no labels embedded in separator lines.
- Adapt layout by viewport width: decisions left + preview right on wide terminals; stacked summary, preview, and decisions on narrow terminals.
- Keep `Deny` as the safe default selection.
- Bound `/agent-permissions` and `/agent-explain` display of long action fingerprints.

**Non-Goals:**

- Changing permission policy evaluation, rule matching, or approval scopes.
- Changing the full normalized action string used by fingerprints or audit entries.
- Adding new approval decisions or free-form denial reasons.
- Capturing terminal PgUp/PgDn or mouse wheel input; terminal scrollback should remain usable while a permission prompt is pending.

## Decisions

1. **Separate security identity from display projection.**
   - Add a small display formatter that derives metadata, short hash, preview lines, and compact summary from `PermissionDecision.fingerprint.normalized`.
   - Keep `decision.fingerprint` and `runtime.addApproval(...)` unchanged.
   - Rationale: approvals must remain exact even when the UI is summarized or scrolled.
   - Alternative considered: truncate the fingerprint before prompting. Rejected because it would make approval/audit identity ambiguous.

2. **Use `ctx.ui.custom()` for interactive TUI prompts when available, with `select`/`confirm` fallback.**
   - The custom component owns rendering, decision selection, preview scroll, and expand/collapse state.
   - The prompt relies on Pi's shared event-driven repaint path: it requests render on input/state changes and avoids a prompt-local timer that can over-drive embedded terminal emulators.
   - The bounded preview region pads to its allocated height so compact prompt footprint stays stable across short and long requests.
   - Fallback prompts use the same bounded summary instead of the full action.
   - Rationale: `ctx.ui.select()` is convenient but cannot reserve fixed preview/decision regions for overflow cases.
   - Alternative considered: keep `select()` and only shorten the prompt. Rejected because long previews still need scrolling and adaptive layout.

3. **Render minimal stacked layout for narrow terminals.**
   - Structure: separator, `Permission required`, metadata, separator, preview body, muted preview position/help line, separator, decisions.
   - No extra labels such as `Request preview` or `Decision` are rendered unless a future accessibility need requires them.
   - Rationale: this matches the requested visual style and keeps the prompt compact.

4. **Render decisions left of preview for wide terminals.**
   - The wide layout keeps the same header/metadata at the top, then splits the body with decisions on the left and the bounded preview on the right.
   - A structural vertical separator divides the decision list from the preview so the two regions are visually distinct without embedding labels in border lines.
   - The vertical separator connects to the horizontal body boundaries with `┬` and `┴`, and the prompt renders a bottom boundary after the decisions/preview body.
   - Code previews render the preview position and controls (`u/d scroll`, `app.tools.expand`) as a muted footer line below the bottom boundary.
   - Rationale: the decision list stays immediately visible and stable while the preview consumes the larger variable-width region.

5. **Use compact summaries for non-bash tool requests.**
   - Built-in tool requests other than `bash` render a compact request/target summary instead of a scrollable code preview and do not show `u`/`d`/expand help.
   - Rationale: paths, URLs, search patterns, and simple tool targets are easier to approve as a short summary than as a fake code preview.

6. **Highlight preview content with Pi theme colors.**
   - Use Pi's `highlightCode()` for code-like previews where possible.
   - Detect inner heredoc/interpreter language for common bash forms such as `python <<'PY'`, `node <<'JS'`, and otherwise fall back to bash or plain text.
   - Rationale: large permission requests are often scripts; syntax coloring makes them inspectable without leaving the prompt.

7. **Use narrow, explicit input handling.**
   - `u`/`d` scroll the preview one line at a time; PgUp/PgDn scroll by the current preview page; arrow up/down move the selected decision; Enter confirms; Escape/Ctrl-C denies; `app.tools.expand` toggles compact/full preview height.
   - Do not advertise PgUp/PgDn in the footer; keep them as convenience shortcuts for users who try them.
   - Do not handle mouse wheel input, so terminal scrollback remains usable.
   - Rationale: prompt-local navigation should not capture the user's normal terminal history navigation.

8. **Bound audit/explain presentation, not stored audit.**
   - `/agent-permissions` and `/agent-explain` display compact action summaries plus hash/line metadata for long actions.
   - Stored audit entries continue to contain the full fingerprint.
   - Rationale: explanations remain useful without flooding notifications or losing exact data for matching.

## Risks / Trade-offs

- **Custom component can drift from Pi selector conventions** → Keep controls small and use standard Pi/TUI keybinding helpers where available.
- **Syntax detection may be incomplete** → Fall back to bash/plain highlighting without blocking approval.
- **Very small terminals may still have little preview space** → Clamp preview height to at least one line and always keep decisions visible.
- **Fallback UI is less capable than custom UI** → It remains bounded and safe; full scroll/expand behavior is best-effort only when `ctx.ui.custom()` exists.
- **Theme highlighting depends on Pi exports** → Use Pi-provided `highlightCode()` and theme methods rather than hard-coded ANSI colors.
