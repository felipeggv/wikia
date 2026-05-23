---
type: report
title: Wikia PHASE-04 Integrated Test Evidence
created: 2026-05-23
tags:
  - wikia-cms
  - phase-04
  - integration
  - validation
related:
  - '[[PHASE-04-INTEGRATION]]'
  - '[[PHASE-04C-FINISH-INTEGRATION-TESTS]]'
---

# Wikia PHASE-04 Integrated Test Evidence

Date: 2026-05-23
Worktree: `/Users/felipegobbi/Documents/VibeworkV2/apps/wikia-worktrees/improve-release-integration`
Branch: `improve/release-integration`
Validated code HEAD before this evidence-only update: `a6357efbb033cdd9ac0fb065f63a8e36bd7830a0`
Test log: `/Users/felipegobbi/Documents/VibeworkV2/apps/wikia-worktrees/improve-release-integration/.maestro/state/integration-test-logs/20260523-154535/summary.txt`

No deploy commands were run.
On 2026-05-23T15:46:16-0300, the syntax checks and full publisher suite were rerun on HEAD `a6357efbb033cdd9ac0fb065f63a8e36bd7830a0`.

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

## Current HEAD Revalidation

| Check | Result |
| --- | --- |
| Validated code HEAD | `a6357efbb033cdd9ac0fb065f63a8e36bd7830a0` |
| Conflicted paths | PASS, none found |
| Shell syntax | PASS |
| Python compile | PASS |
| Node `.mjs` syntax | PASS |
| Publisher tests | PASS, `22/22` |
| `validate-state.sh --json` | PASS, `ok: true`, `issue_count: 0` |
| `_catalog.json` | PASS, `8` records |
| `search.json` | PASS, `4` records |
| `_released.json` | PASS, `0` records |
| `docs/gitpages/**/*.html` | `21` pages |
| `private-source` tracked by Git | PASS, no files |

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
LOG_ROOT=".maestro/state/integration-test-logs"
RUN_ID="$(date +%Y%m%d-%H%M%S)"
LOG_DIR="$LOG_ROOT/$RUN_ID"
mkdir -p "$LOG_DIR" ".tmp/wikia-runtime-tmp"
SUMMARY="$LOG_DIR/summary.txt"
: > "$SUMMARY"
printf 'RUN_ID %s\n' "$RUN_ID" | tee -a "$SUMMARY"
printf 'HEAD %s\n' "$(git rev-parse HEAD)" | tee -a "$SUMMARY"
printf 'BRANCH %s\n' "$(git branch --show-current)" | tee -a "$SUMMARY"
printf 'COMMAND git diff --name-only --diff-filter=U\n' | tee -a "$SUMMARY"
if git diff --name-only --diff-filter=U > "$LOG_DIR/conflicts.out" 2> "$LOG_DIR/conflicts.err" && [ ! -s "$LOG_DIR/conflicts.out" ]; then
  printf 'PASS conflict-check\n' | tee -a "$SUMMARY"
else
  printf 'FAIL conflict-check\n' | tee -a "$SUMMARY"
  exit 1
fi
printf 'COMMAND find publisher/artifacts-publisher-source/scripts publisher/artifacts-publisher-source/tests -name '\''*.sh'\'' -print0 | xargs -0 -n1 bash -n\n' | tee -a "$SUMMARY"
if find publisher/artifacts-publisher-source/scripts publisher/artifacts-publisher-source/tests -name '*.sh' -print0 | xargs -0 -n1 bash -n > "$LOG_DIR/syntax-sh.out" 2> "$LOG_DIR/syntax-sh.err"; then
  printf 'PASS syntax-sh\n' | tee -a "$SUMMARY"
else
  printf 'FAIL syntax-sh\n' | tee -a "$SUMMARY"
  exit 1
