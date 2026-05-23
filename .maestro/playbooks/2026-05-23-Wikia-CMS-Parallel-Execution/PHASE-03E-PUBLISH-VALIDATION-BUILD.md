---
title: "Wikia 03E Publish Validation Build"
type: task
status: active
---

# Wikia 03E Publish Validation Build

> Fresh-agent boot: read `AGENT_PROMPT.md` in this folder first.

```text
lane notes
   |
   v
publish/validation patch
   |
   v
focused tests + commit
```

- [x] Publish-validation lane build. In `/Users/felipegobbi/Documents/VibeworkV2/apps/wikia-worktrees/fix-publish-validation`, implement only validation/publish changes identified in `lane-notes/publish-validation.md`. Focus on `publish.sh`, `validate-state.sh`, and publish tests. Commit with explicit paths only. Stop after this task.
  Result: `publish.sh --validate` now runs `validate-state.sh`, includes `state_validation` in validation JSON, and aborts before push on invalid public output. `validate-state.sh` now defaults to the current worktree `/Users/felipegobbi/Documents/VibeworkV2/apps/wikia-worktrees/fix-publish-validation/docs/gitpages`. Publish/validation tests were made portable and focused tests passed.
