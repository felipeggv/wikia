---
title: "Wikia 05E Verify Publish Validation"
type: task
status: active
---

# Wikia 05E Verify Publish Validation

> Fresh-agent boot: read `/Users/felipegobbi/Documents/VibeworkV2/apps/wikia/.maestro/playbooks/2026-05-23-Wikia-CMS-Parallel-Execution/AGENT_PROMPT.md` first.

```text
publish pipeline
   |
   v
validation and idempotency gates
   |
   v
lane evidence only
```

- [x] In your assigned publish-validation worktree, verify the publish/validation lane without changing implementation code. Confirm `publish.sh` validates state before export, fails loudly instead of silently hiding missing vault helpers, supports dry-run/idempotency expectations, and keeps generated public files synchronized with CMS state. Run the focused publish/validation tests available in this worktree. Write evidence to `lane-final-checks/publish-validation.md` inside your own worktree with exact commands, PASS/BLOCKED status, and any mismatch. Do not deploy. EXIT.
  - Evidence: `/Users/felipegobbi/Documents/VibeworkV2/apps/wikia-worktrees/fix-publish-validation/lane-final-checks/publish-validation.md`
  - Result: PASS. Ran 14 focused publish/validation/CMS-state tests, confirmed missing `vault.mjs` fails loudly, found 0 mismatches, analyzed 0 images, and did not deploy.
