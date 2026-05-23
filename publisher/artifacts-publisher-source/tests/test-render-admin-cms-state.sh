#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_ROOT="${SOURCE_ROOT:-$(cd "$SCRIPT_DIR/.." && pwd)}"
RENDER_ADMIN_SCRIPT="${SOURCE_ROOT}/scripts/render-admin.py"
ADMIN_DB_SCRIPT="${SOURCE_ROOT}/scripts/admin-db.py"
TMP_PARENT="${TMP_PARENT:-${SOURCE_ROOT}/.test-tmp/render-admin-cms-state-tests}"

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

require_file() {
  [[ -f "$1" ]] || fail "missing required file: $1"
}

require_file "$RENDER_ADMIN_SCRIPT"
require_file "$ADMIN_DB_SCRIPT"
mkdir -p "$TMP_PARENT"

RUN_DIR="$(mktemp -d "${TMP_PARENT}/run.XXXXXX")"
trap 'rm -rf "$RUN_DIR"' EXIT

PUBLIC_ROOT="${RUN_DIR}/gitpages"
CMS_DB="${RUN_DIR}/admin-state.sqlite3"
mkdir -p "$PUBLIC_ROOT"

python3 "$ADMIN_DB_SCRIPT" init "$CMS_DB" >/dev/null

python3 "$ADMIN_DB_SCRIPT" upsert "$CMS_DB" \
  --bu staging \
  --project growth-engine \
  --slug public-growth-playbook \
  --title-visible \
  --title-public "Public Growth Playbook" \
  --raw-source-path "private-source/staging/growth-engine/public-growth-playbook/raw.md" \
  --output-url "staging/growth-engine/public-growth-playbook/" \
  --gate-status public \
  --release-status released \
  --scope public \
  --tags-json '["growth","public"]' \
  --raw-hash "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" >/dev/null

python3 "$ADMIN_DB_SCRIPT" upsert "$CMS_DB" \
  --bu gobbi \
  --project private-strategy \
  --slug hidden-funnel-map \
  --raw-source-path "private-source/gobbi/private-strategy/hidden-funnel-map/raw.md" \
  --output-url "gobbi/private-strategy/hidden-funnel-map/" \
  --gate-status gated \
  --release-status unreleased \
  --scope article \
  --tags-json '["strategy","private"]' \
  --raw-hash "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb" >/dev/null

THEME_JSON='{"bgMain":"#0c0e0c","bgSidebar":"#0f100f","border":"#111311","textMain":"#f2f2c0"}'
WIKI_BASE='https://example.test/wikia/gitpages'

python3 "$RENDER_ADMIN_SCRIPT" "$PUBLIC_ROOT" "$THEME_JSON" "$WIKI_BASE" \
  --cms-state "$CMS_DB" > "${RUN_DIR}/render-admin.stdout" 2> "${RUN_DIR}/render-admin.stderr"

ADMIN_HTML="${PUBLIC_ROOT}/admin/index.html"
require_file "$ADMIN_HTML"

python3 - "$ADMIN_HTML" "$RENDER_ADMIN_SCRIPT" <<'PY'
import importlib.util
import sys
from pathlib import Path

admin_html_path = Path(sys.argv[1])
render_admin_path = Path(sys.argv[2])
html = admin_html_path.read_text(encoding="utf-8")

expected_counts = {
    '<nav class="wk-sidebar-nav">': 1,
    '<ul class="wk-tree">': 1,
    'wk-tree-tema': 0,
}
for marker, expected in expected_counts.items():
    actual = html.count(marker)
    if actual != expected:
        raise SystemExit(f"{marker!r} expected {expected}, got {actual}")

required_snippets = [
    'class="wk-tree-admin-shell"',
    'Admin bloqueado',
    'Nenhum catalogo e carregado antes do unlock.',
    '/_admin.enc',
]
for snippet in required_snippets:
    if snippet not in html:
        raise SystemExit(f"missing rendered CMS snippet: {snippet}")

for forbidden in (
    "Secret Private Title",
    "Public Growth Playbook",
    "hidden funnel map",
    "private-strategy",
    "hidden-funnel-map",
    'class="wk-tree-bu"',
    'class="wk-tree-project"',
    'class="wk-tree-article"',
    '<span class="count">',
    "research/",
    "artifacts/",
):
    if forbidden in html:
        raise SystemExit(f"locked admin initial paint leaked catalog value: {forbidden}")

spec = importlib.util.spec_from_file_location("render_admin", render_admin_path)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
module.validate_sidebar_wrapper(html)
PY

cat <<EOF
---
type: report
title: Render Admin CMS State Test
created: $(date +%F)
tags:
  - wikia-cms
  - phase-04
  - renderer
related:
  - '[[PHASE-04-RENDERERS]]'
  - '[[CMS-CONTRACT]]'
---

# Render Admin CMS State Test

## Executive Summary

The admin renderer accepts sanitized CMS state, validates it, and emits only a
safe locked shell before masterpass unlock.

\`\`\`text
admin-state.sqlite3
   |
   v
render-admin.py
   |
   v
admin/index.html locked shell only
\`\`\`

\`\`\`text
masterpass unlock
   |
   v
_admin.enc decrypt
   |
   v
article list appears client-side
\`\`\`

## Verified Checks

| Check | Result |
|---|---|
| Accepts readable sanitized SQLite CMS state | PASS |
| Renders locked admin shell placeholder | PASS |
| Does not render BU nodes before unlock | PASS |
| Does not render project nodes before unlock | PASS |
| Does not render article nodes before unlock | PASS |
| Does not render sidebar count spans before unlock | PASS |
| Does not emit \`wk-tree-tema\` | PASS |
| Does not leak fixture public/private article labels in initial HTML | PASS |
| Keeps one sidebar nav and one tree root | PASS |

## Images Analyzed

0
EOF
