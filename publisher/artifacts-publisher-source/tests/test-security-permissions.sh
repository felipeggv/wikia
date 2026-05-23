#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
GATE_SCRIPT="${SOURCE_ROOT}/scripts/gate.sh"
STRIP_GATE_SCRIPT="${SOURCE_ROOT}/scripts/strip-gate.py"
APPLY_PENDING_SCRIPT="${SOURCE_ROOT}/scripts/apply-pending.py"
VALIDATE_SCRIPT="${SOURCE_ROOT}/scripts/validate-state.sh"
GATE_TEMPLATE="${SOURCE_ROOT}/templates/gate.html.tpl"
TMP_PARENT="${WIKIA_TEST_TMP_PARENT:-${SOURCE_ROOT}/.test-tmp/security-permissions-tests}"

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

require_file() {
  [[ -f "$1" ]] || fail "missing required file: $1"
}

require_no_match() {
  local pattern="$1"
  local path="$2"
  if grep -Eq "$pattern" "$path"; then
    fail "unexpected pattern found in ${path}"
  fi
}

require_file "$GATE_SCRIPT"
require_file "$STRIP_GATE_SCRIPT"
require_file "$APPLY_PENDING_SCRIPT"
require_file "$VALIDATE_SCRIPT"
require_file "$GATE_TEMPLATE"
mkdir -p "$TMP_PARENT"

RUN_DIR="$(mktemp -d "${TMP_PARENT}/run.XXXXXX")"
cleanup() {
  rm -rf "$RUN_DIR"
  rmdir "$TMP_PARENT" "${SOURCE_ROOT}/.test-tmp" 2>/dev/null || true
}
trap cleanup EXIT

PUBLIC_ROOT="${RUN_DIR}/public"
mkdir -p "$PUBLIC_ROOT"

# Gate temp cleanup: force encryption to fail after plaintext extraction and
# assert the plaintext temp file is still removed from the public root.
FAILING_SKILL="${RUN_DIR}/failing-skill"
mkdir -p "${FAILING_SKILL}/scripts"
cp "$GATE_SCRIPT" "${FAILING_SKILL}/scripts/gate.sh"
cp "${SOURCE_ROOT}/scripts/extract-template.mjs" "${FAILING_SKILL}/scripts/extract-template.mjs"
cat > "${FAILING_SKILL}/scripts/encrypt-blob.mjs" <<'JS'
import { existsSync, statSync } from 'node:fs';

const plainPath = process.argv[2];
if (!plainPath || !existsSync(plainPath) || statSync(plainPath).size === 0) {
  process.exit(43);
}
process.exit(42);
JS
chmod +x "${FAILING_SKILL}/scripts/gate.sh"

GATED_HTML="${PUBLIC_ROOT}/gate-fixture.html"
cat > "$GATED_HTML" <<'HTML'
<!doctype html>
<html>
  <body data-slug="gate-fixture" data-repo="fixture/wiki">
    <template id="ap-content-tpl">
      <main><h1>Fixture Protected Content</h1></main>
    </template>
    {{GATE_BLOCK}}
  </body>
</html>
HTML

if TMPDIR="$PUBLIC_ROOT" bash "${FAILING_SKILL}/scripts/gate.sh" "$GATED_HTML" "fixture-password" "fixture-bu" \
  > "${RUN_DIR}/gate-fail.out" 2> "${RUN_DIR}/gate-fail.err"; then
  fail "gate fixture unexpectedly passed with failing encrypt-blob"
fi

if find "$PUBLIC_ROOT" \( -name '*.plaintext.tmp' -o -name 'wikia-gate-plaintext.*' \) -print -quit | grep -q .; then
  fail "gate plaintext temp file remained under public root"
fi
[[ ! -e "${GATED_HTML}.plaintext.tmp" ]] || fail "legacy plaintext temp file remained next to HTML"

# strip-gate mode 1: freshly rendered page unwraps template content and keeps
# nested templates intact.
FRESH_HTML="${RUN_DIR}/fresh-release.html"
cat > "$FRESH_HTML" <<'HTML'
<!doctype html>
<html>
  <body>
    <template id="ap-content-tpl">
      <main id="article-body">
        <template id="nested-fixture"><span>nested</span></template>
      </main>
    </template>
    {{GATE_BLOCK}}
  </body>
