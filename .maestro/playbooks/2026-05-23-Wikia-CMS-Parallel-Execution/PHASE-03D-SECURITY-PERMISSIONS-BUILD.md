---
title: "Wikia 03D Security Permissions Build"
type: task
status: active
---

# Wikia 03D Security Permissions Build

> Fresh-agent boot: read `AGENT_PROMPT.md` in this folder first.

```text
lane notes
   |
   v
vault + scope patch
   |
   v
focused tests + commit
```

- [ ] Security-permissions lane build. In `/Users/felipegobbi/Documents/VibeworkV2/apps/wikia-worktrees/build-security-permissions`, implement only permission/security changes identified in `lane-notes/security-permissions.md`. Focus on vault/encryption/gate behavior and permission-scope tests. Never print secrets. Commit with explicit paths only. Stop after this task.
