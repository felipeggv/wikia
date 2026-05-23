# Wikia PHASE-04 Integration Plan

Date: 2026-05-23
Worktree: `/Users/felipegobbi/Documents/VibeworkV2/apps/wikia-worktrees/improve-release-integration`
Integration branch: `improve/release-integration`
HEAD before this run: `56fa9cf`

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

1. Fetch and review all Wikia lane branches.
2. Write this integration plan before merge commands.
3. Merge lane outputs into `improve/release-integration`.
4. Run syntax checks.
5. Run the integrated publisher test suite under `publisher/artifacts-publisher-source/tests`.

## Branch Inputs

The branch comparison below was checked after `git fetch --all --prune`.
`HEAD-only / ref-only` means commits only on the integration branch versus commits only on that ref.

| Lane | Local ref | Origin ref | HEAD-only / ref-only | Decision |
| --- | --- | --- | --- | --- |
| catalog-state | no active local lane ref | no active origin lane ref | already covered by merge `50fdfa8` | Do not merge `origin/main`; catalog-state content is already integrated and `origin/main` also carries non-lane orchestration commits. |
| render-navigation | `build/render-navigation` | `origin/build/render-navigation` | `22 / 0` for both | Merge origin and local refs; expected no-op. |
| security-permissions | `build/security-permissions` | `origin/build/security-permissions` | `22 / 0` for both | Merge origin and local refs; expected no-op. |
| publish-validation | `fix/publish-validation` | `origin/fix/publish-validation` | local `24 / 0`, origin `25 / 0` | Merge origin first, then local; local has one extra lane commit and both are already integrated. |
| admin-ux | `fix/admin-ux` | `origin/fix/admin-ux` | `24 / 0` for both | Merge origin and local refs; expected no-op. |

## Merge Order

1. Verify catalog-state is already present through merge commit `50fdfa8`.
2. `origin/build/render-navigation`
3. `build/render-navigation`
4. `origin/build/security-permissions`
5. `build/security-permissions`
6. `origin/fix/publish-validation`
7. `fix/publish-validation`
8. `origin/fix/admin-ux`
9. `fix/admin-ux`

## Merge Result

Each active lane merge reported `Already up to date.` No conflicts were opened and no deploy commands were run.

```text
lane refs
   |
   v
already ancestors of HEAD
   |
   v
merge commands changed no source files
```

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
  echo "== $test_script =="
  bash "$test_script"
done
```

Final validation result: 22 publisher tests passed.
