---
title: "Wikia 01 Scaffold Lanes"
type: task
status: active
---

# Wikia 01 Scaffold Lanes

> Fresh-agent boot: read `AGENT_PROMPT.md` in this folder first.

```text
main app repo
   |
   +-- worktree per branch
   |
   v
agent per worktree
```

- [ ] Validate all Wikia worktrees exist and match the manifest. Read `/Users/felipegobbi/Documents/VibeworkV2/apps/wikia/.maestro/playbooks/2026-05-23-Wikia-CMS-Parallel-Execution/manifest.json`, run `git -C /Users/felipegobbi/Documents/VibeworkV2/apps/wikia worktree list`, and write `/Users/felipegobbi/Documents/VibeworkV2/apps/wikia/.maestro/state/worktrees.md` with branch, path, and HEAD for each lane. Do not create or remove worktrees. EXIT.

- [ ] Validate Maestro agents in group `[3] GOBBI/WIKIA`. Run `maestro-cli list agents --group group-cb18689b-21be-4369-9397-090ab09c3786 --json`, map each agent name to a lane in the manifest, and write `/Users/felipegobbi/Documents/VibeworkV2/apps/wikia/.maestro/state/agents.md`. Do not create or remove agents. EXIT.

- [ ] Produce launch commands for all lane playbooks. Generate `/Users/felipegobbi/Documents/VibeworkV2/apps/wikia/.maestro/state/launch-commands.md` with one `maestro-cli auto-run --launch --agent <id>` command per lane, using each worktree path and branch. Do not launch Auto Run. EXIT.

