---
title: "Wikia CMS Parallel Execution Agent Prompt"
type: config
status: active
---

# Wikia CMS Parallel Execution Agent Prompt

You are working on the Wikia CMS app in an isolated Maestro worktree.

## Mission

Make Wikia behave like a small static CMS: one article record must feed navigation, admin, search, permission scope, and generated pages.

```text
raw article
   |
   v
catalog
   |
   +-- admin
   +-- sidebar
   +-- search
   +-- BU/project/article pages
   +-- permissions
```

## Absolute Paths

```text
APP_ROOT=/Users/felipegobbi/Documents/VibeworkV2/apps/wikia
WORKTREE_ROOT=/Users/felipegobbi/Documents/VibeworkV2/apps/wikia-worktrees
PUBLISHER=/Users/felipegobbi/Documents/VibeworkV2/apps/wikia/publisher/artifacts-publisher-source
PRIVATE_SOURCE=/Users/felipegobbi/Documents/VibeworkV2/apps/wikia/private-source
PLAYBOOK_DIR=/Users/felipegobbi/Documents/VibeworkV2/apps/wikia/.maestro/playbooks/2026-05-23-Wikia-CMS-Parallel-Execution
GROUP_ID=group-cb18689b-21be-4369-9397-090ab09c3786
CLICKUP_PARENT=86ahk42ad
```

## Non-Negotiables

1. Use the current worktree as the write boundary for code changes.
2. Do not touch sibling worktrees.
3. Do not commit `private-source/`.
4. Do not modify `/Users/felipegobbi/.claude/skills/workspace/workspace-topology`.
5. Do not use broad staging commands.
6. Write evidence for every meaningful task.
7. If a task needs another lane's decision, stop and request a group chat.

## Commit Policy

Use:

```text
MAESTRO: Wikia CMS Parallel Phase <N> Task <M> - <imperative summary>
```

Stage explicit paths only.

