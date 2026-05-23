---
title: "Wikia 03A Finish Catalog State Build"
type: task
status: active
---

# Wikia 03A Finish Catalog State Build

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

- [ ] Finish catalog-state build in `/Users/felipegobbi/Documents/VibeworkV2/apps/wikia-worktrees/build-catalog-state` on branch `build/catalog-state`. Do not start a new implementation pass; review the existing uncommitted edits to `publisher/artifacts-publisher-source/scripts/public_catalog.py`, `sync-cms-state.py`, `validate-state.sh`, `tests/test-admin-db.sh`, `tests/test-publish-apply-pending.sh`, `tests/test-validate-state.sh`, and the new catalog/search/sync tests. Run the focused tests named in `/Users/felipegobbi/Documents/VibeworkV2/apps/wikia-worktrees/build-catalog-state/lane-notes/catalog-state.md` that fit this lane. If valid, stage explicit intended paths only, commit with a `MAESTRO:` prefix, and update `/Users/felipegobbi/Documents/VibeworkV2/apps/wikia/.maestro/playbooks/2026-05-23-Wikia-CMS-Parallel-Execution/PHASE-03A-CATALOG-STATE-BUILD.md` with `[x]` plus a one-line Result. If blocked, do not discard changes; write a BLOCKED note with exact failing command and stop.
