---
title: "Wikia 03 Parallel Build"
type: task
status: active
---

# Wikia 03 Parallel Build

> Fresh-agent boot: read `AGENT_PROMPT.md` in this folder first.

```text
lane branch
   |
   v
small implementation
   |
   v
focused tests
   |
   v
explicit commit
```

- [ ] Catalog-state lane build. In the current worktree, implement only catalog/state changes identified in `lane-notes/catalog-state.md`. Focus on `publisher/artifacts-publisher-source/scripts/admin-db.py`, `sync-cms-state.py`, `public_catalog.py`, `build-search-index.py`, and related tests. Run focused tests. Commit with explicit paths only. EXIT.

- [ ] Render-navigation lane build. In the current worktree, implement only renderer/navigation changes identified in `lane-notes/render-navigation.md`. Focus on render scripts and `_sidebar.html.tpl`/`_appshell.html.tpl`. Run focused tests. Commit with explicit paths only. EXIT.

- [ ] Admin-ux lane build. In the current worktree, implement only admin UI fixes identified in `lane-notes/admin-ux.md`. Focus on `admin.html.tpl`, `admin-decrypt.js`, and `_admin-styles.css.tpl`. Run focused tests and capture screenshot evidence if possible. Commit with explicit paths only. EXIT.

- [ ] Security-permissions lane build. In the current worktree, implement only permission/security changes identified in `lane-notes/security-permissions.md`. Focus on vault/encryption/gate behavior and tests. Never print secrets. Commit with explicit paths only. EXIT.

- [ ] Publish-validation lane build. In the current worktree, implement only validation/publish changes identified in `lane-notes/publish-validation.md`. Focus on `publish.sh`, `validate-state.sh`, and publish tests. Commit with explicit paths only. EXIT.

