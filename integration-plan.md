# Wikia PHASE-04 Integration Plan

Date: 2026-05-23
Worktree: `/Users/felipegobbi/Documents/VibeworkV2/apps/wikia-worktrees/improve-release-integration`
Integration branch: `improve/release-integration`
HEAD before this run's merge step: `56c0e40`
Plan commit before merge step: `281f53e`
HEAD before publish-validation merge step: `c1835d4`

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

A second ref check during execution showed that `origin/build/render-navigation`
and `origin/fix/publish-validation` were deleted after their pull requests
landed in `origin/main`. To keep this integration scoped, this run merged the
local render-navigation lane ref and the specific publish-validation lane commit
`d4691bf` instead of merging all of `origin/main`.

## Branch Inputs After Fetch

`HEAD-only / ref-only` comes from `git rev-list --left-right --count HEAD...<ref>`.

| Lane | Local branch | Origin branch | Current state | Decision |
| --- | --- | --- | --- | --- |
| catalog-state | missing | missing | Active lane refs are pruned/missing; catalog-state content is already present through merge `50fdfa8`. | No direct lane ref remains to merge. |
| render-navigation | `build/render-navigation` at `2d9b095` | pruned after PR landing | Local ref merged as `c1835d4`; key render-navigation lane commits are now ancestors of HEAD. | Merge local ref and keep catalog-navigation behavior. |
| security-permissions | `build/security-permissions` at `0b33584` | `origin/build/security-permissions` at `0b33584` | Both refs are ancestors of HEAD after the render merge. | Merge/check both; expected no-op. |
| publish-validation | local ref pruned during execution | pruned after PR landing | Specific lane merge commit `d4691bf` remains available locally. | Merge `d4691bf` directly to avoid pulling unrelated `origin/main` changes. |
| admin-ux | `fix/admin-ux` at `5317be5` | `origin/fix/admin-ux` at `5317be5` | Both refs are ancestors of HEAD after the render merge. | Merge/check both; expected no-op. |

## Merge Order

1. `build/render-navigation`
2. `d4691bf` publish-validation lane merge commit
3. `origin/build/security-permissions`
4. `build/security-permissions`
5. `origin/fix/admin-ux`
6. `fix/admin-ux`

## Conflict Forecast

`git merge-tree --write-tree HEAD build/render-navigation` predicted conflicts in the shared test layer:

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

After the render merge, merging `d4691bf` opened conflicts in the shared publish-validation test layer:

| File | Expected resolution principle |
| --- | --- |
| `publisher/artifacts-publisher-source/tests/test-phase-07-smoke.sh` | Preserve current integrated smoke flow and accept publish-validation expectations. |
| `publisher/artifacts-publisher-source/tests/test-publish-apply-pending.sh` | Preserve secure pending-apply behavior and repo-relative temp roots. |
| `publisher/artifacts-publisher-source/tests/test-publish-idempotency.sh` | Preserve idempotency coverage while accepting publish-validation fixtures. |
| `publisher/artifacts-publisher-source/tests/test-publish-private-source.sh` | Preserve private-source safety checks. |
| `publisher/artifacts-publisher-source/tests/test-publish-validation.sh` | Preserve validation-mode no-push guarantees and secret-handling checks. |
| `publisher/artifacts-publisher-source/tests/test-validate-state.sh` | Preserve validation coverage for privacy, catalog/search drift, and stale sidebar counts. |

No conflicts are forecast for the security or admin-ux refs because they are already ancestors of the current integration branch.

## Merge Result

```text
render-navigation merge
        |
        v
publish-validation merge
        |
        v
security/admin already ancestors
```

Completed merge results:

| Input | Result |
| --- | --- |
| `build/render-navigation` at `2d9b095` | Merged as `c1835d4`; conflicts resolved in shared test headers and temp-root setup. |
| publish-validation lane commit `d4691bf` | Merged as `a0d2368`; conflicts resolved in publish/validation tests. |
| `build/security-permissions` / `origin/build/security-permissions` at `0b33584` | Already ancestor of HEAD after the merges. |
| `fix/admin-ux` / `origin/fix/admin-ux` at `5317be5` | Already ancestor of HEAD after the merges. |
| catalog-state | Already present through `50fdfa8`; no active lane ref remained. |

`origin/main` was not merged. The publish-validation lane commit was merged
directly to avoid pulling unrelated mainline changes.

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
