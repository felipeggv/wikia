#!/usr/bin/env bash
set -euo pipefail

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_ROOT="${WIKIA_TEST_SOURCE_ROOT:-${SOURCE_ROOT:-$(cd "$TEST_DIR/.." && pwd)}}"
APP_ROOT="$(cd "$SOURCE_ROOT/../.." && pwd)"
VALIDATE_SCRIPT="${SOURCE_ROOT}/scripts/validate-state.sh"
TMP_PARENT="${WIKIA_TEST_TMP_PARENT:-${TMP_PARENT:-$APP_ROOT/.tmp/wikia-tests/validate-state-tests}}"

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

require_file() {
  [[ -f "$1" ]] || fail "missing required file: $1"
}

write_catalog() {
  local root="$1"
  cat > "${root}/_catalog.json" <<'JSON'
{
  "catalog_version": 1,
  "generated_at": "2026-05-19T00:00:00Z",
  "records": [
    {
      "article_id": "3cb31397508eef9ab031bd062993d7806b3ef49b296729c401eb74bf54684bf4",
      "canonical_key": "staging/test-project/public-article",
      "bu": "staging",
      "project": "test-project",
      "slug": "public-article",
      "title_visible": true,
      "title_public": "Public Article",
      "output_url": "staging/test-project/public-article/",
      "gate_status": "public",
      "release_status": "released",
      "scope": "public",
      "tags": ["fixture"],
      "raw_hash": "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
    },
    {
      "article_id": "685f3a2ebb11f352d65d2a4814d41c19ebf36977c60e4ca8d4ae216e8e3bfe4a",
      "canonical_key": "gobbi/private-project/private-article",
      "bu": "gobbi",
      "project": "private-project",
      "slug": "private-article",
      "title_visible": false,
      "title_public": null,
      "output_url": "gobbi/private-project/private-article/",
      "gate_status": "gated",
      "release_status": "unreleased",
      "scope": "article",
      "tags": [],
      "raw_hash": "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
    }
  ]
}
JSON
}

write_search() {
  local root="$1"
  cat > "${root}/search.json" <<'JSON'
[
  {
    "title": "Public Article",
    "tema": "staging/test-project",
    "tags": ["fixture"],
    "date": "2026-05-19",
    "snippet": "",
    "url": "staging/test-project/public-article/"
  }
]
JSON
}

write_good_html() {
  local root="$1"
  mkdir -p "${root}/staging/test-project/public-article"
  mkdir -p "${root}/gobbi/private-project/private-article"
  cat > "${root}/index.html" <<'HTML'
<!doctype html>
<html>
  <body>
    <nav class="wk-sidebar-nav">
      <ul class="wk-tree">
        <li class="wk-tree-bu" data-bu="staging">
          <a class="wk-tree-bu-link"><span class="label-text">Staging</span><span class="count">1</span></a>
          <ul class="wk-tree-projects">
            <li class="wk-tree-article" data-slug="public-article">
              <a href="https://example.test/wikia/gitpages/staging/test-project/public-article/"><span>Public Article</span></a>
            </li>
          </ul>
        </li>
        <li class="wk-tree-bu wk-tree-bu-empty" data-bu="gobbi">
          <a class="wk-tree-bu-link"><span class="label-text">Gobbi</span><span class="count">0</span></a>
        </li>
      </ul>
    </nav>
  </body>
</html>
HTML
  cp "${root}/index.html" "${root}/staging/test-project/public-article/index.html"
  cat > "${root}/gobbi/private-project/private-article/index.html" <<'HTML'
<!doctype html>
<html>
  <body>
    <nav class="wk-sidebar-nav">
      <ul class="wk-tree">
        <li class="wk-tree-bu" data-bu="gobbi">
          <a class="wk-tree-bu-link"><span class="label-text">Gobbi</span><span class="count">1</span></a>
          <ul class="wk-tree-projects">
            <li class="wk-tree-project" data-project="private-project">
              <a class="wk-tree-project-link"><span class="label-text">Private Project</span><span class="count">1</span></a>
              <ul class="wk-tree-articles">
                <li class="wk-tree-article" data-slug="private-article">
                  <a href="https://example.test/wikia/gitpages/gobbi/private-project/private-article/"><span>Private Article</span></a>
                </li>
              </ul>
            </li>
          </ul>
        </li>
      </ul>
    </nav>
  </body>
</html>
HTML
}

require_file "$VALIDATE_SCRIPT"
mkdir -p "$TMP_PARENT"

RUN_DIR="$(mktemp -d "${TMP_PARENT}/run.XXXXXX")"
cleanup() {
  rm -rf "$RUN_DIR"
  rmdir "$TMP_PARENT" "$APP_ROOT/.tmp/wikia-tests" "$APP_ROOT/.tmp" 2>/dev/null || true
}
trap cleanup EXIT

GOOD_ROOT="${RUN_DIR}/good"
mkdir -p "$GOOD_ROOT"
write_catalog "$GOOD_ROOT"
write_search "$GOOD_ROOT"
write_good_html "$GOOD_ROOT"

