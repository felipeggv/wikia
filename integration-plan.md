# Wikia PHASE-04 Integration Plan

Date: 2026-05-23
Worktree: `/Users/felipegobbi/Documents/VibeworkV2/apps/wikia-worktrees/improve-release-integration`
Integration branch: `improve/release-integration`
Current HEAD while writing this plan: `26c77670a696`

```text
local lane refs + origin refs
        |
        v
write integration plan first
        |
        v
merge/check each approved input
        |
        v
syntax checks + full publisher tests
        |
        v
no deploy
```

## Scope

Run PHASE-04 without deploy:

1. Review local Wikia lane branches and origin branches.
2. Write this `integration-plan.md` before merge commands executed in this run.
3. Merge or confirm already-merged lane outputs into `improve/release-integration`.
4. Run syntax checks after the merge/check step.
5. Run the full publisher test suite under `publisher/artifacts-publisher-source/tests`.
6. Do not deploy.

## Fetch Evidence

Command run before writing this plan:

```bash
git fetch --all --prune
```

The fetch completed successfully and showed these active lane-related refs:

| Lane | Local ref | Origin ref | State against `HEAD` |
| --- | --- | --- | --- |
| catalog-state | missing | missing | Already integrated earlier through merge `50fdfa8`; origin PR content is also in `origin/main`. |
| render-navigation | `build/render-navigation` at `2d9b095` | missing | Local ref is already an ancestor of `HEAD`. |
| security-permissions | `build/security-permissions` at `0b33584` | `origin/build/security-permissions` at `0b33584` | Both refs are already ancestors of `HEAD`. |
| publish-validation | missing | missing | Lane branch is pruned; content is already represented through lane carrier `d4691bf`, integration merge `a0d2368`, and `origin/main`. |
| admin-ux | `fix/admin-ux` at `5317be5` | `origin/fix/admin-ux` at `5317be5` | Both refs are already ancestors of `HEAD`. |
| origin mainline carrier | n/a | `origin/main` at `9ba2959` | Already merged into current `HEAD` by merge commit `26c7767`. |

## Important State Note

While preparing this run, `git reflog` showed that `HEAD` was already at
`26c7767`, a merge commit with message:

```text
Merge remote-tracking branch 'origin/main' into improve/release-integration
```

That merge commit has the same tree as the previous integration evidence commit
`aa678f1`, so it did not change working-tree content. This plan records that
state instead of rewinding it.

## Merge Order

The merge/check step will use both local lane refs and origin refs where they
exist. Missing pruned lane refs will be documented, not recreated.

1. `origin/main`
2. `build/render-navigation`
3. `build/security-permissions`
4. `origin/build/security-permissions`
5. `fix/admin-ux`
6. `origin/fix/admin-ux`

Expected result: all merge commands should report already up to date because the
listed refs are ancestors of `HEAD`.

## Conflict Forecast

No new conflicts are expected in this run.

Reason:

```text
each active lane ref
        |
        v
is ancestor of current HEAD
        |
        v
merge/check should be no-op
```

The prior PHASE-04 conflict history remains relevant context:

| Previous conflict area | Resolution principle already present in integration branch |
| --- | --- |
| Shared admin and publish shell tests | Preserve repo-relative temp roots, admin safety checks, and publish validation guarantees. |
| Navigation and sidebar tests | Preserve catalog-driven navigation while preventing duplicate sidebar wrappers. |
| Security tests | Preserve gate hardening, scope validation, no plaintext temp residue, and no admin-scope public catalog leaks. |

## Validation Plan

Syntax checks:

```bash
find publisher/artifacts-publisher-source/scripts publisher/artifacts-publisher-source/tests -name '*.sh' -print0 | xargs -0 -n1 bash -n
find publisher/artifacts-publisher-source/scripts -name '*.py' -print0 | xargs -0 -n1 python3 -m py_compile
find publisher/artifacts-publisher-source/scripts publisher/artifacts-publisher-source/templates -name '*.mjs' -print0 | xargs -0 -n1 node --check
```

Integrated publisher tests:

```bash
set -u
failed=0
count=0
for test_script in publisher/artifacts-publisher-source/tests/test-*.sh; do
  count=$((count + 1))
  printf 'RUN %s\n' "$test_script"
  output="$(bash "$test_script" 2>&1)"
  exit_code=$?
  if [[ $exit_code -eq 0 ]]; then
    printf 'PASS %s\n' "$test_script"
  else
    printf 'FAIL %s exit=%s\n%s\n' "$test_script" "$exit_code" "$output"
    failed=1
    break
  fi
done
printf 'TOTAL_RUN %s\n' "$count"
exit "$failed"
```

Deploy commands are intentionally excluded.
