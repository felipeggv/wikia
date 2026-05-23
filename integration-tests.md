# Wikia PHASE-04 Integrated Test Evidence

Date: 2026-05-23
Worktree: `/Users/felipegobbi/Documents/VibeworkV2/apps/wikia-worktrees/improve-release-integration`
Branch: `improve/release-integration`

```text
lane merge resolution
        |
        v
syntax checks
        |
        v
publisher test suite
        |
        v
22/22 PASS
```

## Merge Coverage

Lane refs and lane commits checked in this run:

| Lane | Evidence | Result |
| --- | --- | --- |
| catalog-state | merge `50fdfa8` already in history | Preserved; no active lane ref remained after pruning. |
| render-navigation | `build/render-navigation` at `2d9b095` merged as `c1835d4` | Preserved catalog navigation behavior and resolved shared test conflicts. |
| security-permissions | `build/security-permissions` / `origin/build/security-permissions` at `0b33584` | Already ancestor of HEAD; permission/security behavior preserved. |
| admin-ux | `fix/admin-ux` / `origin/fix/admin-ux` at `5317be5` | Already ancestor of HEAD; admin locked-shell behavior preserved. |
| publish-validation | specific lane commit `d4691bf` merged as `a0d2368` | Preserved validation-mode, private-source, idempotency, and pending-apply behavior. |

`origin/main` was not merged. It was only inspected as the remote carrier for deleted lane PR refs; the actual publish-validation merge used commit `d4691bf` directly to avoid unrelated mainline changes.

No deploy commands were run.

## Syntax Checks

Commands:

```bash
find publisher/artifacts-publisher-source/scripts publisher/artifacts-publisher-source/tests -name '*.sh' -print0 | xargs -0 -n1 bash -n
find publisher/artifacts-publisher-source/scripts -name '*.py' -print0 | xargs -0 -n1 python3 -m py_compile
find publisher/artifacts-publisher-source/scripts publisher/artifacts-publisher-source/templates -name '*.mjs' -print0 | xargs -0 -n1 node --check
```

Result: PASS.

## Integrated Publisher Tests

Command:

```bash
for test_script in publisher/artifacts-publisher-source/tests/test-*.sh; do
  echo "== $test_script =="
  bash "$test_script"
done
```

Final result after the final merges: PASS, 22 test scripts passed.

## Test List

All passed:

- `publisher/artifacts-publisher-source/tests/test-admin-db.sh`
- `publisher/artifacts-publisher-source/tests/test-admin-list-from-admin-metadata.sh`
- `publisher/artifacts-publisher-source/tests/test-admin-no-unlock-safe-shell.sh`
- `publisher/artifacts-publisher-source/tests/test-admin-scoped-pending-intents.sh`
- `publisher/artifacts-publisher-source/tests/test-build-search-index-catalog.sh`
- `publisher/artifacts-publisher-source/tests/test-catalog-navigation-model.sh`
- `publisher/artifacts-publisher-source/tests/test-gate-hardening.sh`
- `publisher/artifacts-publisher-source/tests/test-migrate-to-cms-state.sh`
- `publisher/artifacts-publisher-source/tests/test-phase-07-smoke.sh`
- `publisher/artifacts-publisher-source/tests/test-public-catalog-visibility.sh`
- `publisher/artifacts-publisher-source/tests/test-publish-apply-pending.sh`
- `publisher/artifacts-publisher-source/tests/test-publish-idempotency.sh`
- `publisher/artifacts-publisher-source/tests/test-publish-private-source.sh`
- `publisher/artifacts-publisher-source/tests/test-publish-runs-state-validation.sh`
- `publisher/artifacts-publisher-source/tests/test-publish-validation.sh`
- `publisher/artifacts-publisher-source/tests/test-render-admin-cms-state.sh`
- `publisher/artifacts-publisher-source/tests/test-render-admin-sidebar-wrapper.sh`
- `publisher/artifacts-publisher-source/tests/test-security-permissions.sh`
- `publisher/artifacts-publisher-source/tests/test-sync-cms-state-atomic.sh`
- `publisher/artifacts-publisher-source/tests/test-validate-state-default-root.sh`
- `publisher/artifacts-publisher-source/tests/test-validate-state.sh`
- `publisher/artifacts-publisher-source/tests/test-vault-mjs.sh`

## Notes

- Merge conflicts were resolved in the shared test layer only; generated HTML was not edited as source of truth.
- The resolved conflicted tests support both `WIKIA_TEST_*` overrides and legacy `SOURCE_ROOT` / `TMP_PARENT` overrides.
- `origin/main` was not merged because it carries more than this integration lane.
- Deploy commands were intentionally not run.
