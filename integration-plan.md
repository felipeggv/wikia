# Wikia PHASE-04 Integration Plan

Date: 2026-05-23
Worktree: `/Users/felipegobbi/Documents/VibeworkV2/apps/wikia-worktrees/improve-release-integration`
Integration branch: `improve/release-integration`
HEAD before this run's merge step: `56c0e40`

```text
local lane refs + origin lane refs
        |
        v
integration plan first
        |
        v
merge into improve/release-integration
        |
        v
syntax checks + integrated publisher tests
```

## Scope

Run PHASE-04 without deploy:

1. Fetch and review local Wikia lane branches plus origin lane branches.
2. Write this `integration-plan.md` before merge commands.
3. Merge lane outputs into `improve/release-integration`.
4. Run syntax checks after merge resolution.
5. Run the integrated publisher test suite under `publisher/artifacts-publisher-source/tests`.
6. Do not deploy.

## Fetch Evidence

Command run before this plan:

```bash
git fetch --all --prune
```

## Branch Inputs After Fetch

`HEAD-only / ref-only` comes from `git rev-list --left-right --count HEAD...<ref>`.

| Lane | Local branch | Origin branch | Current state | Decision |
| --- | --- | --- | --- | --- |
| catalog-state | missing | missing | Active lane refs are pruned/missing; catalog-state content is already present through merge `50fdfa8`. | Do not merge `main`/`origin/main`; they are not lane refs for this phase. |
| render-navigation | `build/render-navigation` at `2d9b095` | `origin/build/render-navigation` at `2d9b095` | `20 / 20`; both refs match each other but diverge from current integration HEAD. | Merge `origin/build/render-navigation` first, then confirm local branch is no-op. |
| security-permissions | `build/security-permissions` at `0b33584` | `origin/build/security-permissions` at `0b33584` | `25 / 0`; both refs already ancestors of HEAD. | Merge/check both; expected no-op. |
| publish-validation | `fix/publish-validation` at `d331d89` | `origin/fix/publish-validation` at `4431b20` | local `27 / 0`, origin `28 / 0`; both already ancestors of HEAD. | Merge/check origin then local; expected no-op. |
| admin-ux | `fix/admin-ux` at `5317be5` | `origin/fix/admin-ux` at `5317be5` | `27 / 0`; both refs already ancestors of HEAD. | Merge/check both; expected no-op. |

## Merge Order

1. `origin/build/render-navigation`
2. `build/render-navigation`
3. `origin/build/security-permissions`
4. `build/security-permissions`
5. `origin/fix/publish-validation`
6. `fix/publish-validation`
7. `origin/fix/admin-ux`
8. `fix/admin-ux`

## Conflict Forecast

`git merge-tree --write-tree HEAD origin/build/render-navigation` predicts conflicts in the shared test layer:

| File | Expected resolution principle |
| --- | --- |
| `publisher/artifacts-publisher-source/tests/test-admin-no-unlock-safe-shell.sh` | Preserve integrated admin safety assertions and repo-relative temp roots. |
| `publisher/artifacts-publisher-source/tests/test-phase-07-smoke.sh` | Preserve current integrated smoke contract while accepting render-navigation-compatible fixtures where needed. |
| `publisher/artifacts-publisher-source/tests/test-publish-validation.sh` | Preserve stricter publish validation from the integrated branch and keep tests portable. |
| `publisher/artifacts-publisher-source/tests/test-render-admin-cms-state.sh` | Preserve admin CMS-state expectations from the integrated branch. |
| `publisher/artifacts-publisher-source/tests/test-render-admin-sidebar-wrapper.sh` | Preserve one-wrapper sidebar assertions and integrate the catalog navigation helper expectations. |
| `publisher/artifacts-publisher-source/tests/test-validate-state.sh` | Preserve validation coverage for catalog/search/sidebar drift and privacy checks. |

```text
render-navigation ref
        |
        v
shared navigation helper + tests
        |
        v
conflicts against integrated test expectations
        |
        v
resolve to keep both navigation model and integrated safety contracts
```

No conflicts are forecast for the security, publish-validation, or admin-ux refs because they are already ancestors of the current integration branch.

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
