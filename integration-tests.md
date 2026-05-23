# Wikia PHASE-04 Integrated Test Evidence

Date: 2026-05-23
Worktree: `/Users/felipegobbi/Documents/VibeworkV2/apps/wikia-worktrees/improve-release-integration`
Branch: `improve/release-integration`
Validated code HEAD before this evidence-only update: `a799f3c`

No deploy commands were run.

```text
lane output
   |
   v
integration commits
   |
   v
syntax checks
   |
   v
22 publisher tests
   |
   v
PASS
```

## Merge Coverage

| Lane | Final integration evidence |
| --- | --- |
| catalog-state | Already present through merge commit `50fdfa8`; active lane refs were pruned/missing. |
| render-navigation | Merged through integration commit `c1835d4`; `build/render-navigation` is contained by `improve/release-integration`. |
| security-permissions | `build/security-permissions` is contained by `improve/release-integration`. |
| publish-validation | Merged through publish-validation lane carrier commit `d4691bf` and final integration commit `a0d2368`. |
| admin-ux | `fix/admin-ux` is contained by `improve/release-integration`. |

## Conflict Check

Command:

```bash
git diff --name-only --diff-filter=U
```

Result: PASS, no conflicted paths.

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

Final result: PASS, `22/22` test scripts passed.

## Test Results

| Test | Result |
| --- | --- |
| `publisher/artifacts-publisher-source/tests/test-admin-db.sh` | PASS |
| `publisher/artifacts-publisher-source/tests/test-admin-list-from-admin-metadata.sh` | PASS |
| `publisher/artifacts-publisher-source/tests/test-admin-no-unlock-safe-shell.sh` | PASS |
| `publisher/artifacts-publisher-source/tests/test-admin-scoped-pending-intents.sh` | PASS |
| `publisher/artifacts-publisher-source/tests/test-build-search-index-catalog.sh` | PASS |
| `publisher/artifacts-publisher-source/tests/test-catalog-navigation-model.sh` | PASS |
| `publisher/artifacts-publisher-source/tests/test-gate-hardening.sh` | PASS |
| `publisher/artifacts-publisher-source/tests/test-migrate-to-cms-state.sh` | PASS |
| `publisher/artifacts-publisher-source/tests/test-phase-07-smoke.sh` | PASS |
| `publisher/artifacts-publisher-source/tests/test-public-catalog-visibility.sh` | PASS |
| `publisher/artifacts-publisher-source/tests/test-publish-apply-pending.sh` | PASS |
| `publisher/artifacts-publisher-source/tests/test-publish-idempotency.sh` | PASS |
| `publisher/artifacts-publisher-source/tests/test-publish-private-source.sh` | PASS |
| `publisher/artifacts-publisher-source/tests/test-publish-runs-state-validation.sh` | PASS |
| `publisher/artifacts-publisher-source/tests/test-publish-validation.sh` | PASS |
| `publisher/artifacts-publisher-source/tests/test-render-admin-cms-state.sh` | PASS |
| `publisher/artifacts-publisher-source/tests/test-render-admin-sidebar-wrapper.sh` | PASS |
| `publisher/artifacts-publisher-source/tests/test-security-permissions.sh` | PASS |
| `publisher/artifacts-publisher-source/tests/test-sync-cms-state-atomic.sh` | PASS |
| `publisher/artifacts-publisher-source/tests/test-validate-state-default-root.sh` | PASS |
| `publisher/artifacts-publisher-source/tests/test-validate-state.sh` | PASS |
| `publisher/artifacts-publisher-source/tests/test-vault-mjs.sh` | PASS |

## Notes

- Deploy and promotion commands were intentionally not run.
- No plaintext private source was added by this validation step.
- Integration validation touched evidence only; feature behavior was not changed by this evidence update.
