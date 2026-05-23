#!/usr/bin/env bash
set -euo pipefail

PLAYBOOK_ROOT="/Users/felipegobbi/Documents/VibeworkV2/Auto Run Docs/2026-05-19-Wikia-CMS-Refactor"
SOURCE_ROOT="${PLAYBOOK_ROOT}/Working/artifacts-publisher-source"
RENDER_ADMIN_SCRIPT="${SOURCE_ROOT}/scripts/render-admin.py"
RENDER_WIKI_SCRIPT="${SOURCE_ROOT}/scripts/render-wiki.py"
SIDEBAR_TEMPLATE="${SOURCE_ROOT}/templates/_sidebar.html.tpl"
TMP_PARENT="${PLAYBOOK_ROOT}/Working/tmp/render-admin-sidebar-wrapper-tests"

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

require_file() {
  [[ -f "$1" ]] || fail "missing required file: $1"
}

require_file "$RENDER_ADMIN_SCRIPT"
require_file "$RENDER_WIKI_SCRIPT"
require_file "$SIDEBAR_TEMPLATE"
require_file "${SOURCE_ROOT}/templates/admin-decrypt.js"
mkdir -p "$TMP_PARENT"

RUN_DIR="$(mktemp -d "${TMP_PARENT}/run.XXXXXX")"
trap 'rm -rf "$RUN_DIR"' EXIT

PUBLIC_ROOT="${RUN_DIR}/gitpages"
ARTIFACT_DIR="${PUBLIC_ROOT}/research/fixture-tema/artifacts/fixture-article"
mkdir -p "$ARTIFACT_DIR"
printf '%s\n' '<!doctype html><title>Fixture Article · wikia</title><body>fixture</body>' > "${ARTIFACT_DIR}/index.html"

THEME_JSON='{"bgMain":"#0c0e0c","bgSidebar":"#0f100f","border":"#111311","textMain":"#f2f2c0"}'
WIKI_BASE='https://example.test/wikia/gitpages'

python3 "$RENDER_ADMIN_SCRIPT" "$PUBLIC_ROOT" "$THEME_JSON" "$WIKI_BASE" > "${RUN_DIR}/render-admin.stdout" 2> "${RUN_DIR}/render-admin.stderr"
ADMIN_HTML="${PUBLIC_ROOT}/admin/index.html"
require_file "$ADMIN_HTML"

python3 - "$ADMIN_HTML" "$RENDER_WIKI_SCRIPT" "$SIDEBAR_TEMPLATE" <<'PY'
import importlib.util
import sys
from pathlib import Path

admin_html_path = Path(sys.argv[1])
render_wiki_path = Path(sys.argv[2])
sidebar_template_path = Path(sys.argv[3])

html = admin_html_path.read_text(encoding="utf-8")
checks = {
    '<nav class="wk-sidebar-nav">': 1,
    '<ul class="wk-tree">': 1,
}
for marker, expected in checks.items():
    actual = html.count(marker)
    if actual != expected:
        raise SystemExit(f"{marker} expected {expected}, got {actual}")

template = sidebar_template_path.read_text(encoding="utf-8")
for marker in checks:
    actual = template.count(marker)
    if actual != 1:
        raise SystemExit(f"template {marker} expected 1, got {actual}")

spec = importlib.util.spec_from_file_location("render_wiki", render_wiki_path)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
sample_tree = {
    "staging": {
        "title": "Staging",
        "article_count": 1,
        "projects": {
            "fixture-project": {
                "auto_flatten": True,
                "articles": [
                    {
                        "slug": "fixture-article",
                        "title": "Fixture Article",
                        "date": "2026-05-19",
                        "gate": False,
                        "url": "staging/fixture-project/fixture-article/",
                    }
                ],
            }
        },
    }
}
tree = module.tree_html(sample_tree, wiki_base="https://example.test/wikia/gitpages")
for marker in checks:
    if marker in tree:
        raise SystemExit(f"render-wiki.tree_html leaked wrapper marker {marker}")
if '<li class="wk-tree-bu' not in tree:
    raise SystemExit("render-wiki.tree_html did not return BU list items")
PY

cat <<EOF
---
type: report
title: Render Admin Sidebar Wrapper Test
created: $(date +%F)
tags:
  - wikia-cms
  - phase-04
  - renderer
related:
  - '[[PHASE-04-RENDERERS]]'
  - '[[BROWNFIELD-BUGS]]'
---

# Render Admin Sidebar Wrapper Test

## Executive Summary

The admin renderer now produces exactly one sidebar navigation wrapper and one
tree root list. The shared sidebar template owns the wrapper; renderer tree
helpers return only child list items.

\`\`\`text
renderer tree_html()
   |
   v
child <li> items only
   |
   v
_sidebar.html.tpl owns <nav class="wk-sidebar-nav"><ul class="wk-tree">
   |
   v
admin/index.html has exactly one nav and one tree ul
\`\`\`

## Deterministic Checks

| Check | Result |
|---|---|
| Generated admin HTML has one \`<nav class="wk-sidebar-nav">\` | PASS |
| Generated admin HTML has one \`<ul class="wk-tree">\` | PASS |
| Sidebar template has one wrapper owner | PASS |
| \`render-wiki.py:tree_html()\` returns children only | PASS |
| Test fixture used fake content only | PASS |

## Paths

| Artifact | Path |
|---|---|
| Renderer | \`${RENDER_ADMIN_SCRIPT}\` |
| Shared sidebar template | \`${SIDEBAR_TEMPLATE}\` |
| Generated fixture admin HTML | Temporary fixture generated during the test and removed after PASS |
EOF
