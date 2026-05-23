#!/usr/bin/env python3
"""Build the wikia CMS state spine from raw sources.

The public catalog, private build-time SQLite state, and encrypted-admin
metadata plaintext input must describe the same article records before the
publish pipeline renders pages.
"""
from __future__ import annotations

import argparse
import importlib.util
import json
import sys
from pathlib import Path
from typing import Any

SCRIPT_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(SCRIPT_DIR))

from frontmatter_parser import parse_frontmatter  # noqa: E402
import public_catalog  # noqa: E402


def load_json(path: Path, default: Any) -> Any:
    if not path.exists():
        return default
    text = path.read_text(encoding="utf-8").strip()
    if not text:
        return default
    return json.loads(text)


def normalize_token(value: Any) -> str:
    return str(value or "").strip().strip("/")


def key_from_released_item(item: Any) -> str:
    if isinstance(item, str):
        return normalize_token(item)
    if not isinstance(item, dict):
        return ""
    if item.get("bu") and item.get("project") and item.get("slug"):
        return f"{normalize_token(item['bu'])}/{normalize_token(item['project'])}/{normalize_token(item['slug'])}"
    if item.get("url"):
        return normalize_token(item["url"])
    return normalize_token(item.get("slug"))


def released_token_set(released: Any) -> set[str]:
    tokens: set[str] = set()
    if isinstance(released, list):
        for item in released:
            token = key_from_released_item(item)
            if token:
                tokens.add(token)
    elif isinstance(released, dict):
        for key, value in released.items():
            for token in (key_from_released_item(key), key_from_released_item(value)):
                if token:
                    tokens.add(token)
    return tokens


def load_existing_records(catalog_path: Path) -> dict[str, dict[str, Any]]:
    if not catalog_path.exists():
        return {}
    catalog = public_catalog.load_catalog(catalog_path)
    records = {}
    for item in catalog.get("records", []):
        if not isinstance(item, dict):
            continue
        record = public_catalog.with_identity_fields(item)
        key = public_catalog.record_key(record)
        if key:
            records[key] = record
    return records


def raw_paths(raw_root: Path) -> list[Path]:
    if not raw_root.exists():
        return []
    return sorted(
        path
        for path in raw_root.rglob("raw.md")
        if "admin" not in path.parts
    )


def resolve_record_state(
    raw_path: Path,
    existing_records: dict[str, dict[str, Any]],
    released_tokens: set[str],
) -> tuple[dict[str, Any], dict[str, Any]]:
    fm = parse_frontmatter(str(raw_path))
    bu = normalize_token(fm["bu"])
    project = normalize_token(fm["project"])
    slug = normalize_token(fm["slug"])
    key = public_catalog.canonical_key_for(bu, project, slug)
    output_url = f"{bu}/{project}/{slug}/"
    existing = existing_records.get(key, {})
    raw_private = public_catalog.is_private_gate(fm.get("gate"))

    if normalize_token(existing.get("release_status")) == "removed":
        gate_status = "gated"
        release_status = "removed"
        scope = "article"
    elif key in released_tokens or slug in released_tokens or output_url.strip("/") in released_tokens:
        gate_status = "public"
        release_status = "released"
        scope = "public"
    elif not raw_private:
        gate_status = "public"
        release_status = "released"
        scope = "public"
    else:
        gate_status = "gated"
        release_status = "unreleased"
        scope = public_catalog.normalize_navigation_scope(
            normalize_token(existing.get("scope")),
            default="article",
        )
        if scope == "public":
            scope = "article"

    public_record = public_catalog.record_from_raw(
        raw_path,
        output_url=output_url,
        gate_status=gate_status,
        release_status=release_status,
        scope=scope,
    )
    raw_tags = [str(tag) for tag in (fm.get("tags") or [])]
    return public_record, {
        "frontmatter": fm,
        "raw_tags": raw_tags,
        "raw_path": raw_path,
    }


