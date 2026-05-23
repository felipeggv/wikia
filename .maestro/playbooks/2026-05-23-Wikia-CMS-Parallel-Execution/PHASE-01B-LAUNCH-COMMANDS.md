---
title: "Wikia 01B Launch Commands"
type: task
status: active
---

# Wikia 01B Launch Commands

> Fresh-agent boot: read `AGENT_PROMPT.md` in this folder first.

```text
validated lanes
   |
   v
safe launch commands
   |
   v
human/operator starts parallel work
```

- [ ] Produce launch commands for all lane playbooks. Read `/Users/felipegobbi/Documents/VibeworkV2/apps/wikia/.maestro/playbooks/2026-05-23-Wikia-CMS-Parallel-Execution/manifest.json`, `/Users/felipegobbi/Documents/VibeworkV2/apps/wikia/.maestro/state/worktrees.md`, and `/Users/felipegobbi/Documents/VibeworkV2/apps/wikia/.maestro/state/agents.md`. Generate `/Users/felipegobbi/Documents/VibeworkV2/apps/wikia/.maestro/state/launch-commands.md` with one `maestro-cli auto-run --launch --agent <id>` command per implementation lane, using each lane's existing isolated worktree path and branch. Do not launch any lane Auto Run. Mark this checkbox complete and add a one-line result. Commit only the playbook checkbox/result update if needed. Stop after this task.
