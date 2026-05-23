---
title: "Wikia Lane 02 Publish Validation Discovery"
type: task
status: active
---

# Wikia Lane 02 Publish Validation Discovery

> Fresh-agent boot: read `/Users/felipegobbi/Documents/VibeworkV2/apps/wikia/.maestro/playbooks/2026-05-23-Wikia-CMS-Parallel-Execution/AGENT_PROMPT.md` first.

```text
publish/validation lane
   |
   v
read-only discovery
   |
   v
lane-notes/publish-validation.md
```

- [ ] Publish-validation lane discovery. Work only in `/Users/felipegobbi/Documents/VibeworkV2/apps/wikia-worktrees/fix-publish-validation` on branch `fix/publish-validation`. Inspect publish, validation, and smoke-test flow under `/Users/felipegobbi/Documents/VibeworkV2/apps/wikia-worktrees/fix-publish-validation/publisher/artifacts-publisher-source/scripts` and `/Users/felipegobbi/Documents/VibeworkV2/apps/wikia-worktrees/fix-publish-validation/publisher/artifacts-publisher-source/tests`, especially `publish.sh`, `validate-state.sh`, and publish-related tests. Write `/Users/felipegobbi/Documents/VibeworkV2/apps/wikia-worktrees/fix-publish-validation/lane-notes/publish-validation.md` with ownership, risks, proposed changes, and focused tests to run later. Do not edit implementation code. Do not touch other lane worktrees. EXIT.
