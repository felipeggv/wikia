#!/usr/bin/env bash
set -euo pipefail

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_ROOT="${WIKIA_TEST_SOURCE_ROOT:-$(cd "$TEST_DIR/.." && pwd)}"
APP_ROOT="$(cd "$SOURCE_ROOT/../.." && pwd)"
PUBLISH_SCRIPT="${SOURCE_ROOT}/scripts/publish.sh"
TMP_PARENT="${WIKIA_TEST_TMP_PARENT:-$APP_ROOT/.tmp/wikia-tests/publish-runs-state-validation-tests}"

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

require_file() {
  [[ -f "$1" ]] || fail "missing required file: $1"
}

require_file "$PUBLISH_SCRIPT"
mkdir -p "$TMP_PARENT"

RUN_DIR="$(mktemp -d "${TMP_PARENT}/run.XXXXXX")"
trap 'rm -rf "$RUN_DIR"' EXIT

REAL_GIT="$(command -v git)"
ORIGIN_REPO="${RUN_DIR}/origin"
FAKE_BIN="${RUN_DIR}/bin"
mkdir -p "$ORIGIN_REPO/docs/gitpages" "$FAKE_BIN"
touch "$ORIGIN_REPO/docs/.nojekyll" "$ORIGIN_REPO/docs/gitpages/.nojekyll"

"$REAL_GIT" -C "$ORIGIN_REPO" init >/dev/null
"$REAL_GIT" -C "$ORIGIN_REPO" add docs/.nojekyll docs/gitpages/.nojekyll
"$REAL_GIT" -C "$ORIGIN_REPO" \
  -c user.name="Publish State Validation Fixture" \
  -c user.email="publish-state-validation@example.invalid" \
  commit -m "initial fixture" >/dev/null

cat > "${FAKE_BIN}/git" <<'SH'
#!/usr/bin/env bash
set -euo pipefail

if [[ "${1:-}" == "clone" ]]; then
  dest="${@: -1}"
  "$REAL_GIT" clone "$PUBLISH_TEST_ORIGIN" "$dest"
  exit 0
fi

if [[ "${1:-}" == "push" ]]; then
  echo "git push must not run during publish validation" >&2
  exit 70
fi

exec "$REAL_GIT" "$@"
SH
chmod +x "${FAKE_BIN}/git"

cat > "${FAKE_BIN}/gh" <<'SH'
#!/usr/bin/env bash
echo "gh must not run during publish validation" >&2
exit 71
SH
chmod +x "${FAKE_BIN}/gh"

RAW_MD="${RUN_DIR}/raw.md"
cat > "$RAW_MD" <<'EOF'
---
bu: staging
project: validation
slug: invalid-public-output
title: Invalid Public Output
date: 2026-05-23
tags: [fixture, validation]
gate: null
---

# Invalid Public Output

This public fixture deliberately contains wk-tree-tema so state validation fails.
EOF

VALIDATE_JSON="${RUN_DIR}/validate.json"
if PUBLISH_TEST_ORIGIN="$ORIGIN_REPO" REAL_GIT="$REAL_GIT" WIKIA_PUBLISH_TMP_PARENT="${RUN_DIR}/publish-workdirs" PATH="${FAKE_BIN}:$PATH" \
  bash "$PUBLISH_SCRIPT" \
    --title "Invalid Public Output" \
    --content "$RAW_MD" \
    --repo fixture/wiki \
    --no-gate \
    --bu staging \
    --project validation \
    --slug invalid-public-output \
    --validate \
    > "$VALIDATE_JSON" \
    2> "${RUN_DIR}/validate.err"; then
  fail "publish validation passed despite invalid public output"
fi

python3 - "$VALIDATE_JSON" <<'PY'
import json
import sys
from pathlib import Path

payload = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
if payload.get("validate_only") is not True:
    raise SystemExit("publish did not run in validation mode")
if payload.get("would_push") is not False:
    raise SystemExit("publish validation attempted to push")
state_validation = payload.get("state_validation") or {}
if state_validation.get("ok") is not False:
    raise SystemExit(f"state validation should fail: {state_validation}")
rules = {issue.get("rule") for issue in state_validation.get("issues", [])}
if "legacy_wk_tree_tema" not in rules:
    raise SystemExit(f"missing legacy_wk_tree_tema issue: {state_validation}")
staged = set(payload.get("staged_paths") or [])
required = "docs/gitpages/staging/validation/invalid-public-output/index.html"
if required not in staged:
    raise SystemExit(f"missing staged invalid article path: {required}")
PY

cat <<EOF
---
type: report
title: Publish Runs State Validation Test
created: $(date +%F)
tags:
  - wikia-cms
  - publish
  - validation
related:
  - '[[PHASE-06-PUBLISH]]'
  - '[[PHASE-07-VALIDATION]]'
  - '[[CMS-CONTRACT]]'
---

# Publish Runs State Validation Test

## Executive Summary

The publish validation mode now runs public-output state validation and fails
before any push when generated pages violate CMS invariants.

\`\`\`text
publish.sh --validate
   |
   v
render public output
   |
   v
validate-state.sh
   |
   v
fail JSON, no push
\`\`\`

## Verified Checks

| Check | Result |
|---|---|
| Invalid public output made \`publish.sh --validate\` fail | PASS |
| Validation JSON included \`state_validation.ok=false\` | PASS |
| The expected validation rule was reported | PASS |
| Fake git push guard was not triggered | PASS |
| Fake gh guard was not triggered | PASS |

## Images Analyzed

0
EOF
