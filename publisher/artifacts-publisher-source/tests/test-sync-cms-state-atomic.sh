#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_ROOT="${SOURCE_ROOT:-$(cd "$SCRIPT_DIR/.." && pwd)}"
TMP_PARENT="${TMP_PARENT:-${SOURCE_ROOT}/.test-tmp/sync-cms-state-atomic-tests}"

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

require_file() {
  [[ -f "$1" ]] || fail "missing required file: $1"
}

require_file "${SOURCE_ROOT}/scripts/public_catalog.py"
require_file "${SOURCE_ROOT}/scripts/sync-cms-state.py"
mkdir -p "$TMP_PARENT"

RUN_DIR="$(mktemp -d "${TMP_PARENT}/run.XXXXXX")"
trap 'rm -rf "$RUN_DIR"' EXIT

python3 - "$SOURCE_ROOT/scripts" "$RUN_DIR" <<'PY'
from __future__ import annotations

import importlib.util
import json
import sys
from pathlib import Path

scripts_dir = Path(sys.argv[1])
run_dir = Path(sys.argv[2])

sys.path.insert(0, str(scripts_dir))
import public_catalog  # noqa: E402

spec = importlib.util.spec_from_file_location(
    "wikia_sync_cms_state",
    scripts_dir / "sync-cms-state.py",
)
if spec is None or spec.loader is None:
    raise SystemExit("could not load sync-cms-state.py")
sync_cms_state = importlib.util.module_from_spec(spec)
spec.loader.exec_module(sync_cms_state)


def make_record(
    *,
    bu: str,
    project: str,
    slug: str,
    title_visible: bool,
    title_public: str | None,
    gate_status: str,
    release_status: str,
    scope: str,
    tags: list[str],
    raw_hash: str,
) -> dict:
    return public_catalog.validate_record(
        {
            "article_id": public_catalog.article_id_for(bu, project, slug),
            "canonical_key": public_catalog.canonical_key_for(bu, project, slug),
            "bu": bu,
            "project": project,
            "slug": slug,
            "title_visible": title_visible,
            "title_public": title_public,
            "output_url": f"{bu}/{project}/{slug}/",
            "gate_status": gate_status,
            "release_status": release_status,
            "scope": scope,
            "tags": tags,
            "raw_hash": raw_hash,
        }
    )


def assert_no_temp_files(parent: Path, target_name: str) -> None:
    leftovers = sorted(path.name for path in parent.glob(f".{target_name}.*"))
    if leftovers:
        raise SystemExit(f"temporary files were not cleaned up for {target_name}: {leftovers}")


atomic_root = run_dir / "atomic-write"
catalog_path = atomic_root / "public" / "_catalog.json"
cms_db_path = atomic_root / "state" / "admin-state.sqlite3"
admin_metadata_path = atomic_root / "state" / "admin-metadata.json"
catalog_path.parent.mkdir(parents=True, exist_ok=True)
cms_db_path.parent.mkdir(parents=True, exist_ok=True)

existing_record = make_record(
    bu="staging",
    project="test-project",
    slug="existing-article",
    title_visible=True,
    title_public="Existing Article",
    gate_status="public",
    release_status="released",
    scope="public",
    tags=["existing"],
    raw_hash="a" * 64,
)
existing_catalog = public_catalog.validate_catalog(
    {
        "catalog_version": 1,
        "generated_at": "2026-05-23T00:00:00Z",
        "records": [existing_record],
    }
)
public_catalog.write_catalog(catalog_path, existing_catalog)
cms_db_path.write_text("KEEP_DB\n", encoding="utf-8")
admin_metadata_path.write_text('{"keep":"metadata"}\n', encoding="utf-8")

catalog_before = catalog_path.read_text(encoding="utf-8")
db_before = cms_db_path.read_text(encoding="utf-8")
metadata_before = admin_metadata_path.read_text(encoding="utf-8")

raw_path = atomic_root / "private-source" / "staging" / "test-project" / "next-article" / "raw.md"
raw_path.parent.mkdir(parents=True, exist_ok=True)
raw_path.write_text(
    "---\n"
    "bu: staging\n"
    "project: test-project\n"
    "slug: next-article\n"
    "title: Next Article\n"
    "date: 2026-05-23\n"
    "gate: public\n"
    "tags: [growth]\n"
    "---\n\n"
    "# Next Article\n",
    encoding="utf-8",
)
next_record = public_catalog.record_from_raw(
    raw_path,
    output_url="staging/test-project/next-article/",
    gate_status="public",
    release_status="released",
    scope="public",
)
next_catalog, _ = public_catalog.upsert_record(existing_catalog, next_record)
metadata = sync_cms_state.admin_metadata(
    [
        (
            next_record,
            {
                "frontmatter": {},
                "raw_tags": ["growth"],
                "raw_path": raw_path,
            },
        )
    ]
)

original_write_admin_db = sync_cms_state.write_admin_db


def fail_write_admin_db(db_path: Path, records: list[tuple[dict, dict]]) -> None:
    raise RuntimeError("forced admin-db failure")


