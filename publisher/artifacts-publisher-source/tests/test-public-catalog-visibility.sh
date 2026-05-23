#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_ROOT="${SOURCE_ROOT:-$(cd "$SCRIPT_DIR/.." && pwd)}"
PUBLIC_CATALOG_SCRIPT="${SOURCE_ROOT}/scripts/public_catalog.py"

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

require_file() {
  [[ -f "$1" ]] || fail "missing required file: $1"
}

require_file "$PUBLIC_CATALOG_SCRIPT"

python3 - "$SOURCE_ROOT" <<'PY'
import sys

source_root = sys.argv[1]
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
    record("staging", "growth", "public-report", "public", "released", "public", True, "Public Report", ["growth"], "a"),
    record("gobbi", "private", "project-scope", "gated", "unreleased", "project", hash_char="b"),
    record("gobbi", "private", "sibling-scope", "gated", "unreleased", "article", hash_char="c"),
    record("gobbi", "strategy", "bu-scope", "gated", "unreleased", "bu", hash_char="d"),
    record("allin", "ops", "admin-scope", "gated", "unreleased", "admin", hash_char="e"),
    record("gobbi", "private", "removed-report", "gated", "removed", "article", hash_char="f"),
]

catalog = public_catalog.validate_catalog(
    {"catalog_version": public_catalog.CATALOG_VERSION, "generated_at": "2026-05-23T00:00:00Z", "records": records}
)
records = catalog["records"]


def keys(rows):
    return [public_catalog.record_key(row) for row in rows]


public_keys = keys(public_catalog.scoped_records(records))
if public_keys != ["staging/growth/public-report"]:
    raise SystemExit(f"public scope mismatch: {public_keys}")

project_current = next(row for row in records if public_catalog.record_key(row) == "gobbi/private/project-scope")
project_keys = keys(public_catalog.scoped_records(records, project_current))
if project_keys != ["gobbi/private/project-scope", "gobbi/private/sibling-scope"]:
    raise SystemExit(f"project scope mismatch: {project_keys}")

bu_current = next(row for row in records if public_catalog.record_key(row) == "gobbi/strategy/bu-scope")
bu_keys = keys(public_catalog.scoped_records(records, bu_current))
if bu_keys != ["gobbi/private/project-scope", "gobbi/private/sibling-scope", "gobbi/strategy/bu-scope"]:
    raise SystemExit(f"bu scope mismatch: {bu_keys}")

admin_current = next(row for row in records if public_catalog.record_key(row) == "allin/ops/admin-scope")
admin_keys = keys(public_catalog.scoped_records(records, admin_current))
if "gobbi/private/removed-report" in admin_keys:
    raise SystemExit(f"removed record leaked into admin-scope navigation: {admin_keys}")
if len(admin_keys) != 5:
    raise SystemExit(f"admin scope should include all non-removed records, got: {admin_keys}")

removed_record = next(row for row in records if public_catalog.record_key(row) == "gobbi/private/removed-report")
if public_catalog.is_public_record(removed_record):
    raise SystemExit("removed record was treated as public")

bad_removed = dict(removed_record)
bad_removed["gate_status"] = "public"
try:
    public_catalog.validate_record(bad_removed)
except ValueError:
    pass
else:
    raise SystemExit("removed/public malformed record was accepted")

if public_catalog.is_private_gate("false"):
    raise SystemExit("gate=false should behave like public/no gate")
PY

cat <<EOF
---
type: report
title: Public Catalog Visibility Test
created: $(date +%F)
tags:
  - wikia-cms
  - catalog-state
  - visibility
related:
  - '[[CMS-CONTRACT]]'
---

# Public Catalog Visibility Test

## Executive Summary

The public catalog visibility rules passed. Public, scoped, admin, and removed
records now use one shared rulebook.

\`\`\`text
_catalog.json
   |
   v
public_catalog.py
   |
   +-- public search/nav
   +-- scoped gated nav
   +-- validator expectations
\`\`\`

## Verified Checks

| Check | Result |
|---|---|
| Public view includes only released public records | PASS |
| Project scope includes only same project records | PASS |
| BU scope includes only same BU records | PASS |
| Admin scope excludes removed navigation records | PASS |
| Malformed removed/public record rejected | PASS |
| \`gate=false\` treated as no private gate | PASS |

## Images Analyzed

0
EOF
