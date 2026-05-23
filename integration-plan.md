# Wikia PHASE-04 Integration Plan

Date: 2026-05-23
Worktree: `/Users/felipegobbi/Documents/VibeworkV2/apps/wikia-worktrees/improve-release-integration`
Integration branch: `improve/release-integration`
Current HEAD before this run: `56fa9cf`

```text
lane refs, local and origin
        |
        v
improve/release-integration
        |
        v
syntax checks
        |
        v
integrated publisher tests
```

## Scope

Run PHASE-04 without deploy:

1. Review lane outputs from local branches and origin branches.
2. Write this integration plan before merge commands.
3. Merge lane refs into `improve/release-integration`.
4. Run syntax checks and integrated publisher tests.
5. Do not deploy.

## Branch Inputs

The branch comparison below was taken after `git fetch --all --prune`.
`HEAD-only / ref-only` means commits only on the integration branch versus commits only on that ref.

| Lane | Local ref | Origin ref | HEAD-only / ref-only | Decision |
| --- | --- | --- | --- | --- |
| catalog-state | no active local ref | no active origin lane ref | covered by merge `50fdfa8` | Do not merge `origin/main`; catalog lane content is already in this branch, while `origin/main` also carries non-lane orchestration commits. |
| render-navigation | `build/render-navigation` | `origin/build/render-navigation` | `22 / 0` for both | Merge local and origin refs; expected no-op because both are already ancestors. |
| security-permissions | `build/security-permissions` | `origin/build/security-permissions` | `22 / 0` for both | Merge local and origin refs; expected no-op because both are already ancestors. |
| publish-validation | `fix/publish-validation` | `origin/fix/publish-validation` | local `24 / 0`, origin `25 / 0` | Merge origin first, then local; local contains one commit not pushed to origin and is already integrated. |
| admin-ux | `fix/admin-ux` | `origin/fix/admin-ux` | `24 / 0` for both | Merge local and origin refs; expected no-op because both are already ancestors. |

## Merge Order

1. Verify catalog-state is already present through `50fdfa8`.
2. `origin/build/render-navigation`
3. `build/render-navigation`
4. `origin/build/security-permissions`
5. `build/security-permissions`
6. `origin/fix/publish-validation`
7. `fix/publish-validation`
8. `origin/fix/admin-ux`
9. `fix/admin-ux`

## Conflict Forecast

No new conflicts are expected for active lane refs because each listed lane ref is already an ancestor of `HEAD`.

```text
lane ref
   |
   v
already inside HEAD
   |
   v
merge command should report "Already up to date."
```

If a merge unexpectedly opens conflicts, resolve only generated publisher/test integration conflicts inside this worktree, run syntax checks again, and avoid deploy commands.

## Validation Plan

Syntax checks:

```bash
find publisher/artifacts-publisher-source/scripts publisher/artifacts-publisher-source/tests -name '*.sh' -print0 | xargs -0 -n1 bash -n
find publisher/artifacts-publisher-source/scripts -name '*.py' -print0 | xargs -0 -n1 python3 -m py_compile
find publisher/artifacts-publisher-source/scripts publisher/artifacts-publisher-source/templates -name '*.mjs' -print0 | xargs -0 -n1 node --check
```

Integrated publisher tests:

```bash
for test_script in publisher/artifacts-publisher-source/tests/test-*.sh; do
  bash "$test_script"
done
```

Deploy commands are intentionally excluded.
