#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_ROOT="${SOURCE_ROOT:-$(cd "$SCRIPT_DIR/.." && pwd)}"
MIGRATE_SCRIPT="${SOURCE_ROOT}/scripts/migrate-to-cms-state.py"
ADMIN_DB_SCRIPT="${SOURCE_ROOT}/scripts/admin-db.py"
TMP_PARENT="${TMP_PARENT:-${SOURCE_ROOT}/.test-tmp/migrate-to-cms-state-tests}"

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

require_file() {
  [[ -f "$1" ]] || fail "missing required file: $1"
}

require_file "$MIGRATE_SCRIPT"
require_file "$ADMIN_DB_SCRIPT"
mkdir -p "$TMP_PARENT"

RUN_DIR="$(mktemp -d "${TMP_PARENT}/run.XXXXXX")"
trap 'rm -rf "$RUN_DIR"' EXIT

REPO_DIR="${RUN_DIR}/legacy-wikia"
PUBLIC_ROOT="${REPO_DIR}/docs/gitpages"
PUBLIC_ARTICLE="${PUBLIC_ROOT}/staging/public-project/public-article"
PRIVATE_ARTICLE="${PUBLIC_ROOT}/gobbi/private-project/private-article"
OUT_DIR="${RUN_DIR}/out"
mkdir -p "$PUBLIC_ARTICLE" "$PRIVATE_ARTICLE" "$OUT_DIR"

cat > "${PUBLIC_ARTICLE}/raw.md" <<'EOF'
---
bu: staging
project: public-project
slug: public-article
title: Public Growth Memo
date: 2026-05-19
tags: [growth, public]
gate: null
---

Public body may remain public.
EOF

cat > "${PRIVATE_ARTICLE}/raw.md" <<'EOF'
---
bu: gobbi
project: private-project
slug: private-article
title: Secret Private Title
date: 2026-05-19
tags: [private, strategy]
gate: <vault>
---

SECRET PRIVATE BODY MUST NOT BE MIGRATED TO REPORT OR CATALOG.
EOF

printf '%s\n' '<html><title>Public Growth Memo · wikia</title><body>public</body></html>' > "${PUBLIC_ARTICLE}/index.html"
printf '%s\n' '<html><title>Secret Private Title · wikia</title><body>private plaintext legacy page</body></html>' > "${PRIVATE_ARTICLE}/index.html"
printf '%s\n' '[]' > "${PUBLIC_ROOT}/_released.json"
printf '%s\n' '{}' > "${PUBLIC_ROOT}/_pending-changes.json"
cat > "${PUBLIC_ROOT}/search.json" <<'EOF'
[
  {
    "title": "Public Growth Memo",
    "tema": "staging/public-project",
    "tags": ["growth", "public"],
    "date": "2026-05-19",
    "snippet": "public snippet",
    "url": "staging/public-project/public-article/"
  },
  {
    "title": "Secret Private Title",
    "tema": "gobbi/private-project",
    "tags": ["private", "strategy"],
    "date": "2026-05-19",
    "snippet": "SECRET PRIVATE BODY MUST NOT BE MIGRATED TO REPORT OR CATALOG.",
    "url": "gobbi/private-project/private-article/"
  }
]
EOF
printf '%s\n' 'fake encrypted vault fixture' > "${PUBLIC_ROOT}/_passwords.enc"

CATALOG_OUT="${OUT_DIR}/catalog.json"
DB_OUT="${OUT_DIR}/admin-state.sqlite3"
REPORT_OUT="${OUT_DIR}/migration-report.md"
SUMMARY_OUT="${OUT_DIR}/summary.json"

python3 "$MIGRATE_SCRIPT" "$REPO_DIR" \
  --catalog-out "$CATALOG_OUT" \
  --db-out "$DB_OUT" \
  --report-out "$REPORT_OUT" \
  --json > "$SUMMARY_OUT"

[[ -f "$CATALOG_OUT" ]] || fail "catalog was not written"
[[ -f "$DB_OUT" ]] || fail "admin DB was not written"
[[ -f "$REPORT_OUT" ]] || fail "migration report was not written"
[[ -f "${PRIVATE_ARTICLE}/raw.md" ]] || fail "private raw markdown was deleted"

python3 - "$SUMMARY_OUT" "$CATALOG_OUT" "$REPORT_OUT" "$DB_OUT" <<'PY'
import json
import sqlite3
import sys
from pathlib import Path

summary_path, catalog_path, report_path, db_path = [Path(arg) for arg in sys.argv[1:5]]
summary = json.loads(summary_path.read_text(encoding="utf-8"))
catalog_text = catalog_path.read_text(encoding="utf-8")
report_text = report_path.read_text(encoding="utf-8")
catalog = json.loads(catalog_text)

if summary["records"] != 2:
    raise SystemExit(f"expected 2 records, got {summary['records']}")
