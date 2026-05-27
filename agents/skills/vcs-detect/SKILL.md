---
name: vcs-detect
description: Detect whether the current project uses jj (Jujutsu), arc (Arcadia), or git for version control. Run this BEFORE any VCS command to use the correct tool.
---

# VCS Detection Skill

Detect the version control system in use before running any VCS commands.

## Why This Matters

- jj (Jujutsu), arc, and git have different CLIs and workflows
- Running `git` commands in a jj or arc repo (or vice versa) causes errors
- Some repos use jj with git colocated (both `.jj/` and `.git/` exist)
- Arcadia uses `arc`, Yandex's VCS for the Arcadia monorepo

## Detection Logic

`jj root`, `arc root`, and `git rev-parse --show-toplevel` walk up the filesystem to find repo root.

**Priority order:**

1. `jj root` succeeds → jj (handles colocated too)
2. `arc root` succeeds → arc (Arcadia)
3. `git rev-parse` succeeds → git
4. All fail → no VCS

## Detection Command

```bash
if jj root &>/dev/null; then echo "jj"
elif arc root &>/dev/null; then echo "arc"
elif git rev-parse --show-toplevel &>/dev/null; then echo "git"
else echo "none"
fi
```

## Command Mappings

| Operation | git | jj | arc |
|-----------|-----|----|-----|
| Status | `git status` | `jj status` | `arc status` / `arc st` |
| Log | `git log` | `jj log` | `arc log` |
| Diff | `git diff` | `jj diff` | `arc diff` |
| Commit | `git commit` | `jj commit` / `jj describe` | `arc commit` / `arc ci` |
| Branch list | `git branch` | `jj branch list` | `arc branch` / `arc br` |
| New branch | `git checkout -b <name>` | `jj branch create <name>` | `arc checkout -b <name>` / `arc co -b <name>` |
| Push | `git push` | `jj git push` | `arc push` |
| Pull/Fetch | `git pull` / `git fetch` | `jj git fetch` | `arc pull` / `arc fetch` |
| Rebase | `git rebase` | `jj rebase` | `arc rebase` |

## Usage

Before any VCS operation:

1. Run detection command
2. Use appropriate CLI based on result
3. If `none`, warn user directory is not version controlled

## Example Integration

```
User: Show me the git log
Agent: [Runs detection] -> Result: jj
Agent: [Runs `jj log` instead of `git log`]
```

## Colocated Repos

When both `.jj/` and `.git/` exist, the repo is "colocated":
- jj manages the working copy
- git is available for compatibility (GitHub, etc.)
- **Always prefer jj commands** in colocated repos

## Arcadia Repos

When `arc root` succeeds, the repo is managed by `arc`:
- arc is the VCS for Yandex's Arcadia monorepo
- arc's CLI is intentionally similar to git for common operations
- Use `arc --help` or `arc <mode> -h` for command-specific help
- Prefer `arc` commands over `git` commands inside Arcadia
