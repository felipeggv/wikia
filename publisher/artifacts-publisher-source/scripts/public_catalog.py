#!/usr/bin/env python3
"""Public-safe catalog helpers for the wikia publish pipeline.

The public catalog is a routing and navigation contract. It may contain article
identity, URLs, hashes, and visibility labels, but it must not contain raw
markdown, private article bodies, plaintext passwords, or private titles.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from frontmatter_parser import parse_frontmatter


CATALOG_VERSION = 1
KNOWN_BU_DISPLAY = {
    "staging": "Staging",
    "vita": "Vitascience",
    "allin": "AllIn",
    "aleyemma": "Aleyemma",
    "gobbi": "Gobbi",
}


def utc_now_iso() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def article_id_for(bu: str, project: str, slug: str) -> str:
    payload = f"wikia-article:v1:{bu}/{project}/{slug}".encode("utf-8")
    return hashlib.sha256(payload).hexdigest()


def canonical_key_for(bu: str, project: str, slug: str) -> str:
    return f"{bu}/{project}/{slug}"


def idempotency_key_for(bu: str, project: str, slug: str, raw_hash: str, scope: str) -> str:
    payload = f"wikia-publish-idempotency:v1:{bu}/{project}/{slug}:{raw_hash}:{scope}"
    return hashlib.sha256(payload.encode("utf-8")).hexdigest()


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as fh:
        for chunk in iter(lambda: fh.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def is_private_gate(value: Any) -> bool:
    if value is None:
        return False
    if isinstance(value, str) and value.strip().lower() in {"", "none", "null", "public"}:
        return False
    return True


def normalize_output_url(raw: str) -> str:
    return str(raw).strip().strip("/") + "/"


def safe_title_from_slug(slug: str) -> str:
    return str(slug).replace("-", " ").strip() or "artigo protegido"


def public_title(record: dict[str, Any]) -> str:
    if record.get("title_visible") and record.get("title_public"):
        return str(record["title_public"])
    return safe_title_from_slug(str(record.get("slug") or "artigo-protegido"))


def record_key(record: dict[str, Any]) -> str:
    return canonical_key_for(
        str(record.get("bu", "")),
        str(record.get("project", "")),
        str(record.get("slug", "")),
    )


def with_identity_fields(record: dict[str, Any]) -> dict[str, Any]:
    enriched = dict(record)
    bu = str(enriched.get("bu") or "")
    project = str(enriched.get("project") or "")
    slug = str(enriched.get("slug") or "")
    raw_hash = str(enriched.get("raw_hash") or "")
    scope = str(enriched.get("scope") or "")

    if bu and project and slug:
        enriched["article_id"] = article_id_for(bu, project, slug)
        enriched["canonical_key"] = canonical_key_for(bu, project, slug)
    if bu and project and slug and raw_hash and scope:
        enriched["idempotency_key"] = idempotency_key_for(bu, project, slug, raw_hash, scope)
    return enriched


def is_public_record(record: dict[str, Any]) -> bool:
    return (
        str(record.get("gate_status") or "") == "public"
        or str(record.get("scope") or "") == "public"
        or str(record.get("release_status") or "") == "released"
    )


def find_record(records: list[dict[str, Any]], bu: str | None, project: str | None, slug: str | None) -> dict[str, Any] | None:
    if not (bu and project and slug):
        return None
    key = f"{bu}/{project}/{slug}"
    for record in records:
        if record_key(record) == key:
            return record
    return None


def scoped_records(records: list[dict[str, Any]], current: dict[str, Any] | None = None) -> list[dict[str, Any]]:
    """Return records allowed in the current public navigation surface.

    Public pages get public records only. Gated article pages get only the
    article, project, or BU slice declared by the current record's scope.
    """
    if current is None:
        return [record for record in records if is_public_record(record)]

    scope = str(current.get("scope") or "article")
    bu = str(current.get("bu") or "")
    project = str(current.get("project") or "")
    slug = str(current.get("slug") or "")

    if scope == "admin":
        return list(records)
    if scope == "bu":
        return [record for record in records if record.get("bu") == bu]
    if scope == "project":
        return [
            record
            for record in records
            if record.get("bu") == bu and record.get("project") == project
        ]
    if scope == "public":
        return [
            record
            for record in records
            if record.get("bu") == bu and is_public_record(record)
        ]
    return [
        record
        for record in records
        if record.get("bu") == bu
        and record.get("project") == project
        and record.get("slug") == slug
    ]


def record_from_raw(
    raw_path: Path,
    *,
    output_url: str | None = None,
    gate_status: str | None = None,
    release_status: str | None = None,
    scope: str | None = None,
) -> dict[str, Any]:
    fm = parse_frontmatter(str(raw_path))
    bu = str(fm["bu"])
    project = str(fm["project"])
    slug = str(fm["slug"])
    title = str(fm.get("title") or "").strip()
    tags = [str(tag) for tag in (fm.get("tags") or [])]

    gated = is_private_gate(fm.get("gate"))
    actual_gate_status = gate_status or ("gated" if gated else "public")
    title_visible = actual_gate_status == "public"
    actual_release_status = release_status or ("released" if title_visible else "unreleased")
    actual_scope = scope or ("public" if title_visible else "article")
    raw_hash = sha256_file(raw_path)

    return {
        "article_id": article_id_for(bu, project, slug),
        "canonical_key": canonical_key_for(bu, project, slug),
        "idempotency_key": idempotency_key_for(bu, project, slug, raw_hash, actual_scope),
        "bu": bu,
        "project": project,
        "slug": slug,
        "title_visible": title_visible,
        "title_public": title if title_visible else None,
        "output_url": normalize_output_url(output_url or f"{bu}/{project}/{slug}/"),
        "gate_status": actual_gate_status,
        "release_status": actual_release_status,
        "scope": actual_scope,
        "tags": tags if title_visible else [],
        "raw_hash": raw_hash,
    }


def empty_catalog() -> dict[str, Any]:
    return {
        "catalog_version": CATALOG_VERSION,
        "generated_at": utc_now_iso(),
        "records": [],
    }


def load_catalog(path: Path) -> dict[str, Any]:
    if not path.exists():
        return empty_catalog()
    payload = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(payload, dict):
        raise ValueError(f"{path}: catalog must be a JSON object")
    records = payload.get("records")
    if not isinstance(records, list):
        raise ValueError(f"{path}: catalog records must be a JSON array")
    return payload


def load_records_from_public_root(public_root: str | Path) -> list[dict[str, Any]]:
    catalog_path = Path(public_root) / "_catalog.json"
    if not catalog_path.exists():
        return []
    payload = load_catalog(catalog_path)
    return [with_identity_fields(record) for record in payload.get("records", []) if isinstance(record, dict)]


def upsert_record(catalog: dict[str, Any], record: dict[str, Any]) -> tuple[dict[str, Any], dict[str, Any]]:
    records = [item for item in catalog.get("records", []) if isinstance(item, dict)]
    record = with_identity_fields(record)
    key = record_key(record)
    idempotency_key = str(record.get("idempotency_key") or "")
    matched_records = [with_identity_fields(item) for item in records if record_key(item) == key]

    if not matched_records:
        action = "inserted"
    elif str(matched_records[-1].get("idempotency_key") or "") == idempotency_key:
        action = "unchanged"
    else:
        action = "updated"

    next_records = [with_identity_fields(item) for item in records if record_key(item) != key]
    next_records.append(record)
    next_records.sort(key=record_key)
    catalog["catalog_version"] = CATALOG_VERSION
    catalog["generated_at"] = utc_now_iso()
    catalog["records"] = next_records
    return catalog, {
        "action": action,
        "canonical_key": key,
        "idempotency_key": idempotency_key,
        "duplicate_records_collapsed": max(0, len(matched_records) - 1),
    }


def write_catalog(path: Path, catalog: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        json.dumps(catalog, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )


def upsert_from_raw(catalog_path: Path, raw_path: Path, args: argparse.Namespace) -> dict[str, Any]:
    catalog = load_catalog(catalog_path)
    record = record_from_raw(
        raw_path,
        output_url=args.output_url,
        gate_status=args.gate_status,
        release_status=args.release_status,
        scope=args.scope,
    )
    catalog, upsert = upsert_record(catalog, record)
    write_catalog(catalog_path, catalog)
    return {"ok": True, "catalog": str(catalog_path), "record": record, "upsert": upsert}


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Maintain public-safe wikia catalog JSON.")
    sub = parser.add_subparsers(dest="command", required=True)

    inspect = sub.add_parser("inspect-raw", help="print the sanitized record derived from raw.md")
    inspect.add_argument("raw_path")
    inspect.add_argument("--output-url")
    inspect.add_argument("--gate-status")
    inspect.add_argument("--release-status")
    inspect.add_argument("--scope")
    inspect.add_argument("--json", action="store_true")

    upsert = sub.add_parser("upsert-from-raw", help="upsert one raw.md into _catalog.json")
    upsert.add_argument("catalog_path")
    upsert.add_argument("raw_path")
    upsert.add_argument("--output-url")
    upsert.add_argument("--gate-status")
    upsert.add_argument("--release-status")
    upsert.add_argument("--scope")
    upsert.add_argument("--json", action="store_true")

    return parser


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)

    try:
        if args.command == "inspect-raw":
            payload = {
                "ok": True,
                "record": record_from_raw(
                    Path(args.raw_path),
                    output_url=args.output_url,
                    gate_status=args.gate_status,
                    release_status=args.release_status,
                    scope=args.scope,
                ),
            }
        elif args.command == "upsert-from-raw":
            payload = upsert_from_raw(Path(args.catalog_path), Path(args.raw_path), args)
        else:
            parser.error(f"unknown command: {args.command}")
            return 2
    except (OSError, ValueError, json.JSONDecodeError) as exc:
        print(f"ERR: {exc}", file=sys.stderr)
        return 1

    if args.json:
        print(json.dumps(payload, ensure_ascii=False, indent=2, sort_keys=True))
    else:
        print("public-catalog: ok")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
