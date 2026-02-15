## 1. Create Codemodder Subagent Definition

- [x] 1.1 Add `agents/opencode/agents/codemodder.md` with subagent frontmatter (mode, model, limits, and permissions).
- [x] 1.2 Define codemodder input contract fields for `goal`, `mode`, scope filters, edit operations, and safety limits.
- [x] 1.3 Define codemodder output contract fields for result status, counts, changed paths, skipped items, follow-ups, and idempotency.
- [x] 1.4 Add hard boundary rules that restrict codemodder to deterministic mechanical edits only.

## 2. Integrate Codemodder into Local OpenCode Setup

- [x] 2.1 Register `codemodder` in the `opencodeAgents` list in `agents/opencode.nix`.
- [x] 2.2 Ensure Home Manager activation copies `codemodder.md` into `~/.config/opencode/agents`.
- [x] 2.3 Update `agents/opencode/_AGENTS.md` with codemodder role and delegation defaults.

## 3. Validate Delegation Flow

- [x] 3.1 Add a `plan` delegation example in codemodder instructions showing non-mutating preview behavior.
- [x] 3.2 Add an `apply` delegation example in codemodder instructions showing guarded execution behavior.
- [x] 3.3 Verify all referenced paths and contract field names are consistent across `codemodder.md`, `_AGENTS.md`, and `opencode.nix`.
- [x] 3.4 Confirm OpenSpec reports the change as apply-ready after artifact creation.
