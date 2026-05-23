---
title: "Wikia 05 Verify And Handoff"
type: task
status: active
---

# Wikia 05 Verify And Handoff

> Fresh-agent boot: read `AGENT_PROMPT.md` in this folder first.

```text
integrated build
   |
   v
visual and invariant gates
   |
   v
handoff
```

- [x] Run final no-secret and catalog invariants. Verify private raw markdown is not tracked or public, generated catalog/search/admin agree on article counts, and sidebar wrappers are not duplicated. Write `/Users/felipegobbi/Documents/VibeworkV2/apps/wikia/.maestro/evidence/final-invariants.md`. EXIT.

- [x] Prepare release handoff. Write `/Users/felipegobbi/Documents/VibeworkV2/apps/wikia/.maestro/evidence/release-handoff.md` with branches, commits, tests, screenshots, known risks, rollback, and exact deploy/promotion commands. Do not deploy. EXIT.

- [x] Prepare next-step ClickUp update draft. Write `/Users/felipegobbi/Documents/VibeworkV2/apps/wikia/.maestro/evidence/clickup-update-draft.md` summarizing what should be posted to `https://app.clickup.com/t/86ahk42ad`. Do not post to ClickUp. EXIT.
