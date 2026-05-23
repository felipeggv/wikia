---
title: "Wikia 00B Secret Scan"
type: task
status: active
---

# Wikia 00B Secret Scan

> Fresh-agent boot: read `AGENT_PROMPT.md` in this folder first.

```text
private source
   |
   v
git tracking + public raw.md scan
   |
   v
PASS/BLOCKED evidence
```

- [ ] Check secret and plaintext exposure for the official Wikia app. Verify `git -C /Users/felipegobbi/Documents/VibeworkV2/apps/wikia ls-files private-source` returns no tracked files. Search `/Users/felipegobbi/Documents/VibeworkV2/apps/wikia/docs/gitpages` for likely plaintext private `raw.md` exposure without printing secret values or article contents. Write `/Users/felipegobbi/Documents/VibeworkV2/apps/wikia/.maestro/state/secret-scan.md` with PASS/BLOCKED, counts only, exact commands used, and next action if blocked. Mark this checkbox complete and add a one-line result. Do not modify implementation code. Commit only this playbook checkbox/result line if you mark it complete. Stop after this task.
