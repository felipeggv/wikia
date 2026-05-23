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
import os
import re
import sys
import tempfile
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from frontmatter_parser import parse_frontmatter


CATALOG_VERSION = 1
ALLOWED_GATE_STATUS = {"public", "gated", "encrypted", "unknown"}
ALLOWED_RELEASE_STATUS = {"unreleased", "released", "archived", "removed"}
ALLOWED_SCOPE = {"public", "article", "project", "bu", "admin"}
KEBAB_RE = re.compile(r"^[a-z0-9]+(-[a-z0-9]+)*$")
SHA256_RE = re.compile(r"^[a-f0-9]{64}$")
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
    if isinstance(value, str) and value.strip().lower() in {"", "none", "null", "public", "false"}:
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


def _require_kebab(record: dict[str, Any], field: str, max_len: int) -> str:
    value = str(record.get(field) or "").strip()
    if not value:
        raise ValueError(f"catalog record {field} is required")
    if len(value) > max_len:
        raise ValueError(f"catalog record {field} length must be <= {max_len}: {value!r}")
    if not KEBAB_RE.fullmatch(value):
        raise ValueError(f"catalog record {field} must be kebab-case: {value!r}")
    return value


def _require_enum(record: dict[str, Any], field: str, allowed: set[str]) -> str:
    value = str(record.get(field) or "").strip()
    if value not in allowed:
        raise ValueError(f"catalog record {field} must be one of {sorted(allowed)}: {value!r}")
    return value


def _require_bool(record: dict[str, Any], field: str) -> bool:
    value = record.get(field)
    if not isinstance(value, bool):
        raise ValueError(f"catalog record {field} must be boolean")
    return value


def _validate_output_url(record: dict[str, Any], bu: str, project: str) -> str:
    output_url = normalize_output_url(str(record.get("output_url") or ""))
    parts = output_url.strip("/").split("/")
    if len(parts) != 3:
        raise ValueError(f"catalog record output_url must be bu/project/slug/: {output_url!r}")
    if parts[0] != bu or parts[1] != project:
        raise ValueError(
            "catalog record output_url must stay under its bu/project: "
            f"{output_url!r} for {bu}/{project}"
        )
    for part in parts:
        if not KEBAB_RE.fullmatch(part):
            raise ValueError(f"catalog record output_url segment must be kebab-case: {output_url!r}")
    return output_url


def _validate_tags(value: Any, *, title_visible: bool) -> list[str]:
    tags = value if value is not None else []
    if not isinstance(tags, list):
        raise ValueError("catalog record tags must be an array")
    clean_tags: list[str] = []
    for tag in tags:
        if not isinstance(tag, str) or not KEBAB_RE.fullmatch(tag):
            raise ValueError(f"catalog record tag must be kebab-case: {tag!r}")
        clean_tags.append(tag)
    if not title_visible and clean_tags:
        raise ValueError("catalog record tags must be empty when title_visible is false")
    return clean_tags


def validate_record(record: dict[str, Any]) -> dict[str, Any]:
    """Return a normalized catalog record or raise when the public contract breaks."""
    if not isinstance(record, dict):
        raise ValueError("catalog record must be an object")

    clean = dict(record)
    bu = _require_kebab(clean, "bu", 40)
    if bu not in KNOWN_BU_DISPLAY:
        raise ValueError(f"catalog record bu must be one of {sorted(KNOWN_BU_DISPLAY)}: {bu!r}")
    project = _require_kebab(clean, "project", 80)
    slug = _require_kebab(clean, "slug", 160)
    gate_status = _require_enum(clean, "gate_status", ALLOWED_GATE_STATUS)
    release_status = _require_enum(clean, "release_status", ALLOWED_RELEASE_STATUS)
    scope = _require_enum(clean, "scope", ALLOWED_SCOPE)
    title_visible = _require_bool(clean, "title_visible")
    output_url = _validate_output_url(clean, bu, project)

    raw_hash = str(clean.get("raw_hash") or "").strip().lower()
    if not SHA256_RE.fullmatch(raw_hash):
        raise ValueError("catalog record raw_hash must be a lowercase SHA-256 hex digest")

    title_public = clean.get("title_public")
    if title_visible:
        if not isinstance(title_public, str) or not title_public.strip():
            raise ValueError("catalog record title_public is required when title_visible is true")
        title_public = title_public.strip()
    elif title_public not in (None, ""):
        raise ValueError("catalog record title_public must be null when title_visible is false")
    else:
        title_public = None

    tags = _validate_tags(clean.get("tags"), title_visible=title_visible)

    public_flags = {
        "gate_status": gate_status == "public",
        "release_status": release_status == "released",
        "scope": scope == "public",
    }
    if any(public_flags.values()) and not all(public_flags.values()):
        raise ValueError(f"catalog record public flags must move together: {public_flags}")
    if all(public_flags.values()) and not title_visible:
        raise ValueError("catalog record public records must have title_visible true")
    if release_status == "removed":
        if gate_status == "public" or scope == "public" or title_visible or title_public or tags:
            raise ValueError("catalog record removed records must stay gated, non-public, untitled, and untagged")
        if scope != "article":
            raise ValueError("catalog record removed records must use article scope")
    if release_status == "released" and (gate_status != "public" or scope != "public"):
        raise ValueError("released catalog records must use public gate_status and public scope")
    if scope == "public" and gate_status != "public":
        raise ValueError("public catalog scope requires public gate_status")

    expected_key = canonical_key_for(bu, project, slug)
    if clean.get("canonical_key") not in (None, "", expected_key):
        raise ValueError(f"catalog record canonical_key mismatch for {expected_key}")

    expected_article_id = article_id_for(bu, project, slug)
    if clean.get("article_id") not in (None, "", expected_article_id):
        raise ValueError(f"catalog record article_id mismatch for {expected_key}")
    expected_idempotency_key = idempotency_key_for(bu, project, slug, raw_hash, scope)
    if clean.get("idempotency_key") not in (None, "", expected_idempotency_key):
        raise ValueError(f"catalog record idempotency_key mismatch for {expected_key}")

    clean.update(
        {
            "bu": bu,
            "project": project,
            "slug": slug,
            "title_visible": title_visible,
            "title_public": title_public,
            "output_url": output_url,
            "gate_status": gate_status,
            "release_status": release_status,
            "scope": scope,
            "tags": tags,
            "raw_hash": raw_hash,
            "canonical_key": expected_key,
            "article_id": expected_article_id,
            "idempotency_key": expected_idempotency_key,
        }
    )
    return clean