</html>
HTML
python3 "$STRIP_GATE_SCRIPT" "$FRESH_HTML" > "${RUN_DIR}/strip-fresh.out" 2> "${RUN_DIR}/strip-fresh.err"
grep -Fq 'id="article-body"' "$FRESH_HTML" || fail "fresh strip did not unwrap article body"
grep -Fq 'id="nested-fixture"' "$FRESH_HTML" || fail "fresh strip lost nested template content"
require_no_match 'ap-gate-script|ap-gate-wrap|\{\{GATE_BLOCK\}\}' "$FRESH_HTML"

# strip-gate mode 2: already-gated page drops stale gate wrapper, CSS, and JS.
ALREADY_GATED_HTML="${RUN_DIR}/already-gated-release.html"
cat > "$ALREADY_GATED_HTML" <<'HTML'
<!doctype html>
<html>
  <body>
    <style>.regular-style { color: green; }</style>
    <main id="public-body">Public body remains</main>
    <div class="ap-gate-wrap">
      <div id="ap-gate"><div class="ap-gate-card">stale gate</div></div>
      <div id="ap-content-mount" style="display:none"></div>
    </div>
    <div id="ap-content-mount" style="display:none"></div>
    <style>.ap-gate-wrap { display: block; } #ap-gate { display: flex; }</style>
    <script id="ap-gate-script">window.__gateFixture = true;</script>
  </body>
</html>
HTML
python3 "$STRIP_GATE_SCRIPT" "$ALREADY_GATED_HTML" > "${RUN_DIR}/strip-gated.out" 2> "${RUN_DIR}/strip-gated.err"
grep -Fq 'id="public-body"' "$ALREADY_GATED_HTML" || fail "already-gated strip removed public body"
grep -Fq '.regular-style' "$ALREADY_GATED_HTML" || fail "already-gated strip removed unrelated CSS"
require_no_match 'ap-gate-wrap|ap-gate-card|ap-content-mount|ap-gate-script|__gateFixture' "$ALREADY_GATED_HTML"

# Pending scope contract: article scope changes may target article/project/BU,
# but must reject admin scope from hand-edited pending JSON.
CATALOG_PATH="${RUN_DIR}/_catalog.json"
RELEASED_PATH="${RUN_DIR}/_released.json"
VAULT_PATH="${RUN_DIR}/_passwords.enc"
PENDING_VALID="${RUN_DIR}/_pending-valid.json"
PENDING_ADMIN="${RUN_DIR}/_pending-admin.json"
printf '[]\n' > "$RELEASED_PATH"
printf '{}\n' > "$VAULT_PATH"
cat > "$CATALOG_PATH" <<'JSON'
{
  "catalog_version": 1,
  "generated_at": "2026-05-23T00:00:00Z",
  "records": [
    {
      "canonical_key": "staging/security/scope-target",
      "bu": "staging",
      "project": "security",
      "slug": "scope-target",
      "title_visible": false,
      "title_public": null,
      "output_url": "staging/security/scope-target/",
      "gate_status": "gated",
      "release_status": "unreleased",
      "scope": "article",
      "tags": [],
      "raw_hash": "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
    }
  ]
}
JSON
cat > "$PENDING_VALID" <<'JSON'
{
  "scope": [
    {
      "key": "staging/security/scope-target",
      "bu": "staging",
      "project": "security",
      "slug": "scope-target",
      "from_scope": "article",
      "to_scope": "bu"
    }
  ]
}
JSON
WIKIA_MASTERPASS="fixture-masterpass" python3 "$APPLY_PENDING_SCRIPT" \
  "$PENDING_VALID" "$VAULT_PATH" "$RELEASED_PATH" \
  --catalog-path "$CATALOG_PATH" \
  > "${RUN_DIR}/apply-valid.out" 2> "${RUN_DIR}/apply-valid.err"
python3 - "$CATALOG_PATH" "$PENDING_VALID" <<'PY'
import json
import sys
from pathlib import Path

catalog = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
pending = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))
record = catalog["records"][0]
if record.get("scope") != "bu":
    raise SystemExit("valid BU scope intent was not applied")
if pending != {}:
    raise SystemExit("valid pending queue was not cleared")
PY

