# Wikia PHASE-04 Integrated Test Evidence

Date: 2026-05-23
Worktree: `/Users/felipegobbi/Documents/VibeworkV2/apps/wikia-worktrees/improve-release-integration`
Branch: `improve/release-integration`

```text
lane refs already merged
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

Lane refs checked and merged in this run:

- `origin/build/render-navigation`
- `build/render-navigation`
- `origin/build/security-permissions`
- `build/security-permissions`
- `origin/fix/publish-validation`
- `fix/publish-validation`
- `origin/fix/admin-ux`
- `fix/admin-ux`

Catalog-state was already present through merge commit `50fdfa8`; no active local or origin catalog-state lane ref exists after fetch/prune.

Result: every active lane merge returned `Already up to date.` No deploy commands were run.

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

Final result: PASS, 22 test scripts passed.

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

- `origin/main` was not merged because it is not a lane ref for this integration step.
- `fix/publish-validation` local is ahead of `origin/fix/publish-validation` by one lane commit, and that local commit is already integrated.
- Deploy commands were intentionally not run.
