---
title: "Wikia"
type: config
status: active
---

# Wikia

Wikia is the official app home for Felipe's internal knowledge wiki and static CMS publishing pipeline.

```text
private-source
   |
   v
publisher
   |
   +-- catalog
   +-- admin
   +-- search
   +-- scoped pages
   |
   v
docs/gitpages
```

## Paths

```text
/Users/felipegobbi/Documents/VibeworkV2/apps/wikia
/Users/felipegobbi/Documents/VibeworkV2/apps/wikia-worktrees
/Users/felipegobbi/Documents/VibeworkV2/apps/wikia/.maestro/playbooks/2026-05-23-Wikia-CMS-Parallel-Execution
```

## Safety

Private markdown sources live in `private-source/` and are intentionally ignored by Git.
The public GitHub Pages output lives under `docs/gitpages/`.
