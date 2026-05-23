#!/usr/bin/env bash
set -euo pipefail

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_ROOT="$(cd "${TEST_DIR}/.." && pwd)"
TMP_PARENT="${SOURCE_ROOT}/tmp/phase-07-smoke-tests"

VAULT_SCRIPT="${SOURCE_ROOT}/scripts/vault.mjs"
MIGRATE_SCRIPT="${SOURCE_ROOT}/scripts/migrate-to-cms-state.py"
RENDER_ARTIFACT_SCRIPT="${SOURCE_ROOT}/scripts/render-artifact.py"
RENDER_WIKI_SCRIPT="${SOURCE_ROOT}/scripts/render-wiki.py"
RENDER_ADMIN_SCRIPT="${SOURCE_ROOT}/scripts/render-admin.py"
PUBLISH_SCRIPT="${SOURCE_ROOT}/scripts/publish.sh"

THEME_JSON='{"bgMain":"#0c0e0c","bgSidebar":"#0f100f","bgActivity":"#141415","border":"#111311","textMain":"#f2f2c0","textDim":"#cec8ba","accent":"#5b675b","accentDim":"#262121","accentText":"#ffffff","success":"#bed78e","warning":"#d0a795","error":"#ff5555"}'
WIKI_BASE="https://fixture.test/wikia/gitpages"

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

require_file() {
  [[ -f "$1" ]] || fail "missing required file: $1"
}

write_raw_fixture() {
  local path="$1"
  local bu="$2"
  local project="$3"
  local slug="$4"
  local title="$5"
  local gate="$6"

  mkdir -p "$(dirname "$path")"
  cat > "$path" <<MD
---
bu: $bu
project: $project
slug: $slug
title: $title
date: 2026-05-19
tags: [smoke, phase-seven]
gate: $gate
---

# $title

Fixture body for deterministic smoke tests.
MD
}

write_html_fixture() {
  local path="$1"
  local title="$2"

  mkdir -p "$(dirname "$path")"
  cat > "$path" <<HTML
<!doctype html>
<html>
  <head>
    <title>$title - wikia</title>
    <meta name="description" content="Smoke fixture">
  </head>
  <body>$title</body>
</html>
HTML
}

verify_vault_smoke() {
  local vault_path="$1"
  local set_json="$2"
  local get_json="$3"
  local list_json="$4"
  local expected_password="$5"

  python3 - "$set_json" "$get_json" "$list_json" "$expected_password" <<'PY'
import json
import sys

set_path, get_path, list_path, expected_password = sys.argv[1:5]
set_payload = json.load(open(set_path, encoding="utf-8"))
get_payload = json.load(open(get_path, encoding="utf-8"))
list_payload = json.load(open(list_path, encoding="utf-8"))

if set_payload.get("ok") is not True or set_payload.get("entries") != 1:
    raise SystemExit(f"vault set smoke failed: {set_payload}")
if get_payload.get("password") != expected_password:
    raise SystemExit("vault get did not round-trip the fixture password")
if list_payload.get("ok") is not True or list_payload.get("slugs") != ["smoke-vault-article"]:
    raise SystemExit(f"vault list smoke failed: {list_payload}")
PY

  if grep -Fq "$expected_password" "$vault_path"; then
    fail "vault file contains plaintext fixture password"
  fi
}

