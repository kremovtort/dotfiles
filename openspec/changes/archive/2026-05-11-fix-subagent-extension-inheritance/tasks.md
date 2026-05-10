## 1. Child Extension Loading

- [x] 1.1 Inspect Pi SDK `DefaultResourceLoader` extension/package loading options and identify the narrowest way to prevent recursive loading of this framework in child sessions.
- [x] 1.2 Implement a non-recursive child-session mode or package filter so inherited extensions exclude `agent-permission-framework` while preserving other inherited extensions.
- [x] 1.3 Ensure child permission enforcement still uses the delegated child identity and effective policy installed by the parent-created `extensionFactories` hook.

## 2. Regression Coverage

- [x] 2.1 Add a regression test or scripted smoke check covering an `extensions: true` read-only subagent that uses repository read/search tools successfully.
- [x] 2.2 Verify the smoke scenario that previously produced `read`/`grep`/`find`/`ls` `resolved to deny` now succeeds under active `build`.
- [x] 2.3 Run package tests and strict OpenSpec validation.