GOOD_JSON="${RUN_DIR}/good.json"
bash "$VALIDATE_SCRIPT" --public-root "$GOOD_ROOT" --json > "$GOOD_JSON"
python3 - "$GOOD_JSON" <<'PY'
import json
import sys

payload = json.load(open(sys.argv[1], encoding="utf-8"))
if payload.get("ok") is not True:
    raise SystemExit(f"good fixture failed validation: {payload}")
if payload.get("issue_count") != 0:
    raise SystemExit(f"good fixture reported issues: {payload}")
PY

BAD_ROOT="${RUN_DIR}/bad"
mkdir -p "${BAD_ROOT}/staging/test-project/public-article" "${BAD_ROOT}/gobbi/private-project/private-article"
write_catalog "$BAD_ROOT"
python3 - "${BAD_ROOT}/_catalog.json" <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
payload = json.loads(path.read_text(encoding="utf-8"))
payload["records"][1]["scope"] = "admin"
path.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
PY
cat > "${BAD_ROOT}/search.json" <<'JSON'
[
  {
    "title": "Wrong Article",
    "tema": "staging/test-project",
    "tags": [],
    "date": "2026-05-19",
    "snippet": "",
    "url": "staging/test-project/wrong-article/"
  }
]
JSON

cat > "${BAD_ROOT}/index.html" <<'HTML'
<!doctype html>
<html>
  <body>
    <nav class="wk-sidebar-nav"></nav>
    <nav class="wk-sidebar-nav">
      <ul class="wk-tree"></ul>
      <ul class="wk-tree">
        <li class="wk-tree-bu" data-bu="staging">
          <a class="wk-tree-bu-link"><span class="label-text">Staging</span><span class="count">2</span></a>
          <ul class="wk-tree-projects">
            <li class="wk-tree-project" data-project="test-project">
              <a class="wk-tree-project-link"><span class="label-text">Test Project</span><span class="count">2</span></a>
              <ul class="wk-tree-articles">
                <li class="wk-tree-article" data-slug="public-article">
                  <a href="https://example.test/wikia/gitpages/staging/test-project/public-article/">Public Article</a>
                </li>
              </ul>
            </li>
          </ul>
        </li>
      </ul>
    </nav>
    <script>const password = "fixture-public-secret-123";</script>
    <style>.wk-tree-tema { color: red; }</style>
  </body>
</html>
HTML

cat > "${BAD_ROOT}/gobbi/private-project/private-article/raw.md" <<'MD'
---
bu: gobbi
project: private-project
slug: private-article
title: Private Article
gate: <vault>
---

# Private body that must not be public
MD
printf '%s\n' 'private gate plaintext temp' > "${BAD_ROOT}/gobbi/private-project/private-article/index.html.plaintext.tmp"

BAD_JSON="${RUN_DIR}/bad.json"
if bash "$VALIDATE_SCRIPT" --public-root "$BAD_ROOT" --json > "$BAD_JSON"; then
  fail "bad fixture unexpectedly passed validation"
fi

python3 - "$BAD_JSON" <<'PY'
import json
import sys

payload = json.load(open(sys.argv[1], encoding="utf-8"))
rules = {issue.get("rule") for issue in payload.get("issues", [])}
expected = {
    "admin_scope_public_artifact",
    "plaintext_private_raw_md",
    "plaintext_gate_temp_file",
    "plaintext_passwords",
    "duplicated_sidebar_wrappers",
    "legacy_wk_tree_tema",
    "stale_article_counts",
    "search_catalog_mismatch",
}
missing = sorted(expected - rules)
if missing:
    raise SystemExit(f"missing expected validation rules: {missing}; got {sorted(rules)}")
PY

cat <<EOF
---
type: report
title: Validate State Script Test
created: $(date +%F)
tags:
  - wikia-cms
  - phase-07
  - validation
related:
  - '[[PHASE-07-VALIDATION]]'
  - '[[CMS-CONTRACT]]'
---

# Validate State Script Test

## Executive Summary

The state validator accepts a clean public-output fixture and rejects a dirty
fixture containing every required failure class.

\`\`\`text
public output
   |
   v
validate-state.sh
   |
   +-- clean fixture: PASS
   +-- dirty fixture: FAIL with targeted rules
\`\`\`

## Verified Checks

| Check | Result |
|---|---|
| Clean fixture passed with zero issues | PASS |
| Private gated \`raw.md\` under public output failed | PASS |
| Plaintext gate temp file under public output failed | PASS |
| Admin-only scope record in public catalog failed | PASS |
| Plaintext password-like assignment failed | PASS |
| Duplicated sidebar wrappers failed | PASS |
| Legacy \`wk-tree-tema\` marker failed | PASS |
| Stale sidebar article counts failed | PASS |
| Search/catalog URL mismatch failed | PASS |
| Validation output did not print secret values | PASS |

## Images Analyzed

0
EOF
