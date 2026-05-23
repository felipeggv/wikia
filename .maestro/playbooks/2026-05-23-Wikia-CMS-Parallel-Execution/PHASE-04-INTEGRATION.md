---
title: "Wikia 04 Integration"
type: task
status: active
---

# Wikia 04 Integration

> Fresh-agent boot: read `AGENT_PROMPT.md` in this folder first.

```text
parallel branches
   |
   v
integration branch
   |
   v
full validation
```

- [ ] Review lane outputs before merge. In branch `improve/release-integration`, fetch all Wikia lane branches, list commits, and write `/Users/felipegobbi/Documents/VibeworkV2/apps/wikia/.maestro/state/integration-plan.md` with merge order and conflicts. Do not merge yet. EXIT.

- [ ] Merge approved lane branches into `improve/release-integration`. Use normal merge commits unless a conflict requires manual resolution. Never use force push. Run syntax checks after each merge. Commit only merge results. EXIT.

- [ ] Run integrated publisher tests. From the integration worktree, run the full Wikia publisher test suite under `publisher/artifacts-publisher-source/tests`. Write `/Users/felipegobbi/Documents/VibeworkV2/apps/wikia/.maestro/evidence/integration-tests.md` with exact commands and pass/fail. EXIT.

