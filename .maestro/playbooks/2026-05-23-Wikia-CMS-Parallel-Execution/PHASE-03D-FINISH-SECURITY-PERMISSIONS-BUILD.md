---
title: "Wikia 03D Finish Security Permissions Build"
type: task
status: active
---

# Wikia 03D Finish Security Permissions Build

> Fresh-agent boot: read `/Users/felipegobbi/Documents/VibeworkV2/apps/wikia/.maestro/playbooks/2026-05-23-Wikia-CMS-Parallel-Execution/AGENT_PROMPT.md` first.

```text
existing build edits
   |
   v
focused validation
   |
   v
explicit commit or BLOCKED note
```

- [ ] Finish security-permissions build in `/Users/felipegobbi/Documents/VibeworkV2/apps/wikia-worktrees/build-security-permissions` on branch `build/security-permissions`. Do not start a new implementation pass; review the existing uncommitted edits to `publisher/artifacts-publisher-source/SKILL.md`, `scripts/apply-pending.py`, `gate.sh`, `public_catalog.py`, `strip-gate.py`, `sync-cms-state.py`, `validate-state.sh`, and `templates/gate.html.tpl`. Never print secrets or private source content. Run focused tests named in `/Users/felipegobbi/Documents/VibeworkV2/apps/wikia-worktrees/build-security-permissions/lane-notes/security-permissions.md` that fit this lane. If valid, stage explicit intended paths only, commit with a `MAESTRO:` prefix, and update `/Users/felipegobbi/Documents/VibeworkV2/apps/wikia/.maestro/playbooks/2026-05-23-Wikia-CMS-Parallel-Execution/PHASE-03D-SECURITY-PERMISSIONS-BUILD.md` with `[x]` plus a one-line Result. If blocked, do not discard changes; write a BLOCKED note with exact failing command and stop.