def load_admin_db_module() -> Any:
    admin_db_path = SCRIPT_DIR / "admin-db.py"
    spec = importlib.util.spec_from_file_location("wikia_admin_db", admin_db_path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"cannot load admin-db.py from {admin_db_path}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


def write_admin_db(db_path: Path, records: list[tuple[dict[str, Any], dict[str, Any]]]) -> None:
    admin_db = load_admin_db_module()
    if db_path.exists():
        db_path.unlink()
    admin_db.init_db(db_path)
    for public_record, source in records:
        admin_db.upsert_article(
            db_path,
            admin_db.ArticleRecord(
                bu=public_record["bu"],
                project=public_record["project"],
                slug=public_record["slug"],
                title_visible=bool(public_record.get("title_visible")),
                title_public=public_record.get("title_public"),
                raw_source_path=str(source["raw_path"]),
                output_url=public_record["output_url"],
                gate_status=public_record["gate_status"],
                release_status=public_record["release_status"],
                scope=public_record["scope"],
                tags_json=json.dumps(source["raw_tags"], ensure_ascii=False, separators=(",", ":")),
                raw_hash=public_record["raw_hash"],
            ),
        )


def admin_metadata(records: list[tuple[dict[str, Any], dict[str, Any]]]) -> dict[str, Any]:
    return {
        "schema_version": 1,
        "generated_at": public_catalog.utc_now_iso(),
        "records": [
            {
                "article_id": record["article_id"],
                "key": record["canonical_key"],
                "bu": record["bu"],
                "project": record["project"],
                "slug": record["slug"],
                "title": public_catalog.public_title(record),
                "title_visible": record["title_visible"],
                "title_public": record["title_public"],
                "output_url": record["output_url"],
                "gate_status": record["gate_status"],
                "release_status": record["release_status"],
                "scope": record["scope"],
                "tags": source["raw_tags"],
                "raw_hash": record["raw_hash"],
            }
            for record, source in sorted(records, key=lambda pair: public_catalog.record_key(pair[0]))
        ],
    }


def sync_state(
    public_root: Path,
    raw_root: Path,
    released_path: Path,
    cms_db_path: Path,
    admin_metadata_path: Path,
) -> dict[str, Any]:
    catalog_path = public_root / "_catalog.json"
    existing_records = load_existing_records(catalog_path)
    released_tokens = released_token_set(load_json(released_path, []))

    catalog = public_catalog.empty_catalog()
    records: list[tuple[dict[str, Any], dict[str, Any]]] = []
    skipped: list[dict[str, str]] = []

    for raw_path in raw_paths(raw_root):
        try:
            record, source = resolve_record_state(raw_path, existing_records, released_tokens)
        except (OSError, ValueError, KeyError) as exc:
            skipped.append({"path": str(raw_path), "error": str(exc)})
            continue
        catalog, _ = public_catalog.upsert_record(catalog, record)
        records.append((record, source))

    public_catalog.write_catalog(catalog_path, catalog)
    write_admin_db(cms_db_path, records)
    metadata = admin_metadata(records)
    admin_metadata_path.parent.mkdir(parents=True, exist_ok=True)
    admin_metadata_path.write_text(
        json.dumps(metadata, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )

    return {
        "ok": True,
        "public_root": str(public_root),
        "raw_root": str(raw_root),
        "catalog": str(catalog_path),
        "cms_db": str(cms_db_path),
        "admin_metadata": str(admin_metadata_path),
        "records": len(records),
        "skipped": skipped,
    }


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Sync public catalog, CMS DB, and admin metadata from raw sources.")
    parser.add_argument("public_root")
    parser.add_argument("raw_root")
    parser.add_argument("--released", required=True)
    parser.add_argument("--cms-db", required=True)
    parser.add_argument("--admin-metadata-out", required=True)
    parser.add_argument("--json", action="store_true")
    return parser


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)

    try:
        payload = sync_state(
            Path(args.public_root),
            Path(args.raw_root),
            Path(args.released),
            Path(args.cms_db),
            Path(args.admin_metadata_out),
        )
    except (OSError, ValueError, json.JSONDecodeError, RuntimeError) as exc:
        print(f"ERR: {exc}", file=sys.stderr)
        return 1

    if args.json:
        print(json.dumps(payload, ensure_ascii=False, indent=2, sort_keys=True))
    else:
        print(f"sync-cms-state: {payload['records']} records", file=sys.stderr)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