if summary["private_raw_markdown_exposures"] != 1:
    raise SystemExit(f"expected 1 private raw exposure, got {summary['private_raw_markdown_exposures']}")
if summary["private_search_index_exposures"] != 1:
    raise SystemExit(f"expected 1 private search exposure, got {summary['private_search_index_exposures']}")
if summary["legacy_files_auto_deleted"] != 0:
    raise SystemExit("migrator reported legacy file deletion")

for leaked in ("Secret Private Title", "SECRET PRIVATE BODY", "private plaintext legacy page"):
    if leaked in catalog_text:
        raise SystemExit(f"private data leaked into catalog: {leaked}")
if "SECRET PRIVATE BODY" in report_text or "private plaintext legacy page" in report_text:
    raise SystemExit("private body leaked into report")

records = {f"{row['bu']}/{row['project']}/{row['slug']}": row for row in catalog["records"]}
private_row = records["gobbi/private-project/private-article"]
if private_row["title_visible"] is not False:
    raise SystemExit("private title should not be visible")
if private_row["title_public"] is not None:
    raise SystemExit("private title_public should be null")
if private_row["tags"] != []:
    raise SystemExit("private tags should be hidden from public catalog")
if private_row["gate_status"] != "gated":
    raise SystemExit("private record gate_status should be gated")

conn = sqlite3.connect(db_path)
conn.row_factory = sqlite3.Row
db_private = conn.execute(
    "SELECT title_visible, title_public, tags_json FROM articles WHERE bu=? AND project=? AND slug=?",
    ("gobbi", "private-project", "private-article"),
).fetchone()
if db_private is None:
    raise SystemExit("private row missing from admin DB")
if db_private["title_visible"] != 0 or db_private["title_public"] is not None:
    raise SystemExit("private title leaked into admin DB public title field")
if json.loads(db_private["tags_json"]) != ["private", "strategy"]:
    raise SystemExit("admin DB should preserve tags for unlocked admin state")
PY

DRY_CATALOG="${OUT_DIR}/dry-catalog.json"
DRY_DB="${OUT_DIR}/dry-admin-state.sqlite3"
DRY_REPORT="${OUT_DIR}/dry-report.md"
DRY_SUMMARY="${OUT_DIR}/dry-summary.json"

python3 "$MIGRATE_SCRIPT" "$REPO_DIR" \
  --dry-run \
  --catalog-out "$DRY_CATALOG" \
  --db-out "$DRY_DB" \
  --report-out "$DRY_REPORT" \
  --json > "$DRY_SUMMARY"

[[ ! -e "$DRY_CATALOG" ]] || fail "dry-run wrote catalog"
[[ ! -e "$DRY_DB" ]] || fail "dry-run wrote admin DB"
[[ -f "$DRY_REPORT" ]] || fail "dry-run did not write report"
[[ -f "${PRIVATE_ARTICLE}/raw.md" ]] || fail "dry-run deleted private raw markdown"

python3 - "$DRY_SUMMARY" <<'PY'
import json
import sys

summary = json.loads(open(sys.argv[1], encoding="utf-8").read())
if summary["dry_run"] is not True:
    raise SystemExit("expected dry_run true")
if summary["catalog_written"] is not None:
    raise SystemExit("dry-run should not write catalog")
if summary["db_written"] is not None:
    raise SystemExit("dry-run should not write DB")
if summary["plaintext_private_content_public_after_migration"] is not True:
    raise SystemExit("dry-run should flag remaining private raw exposure")
preview = summary.get("catalog_preview") or {}
if len(preview.get("records", [])) != 2:
    raise SystemExit("dry-run catalog preview missing records")
PY

cat <<EOF
---
type: report
title: Migrate To CMS State Test
created: $(date +%F)
tags:
  - wikia-cms
  - phase-03
  - migration
related:
  - '[[PHASE-03-STATE]]'
  - '[[CMS-CONTRACT]]'
---

# Migrate To CMS State Test

## Executive Summary

The migration script passed fixture coverage for legacy state reads, sanitized
catalog generation, private raw markdown exposure detection, and dry-run
behavior.

\`\`\`text
legacy fixture
   |
   +-- public raw.md
   +-- gated raw.md
   +-- search.json
   |
   v
sanitized catalog + SQLite admin state + migration report
\`\`\`

## Verified Checks

| Check | Result |
|---|---|
| Reads legacy public repo state | PASS |
| Writes sanitized catalog in apply mode | PASS |
| Writes sanitized admin SQLite state in apply mode | PASS |
| Detects gated raw.md under public root | PASS |
| Detects gated metadata in public search index | PASS |
| Does not delete legacy raw.md files | PASS |
| Does not leak private body into catalog/report | PASS |
| Hides private title and tags from public catalog | PASS |
| Preserves private tags only inside admin DB state | PASS |
| Dry-run skips catalog and DB writes | PASS |

## Images Analyzed

0
EOF
