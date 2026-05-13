## Context

The permission gate evaluates each tool call before execution. For file-related tools, it currently combines the ordinary `permission.tools` decision with a top-level `permission.external_directory` decision when the requested path is outside the current project. The external-directory decision uses a path-only fingerprint such as `file:external_directory:/outside/file`, which is good for path-based policy matching but loses the concrete requested tool when the prompt, audit summary, and reusable approval are displayed or stored.

This change keeps `permission.external_directory` as a path policy while making the resulting approval action identify both the file tool/operation and the external path.

## Goals / Non-Goals

**Goals:**

- Make external-directory prompts show the concrete tool name and external path/argument being requested.
- Scope reusable approvals by file tool/operation and external path.
- Preserve existing bureau configuration semantics for `permission.external_directory` path patterns.
- Preserve bounded display behavior and stable full-fingerprint audit correlation.

**Non-Goals:**

- Introduce a new first-class file permission category.
- Require existing `permission.external_directory` patterns to include tool names.
- Change ordinary `permission.tools` matching semantics.
- Add preview bodies for non-bash file tools beyond compact request/target summaries.

## Decisions

### Decision: Keep policy matching path-only, make the decision fingerprint tool-aware

`evaluateExternalDirectoryPermission` should continue to match only the normalized external path against `permission.external_directory`. The tool-call enforcement path should pass the requesting file operation/tool context into the external-directory guard so the returned `PermissionDecision.fingerprint` can encode both operation/tool and path.

Rationale: existing configs such as `external_directory: { "/tmp/**": "ask" }` should continue to work. The user-facing approval should still be for the actual requested action, not a path-only abstraction.

Alternative considered: make `external_directory` rules match `tool:path` strings. This was rejected because it would break existing configuration and make broad path policies noisier to author.

### Decision: Use a normalized fingerprint that separates operation from path

External-directory fingerprints should distinguish file operations in the normalized action, for example by using `file:external_directory:read:/outside/file` or an equivalent unambiguous encoding. Approval reuse and audit matching then naturally require the same operation and path. The path component should remain the normalized absolute path for external targets.

Rationale: approving `read /outside/file` must not approve `write /outside/file`. Including the operation in the full normalized fingerprint achieves this without adding another approval-scoping mechanism.

Alternative considered: keep the fingerprint path-only and store display-only metadata separately. This was rejected because the prompt would imply a narrower approval than the approval store actually enforces.

### Decision: Display external-directory actions as concrete file tool requests

Permission display parsing should recognize tool-aware external-directory fingerprints and produce compact summaries such as `file read: /outside/file` or `tool read: /outside/file` rather than `file external_directory: /outside/file`. UI surfaces that use `createPermissionDisplay`—custom approval UI, fallback select/confirm prompts, `/agent-permissions`, and `/agent-explain`—should therefore show the concrete operation and path without duplicating special formatting logic across callers.

Rationale: the formatting layer already centralizes bounded permission action display. Teaching it the new normalized form keeps all user-facing surfaces consistent.

Alternative considered: special-case only the approval component. This was rejected because audits and fallback prompts would remain ambiguous.

## Risks / Trade-offs

- Existing session approvals for path-only external-directory fingerprints will not match the new tool-aware fingerprints after reload. → This is acceptable and safety-preserving; users may be asked again once per operation/path.
- Encoding operation and path with colon separators can be ambiguous for unusual paths. → Parsing should split only the fixed prefix and treat the remainder as the path, preserving colons in file names.
- A single tool may imply different semantic operations in the future. → Start with the existing `fileOperationForTool` mapping and keep the display/fingerprint helper narrow enough to extend for new tools.
- More prompts may appear when a session first touches the same external path with multiple operations. → This is intentional: write/edit access is riskier than read access and should require separate approval.
