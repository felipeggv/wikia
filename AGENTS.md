---
title: "Wikia Agent Guide"
type: config
status: active
---

# Wikia Agent Guide

Agents working in this app must treat Wikia as a CMS-like publishing system, not as manually edited static HTML.

## Source Model

```text
private-source/{bu}/{project}/{slug}/raw.md
   |
   v
publisher/artifacts-publisher-source
   |
   v
docs/gitpages
```

## Rules

1. Do not commit plaintext private sources.
2. Do not edit generated HTML as the source of truth.
3. Do not hardcode navigation trees in generated pages.
4. Keep admin, search, sidebar, BU pages, project pages, and article pages synchronized from the same catalog.
5. Use isolated worktrees for parallel work.
6. Never use `git add -A`, `git add .`, or `git commit -a`.
7. Stage explicit paths only.
8. Use `MAESTRO:` commit prefixes for Auto Run work.

## Key Paths

```text
/Users/felipegobbi/Documents/VibeworkV2/apps/wikia
/Users/felipegobbi/Documents/VibeworkV2/apps/wikia/publisher/artifacts-publisher-source
/Users/felipegobbi/Documents/VibeworkV2/apps/wikia/private-source
/Users/felipegobbi/Documents/VibeworkV2/apps/wikia/docs/gitpages
/Users/felipegobbi/Documents/VibeworkV2/apps/wikia-worktrees
```