verify_migration_smoke() {
  local dry_json="$1"
  local write_json="$2"
  local catalog_path="$3"
  local db_path="$4"

  python3 - "$dry_json" "$write_json" "$catalog_path" "$db_path" <<'PY'
import json
import sqlite3
import sys
from pathlib import Path

dry_path, write_path, catalog_path, db_path = sys.argv[1:5]
dry = json.load(open(dry_path, encoding="utf-8"))
written = json.load(open(write_path, encoding="utf-8"))
catalog = json.load(open(catalog_path, encoding="utf-8"))

if dry.get("dry_run") is not True:
    raise SystemExit(f"migration dry-run flag missing: {dry}")
if dry.get("records") != 2:
    raise SystemExit(f"expected 2 migrated records in dry-run, got {dry.get('records')}")
if dry.get("private_raw_markdown_exposures") != 1:
    raise SystemExit(f"expected 1 private raw exposure, got {dry.get('private_raw_markdown_exposures')}")
if dry.get("private_search_index_exposures") != 1:
    raise SystemExit(f"expected 1 private search exposure, got {dry.get('private_search_index_exposures')}")
if written.get("dry_run") is not False:
    raise SystemExit(f"migration write run was still dry-run: {written}")

records = catalog.get("records") or []
if len(records) != 2:
    raise SystemExit(f"expected 2 catalog records, got {len(records)}")

private = [r for r in records if r.get("slug") == "smoke-private"]
if len(private) != 1:
    raise SystemExit("missing private catalog record")
private = private[0]
if private.get("title_visible") is not False or private.get("title_public") is not None:
    raise SystemExit(f"private catalog title was not sanitized: {private}")
if private.get("tags") != []:
    raise SystemExit(f"private catalog tags were not sanitized: {private}")

with sqlite3.connect(db_path) as conn:
    count = conn.execute("SELECT COUNT(*) FROM articles").fetchone()[0]
    private_row = conn.execute(
        "SELECT title_visible, title_public FROM articles WHERE slug = 'smoke-private'"
    ).fetchone()
if count != 2:
    raise SystemExit(f"expected 2 admin DB rows, got {count}")
if private_row != (0, None):
    raise SystemExit(f"private DB row was not sanitized: {private_row}")

for path in (catalog_path, db_path):
    if not Path(path).exists():
        raise SystemExit(f"missing migration output: {path}")
PY
}

verify_renderer_smoke() {
  local wiki_index="$1"
  local artifact_html="$2"

  python3 - "$wiki_index" "$artifact_html" <<'PY'
import sys
from pathlib import Path

wiki_index = Path(sys.argv[1]).read_text(encoding="utf-8")
artifact = Path(sys.argv[2]).read_text(encoding="utf-8")

if "Smoke Public Article" not in wiki_index:
    raise SystemExit("wiki renderer did not include the public smoke article")
if "Smoke Private Article" in wiki_index or "smoke-private" in wiki_index:
    raise SystemExit("wiki renderer leaked private smoke metadata")
if "Smoke Public Article" not in artifact:
    raise SystemExit("artifact renderer did not include the smoke article")
if artifact.count('<nav class="wk-sidebar-nav">') != 1:
    raise SystemExit("artifact renderer did not emit exactly one sidebar nav")
if artifact.count('<ul class="wk-tree">') != 1:
    raise SystemExit("artifact renderer did not emit exactly one tree root")
if "wk-tree-tema" in artifact:
    raise SystemExit("artifact renderer emitted legacy wk-tree-tema")
if "gobbi/private-project" in artifact or "smoke-private" in artifact:
    raise SystemExit("artifact renderer leaked cross-BU private metadata")
PY
}

verify_admin_contract_smoke() {
  local admin_html="$1"
  local released_json="$2"
  local pending_json="$3"

  python3 - "$admin_html" "$released_json" "$pending_json" <<'PY'
import json
import sys
from pathlib import Path

admin_html, released_json, pending_json = sys.argv[1:4]
html = Path(admin_html).read_text(encoding="utf-8")

required = [
    "/_admin.enc",
    "window.__admin",
    "adminMetadata",
    "password vault only; never defines article universe",
    "A lista vem de _admin.enc",
]
for marker in required:
    if marker not in html:
        raise SystemExit(f"admin contract marker missing: {marker}")

for forbidden in [
    "Object.keys(vault",
    "pending.vault",
    "docs/gitpages/_passwords.enc",
    "Smoke Public Article",
    "Smoke Private Article",
    "smoke-private",
    "gobbi/private-project",
    '<span class="count">',
    'class="wk-tree-bu"',
    'class="wk-tree-project"',
    'class="wk-tree-article"',
    "wk-tree-tema",
]:
    if forbidden in html:
        raise SystemExit(f"admin initial HTML leaked forbidden marker: {forbidden}")

if json.load(open(released_json, encoding="utf-8")) != []:
    raise SystemExit("admin renderer did not bootstrap an empty release ledger")
if json.load(open(pending_json, encoding="utf-8")) != {}:
    raise SystemExit("admin renderer did not bootstrap an empty pending ledger")
PY
}