fi
printf 'COMMAND find publisher/artifacts-publisher-source/scripts -name '\''*.py'\'' -print0 | xargs -0 -n1 python3 -m py_compile\n' | tee -a "$SUMMARY"
if find publisher/artifacts-publisher-source/scripts -name '*.py' -print0 | xargs -0 -n1 python3 -m py_compile > "$LOG_DIR/syntax-py.out" 2> "$LOG_DIR/syntax-py.err"; then
  printf 'PASS syntax-py\n' | tee -a "$SUMMARY"
else
  printf 'FAIL syntax-py\n' | tee -a "$SUMMARY"
  exit 1
fi
printf 'COMMAND find publisher/artifacts-publisher-source/scripts publisher/artifacts-publisher-source/templates -name '\''*.mjs'\'' -print0 | xargs -0 -n1 node --check\n' | tee -a "$SUMMARY"
if find publisher/artifacts-publisher-source/scripts publisher/artifacts-publisher-source/templates -name '*.mjs' -print0 | xargs -0 -n1 node --check > "$LOG_DIR/syntax-mjs.out" 2> "$LOG_DIR/syntax-mjs.err"; then
  printf 'PASS syntax-mjs\n' | tee -a "$SUMMARY"
else
  printf 'FAIL syntax-mjs\n' | tee -a "$SUMMARY"
  exit 1
fi
failed=0
count=0
passed=0
for test_script in publisher/artifacts-publisher-source/tests/test-*.sh; do
  count=$((count + 1))
  test_name="$(basename "$test_script")"
  test_log_out="$LOG_DIR/$test_name.out"
  test_log_err="$LOG_DIR/$test_name.err"
  printf 'RUN %s\n' "$test_script" | tee -a "$SUMMARY"
  if TMPDIR="$PWD/.tmp/wikia-runtime-tmp" bash "$test_script" > "$test_log_out" 2> "$test_log_err"; then
    passed=$((passed + 1))
    printf 'PASS %s\n' "$test_script" | tee -a "$SUMMARY"
  else
    printf 'FAIL %s\n' "$test_script" | tee -a "$SUMMARY"
    failed=1
    break
  fi
done
printf 'TOTAL_RUN %s\n' "$count" | tee -a "$SUMMARY"
printf 'TOTAL_PASS %s\n' "$passed" | tee -a "$SUMMARY"
printf 'LOG_DIR %s\n' "$LOG_DIR" | tee -a "$SUMMARY"
exit "$failed"
```

Result: PASS.

Earlier equivalent suite command:

```bash
set -u
LOG_ROOT=".maestro/state/integration-test-logs"
RUN_ID="$(date +%Y%m%d-%H%M%S)"
LOG_DIR="$LOG_ROOT/$RUN_ID"
mkdir -p "$LOG_DIR"
SUMMARY="$LOG_DIR/summary.txt"
: > "$SUMMARY"

failed=0
count=0
for test_script in publisher/artifacts-publisher-source/tests/test-*.sh; do
  count=$((count + 1))
  test_name="$(basename "$test_script")"
  test_log="$LOG_DIR/$test_name.log"
  printf 'RUN %s\n' "$test_script" | tee -a "$SUMMARY"
  if bash "$test_script" > "$test_log" 2>&1; then
    printf 'PASS %s\n' "$test_script" | tee -a "$SUMMARY"
  else
    printf 'FAIL %s\n' "$test_script" | tee -a "$SUMMARY"
    failed=1
    break
  fi
done
printf 'TOTAL_RUN %s\n' "$count" | tee -a "$SUMMARY"
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
- The root `integration-plan.md` is tracked, so there was no untracked duplicate root artifact to move.
- The integration plan remains summarized at `/Users/felipegobbi/Documents/VibeworkV2/apps/wikia-worktrees/improve-release-integration/.maestro/state/integration-plan.md`.
- Maestro write restrictions prevent this agent from writing `/Users/felipegobbi/Documents/VibeworkV2/apps/wikia/.maestro/evidence/integration-tests.md`; this tracked worktree report is the allowed evidence artifact.
- Images analyzed: 0.
