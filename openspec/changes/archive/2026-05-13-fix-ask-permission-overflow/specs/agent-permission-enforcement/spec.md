## ADDED Requirements

### Requirement: Interactive approval displays are bounded and responsive
The framework MUST render interactive `ask` approval prompts so that long action text cannot push the decision controls off-screen or make the Pi session unresponsive. The displayed prompt SHALL be a bounded presentation of the full action fingerprint, while approval matching and audit records SHALL continue to use the full, untruncated fingerprint.

#### Scenario: Long action uses bounded preview
- **WHEN** an active agent requests a tool call that resolves to `ask`
- **AND** the action fingerprint contains more lines or columns than fit in the permission prompt
- **THEN** the framework SHALL display a bounded preview of the action instead of rendering the full action inline
- **AND** the approval decision controls SHALL remain visible and selectable
- **AND** approval reuse and audit SHALL still use the full action fingerprint

#### Scenario: Permission preview preserves exact action identity by hash
- **WHEN** the framework displays a bounded permission preview
- **THEN** it SHALL include metadata that identifies the full action, including a stable short hash of the full normalized action
- **AND** it SHALL NOT treat the displayed truncated preview as the action fingerprint for approval matching

#### Scenario: Narrow permission prompt stacks preview above decisions
- **WHEN** the terminal viewport is too narrow for a readable split layout
- **AND** the framework displays an interactive permission prompt
- **THEN** the prompt SHALL render a standalone `Permission required` heading, request metadata, a horizontal separator, the bounded request preview, preview position/help metadata, another horizontal separator, and the decision choices
- **AND** separator lines SHALL remain structural and SHALL NOT embed labels or headings inside the line
- **AND** the prompt SHALL render a bottom separator after the decision choices

#### Scenario: Wide permission prompt puts decisions left of preview
- **WHEN** the terminal viewport is wide enough for a readable split layout
- **AND** the framework displays an interactive permission prompt
- **THEN** the prompt SHALL render the decision choices on the left and the bounded request preview on the right
- **AND** the prompt SHALL render a structural vertical separator between the decision choices and preview region
- **AND** the vertical separator SHALL connect to horizontal body boundaries above and below the split region
- **AND** the selected decision SHALL remain visible while the preview is scrolled

#### Scenario: Non-bash built-in tool requests use compact summaries
- **WHEN** an interactive permission prompt displays a built-in tool request other than `bash`
- **THEN** the prompt SHALL show a compact request and target summary instead of a scrollable code preview
- **AND** it SHALL omit preview scroll and expansion hints that are only relevant to multi-line code previews

#### Scenario: Preview uses theme-aware highlighting
- **WHEN** the bounded permission preview contains code-like content such as a bash command or interpreter heredoc script
- **THEN** the framework SHALL render the preview with Pi theme-aware syntax highlighting when available
- **AND** it SHALL fall back to unhighlighted bounded text if no language can be detected or highlighting is unavailable

#### Scenario: Preview scroll and expansion use prompt-local keys
- **WHEN** a bounded permission preview contains hidden lines
- **THEN** the framework SHALL allow the user to scroll the preview with `u` and `d`
- **AND** it SHALL use the configured `app.tools.expand` keybinding to toggle the amount of preview detail shown
- **AND** it SHALL render the preview position and prompt-local scroll/expand controls as muted footer text below the prompt body boundary
- **AND** it MAY allow PgUp and PgDn as unadvertised convenience shortcuts for page-sized preview scrolling
- **AND** it SHALL NOT require PgUp, PgDn, or mouse wheel input for prompt-local scrolling

### Requirement: Permission explanation displays are bounded
The framework MUST keep user-facing permission explanation displays bounded even when audit entries contain long action fingerprints. Commands and notifications that summarize permission decisions SHALL show compact action summaries and metadata while preserving full audit data internally.

#### Scenario: Recent permission list summarizes long actions
- **WHEN** the user runs `/agent-permissions`
- **AND** a recent audit entry contains a long action fingerprint
- **THEN** the framework SHALL display a compact action summary rather than the full fingerprint
- **AND** it SHALL include enough metadata, such as a short hash, to correlate the summary with the full action

#### Scenario: Permission explanation summarizes long actions
- **WHEN** the user runs `/agent-explain` for an audit entry with a long action fingerprint
- **THEN** the framework SHALL display a bounded action summary and relevant policy details
- **AND** it SHALL NOT flood the notification with the full normalized action text by default
