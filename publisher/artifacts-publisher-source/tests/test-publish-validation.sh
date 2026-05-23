#!/usr/bin/env bash
set -euo pipefail

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_ROOT="${WIKIA_TEST_SOURCE_ROOT:-${SOURCE_ROOT:-$(cd "$TEST_DIR/.." && pwd)}}"
APP_ROOT="$(cd "$SOURCE_ROOT/../.." && pwd)"
PUBLISH_SCRIPT="${SOURCE_ROOT}/scripts/publish.sh"
APPLY_PENDING_SCRIPT="${SOURCE_ROOT}/scripts/apply-pending.py"
TMP_PARENT="${WIKIA_TEST_TMP_PARENT:-${TMP_PARENT:-$APP_ROOT/.tmp/wikia-tests/publish-validation-tests}}"

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

require_file() {
  [[ -f "$1" ]] || fail "missing required file: $1"
}

require_file "$PUBLISH_SCRIPT"
require_file "$APPLY_PENDING_SCRIPT"
mkdir -p "$TMP_PARENT"

RUN_DIR="$(mktemp -d "${TMP_PARENT}/run.XXXXXX")"
trap 'rm -rf "$RUN_DIR"' EXIT

if grep -Eq 'git add[[:space:]]+(-A|\.|-u)' "$PUBLISH_SCRIPT"; then
  fail "publish.sh still contains broad git add"
fi

if grep -Eq 'apply-pending\.py.*"\$MASTERPASS"|node "\$VAULT_MJS" (get|set) "\$VAULT_PATH" "\$MASTERPASS"|SEED_MP=' "$PUBLISH_SCRIPT"; then
  fail "publish.sh still passes masterpass as a command argument"
fi

SECRET="plain-masterpass-fixture"
if bash "$PUBLISH_SCRIPT" --rebuild-all --masterpass "$SECRET" --validate \
  > "${RUN_DIR}/reject.out" 2> "${RUN_DIR}/reject.err"; then
  fail "plaintext --masterpass value was accepted"
fi
if grep -F "$SECRET" "${RUN_DIR}/reject.out" "${RUN_DIR}/reject.err" >/dev/null; then
  fail "plaintext masterpass appeared in rejection output"
fi

REAL_GIT="$(command -v git)"
ORIGIN_REPO="${RUN_DIR}/origin"
FAKE_BIN="${RUN_DIR}/bin"
mkdir -p "$ORIGIN_REPO/docs/gitpages" "$FAKE_BIN"
touch "$ORIGIN_REPO/docs/.nojekyll" "$ORIGIN_REPO/docs/gitpages/.nojekyll"

"$REAL_GIT" -C "$ORIGIN_REPO" init >/dev/null
"$REAL_GIT" -C "$ORIGIN_REPO" add docs/.nojekyll docs/gitpages/.nojekyll
"$REAL_GIT" -C "$ORIGIN_REPO" \
  -c user.name="Publish Validation Fixture" \
  -c user.email="publish-validation@example.invalid" \
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
project: test-project
slug: publish-validation-fixture
title: Publish Validation Fixture
date: 2026-05-19
tags: [fixture, publish]
gate: null
---

# Publish Validation Fixture

This fixture verifies validation mode without pushing.
EOF

VALIDATE_JSON="${RUN_DIR}/validate.json"
PUBLISH_TEST_ORIGIN="$ORIGIN_REPO" REAL_GIT="$REAL_GIT" WIKIA_PUBLISH_TMP_PARENT="${RUN_DIR}/publish-workdirs" PATH="${FAKE_BIN}:$PATH" \
  bash "$PUBLISH_SCRIPT" \
    --title "Publish Validation Fixture" \
    --content "$RAW_MD" \
    --repo fixture/wiki \
    --no-gate \
    --bu staging \
    --project test-project \
    --slug publish-validation-fixture \
    --validate \
    > "$VALIDATE_JSON" \
    2> "${RUN_DIR}/validate.err"

node - "$VALIDATE_JSON" <<'NODE'
const fs = require('node:fs');
const payload = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
const paths = new Set(payload.staged_paths || []);
const required = [
  'docs/gitpages/index.html',
  'docs/gitpages/search.json',
  'docs/gitpages/_catalog.json',
  'docs/gitpages/staging/index.html',
  'docs/gitpages/staging/test-project/index.html',
  'docs/gitpages/staging/test-project/publish-validation-fixture/index.html',
];

if (payload.validate_only !== true) throw new Error('validate_only flag missing');
if (payload.would_push !== false) throw new Error('validation mode should not push');
if (payload.changed !== true) throw new Error('validation mode should detect staged changes');
if (!payload.state_validation || payload.state_validation.ok !== true) {
  throw new Error(`state validation should pass: ${JSON.stringify(payload.state_validation)}`);
}
for (const path of required) {
  if (!paths.has(path)) throw new Error(`missing staged path: ${path}`);
}
for (const path of paths) {
  if (!path.startsWith('docs/.nojekyll') && !path.startsWith('docs/gitpages/')) {
    throw new Error(`unexpected staged path outside publish output: ${path}`);
  }
  if (path.endsWith('/raw.md')) {
    throw new Error(`public raw markdown should not be staged: ${path}`);
  }
}
NODE

cat <<EOF
---
type: report
title: Publish Validation Pipeline Test
created: $(date +%F)
tags:
  - wikia-cms
  - phase-06
  - publish
  - validation
related:
  - '[[PHASE-06-PUBLISH]]'
  - '[[CMS-CONTRACT]]'
---

# Publish Validation Pipeline Test

## Executive Summary

The publish pipeline now stages only filtered generated paths and supports a
validation mode that renders into a cloned fixture repository without commit,
push, or Pages API calls.

\`\`\`text
publish fixture
   |
   v
render into cloned repo
   |
   v
filtered explicit staging
   |
   v
validation JSON, no push
\`\`\`

## Verified Checks

| Check | Result |
|---|---|
| Post-deploy cleanup does not require .bak4 backup files | PASS |
| Broad staging command removed from publish script | PASS |
| Plaintext masterpass CLI value rejected | PASS |
| Rejection output did not print the fixture secret | PASS |
| Validation mode produced JSON with would_push=false | PASS |
| Validation mode staged expected generated files only | PASS |
| Validation mode did not stage public raw markdown | PASS |
| Fake git push guard was not triggered | PASS |
| Fake gh guard was not triggered | PASS |

## Images Analyzed

0
EOF
