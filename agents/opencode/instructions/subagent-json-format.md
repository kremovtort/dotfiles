# Subagent JSON Formatting

Use human-readable formatted JSON at subagent boundaries.

## Invocation rule

- Construct the payload as a single JSON object that matches the target subagent contract.
- Use valid JSON only: double-quoted keys/strings, no trailing commas, no comments.
- Use 2-space indentation.
- Keep nesting shallow and prefer arrays of objects over dense prose.

## Runtime wrappers

### OpenCode

When the subagent interface expects a direct payload, send only the JSON object with no prose wrapper.

### Pi with `npm:@tintinweb/pi-subagents`

The `Agent` tool's `prompt` parameter is a string. Put only the formatted JSON object in that string.

```js
Agent({
  subagent_type: "researcher",
  description: "Check Nix docs",
  prompt:
    '{\n  "q": "What does builtins.readFile return in Nix?",\n  "limit": 4\n}',
  run_in_background: true,
});
```

Do not wrap the JSON in explanatory prose inside `prompt`.

## Display rule

If the payload is shown to the user, render it in a fenced `json` block with 2-space indentation.

## Result rule

- Prefer formatted JSON output from subagents whenever the subagent contract permits JSON.
- If a subagent contract requires non-JSON output, such as Markdown citations or Markdown review findings, keep that contract unchanged.
- When summarizing subagent results at the parent level, use stable keys:
  - `subagent`
  - `result`
  - `highlights`
  - `artifacts`
  - `next_actions`
