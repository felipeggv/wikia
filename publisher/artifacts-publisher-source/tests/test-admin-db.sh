#!/usr/bin/env bash
set -euo pipefail

PLAYBOOK_ROOT="/Users/felipegobbi/Documents/VibeworkV2/Auto Run Docs/2026-05-19-Wikia-CMS-Refactor"
SOURCE_ROOT="${PLAYBOOK_ROOT}/Working/artifacts-publisher-source"
ADMIN_DB_SCRIPT="${SOURCE_ROOT}/scripts/admin-db.py"
TMP_PARENT="${PLAYBOOK_ROOT}/Working/tmp/admin-db-tests"

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

require_file() {
  [[ -f "$1" ]] || fail "missing required file: $1"
}

require_file "$ADMIN_DB_SCRIPT"
mkdir -p "$TMP_PARENT"

RUN_DIR="$(mktemp -d "${TMP_PARENT}/run.XXXXXX")"
trap 'rm -rf "$RUN_DIR"' EXIT

DB_PATH="${RUN_DIR}/admin.db"
RAW_SOURCE_PATH="${RUN_DIR}/private-source/raw.md"
mkdir -p "$(dirname "$RAW_SOURCE_PATH")"
printf '%s\n' 'fixture raw source used only for hash verification' > "$RAW_SOURCE_PATH"

RAW_HASH="$(python3 - "$RAW_SOURCE_PATH" <<'PY'
import hashlib
import sys
from pathlib import Path

print(hashlib.sha256(Path(sys.argv[1]).read_bytes()).hexdigest())
PY
)"

INIT_JSON="${RUN_DIR}/init.json"
python3 "$ADMIN_DB_SCRIPT" init "$DB_PATH" --json > "$INIT_JSON"

AUDIT_JSON="${RUN_DIR}/audit.json"
python3 "$ADMIN_DB_SCRIPT" audit "$DB_PATH" --json > "$AUDIT_JSON"

python3 - "$DB_PATH" "$AUDIT_JSON" <<'PY'
import json
import sqlite3
import sys

db_path, audit_path = sys.argv[1:3]
expected = {
    "article_id",
    "bu",
    "project",
    "slug",
    "title_visible",
    "raw_source_path",
    "output_url",
    "gate_status",
    "release_status",
    "scope",
    "tags_json",
    "raw_hash",
}
forbidden_terms = (
    "password",
    "passwd",
    "passphrase",
    "masterpass",
    "secret",
    "token",
    "plaintext",
    "body",
    "content",
    "markdown",
    "private_title",
    "private_content",
)

audit = json.loads(open(audit_path, encoding="utf-8").read())
if audit.get("ok") is not True:
    raise SystemExit(f"audit did not pass: {audit}")

conn = sqlite3.connect(db_path)
columns = {row[1] for row in conn.execute("PRAGMA table_info(articles)")}
missing = sorted(expected - columns)
if missing:
    raise SystemExit(f"missing expected columns: {missing}")

bad = [
    column
    for column in columns
    if any(term in column.lower() for term in forbidden_terms)
]
if bad:
    raise SystemExit(f"forbidden schema columns found: {bad}")
PY

UPSERT_JSON="${RUN_DIR}/upsert.json"
python3 "$ADMIN_DB_SCRIPT" upsert "$DB_PATH" \
  --bu staging \
  --project test-project \
  --slug pricing-strategy-playbook \
  --raw-source-path "$RAW_SOURCE_PATH" \
  --output-url "staging/test-project/pricing-strategy-playbook/" \
  --gate-status gated \
  --release-status unreleased \
  --scope article \
  --tags-json '["fixture","cms-state"]' \
  --raw-hash "$RAW_HASH" \
  --json > "$UPSERT_JSON"

if python3 "$ADMIN_DB_SCRIPT" upsert "$DB_PATH" \
  --bu staging \
  --project private-project \
  --slug hidden-title-fixture \
  --title-public "Hidden Title Must Not Persist" \
  --raw-source-path "$RAW_SOURCE_PATH" \
  --output-url "staging/private-project/hidden-title-fixture/" \
  --gate-status gated \
  --release-status unreleased \
  --scope article \
  --tags-json '[]' \
  --raw-hash "$RAW_HASH" \
  --json > "${RUN_DIR}/bad-title.json" 2> "${RUN_DIR}/bad-title.err"; then
  fail "title_public was accepted while title_visible was false"
fi

LIST_JSON="${RUN_DIR}/list.json"
python3 "$ADMIN_DB_SCRIPT" list "$DB_PATH" --json > "$LIST_JSON"

python3 - "$LIST_JSON" "$RAW_HASH" "$RAW_SOURCE_PATH" <<'PY'
import json
import sys

list_path, raw_hash, raw_source_path = sys.argv[1:4]
payload = json.loads(open(list_path, encoding="utf-8").read())
if payload.get("ok") is not True:
    raise SystemExit(f"list did not pass: {payload}")
if payload.get("entries") != 1:
    raise SystemExit(f"expected 1 row, got {payload.get('entries')}")
row = payload["articles"][0]
checks = {
    "bu": "staging",
    "project": "test-project",
    "slug": "pricing-strategy-playbook",
    "title_visible": 0,
    "title_public": None,
    "raw_source_path": raw_source_path,
    "output_url": "staging/test-project/pricing-strategy-playbook/",
    "gate_status": "gated",
    "release_status": "unreleased",
    "scope": "article",
    "tags_json": '["fixture","cms-state"]',
    "raw_hash": raw_hash,
}
for key, expected in checks.items():
    actual = row.get(key)
    if actual != expected:
        raise SystemExit(f"{key} mismatch: expected {expected!r}, got {actual!r}")
PY

cat <<EOF
---
type: report
title: Admin DB Schema Test
created: $(date +%F)
tags:
  - wikia-cms
  - phase-03
  - sqlite
related:
  - '[[PHASE-03-STATE]]'
  - '[[CMS-CONTRACT]]'
---

# Admin DB Schema Test

## Executive Summary

The sanitized SQLite admin state schema passed. It stores article routing and
state labels only; it does not define plaintext password columns or article body
columns.

\`\`\`text
article source
   |
   v
SHA-256 hash + route metadata
   |
   v
sanitized SQLite catalog
\`\`\`

## Verified Fields

| Field | Result |
|---|---|
| article_id | PASS |
| bu | PASS |
| project | PASS |
| slug | PASS |
| title_visible | PASS |
| raw_source_path | PASS |
| output_url | PASS |
| gate_status | PASS |
| release_status | PASS |
| scope | PASS |
| tags_json | PASS |
| raw_hash | PASS |

## Privacy Checks

| Check | Result |
|---|---|
| Schema audit returned ok | PASS |
| Plaintext password-like columns absent | PASS |
| Article body/content columns absent | PASS |
| Private title rejected when title_visible is false | PASS |
| Test data used fake fixture values only | PASS |

## Files Exercised

\`\`\`text
${ADMIN_DB_SCRIPT}
temporary SQLite database under ${TMP_PARENT}
\`\`\`

## Images Analyzed

0
EOF
