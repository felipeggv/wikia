---
title: "Wikia 02 Parallel Discovery"
type: task
status: active
---

# Wikia 02 Parallel Discovery

> Fresh-agent boot: read `AGENT_PROMPT.md` in this folder first.

```text
independent lane discovery
   |
   v
contract notes
   |
   v
group chat if interfaces conflict
```

- [ ] Catalog-state lane: inspect catalog, admin DB, search, and sync scripts. Target branch `build/catalog-state`. Read only files under `publisher/artifacts-publisher-source/scripts` relevant to catalog generation. Write `lane-notes/catalog-state.md` in the current worktree with ownership, risks, and proposed changes. Do not edit implementation code. EXIT.

- [ ] Render-navigation lane: inspect renderers and navigation templates. Target branch `build/render-navigation`. Read only renderer scripts and app shell/sidebar templates. Write `lane-notes/render-navigation.md` in the current worktree. Do not edit implementation code. EXIT.

- [ ] Admin-ux lane: inspect admin template, admin decrypt JS, and admin CSS. Target branch `fix/admin-ux`. Write `lane-notes/admin-ux.md` in the current worktree with visual risk and required screenshot checks. Do not edit implementation code. EXIT.

- [ ] Security-permissions lane: inspect vault, encryption, gate, and permission scope flows. Target branch `build/security-permissions`. Write `lane-notes/security-permissions.md` in the current worktree. Do not print or request secret values. EXIT.

- [ ] Publish-validation lane: inspect `publish.sh`, validation tests, and smoke tests. Target branch `fix/publish-validation`. Write `lane-notes/publish-validation.md` in the current worktree. Do not edit implementation code. EXIT.

