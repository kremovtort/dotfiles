## 1. Permission display model

- [x] 1.1 Add a permission display formatter that derives compact summaries, line counts, stable short hashes, preview lines, and detected highlight language from full action fingerprints.
- [x] 1.2 Add unit coverage proving display summaries are bounded while full normalized fingerprints remain available for approval and audit semantics.

## 2. Custom approval UI

- [x] 2.1 Add a custom approval component for interactive UI contexts with structural horizontal separators, standalone heading/metadata text, and `Deny` as the default selection.
- [x] 2.2 Implement stacked narrow layout with metadata, bounded highlighted preview, scroll/expand help, and visible decision choices.
- [x] 2.3 Implement wide split layout with decision choices on the left and bounded highlighted preview on the right.
- [x] 2.4 Implement prompt-local controls: up/down for decision selection, Enter to confirm, Escape/Ctrl-C to deny, `u`/`d` to scroll preview, and configured `app.tools.expand` to toggle preview detail.
- [x] 2.5 Ensure fallback `select`/`confirm` prompts use bounded summaries instead of full long action text.
- [x] 2.6 Keep the custom UI on Pi's event-driven repaint path and stabilize the compact preview footprint without a prompt-local render ticker.
- [x] 2.7 Add a structural vertical separator between decisions and preview in the wide layout, connected to horizontal body boundaries with top/bottom junctions.
- [x] 2.8 Use a compact request/target summary for non-bash built-in tool requests without code preview scroll/expand hints.
- [x] 2.9 Render a bottom separator so the custom approval prompt has a clear lower boundary.
- [x] 2.10 Render code preview position and scroll/expand controls as muted footer text below the prompt body.
- [x] 2.11 Support unadvertised PgUp/PgDn page scrolling for code previews.

## 3. Command display updates

- [x] 3.1 Update `/agent-permissions` to show compact action summaries and hash metadata for long audited actions.
- [x] 3.2 Update `/agent-explain` to show bounded action summaries by default while preserving stored full audit data.

## 4. Verification

- [x] 4.1 Add or update tests for formatter behavior, fallback prompt content, custom UI rendering shape, decision handling, and scroll/expand behavior.
- [x] 4.2 Run the package test suite.
- [x] 4.3 Validate the OpenSpec change with strict validation.