def validate_catalog(catalog: dict[str, Any], *, path: Path | None = None) -> dict[str, Any]:
    label = f"{path}: " if path else ""
    if not isinstance(catalog, dict):
        raise ValueError(f"{label}catalog must be a JSON object")
    if catalog.get("catalog_version") != CATALOG_VERSION:
        raise ValueError(f"{label}catalog_version must be {CATALOG_VERSION}")
    records = catalog.get("records")
    if not isinstance(records, list):
        raise ValueError(f"{label}catalog records must be a JSON array")

    clean_records = [validate_record(record) for record in records]
    keys = [record_key(record) for record in clean_records]
    duplicate_keys = sorted(key for key in set(keys) if keys.count(key) > 1)
    if duplicate_keys:
        raise ValueError(f"{label}duplicate catalog records: {duplicate_keys[:5]}")

    output_urls = [str(record.get("output_url") or "") for record in clean_records]
    duplicate_urls = sorted(url for url in set(output_urls) if output_urls.count(url) > 1)
    if duplicate_urls:
        raise ValueError(f"{label}duplicate catalog output_url values: {duplicate_urls[:5]}")

    clean = dict(catalog)
    clean["catalog_version"] = CATALOG_VERSION
    clean["records"] = sorted(clean_records, key=record_key)
    return clean


def is_public_record(record: dict[str, Any]) -> bool:
    if str(record.get("release_status") or "") == "removed":
        return False
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
    available_records = [
        record
        for record in records
        if str(record.get("release_status") or "") != "removed"
    ]
    if current is None:
        return [record for record in available_records if is_public_record(record)]
    if str(current.get("release_status") or "") == "removed":
        return []

    scope = str(current.get("scope") or "article")
    bu = str(current.get("bu") or "")
    project = str(current.get("project") or "")
    slug = str(current.get("slug") or "")

    if scope == "admin":
        return list(available_records)
    if scope == "bu":
        return [record for record in available_records if record.get("bu") == bu]
    if scope == "project":
        return [
            record
            for record in available_records
            if record.get("bu") == bu and record.get("project") == project
        ]
    if scope == "public":
        return [
            record
            for record in available_records
            if record.get("bu") == bu and is_public_record(record)
        ]
    return [
        record
        for record in available_records
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

    return validate_record({
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
    })


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
    return validate_catalog(payload, path=path)


def load_records_from_public_root(public_root: str | Path) -> list[dict[str, Any]]:
    catalog_path = Path(public_root) / "_catalog.json"
    if not catalog_path.exists():
        return []
    payload = load_catalog(catalog_path)
    return [with_identity_fields(record) for record in payload.get("records", []) if isinstance(record, dict)]


def upsert_record(catalog: dict[str, Any], record: dict[str, Any]) -> tuple[dict[str, Any], dict[str, Any]]:
    catalog = validate_catalog(catalog)
    records = [item for item in catalog.get("records", []) if isinstance(item, dict)]
    record = validate_record(record)
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
    catalog = validate_catalog(catalog)
    return catalog, {
        "action": action,
        "canonical_key": key,
        "idempotency_key": idempotency_key,
        "duplicate_records_collapsed": max(0, len(matched_records) - 1),
    }


def write_catalog(path: Path, catalog: dict[str, Any]) -> None:
    catalog = validate_catalog(catalog)
    text = json.dumps(catalog, ensure_ascii=False, indent=2, sort_keys=True) + "\n"
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, tmp_name = tempfile.mkstemp(prefix=f".{path.name}.", suffix=".tmp", dir=path.parent)
    tmp_path = Path(tmp_name)
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as fh:
            fh.write(text)
            fh.flush()
            os.fsync(fh.fileno())
        os.replace(tmp_path, path)
    except Exception:
        try:
            tmp_path.unlink()
        except FileNotFoundError:
            pass
        raise


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
