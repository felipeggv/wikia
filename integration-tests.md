# Wikia PHASE-04 Integrated Test Evidence

Date: 2026-05-23
Worktree: `/Users/felipegobbi/Documents/VibeworkV2/apps/wikia-worktrees/improve-release-integration`
Branch: `improve/release-integration`
Validated code HEAD: `26c7767`
Test log: `/Users/felipegobbi/Documents/VibeworkV2/apps/wikia-worktrees/improve-release-integration/.maestro/state/integration-test-logs/20260523-094846/summary.txt`

No deploy commands were run.

```text
lane refs + origin carrier
        |
        v
merge/check complete
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

| Lane/input | Final integration evidence |
| --- | --- |
| `catalog-state` | Already present through merge commit `50fdfa8`; active lane refs are pruned/missing. |
| `render-navigation` | Local ref `build/render-navigation` is contained through merge commit `c1835d4`; origin PR merge is represented through `origin/main`. |
| `security-permissions` | Local `build/security-permissions` and `origin/build/security-permissions` are contained by `improve/release-integration`. |
| `publish-validation` | Lane branch is pruned; content is contained through carrier `d4691bf`, integration merge `a0d2368`, and `origin/main`. |
| `admin-ux` | Local `fix/admin-ux` and `origin/fix/admin-ux` are contained by `improve/release-integration`. |
| `origin/main` | Merged as carrier commit `26c7767`; no file-level diff from pre-merge `aa678f1`. |

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
run_id="$(date +%Y%m%d-%H%M%S)"
log_dir=".maestro/state/integration-test-logs/${run_id}"
mkdir -p "$log_dir"
summary="$log_dir/summary.txt"
failed=0
count=0
for test_script in publisher/artifacts-publisher-source/tests/test-*.sh; do
  count=$((count + 1))
  name="$(basename "$test_script")"
  printf 'RUN %s\n' "$test_script" | tee -a "$summary"
  if bash "$test_script" > "$log_dir/${name}.out" 2> "$log_dir/${name}.err"; then
    printf 'PASS %s\n' "$test_script" | tee -a "$summary"
  else
    exit_code=$?
    printf 'FAIL %s exit=%s\n' "$test_script" "$exit_code" | tee -a "$summary"
    failed=1
    break
  fi
done
printf 'TOTAL_RUN %s\n' "$count" | tee -a "$summary"
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
- Existing untracked handoff drafts were left untouched.
