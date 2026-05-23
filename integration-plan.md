# Wikia PHASE-04 Integration Plan

Date: 2026-05-23
Worktree: `/Users/felipegobbi/Documents/VibeworkV2/apps/wikia-worktrees/improve-release-integration`
Integration branch: `improve/release-integration`

```text
lane branches
     |
     v
improve/release-integration
     |
     v
publisher syntax checks
     |
     v
integrated test suite
```

## Scope

Run PHASE-04 without deploy:

1. Fetch and review all Wikia lane branches.
2. Merge lane outputs into `improve/release-integration`.
3. Run syntax checks after each merge.
4. Run the integrated publisher test suite under `publisher/artifacts-publisher-source/tests`.

## Branch Inputs

| Lane | Local branch | Origin branch | Local vs origin |
| --- | --- | --- | --- |
| catalog-state | `build/catalog-state` | `origin/build/catalog-state` | same commit |
| render-navigation | `build/render-navigation` | `origin/build/render-navigation` | same commit |
| security-permissions | `build/security-permissions` | `origin/build/security-permissions` | same commit |
| publish-validation | `fix/publish-validation` | `origin/fix/publish-validation` | local was 1 commit ahead |
| admin-ux | `fix/admin-ux` | `origin/fix/admin-ux` | same commit |

## Merge Order

1. `build/catalog-state`
2. `build/render-navigation`
3. `build/security-permissions`
4. `origin/fix/publish-validation`
5. `fix/publish-validation`
6. `fix/admin-ux`

This order put catalog contracts first, navigation second, security and publish validation next, and admin UX last.

## Conflict Forecast And Actual Resolution

Initial `git merge-tree --write-tree HEAD <branch>` checks returned clean trees for each lane in isolation. Sequential integration still produced header and expectation conflicts because multiple lanes touched the same tests.

Resolved conflict areas:

| Area | Resolution |
| --- | --- |
| Test temp roots | Kept configurable test roots and isolated temp directories. |
| Catalog hashes | Updated fixtures to use valid SHA-256 `raw_hash` values. |
| Admin scope navigation | Chose safer behavior: admin scope falls back to the current article instead of expanding public navigation. |
| Admin UX smoke marker | Updated smoke assertion to the current admin copy while preserving the encrypted `_admin.enc` contract. |
| Security fixtures | Added required catalog fields so stricter schema validation and security assertions both pass. |

## Post-Merge Checks

Syntax checks used:

```bash
find publisher/artifacts-publisher-source/scripts publisher/artifacts-publisher-source/tests -name '*.sh' -print0 | xargs -0 -n1 bash -n
find publisher/artifacts-publisher-source/scripts -name '*.py' -print0 | xargs -0 -n1 python3 -m py_compile
find publisher/artifacts-publisher-source/scripts publisher/artifacts-publisher-source/templates -name '*.mjs' -print0 | xargs -0 -n1 node --check
```

Integrated tests used:

```bash
for test_script in publisher/artifacts-publisher-source/tests/test-*.sh; do
  bash "$test_script"
done
```

Final result: 22 publisher tests passed. No deploy commands were run.
