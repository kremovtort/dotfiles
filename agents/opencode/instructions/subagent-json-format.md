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
