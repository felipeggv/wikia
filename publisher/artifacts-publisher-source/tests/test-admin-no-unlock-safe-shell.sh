#!/usr/bin/env bash
set -euo pipefail

PLAYBOOK_ROOT="/Users/felipegobbi/Documents/VibeworkV2/Auto Run Docs/2026-05-19-Wikia-CMS-Refactor"
SOURCE_ROOT="${PLAYBOOK_ROOT}/Working/artifacts-publisher-source"
RENDER_ADMIN_SCRIPT="${SOURCE_ROOT}/scripts/render-admin.py"
ADMIN_DB_SCRIPT="${SOURCE_ROOT}/scripts/admin-db.py"
TMP_PARENT="${PLAYBOOK_ROOT}/Working/tmp/admin-no-unlock-safe-shell-tests"

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
WIKI_BASE='https://fixture.test/wikia'

python3 "$RENDER_ADMIN_SCRIPT" "$PUBLIC_ROOT" "$THEME_JSON" "$WIKI_BASE" \
  --cms-state "$CMS_DB" > "${RUN_DIR}/render-admin.stdout" 2> "${RUN_DIR}/render-admin.stderr"

ADMIN_HTML="${PUBLIC_ROOT}/admin/index.html"
require_file "$ADMIN_HTML"

CREATED="$(date +%F)" python3 - "$ADMIN_HTML" "$RENDER_ADMIN_SCRIPT" <<'PY'
from pathlib import Path
import os
import re
import sys

admin_html_path = Path(sys.argv[1])
render_admin_path = Path(sys.argv[2])
html = admin_html_path.read_text(encoding="utf-8")

aside_match = re.search(r'<aside class="wk-sidebar"[\s\S]*?</aside>', html)
if not aside_match:
    raise SystemExit("missing admin sidebar shell")
sidebar = aside_match.group(0)

tree_match = re.search(r'<nav class="wk-sidebar-nav">[\s\S]*?</nav>', sidebar)
if not tree_match:
    raise SystemExit("missing admin sidebar nav")
tree_html = tree_match.group(0)

recents_match = re.search(r'<ul class="wk-recents">[\s\S]*?</ul>', sidebar)
if not recents_match:
    raise SystemExit("missing admin recents shell")
recents_html = recents_match.group(0)

for marker in (
    "Public Growth Playbook",
    "public-growth-playbook",
    "growth-engine",
    "private-strategy",
    "hidden-funnel-map",
    "hidden funnel map",
    "gobbi/private-strategy",
    "staging/growth-engine",
):
    if marker in html:
        raise SystemExit(f"locked admin HTML leaked article/project marker: {marker}")

for marker in (
    'class="wk-tree-bu"',
    'class="wk-tree-project"',
    'class="wk-tree-article"',
    '<span class="count">',
):
    if marker in sidebar:
        raise SystemExit(f"locked admin sidebar leaked catalog marker: {marker}")

for marker in (
    'class="wk-tree-admin-shell"',
    "Admin bloqueado",
    "Nenhum catalogo e carregado antes do unlock.",
):
    if marker not in sidebar:
        raise SystemExit(f"locked admin safe shell marker missing: {marker}")

for marker in (
    "function isAdminLockedShell()",
    "function loadSearchIndex()",
    "if (!isAdminLockedShell()) loadSearchIndex();",
    "/_admin.enc",
):
    if marker not in html:
        raise SystemExit(f"admin app shell search guard missing: {marker}")

def snippet(value):
    value = re.sub(r'<svg[\s\S]*?</svg>', '<svg ...></svg>', value)
    value = re.sub(r'\s+', ' ', value).strip()
    return value[:900]

before = (
    '<li class="wk-tree-project" data-project="private-strategy" '
    'data-expanded="false">...<span class="label-text">private-strategy</span>'
    '<span class="count">1</span>...'
    '<li class="wk-tree-article" data-slug="hidden-funnel-map">'
    '...<span>hidden funnel map</span>...</li>'
)
after = snippet(tree_html + "\n" + recents_html)

created = os.environ["CREATED"]
print(f"""---
type: report
title: Admin No-Unlock Safe Shell Test
created: {created}
tags:
  - wikia-cms
  - phase-05
  - admin-client
  - privacy
related:
  - '[[PHASE-05-ADMIN]]'
  - '[[CMS-CONTRACT]]'
  - '[[Wikia CMS Security Decision]]'
---

# Admin No-Unlock Safe Shell Test

## Executive Summary

The admin initial HTML now shows only a locked shell. It does not expose
cross-BU article titles, project names, article slugs, or sidebar count spans
before masterpass unlock.

```text
browser opens /admin/
   |
   v
safe locked shell only
   |
   v
masterpass unlock
   |
   v
_admin.enc decrypts article metadata in memory
```

## HTML Snippet Comparison

### Before

```html
{before}
```

### After

```html
{after}
```

## Verified Checks

| Check | Result |
|---|---|
| Initial HTML excludes private project marker `private-strategy` | PASS |
| Initial HTML excludes private article slug `hidden-funnel-map` | PASS |
| Initial HTML excludes private/public article labels before unlock | PASS |
| Sidebar excludes BU/project/article list item classes before unlock | PASS |
| Sidebar excludes `<span class="count">` before unlock | PASS |
| Search index load is guarded while admin is locked | PASS |
| Unlock path still references encrypted `_admin.enc` | PASS |

## Paths

| Artifact | Path |
|---|---|
| Renderer | `{render_admin_path}` |
| Generated fixture HTML | Temporary fixture generated during the test and removed after PASS |

## Images Analyzed

0
""")
PY
