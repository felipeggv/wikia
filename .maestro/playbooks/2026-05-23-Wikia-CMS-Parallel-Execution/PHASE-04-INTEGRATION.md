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
  - Blocked 2026-05-23 by `improve/wikia-release-integration-cdx`: fetched all refs, listed present lane commits, and forecasted conflicts without merging. Could not write the required `/Users/felipegobbi/Documents/VibeworkV2/apps/wikia/.maestro/state/integration-plan.md` because Maestro write rules only allow this agent to write inside `/Users/felipegobbi/Documents/VibeworkV2/apps/wikia-worktrees/improve-release-integration` or `/Users/felipegobbi/Documents/VibeworkV2/apps/wikia/.maestro/playbooks/2026-05-23-Wikia-CMS-Parallel-Execution`. Safe fallback report: `/Users/felipegobbi/Documents/VibeworkV2/apps/wikia/.maestro/playbooks/2026-05-23-Wikia-CMS-Parallel-Execution/Working/integration-plan-review-blocked.md`. No merge performed. Images analyzed: 0.
  - Reconfirmed 2026-05-23 by `improve/wikia-release-integration-cdx`: `git fetch --all --prune` passed, local `improve/release-integration` matches `origin/improve/release-integration` at `f80383c`, present lane refs were listed, and `git merge-tree --write-tree` forecasts clean merges for the observed refs. Required state path remains outside this agent's write boundary, so the task stays unchecked and no merge was performed. Updated fallback report: `/Users/felipegobbi/Documents/VibeworkV2/apps/wikia/.maestro/playbooks/2026-05-23-Wikia-CMS-Parallel-Execution/Working/integration-plan-review-blocked.md`. Images analyzed: 0.
<!-- maestro:halt: PHASE-04 requires writing /Users/felipegobbi/Documents/VibeworkV2/apps/wikia/.maestro/state/integration-plan.md, which is outside this agent's allowed write boundary -->

- [ ] Merge approved lane branches into `improve/release-integration`. Use normal merge commits unless a conflict requires manual resolution. Never use force push. Run syntax checks after each merge. Commit only merge results. EXIT.

- [ ] Run integrated publisher tests. From the integration worktree, run the full Wikia publisher test suite under `publisher/artifacts-publisher-source/tests`. Write `/Users/felipegobbi/Documents/VibeworkV2/apps/wikia/.maestro/evidence/integration-tests.md` with exact commands and pass/fail. EXIT.
