# Wikia PHASE-04 Integrated Test Evidence

Date: 2026-05-23
Worktree: `/Users/felipegobbi/Documents/VibeworkV2/apps/wikia-worktrees/improve-release-integration`
Branch: `improve/release-integration`

```text
merged lanes
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

Merged lane refs:

- `build/catalog-state`
- `build/render-navigation`
- `build/security-permissions`
- `origin/fix/publish-validation`
- `fix/publish-validation`
- `fix/admin-ux`

No deploy commands were run.

## Syntax Checks

Command run after merges and conflict resolutions:

```bash
find publisher/artifacts-publisher-source/scripts publisher/artifacts-publisher-source/tests -name '*.sh' -print0 | xargs -0 -n1 bash -n
find publisher/artifacts-publisher-source/scripts -name '*.py' -print0 | xargs -0 -n1 python3 -m py_compile
find publisher/artifacts-publisher-source/scripts publisher/artifacts-publisher-source/templates -name '*.mjs' -print0 | xargs -0 -n1 node --check
```

Result: PASS.

## Integrated Publisher Tests

Final command:

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

Final result: PASS, `TOTAL_RUN 22`.

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

## Integration Fixes Made During Validation

- Updated navigation fixtures to use valid SHA-256 `raw_hash` values required by the catalog contract.
- Aligned admin scope expectations to the safer integrated behavior: admin scope falls back to the current article instead of expanding public navigation.
- Updated the smoke test admin-copy marker to the current admin UX contract text.
- Updated security validation fixtures so catalog records satisfy the stricter catalog schema while still proving `admin` scope is rejected in public output.