verify_publish_smoke() {
  local publish_json="$1"
  local publish_stderr="$2"
  local publish_workdir_out="$3"

  python3 - "$publish_json" "$publish_stderr" "$publish_workdir_out" <<'PY'
import json
import sys
from pathlib import Path

payload_path, stderr_path, workdir_out = sys.argv[1:4]
payload = json.load(open(payload_path, encoding="utf-8"))

if payload.get("dry_run") is not True:
    raise SystemExit(f"publish did not report dry_run=true: {payload}")
if payload.get("slug") != "smoke-publish-article":
    raise SystemExit(f"publish slug mismatch: {payload}")
if not payload.get("url", "").endswith("/staging/smoke-project/smoke-publish-article/"):
    raise SystemExit(f"publish URL mismatch: {payload}")

workdir = Path(payload.get("workdir", ""))
if not workdir.is_dir():
    raise SystemExit(f"publish workdir was not preserved: {workdir}")

expected_files = [
    workdir / "docs/gitpages/_catalog.json",
    workdir / "docs/gitpages/search.json",
    workdir / "docs/gitpages/index.html",
    workdir / "docs/gitpages/staging/index.html",
    workdir / "docs/gitpages/staging/smoke-project/index.html",
    workdir / "docs/gitpages/staging/smoke-project/smoke-publish-article/index.html",
]
for path in expected_files:
    if not path.exists():
        raise SystemExit(f"publish dry-run missing expected file: {path}")

catalog = json.load(open(workdir / "docs/gitpages/_catalog.json", encoding="utf-8"))
records = catalog.get("records") or []
if len(records) != 1:
    raise SystemExit(f"publish catalog expected 1 record, got {len(records)}")
record = records[0]
if record.get("gate_status") != "public" or record.get("release_status") != "released":
    raise SystemExit(f"publish public state mismatch: {record}")
if record.get("output_url") != "staging/smoke-project/smoke-publish-article/":
    raise SystemExit(f"publish output URL mismatch: {record}")

search = json.load(open(workdir / "docs/gitpages/search.json", encoding="utf-8"))
if len(search) != 1 or search[0].get("url") != "staging/smoke-project/smoke-publish-article/":
    raise SystemExit(f"publish search mismatch: {search}")

artifact = (workdir / "docs/gitpages/staging/smoke-project/smoke-publish-article/index.html").read_text(
    encoding="utf-8"
)
if "Smoke Publish Article" not in artifact:
    raise SystemExit("publish dry-run artifact missing title")
if "{{GATE_BLOCK}}" in artifact:
    raise SystemExit("publish dry-run left gate placeholder in public artifact")
if list((workdir / "docs/gitpages").rglob("raw.md")):
    raise SystemExit("publish dry-run copied raw.md into public output")

stderr = Path(stderr_path).read_text(encoding="utf-8")
if "Workdir preserved" not in stderr:
    raise SystemExit("publish dry-run did not report preserved workdir")

Path(workdir_out).write_text(str(workdir), encoding="utf-8")
PY
}

require_file "$VAULT_SCRIPT"
require_file "$MIGRATE_SCRIPT"
require_file "$RENDER_ARTIFACT_SCRIPT"
require_file "$RENDER_WIKI_SCRIPT"
require_file "$RENDER_ADMIN_SCRIPT"
require_file "$PUBLISH_SCRIPT"