cat > "$PENDING_ADMIN" <<'JSON'
{
  "scope": [
    {
      "key": "staging/security/scope-target",
      "bu": "staging",
      "project": "security",
      "slug": "scope-target",
      "from_scope": "bu",
      "to_scope": "admin"
    }
  ]
}
JSON
if WIKIA_MASTERPASS="fixture-masterpass" python3 "$APPLY_PENDING_SCRIPT" \
  "$PENDING_ADMIN" "$VAULT_PATH" "$RELEASED_PATH" \
  --catalog-path "$CATALOG_PATH" \
  > "${RUN_DIR}/apply-admin.out" 2> "${RUN_DIR}/apply-admin.err"; then
  fail "admin scope pending intent was accepted"
fi
grep -Fq "article scope changes only support article, project, or bu" "${RUN_DIR}/apply-admin.err" \
  || fail "admin scope rejection did not explain the contract"

python3 - "${SOURCE_ROOT}/scripts" <<'PY'
import sys
from pathlib import Path

sys.path.insert(0, str(Path(sys.argv[1])))
import public_catalog

records = [
    {"bu": "staging", "project": "security", "slug": "scope-target", "scope": "admin"},
    {"bu": "gobbi", "project": "strategy", "slug": "other-private", "scope": "article"},
]
visible = [public_catalog.record_key(record) for record in public_catalog.scoped_records(records, records[0])]
if visible != ["staging/security/scope-target"]:
    raise SystemExit(f"admin scope expanded article navigation: {visible}")
PY

# validate-state must catch admin scope and plaintext gate temp residue in
# public output without needing to inspect private source files.
BAD_PUBLIC="${RUN_DIR}/bad-public"
mkdir -p "$BAD_PUBLIC"
cat > "${BAD_PUBLIC}/_catalog.json" <<'JSON'
{
  "catalog_version": 1,
  "generated_at": "2026-05-23T00:00:00Z",
  "records": [
    {
      "bu": "staging",
      "project": "security",
      "slug": "admin-scope",
      "title_visible": false,
      "title_public": null,
      "output_url": "staging/security/admin-scope/",
      "gate_status": "gated",
      "release_status": "unreleased",
      "scope": "admin",
      "tags": [],
      "raw_hash": "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
    }
  ]
}
JSON
printf 'temporary plaintext residue\n' > "${BAD_PUBLIC}/wikia-gate-plaintext.fixture"
BAD_JSON="${RUN_DIR}/bad-validate.json"
if bash "$VALIDATE_SCRIPT" --public-root "$BAD_PUBLIC" --json > "$BAD_JSON"; then
  fail "validate-state accepted admin scope and gate temp residue"
fi
python3 - "$BAD_JSON" <<'PY'
import json
import sys
from pathlib import Path

payload = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
rules = {issue.get("rule") for issue in payload.get("issues", [])}
expected = {"admin_scope_public_artifact", "plaintext_gate_temp_file"}
missing = expected - rules
if missing:
    raise SystemExit(f"missing expected rules: {sorted(missing)}")
PY

require_no_match 'localStorage' "$GATE_TEMPLATE"
grep -Fq 'sessionStorage' "$GATE_TEMPLATE" || fail "gate template does not use sessionStorage"

cat <<EOF
---
type: report
title: Security Permissions Test
created: $(date +%F)
tags:
  - wikia-cms
  - security
  - permissions
related:
  - '[[Wikia Security Permissions Lane Discovery]]'
---

# Security Permissions Test

## Executive Summary

Security-permissions controls passed focused fixture checks without printing
secret values.

\`\`\`text
gate temp cleanup
   |
   +-- no plaintext residue under public root
scope intents
   |
   +-- BU allowed
   +-- admin rejected
released pages
   |
   +-- stale gate wrapper stripped
\`\`\`

## Verified Checks

| Check | Result |
|---|---|
| Failed gate encryption cleaned plaintext temp file | PASS |
| Legacy adjacent plaintext temp file was not created | PASS |
| Fresh strip-gate release unwrapped article body | PASS |
| Fresh strip-gate preserved nested templates | PASS |
| Already-gated release removed stale gate wrapper, CSS, and JS | PASS |
| Valid BU scope pending intent applied | PASS |
| Hand-edited admin scope pending intent rejected | PASS |
| Public catalog treats admin article scope as article-only | PASS |
| validate-state flags public admin scope | PASS |
| validate-state flags gate plaintext temp residue | PASS |
| Gate browser storage uses sessionStorage, not localStorage | PASS |

## Images Analyzed

0
EOF