sync_cms_state.write_admin_db = fail_write_admin_db
try:
    try:
        sync_cms_state.write_state_atomically(
            catalog_path,
            next_catalog,
            cms_db_path,
            admin_metadata_path,
            [
                (
                    next_record,
                    {
                        "frontmatter": {},
                        "raw_tags": ["growth"],
                        "raw_path": raw_path,
                    },
                )
            ],
            metadata,
        )
    except RuntimeError as exc:
        if "forced admin-db failure" not in str(exc):
            raise SystemExit(f"unexpected atomic failure error: {exc}")
    else:
        raise SystemExit("write_state_atomically unexpectedly succeeded")
finally:
    sync_cms_state.write_admin_db = original_write_admin_db

if catalog_path.read_text(encoding="utf-8") != catalog_before:
    raise SystemExit("catalog changed after forced admin-db failure")
if cms_db_path.read_text(encoding="utf-8") != db_before:
    raise SystemExit("cms DB target changed after forced admin-db failure")
if admin_metadata_path.read_text(encoding="utf-8") != metadata_before:
    raise SystemExit("admin metadata target changed after forced admin-db failure")

assert_no_temp_files(catalog_path.parent, catalog_path.name)
assert_no_temp_files(cms_db_path.parent, cms_db_path.name)
assert_no_temp_files(admin_metadata_path.parent, admin_metadata_path.name)

invalid_root = run_dir / "invalid-sync"
public_root = invalid_root / "public"
raw_root = invalid_root / "private-source"
catalog_target = public_root / "_catalog.json"
cms_db_target = invalid_root / "state" / "admin-state.sqlite3"
admin_metadata_target = invalid_root / "state" / "admin-metadata.json"
released_path = public_root / "_released.json"

public_root.mkdir(parents=True, exist_ok=True)
cms_db_target.parent.mkdir(parents=True, exist_ok=True)
released_path.write_text("[]\n", encoding="utf-8")
public_catalog.write_catalog(catalog_target, existing_catalog)
cms_db_target.write_text("KEEP_SYNC_DB\n", encoding="utf-8")
admin_metadata_target.write_text('{"keep":"sync-metadata"}\n', encoding="utf-8")

invalid_catalog_before = catalog_target.read_text(encoding="utf-8")
invalid_db_before = cms_db_target.read_text(encoding="utf-8")
invalid_metadata_before = admin_metadata_target.read_text(encoding="utf-8")

bad_raw = raw_root / "staging" / "bad-project" / "BadSlug" / "raw.md"
bad_raw.parent.mkdir(parents=True, exist_ok=True)
bad_raw.write_text(
    "---\n"
    "bu: staging\n"
    "project: bad-project\n"
    "slug: BadSlug\n"
    "title: Bad Slug\n"
    "date: 2026-05-23\n"
    "gate: public\n"
    "---\n\n"
    "# Bad Slug\n",
    encoding="utf-8",
)

try:
    sync_cms_state.sync_state(
        public_root,
        raw_root,
        released_path,
        cms_db_target,
        admin_metadata_target,
    )
except ValueError as exc:
    if "BadSlug" not in str(exc):
        raise SystemExit(f"unexpected sync validation error: {exc}")
else:
    raise SystemExit("sync_state unexpectedly succeeded for invalid raw slug")

if catalog_target.read_text(encoding="utf-8") != invalid_catalog_before:
    raise SystemExit("catalog changed after sync_state validation failure")
if cms_db_target.read_text(encoding="utf-8") != invalid_db_before:
    raise SystemExit("cms DB changed after sync_state validation failure")
if admin_metadata_target.read_text(encoding="utf-8") != invalid_metadata_before:
    raise SystemExit("admin metadata changed after sync_state validation failure")
PY

cat <<EOF
---
type: report
title: Sync CMS State Atomic Test
created: $(date +%F)
tags:
  - wikia-cms
  - phase-03
  - sync-state
related:
  - '[[PHASE-03-STATE]]'
  - '[[CMS-CONTRACT]]'
---

# Sync CMS State Atomic Test

## Executive Summary

The state sync now behaves like a bank transfer with a rollback: if admin-state
writing fails or a raw record breaks the catalog contract, the final catalog,
DB target, and admin metadata stay untouched.

\`\`\`text
temp files
   |
   v
validate everything
   |
   +-- success -> replace final files
   +-- failure -> keep original files
\`\`\`

## Verified Checks

| Check | Result |
|---|---|
| Forced admin DB failure left final catalog unchanged | PASS |
| Forced admin DB failure left final DB target unchanged | PASS |
| Forced admin DB failure left final admin metadata unchanged | PASS |
| Forced admin DB failure cleaned temp sibling files | PASS |
| Invalid raw slug failed sync before writing final targets | PASS |
| Invalid raw slug left existing catalog unchanged | PASS |
| Invalid raw slug left existing DB target unchanged | PASS |
| Invalid raw slug left existing admin metadata unchanged | PASS |

## Images Analyzed

0
EOF