mkdir -p "$TMP_PARENT"
RUN_DIR="$(mktemp -d "${TMP_PARENT}/run.XXXXXX")"
PUBLISH_WORKDIR=""
cleanup() {
  rm -rf "$RUN_DIR"
  if [[ -n "$PUBLISH_WORKDIR" ]]; then
    rm -rf "$PUBLISH_WORKDIR"
  fi
}
trap cleanup EXIT

# 1. Vault smoke.
VAULT_PATH="${RUN_DIR}/_passwords.enc"
MASTERPASS="phase-07-smoke-masterpass"
SMOKE_PASSWORD="phase-07-smoke-password"
printf '%s' "$MASTERPASS" | node "$VAULT_SCRIPT" init "$VAULT_PATH" - > "${RUN_DIR}/vault-init.json"
printf '%s' "$MASTERPASS" | node "$VAULT_SCRIPT" set "$VAULT_PATH" - smoke-vault-article "$SMOKE_PASSWORD" smoke-project > "${RUN_DIR}/vault-set.json"
printf '%s' "$MASTERPASS" | node "$VAULT_SCRIPT" get "$VAULT_PATH" - smoke-vault-article > "${RUN_DIR}/vault-get.json"
printf '%s' "$MASTERPASS" | node "$VAULT_SCRIPT" list "$VAULT_PATH" - > "${RUN_DIR}/vault-list.json"
verify_vault_smoke "$VAULT_PATH" "${RUN_DIR}/vault-set.json" "${RUN_DIR}/vault-get.json" "${RUN_DIR}/vault-list.json" "$SMOKE_PASSWORD"

# 2. Migration smoke.
LEGACY_REPO="${RUN_DIR}/legacy-repo"
PUBLIC_ROOT="${LEGACY_REPO}/docs/gitpages"
PUBLIC_RAW="${PUBLIC_ROOT}/staging/smoke-project/smoke-public/raw.md"
PRIVATE_RAW="${PUBLIC_ROOT}/gobbi/private-project/smoke-private/raw.md"
write_raw_fixture "$PUBLIC_RAW" staging smoke-project smoke-public "Smoke Public Article" null
write_raw_fixture "$PRIVATE_RAW" gobbi private-project smoke-private "Smoke Private Article" smoke-gate
write_html_fixture "${PUBLIC_ROOT}/staging/smoke-project/smoke-public/index.html" "Smoke Public Article"
write_html_fixture "${PUBLIC_ROOT}/gobbi/private-project/smoke-private/index.html" "Smoke Private Article"
cat > "${PUBLIC_ROOT}/_released.json" <<'JSON'
[
  "staging/smoke-project/smoke-public/"
]
JSON
cat > "${PUBLIC_ROOT}/search.json" <<'JSON'
[
  {
    "title": "Smoke Public Article",
    "tema": "staging/smoke-project",
    "tags": ["smoke"],
    "date": "2026-05-19",
    "snippet": "public",
    "url": "staging/smoke-project/smoke-public/"
  },
  {
    "title": "Smoke Private Article",
    "tema": "gobbi/private-project",
    "tags": ["smoke"],
    "date": "2026-05-19",
    "snippet": "private",
    "url": "gobbi/private-project/smoke-private/"
  }
]
JSON

CATALOG_PATH="${PUBLIC_ROOT}/_catalog.json"
DB_PATH="${RUN_DIR}/admin-state.sqlite3"
REPORT_PATH="${RUN_DIR}/migration-report.md"
python3 "$MIGRATE_SCRIPT" "$LEGACY_REPO" --dry-run --json > "${RUN_DIR}/migrate-dry.json"
python3 "$MIGRATE_SCRIPT" "$LEGACY_REPO" --catalog-out "$CATALOG_PATH" --db-out "$DB_PATH" --report-out "$REPORT_PATH" --json > "${RUN_DIR}/migrate-write.json"
verify_migration_smoke "${RUN_DIR}/migrate-dry.json" "${RUN_DIR}/migrate-write.json" "$CATALOG_PATH" "$DB_PATH"

