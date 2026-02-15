# Subagent JSON Formatting

Use human-readable formatted JSON at subagent boundaries.

## Invocation Rule

- When delegating to a subagent, construct the payload as a single JSON object that matches the subagent contract.
- If the payload is shown to the user, render it in a fenced `json` block with 2-space indentation.
- Do not wrap JSON payloads in prose when a pure object is required.

## Result Rule

- Prefer formatted JSON output from subagents whenever the subagent contract permits JSON.
- If a subagent contract requires non-JSON output (for example strict TOML or Markdown citations), keep that contract unchanged and also provide a concise parent-level JSON summary for readability.
- Parent-level JSON summaries should use stable keys:
  - `subagent`
  - `result`
  - `highlights`
  - `artifacts`
  - `next_actions`

## Formatting Rule

- Use valid JSON only (double-quoted keys/strings, no trailing commas).
- Use 2-space indentation for readability.
- Keep nesting shallow and prefer arrays of objects over dense prose.
- Do not include code comments inside JSON.
