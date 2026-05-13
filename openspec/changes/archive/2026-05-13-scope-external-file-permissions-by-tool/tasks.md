## 1. Permission Decision Model

- [x] 1.1 Add a narrow helper for tool-aware external-directory fingerprints that encodes the file operation/tool and normalized external path without changing path-only rule matching.
- [x] 1.2 Update file-related tool-call enforcement to pass the concrete file operation/tool context into the external-directory guard.
- [x] 1.3 Ensure reusable approvals distinguish same-path `read`, `write`, and `edit` requests while still reusing approvals for the same operation/path.

## 2. User-Facing Permission Display

- [x] 2.1 Teach permission display parsing/formatting to render tool-aware external-directory fingerprints as concrete file action summaries with the external path as target.
- [x] 2.2 Verify custom approval UI, fallback approval prompts, audit summaries, and `/agent-explain` display the concrete file action instead of generic `file external_directory` text.

## 3. Tests and Validation

- [x] 3.1 Add policy/enforcement tests showing `permission.external_directory` rules still match normalized paths without tool prefixes.
- [x] 3.2 Add approval reuse tests showing same operation/path reuses approval and different operations on the same path do not.
- [x] 3.3 Add display/UI tests covering external read/write/edit prompt summaries and bounded audit/fallback formatting.
- [x] 3.4 Run the agent-permission-framework test suite and `openspec validate` for this change.