# 3. Renderer smoke.
python3 "$RENDER_WIKI_SCRIPT" "$PUBLIC_ROOT" "$THEME_JSON" wikia "$WIKI_BASE" > "${RUN_DIR}/render-wiki.stdout" 2> "${RUN_DIR}/render-wiki.stderr"
WIKIA_PUBLIC_ROOT="$PUBLIC_ROOT" python3 "$RENDER_ARTIFACT_SCRIPT" \
  "$PUBLIC_RAW" "$THEME_JSON" "Smoke Public Article" smoke-public smoke-project wikia 2026-05-19 smoke,phase-seven claude "[]" "[]" "$WIKI_BASE" \
  > "${PUBLIC_ROOT}/staging/smoke-project/smoke-public/index.html"
verify_renderer_smoke "${PUBLIC_ROOT}/index.html" "${PUBLIC_ROOT}/staging/smoke-project/smoke-public/index.html"

# 4. Admin client contract smoke.
ADMIN_ROOT="${RUN_DIR}/admin-root"
mkdir -p "$ADMIN_ROOT"
python3 "$RENDER_ADMIN_SCRIPT" "$ADMIN_ROOT" "$THEME_JSON" "$WIKI_BASE" --cms-state "$DB_PATH" > "${RUN_DIR}/render-admin.stdout" 2> "${RUN_DIR}/render-admin.stderr"
verify_admin_contract_smoke "${ADMIN_ROOT}/admin/index.html" "${ADMIN_ROOT}/_released.json" "${ADMIN_ROOT}/_pending-changes.json"

# 5. Publish dry-run smoke.
PUBLISH_SOURCE="${RUN_DIR}/publish-source.md"
write_raw_fixture "$PUBLISH_SOURCE" staging smoke-project smoke-publish-article "Smoke Publish Article" null
bash "$PUBLISH_SCRIPT" \
  --title "Smoke Publish Article" \
  --content "$PUBLISH_SOURCE" \
  --slug smoke-publish-article \
  --bu staging \
  --project smoke-project \
  --tags smoke,phase-seven \
  --no-gate \
  --dry-run \
  --repo felipeggv/wikia \
  > "${RUN_DIR}/publish.json" 2> "${RUN_DIR}/publish.stderr"
verify_publish_smoke "${RUN_DIR}/publish.json" "${RUN_DIR}/publish.stderr" "${RUN_DIR}/publish-workdir.txt"
PUBLISH_WORKDIR="$(cat "${RUN_DIR}/publish-workdir.txt")"

cat <<EOF
---
type: report
title: Phase 07 Smoke Tests
created: $(date +%F)
tags:
  - wikia-cms
  - phase-07
  - smoke-tests
related:
  - '[[PHASE-07-VALIDATION]]'
  - '[[CMS-CONTRACT]]'
---

# Phase 07 Smoke Tests

## Executive Summary

The smoke suite passed for the critical CMS path: vault, migration, renderers,
admin client contract, and publish dry-run.

\`\`\`text
fixture content
   |
   +-- vault encryption
   +-- state migration
   +-- renderer output
   +-- admin locked contract
   +-- publish dry-run
   |
   v
deterministic PASS
\`\`\`

## Results

| Area | Result | Smoke Coverage |
|---|---|---|
| Vault | PASS | init, set, get, list, no plaintext password in vault file |
| Migration | PASS | dry-run summary, catalog write, admin SQLite write, private metadata sanitization |
| Renderer | PASS | wiki home, artifact page, one sidebar wrapper, no legacy \`wk-tree-tema\`, no cross-BU private leak |
| Admin client contract | PASS | locked shell, encrypted \`_admin.enc\` contract, no vault-derived article universe, ledger bootstraps |
| Publish dry-run | PASS | public article dry-run, catalog/search/index outputs, no public \`raw.md\`, preserved workdir validated |

## Images Analyzed

0
EOF
