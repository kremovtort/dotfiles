# Agent global rules (OpenCode + Pi)

These rules are injected globally for OpenCode sessions and are also installed as Pi global instructions via `agents/pi.nix`.

## Never discard unrelated changes

- Never discard unrelated changes just because they look “extra”.
- This includes destructive commands in any VCS, for example `jj restore`, `git reset --hard`, `git checkout --`, force pushes, and similar operations.
- If you accidentally mixed multiple concerns in one change, use non-destructive separation workflows and ask before rewriting user work.
- If build/generated output, such as `flake.lock`, changes unexpectedly, keep it as a separate change. The user decides whether to discard it.
- Only discard changes when the user explicitly asked you to do it.

## Subagent usage

Use subagents by default for mechanical I/O work: heavy search, documentation lookup, repetitive codemods, independent review passes, and other tasks that can bloat the parent context.

The parent agent owns interpretation and final decisions. Subagents collect and compress evidence.

### Runtime-specific invocation

#### OpenCode

- Delegate to the named subagent, for example `@scout`, `@docs-digger`, `@codemodder`, or `@openspec-reviewer-gpt`.
- Send a single JSON object matching that subagent's input contract; no prose wrapper.

#### Pi with `npm:@tintinweb/pi-subagents`

- Use the `Agent` tool.
- Set `subagent_type` to the custom agent filename, for example `scout`, `docs-digger`, `codemodder`, `openspec-reviewer-gpt`, `openspec-reviewer-glm`, or `openspec-reviewer-kimi`.
- Put the formatted JSON payload in the `prompt` string and do not add prose around it.
- Use a short `description` of 3-5 words.
- Do not set `schedule` unless the user explicitly asked for delayed or recurring execution.

Example Pi call:

```js
Agent({
  subagent_type: "scout",
  description: "Find auth flow",
  prompt:
    '{\n  "q": "Trace how login reaches token issuance",\n  "mode": "trace",\n  "focus": "auth login token"\n}',
  run_in_background: false,
});
```

### Invocation rules (all subagents)

- Send exactly one JSON object matching the target subagent's input contract.
- Keep prompts tiny and task-focused; do not paste large context blobs.
- To pass local context, use inline refs: `@<file_path>[:<start_line>[:<end_line>]][::<identifier>]` (1-based).
  - Examples: `@agents/opencode/instructions/base.md`, `@agents/opencode/instructions/base.md:23:60`, `@agents/opencode/instructions/base.md::<Subagent usage>`.
- Subagents normally do not invoke other subagents. Only OpenSpec reviewer variants may call `scout` or `docs-digger` for focused evidence gathering.
- For build/test/lint execution in Pi, prefer the `process` tool for long-running/noisy commands. There is no custom `runner` subagent in this repository unless one is added later.

## Subagent roles and contracts

### `scout`

- Purpose: fast read-only codebase discovery and call-path tracing.
- Delegate by default for repository navigation work: locating files/symbols/config entries, finding usages, mapping references, and tracing indirect flows (`X -> wrapper/layer -> Y`).
- Output: 2-6 concise sentences in the user's language with refs like `path/to/file.ext:line`; for trace mode include a compact hop chain plus 2-5 refs.
- Hard scope: discovery/indexing helper only. Do not use for full code review, final quality/security/performance verdicts, or autonomous bug-finding loops.

Input contract:

```json
{
  "q": "what to find/trace",
  "mode": "search|trace",
  "focus": "optional keywords/paths",
  "from": "trace start (optional)",
  "to": "trace target (optional)"
}
```

### `docs-digger`

- Purpose: documentation research for authoritative, quotable evidence with minimal context bloat.
- Delegate when the parent needs source-backed facts: CLI flag semantics, API behavior, config options, standards/spec details, or error interpretation from official docs.
- Output: Markdown citations pack, not a full end-user solution. Every quote must be verbatim, short, and paired with `Source:` metadata.
- Not for codebase tracing or command execution triage.

Input contract:

```json
{
  "q": "exact research question",
  "focus": "optional keywords/paths",
  "limit": 8,
  "prefer": ["man", "web", "github", "code", "api"],
  "skills": ["optional-skill-name"]
}
```

### `codemodder`

- Purpose: deterministic mechanical edits for large repetitive refactors.
- Delegate only for broad but simple transformations that follow explicit rules.
- Use `mode="plan"` before `mode="apply"` unless the user explicitly asks for direct application and the rule is low risk.
- Hard scope: mechanical edits only. No architecture decisions, no tests/builds, no VCS operations.
- Output: one machine-readable JSON object with result, counts, changed paths, skipped items, manual follow-ups, and idempotency remainder.

Input contract:

```json
{
  "goal": "what to transform",
  "mode": "plan|apply",
  "include": ["glob"],
  "exclude": ["glob"],
  "edits": [
    {
      "id": "rule-id",
      "kind": "ast_replace|regex_replace|literal_replace",
      "lang": "optional",
      "pattern": "match",
      "rewrite": "replacement"
    }
  ],
  "safety": {
    "max_files": 200,
    "max_edits_per_file": 50,
    "allow_new_files": false,
    "allow_delete_files": false,
    "stop_on_ambiguous": true
  },
  "focus": "optional keywords/paths"
}
```

### `openspec-reviewer-gpt`, `openspec-reviewer-glm`, `openspec-reviewer-kimi`

- Purpose: independent read-only review of one OpenSpec change and its implementation.
- Delegate from OpenSpec review workflows when you need multiple model perspectives.
- Each reviewer must load/follow the shared `openspec-reviewer` skill and return Markdown findings using that skill's output format.
- Reviewers may use `scout` or `docs-digger` only for focused evidence gathering. They must not edit files or ask subagents to edit.

Input contract:

```json
{
  "change": "openspec-change-name",
  "location": {
    "kind": "working-copy|jj-revset|jj-bookmark|git-branch|git-commit|git-range|github-pr|arc-review|patch|custom",
    "value": "user-provided location or command details"
  },
  "artifacts": {
    "proposal": ["path"],
    "design": ["path"],
    "specs": ["path"],
    "tasks": ["path"]
  },
  "diff_context": "optional summary or command output from the orchestrator",
  "focus": "optional review focus"
}
```

## Delegation defaults

- If the task needs codebase discovery (“where is X?”, “who calls Y?”, “find config for Z?”), delegate to `scout` early.
- In the parent agent, do at most one discovery tool call before delegating to `scout`, unless the answer is trivial.
- If the task needs external documentation research, delegate to `docs-digger`.
- If the task is a repetitive mechanical refactor, delegate to `codemodder` with an explicit rule set.
- If the task needs independent OpenSpec review, run the reviewer variants in parallel and synthesize their findings in the parent.
- For full review/bug-finding, `scout` is only evidence gathering; the parent does analysis and validation.
