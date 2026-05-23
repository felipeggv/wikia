---
title: "Wikia 00 Preflight"
type: task
status: active
---

# Wikia 00 Preflight

> Fresh-agent boot: read `AGENT_PROMPT.md` in this folder first.

```text
repo state
   |
   v
source inventory
   |
   v
safe-to-run verdict
```

- [ ] Verify the official Wikia app scaffold. Read `/Users/felipegobbi/Documents/VibeworkV2/apps/wikia/AGENTS.md`, `/Users/felipegobbi/Documents/VibeworkV2/apps/wikia/.maestro/playbooks/2026-05-23-Wikia-CMS-Parallel-Execution/manifest.json`, and `git -C /Users/felipegobbi/Documents/VibeworkV2/apps/wikia status --short`. Write `/Users/felipegobbi/Documents/VibeworkV2/apps/wikia/.maestro/state/preflight-scaffold.md` with PASS/BLOCKED, exact git HEAD, current branch, and whether any private-source files are tracked. Do not modify code. EXIT.

- [ ] Inventory publisher source boundaries. Inspect `/Users/felipegobbi/Documents/VibeworkV2/apps/wikia/publisher/artifacts-publisher-source/scripts`, `/Users/felipegobbi/Documents/VibeworkV2/apps/wikia/publisher/artifacts-publisher-source/templates`, and `/Users/felipegobbi/Documents/VibeworkV2/apps/wikia/publisher/artifacts-publisher-source/tests`. Write `/Users/felipegobbi/Documents/VibeworkV2/apps/wikia/.maestro/state/publisher-inventory.md` with file counts and likely ownership by lane. Do not modify code. EXIT.

- [ ] Check secret and plaintext exposure. Verify `git -C /Users/felipegobbi/Documents/VibeworkV2/apps/wikia ls-files private-source` returns no tracked files and grep for likely plaintext private `raw.md` under `docs/gitpages`. Write `/Users/felipegobbi/Documents/VibeworkV2/apps/wikia/.maestro/state/secret-scan.md`. Do not print secret values. EXIT.

