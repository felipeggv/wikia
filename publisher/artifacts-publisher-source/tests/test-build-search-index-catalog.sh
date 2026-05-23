#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_ROOT="${SOURCE_ROOT:-$(cd "$SCRIPT_DIR/.." && pwd)}"
SEARCH_SCRIPT="${SOURCE_ROOT}/scripts/build-search-index.py"
TMP_PARENT="${TMP_PARENT:-${SOURCE_ROOT}/.test-tmp/build-search-index-catalog-tests}"

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

require_file() {
  [[ -f "$1" ]] || fail "missing required file: $1"
}

require_file "$SEARCH_SCRIPT"
mkdir -p "$TMP_PARENT"

RUN_DIR="$(mktemp -d "${TMP_PARENT}/run.XXXXXX")"
trap 'rm -rf "$RUN_DIR"' EXIT

PUBLIC_ROOT="${RUN_DIR}/public"
mkdir -p "$PUBLIC_ROOT"

python3 - "$SOURCE_ROOT" "$PUBLIC_ROOT" <<'PY'
import sys
from pathlib import Path

source_root, public_root = sys.argv[1:3]
sys.path.insert(0, f"{source_root}/scripts")

import public_catalog


def record(bu, project, slug, gate, release, scope, visible=False, title=None, tags=None, hash_char="a"):
    return public_catalog.validate_record(
        {
            "bu": bu,
            "project": project,
            "slug": slug,
            "title_visible": visible,
            "title_public": title,
            "output_url": f"{bu}/{project}/{slug}/",
            "gate_status": gate,
            "release_status": release,
            "scope": scope,
            "tags": tags or [],
            "raw_hash": hash_char * 64,
        }
    )


records = [
    record("staging", "search", "public-article", "public", "released", "public", True, "Public Article", ["search"], "a"),
    record("staging", "search", "gated-article", "gated", "unreleased", "article", hash_char="b"),
    record("staging", "search", "removed-article", "gated", "removed", "article", hash_char="c"),
]
public_catalog.write_catalog(
    Path(public_root) / "_catalog.json",
    {"catalog_version": public_catalog.CATALOG_VERSION, "generated_at": "2026-05-23T00:00:00Z", "records": records},
)
PY

mkdir -p "${PUBLIC_ROOT}/staging/search/public-article"
cat > "${PUBLIC_ROOT}/staging/search/public-article/index.html" <<'HTML'
<!doctype html>
<html>
  <head><title>Public Article · Wikia</title></head>
  <body>PUBLIC_BODY_MARKER</body>
</html>
HTML

python3 "$SEARCH_SCRIPT" "$PUBLIC_ROOT" >/dev/null

python3 - "$PUBLIC_ROOT/search.json" <<'PY'
import json
import sys
from pathlib import Path

items = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
urls = [item.get("url") for item in items]
if urls != ["staging/search/public-article/"]:
    raise SystemExit(f"search urls mismatch: {urls}")
item = items[0]
if item.get("title") != "Public Article":
    raise SystemExit(f"title mismatch: {item}")
if item.get("tags") != ["search"]:
    raise SystemExit(f"tags mismatch: {item}")
if item.get("snippet") != "":
    raise SystemExit("catalog-backed search must not scrape private/raw snippets")
PY

cat <<EOF
---
type: report
title: Catalog Search Index Test
created: $(date +%F)
tags:
  - wikia-cms
  - catalog-state
  - search
related:
  - '[[CMS-CONTRACT]]'
---

# Catalog Search Index Test

## Executive Summary

The search index reads the catalog as the approved public listing and excludes
gated or removed records.

\`\`\`text
_catalog.json
   |
   v
build-search-index.py
   |
   v
search.json public URLs only
\`\`\`

## Verified Checks

| Check | Result |
|---|---|
| Public catalog record included | PASS |
| Gated catalog record excluded | PASS |
| Removed catalog record excluded | PASS |
| Search snippet stayed empty in catalog mode | PASS |

## Images Analyzed

0
EOF
