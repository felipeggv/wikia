#!/usr/bin/env python3
"""Migrate legacy public wikia state into sanitized CMS state.

The migrator inventories a legacy GitHub Pages checkout, builds public-safe
catalog data, can populate the sanitized admin SQLite catalog, and emits a
report of unsafe legacy files that still need a manual cleanup step. It never
deletes or rewrites legacy public files.
"""
from __future__ import annotations

import argparse
import hashlib
import importlib.util
import json
import sqlite3
import sys
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


SCRIPT_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(SCRIPT_DIR))

from frontmatter_parser import parse_frontmatter  # noqa: E402
import public_catalog  # noqa: E402


CATALOG_VERSION = 1
DEFAULT_PUBLIC_ROOT = Path("docs/gitpages")
KNOWN_BU = {"staging", "vita", "allin", "aleyemma", "gobbi"}


@dataclass(frozen=True)
class LegacyRecord:
    article_id: str
    bu: str
    project: str
    slug: str
    title_visible: bool
    title_public: str | None
    title_private_present: bool
    raw_source_path: str
    output_url: str
    gate_status: str
    release_status: str
    scope: str
    tags: list[str]
    raw_hash: str
    raw_path: Path
    html_path: Path | None
    source_warnings: tuple[str, ...]

    @property
    def key(self) -> str:
        return f"{self.bu}/{self.project}/{self.slug}"

    def public_catalog_entry(self) -> dict[str, Any]:
        """Return a public-safe record with no body, snippet, or private title."""
        return {
            "article_id": self.article_id,
            "canonical_key": self.key,
            "idempotency_key": public_catalog.idempotency_key_for(
                self.bu,
                self.project,
                self.slug,
                self.raw_hash,
                self.scope,
            ),
            "bu": self.bu,
            "project": self.project,
            "slug": self.slug,
            "title_visible": self.title_visible,
            "title_public": self.title_public if self.title_visible else None,
            "output_url": self.output_url,
            "gate_status": self.gate_status,
            "release_status": self.release_status,
            "scope": self.scope,
            "tags": self.tags if self.title_visible else [],
            "raw_hash": self.raw_hash,
        }


def utc_now() -> datetime:
    return datetime.now(timezone.utc).replace(microsecond=0)


def iso_z(dt: datetime) -> str:
    return dt.isoformat().replace("+00:00", "Z")


def read_json(path: Path, default: Any) -> Any:
    if not path.exists():
        return default
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        raise ValueError(f"{path}: invalid JSON: {exc}") from exc


def write_json(path: Path, payload: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        json.dumps(payload, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as fh:
        for chunk in iter(lambda: fh.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def article_id_for(bu: str, project: str, slug: str) -> str:
    payload = f"wikia-article:v1:{bu}/{project}/{slug}".encode("utf-8")
    return hashlib.sha256(payload).hexdigest()


def is_private_gate(value: Any) -> bool:
    if value is None:
        return False
    if isinstance(value, str) and value.strip().lower() in {"", "none", "null", "public"}:
        return False
    return True


def relative_to(path: Path, root: Path) -> str:
    try:
        return path.relative_to(root).as_posix()
    except ValueError:
        return path.as_posix()


def public_root_for(repo_root: Path, explicit_public_root: str | None) -> Path:
    if explicit_public_root:
        return Path(explicit_public_root).expanduser().resolve()
    candidate = repo_root / DEFAULT_PUBLIC_ROOT
    if candidate.is_dir():
        return candidate.resolve()
    return repo_root.resolve()


def normalize_release_keys(released: Any) -> set[str]:
    keys: set[str] = set()
    if isinstance(released, list):
        for item in released:
            key = key_from_legacy_item(item)
            if key:
                keys.add(key)
    elif isinstance(released, dict):
        for item_key, item_value in released.items():
            key = key_from_legacy_item(item_value) or key_from_url(str(item_key))
            if key:
                keys.add(key)
    return keys


def key_from_url(url: str) -> str | None:
    clean = url.strip().strip("/")
    if not clean:
        return None
    marker = "gitpages/"
    if marker in clean:
        clean = clean.split(marker, 1)[1]
    parts = [part for part in clean.split("/") if part]
    if len(parts) < 3:
        return None
    bu, project, slug = parts[:3]
    if bu not in KNOWN_BU:
        return None
    return f"{bu}/{project}/{slug}"


def key_from_legacy_item(item: Any) -> str | None:
    if isinstance(item, str):
        return key_from_url(item)
    if not isinstance(item, dict):
        return None
    if all(item.get(field) for field in ("bu", "project", "slug")):
        return f"{item['bu']}/{item['project']}/{item['slug']}"
    if item.get("url"):
        return key_from_url(str(item["url"]))
    return None


def collect_search_urls(search_index: Any) -> dict[str, dict[str, Any]]:
    entries: dict[str, dict[str, Any]] = {}
    if not isinstance(search_index, list):
        return entries
    for item in search_index:
        if not isinstance(item, dict):
            continue
        key = key_from_legacy_item(item)
        if key:
            entries[key] = item
    return entries


def html_for_raw(raw_path: Path) -> Path | None:
    html_path = raw_path.parent / "index.html"
    return html_path if html_path.exists() else None


def infer_path_parts(raw_path: Path, public_root: Path) -> tuple[str | None, str | None, str | None]:
    try:
        rel = raw_path.relative_to(public_root)
    except ValueError:
        return None, None, None
    if len(rel.parts) < 4:
        return None, None, None
    bu, project, slug = rel.parts[:3]
    if bu not in KNOWN_BU:
        return None, None, None
    return bu, project, slug


def build_record(raw_path: Path, public_root: Path, repo_root: Path, released_keys: set[str]) -> LegacyRecord:
    fm = parse_frontmatter(str(raw_path))
    path_bu, path_project, path_slug = infer_path_parts(raw_path, public_root)

    bu = str(fm["bu"])
    project = str(fm["project"])
    slug = str(fm["slug"])
    gate_private = is_private_gate(fm.get("gate"))
    key = f"{bu}/{project}/{slug}"

    warnings: list[str] = []
    if (path_bu, path_project, path_slug) != (bu, project, slug):
        warnings.append("frontmatter_path_mismatch")

    title = str(fm.get("title", "")).strip()
    tags = [str(tag) for tag in fm.get("tags", []) or []]

    title_visible = not gate_private
    gate_status = "gated" if gate_private else "public"
    release_status = "released" if (key in released_keys or not gate_private) else "unreleased"
    scope = "article" if gate_private else "public"

    return LegacyRecord(
        article_id=article_id_for(bu, project, slug),
        bu=bu,
        project=project,
        slug=slug,
        title_visible=title_visible,
        title_public=title if title_visible else None,
        title_private_present=bool(title) and not title_visible,
        raw_source_path=relative_to(raw_path, repo_root),
        output_url=f"{bu}/{project}/{slug}/",
        gate_status=gate_status,
        release_status=release_status,
        scope=scope,
        tags=tags,
        raw_hash=sha256_file(raw_path),
        raw_path=raw_path,
        html_path=html_for_raw(raw_path),
        source_warnings=tuple(warnings),
    )


def collect_records(public_root: Path, repo_root: Path, released_keys: set[str]) -> tuple[list[LegacyRecord], list[dict[str, str]]]:
    records: list[LegacyRecord] = []
    errors: list[dict[str, str]] = []

    for raw_path in sorted(public_root.rglob("raw.md")):
        try:
            records.append(build_record(raw_path, public_root, repo_root, released_keys))
        except (OSError, ValueError) as exc:
            errors.append(
                {
                    "path": relative_to(raw_path, repo_root),
                    "error": str(exc),
                }
            )

    return records, errors


def collect_html_orphans(public_root: Path, records_by_key: dict[str, LegacyRecord]) -> list[str]:
    orphans: list[str] = []
    for html_path in sorted(public_root.rglob("index.html")):
        try:
            rel = html_path.relative_to(public_root)
        except ValueError:
            continue
        if len(rel.parts) < 4:
            continue
        bu, project, slug = rel.parts[:3]
        if bu not in KNOWN_BU:
            continue
        key = f"{bu}/{project}/{slug}"
        if key not in records_by_key:
            orphans.append(rel.as_posix())
    return orphans


def detect_private_raw_exposures(records: list[LegacyRecord], public_root: Path, repo_root: Path) -> list[dict[str, str]]:
    exposures: list[dict[str, str]] = []
    for record in records:
        if record.gate_status == "public":
            continue
        try:
            record.raw_path.relative_to(public_root)
        except ValueError:
            continue
        exposures.append(
            {
                "article_id": record.article_id,
                "key": record.key,
                "raw_path": relative_to(record.raw_path, repo_root),
                "reason": "gated_article_raw_markdown_under_public_root",
                "proposed_action": "move plaintext source outside public GitHub Pages output and publish only encrypted/sanitized artifacts",
            }
        )
    return exposures


def detect_private_search_exposures(records: list[LegacyRecord], search_entries: dict[str, dict[str, Any]]) -> list[dict[str, str]]:
    exposures: list[dict[str, str]] = []
    by_key = {record.key: record for record in records}
    for key, item in sorted(search_entries.items()):
        record = by_key.get(key)
        if not record or record.gate_status == "public":
            continue
        exposed_fields = [
            field
            for field in ("title", "snippet", "tags", "tema")
            if item.get(field) not in (None, "", [])
        ]
        if exposed_fields:
            exposures.append(
                {
                    "article_id": record.article_id,
                    "key": key,
                    "search_url": str(item.get("url", "")),
                    "exposed_fields": ",".join(exposed_fields),
                    "reason": "gated_article_metadata_in_public_search_index",
                }
            )
    return exposures


def build_catalog(
    records: list[LegacyRecord],
    repo_root: Path,
    public_root: Path,
    now: datetime,
) -> dict[str, Any]:
    return {
        "catalog_version": CATALOG_VERSION,
        "generated_at": iso_z(now),
        "source": {
            "legacy_repo_root": repo_root.as_posix(),
            "legacy_public_root": public_root.as_posix(),
        },
        "records": [record.public_catalog_entry() for record in sorted(records, key=lambda r: r.key)],
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


def write_admin_db(db_out: Path, records: list[LegacyRecord]) -> None:
    admin_db = load_admin_db_module()
    admin_db.init_db(db_out)
    for record in sorted(records, key=lambda r: r.key):
        admin_db.upsert_article(
            db_out,
            admin_db.ArticleRecord(
                bu=record.bu,
                project=record.project,
                slug=record.slug,
                title_visible=record.title_visible,
                title_public=record.title_public,
                raw_source_path=record.raw_source_path,
                output_url=record.output_url,
                gate_status=record.gate_status,
                release_status=record.release_status,
                scope=record.scope,
                tags_json=json.dumps(record.tags, ensure_ascii=False, separators=(",", ":")),
                raw_hash=record.raw_hash,
            ),
        )


def report_table(rows: list[tuple[str, Any]]) -> str:
    out = ["| Metric | Value |", "|---|---:|"]
    for label, value in rows:
        out.append(f"| {label} | {value} |")
    return "\n".join(out)


def render_report(
    *,
    records: list[LegacyRecord],
    frontmatter_errors: list[dict[str, str]],
    private_raw_exposures: list[dict[str, str]],
    private_search_exposures: list[dict[str, str]],
    orphan_search_entries: list[str],
    orphan_html_pages: list[str],
    catalog_out: Path | None,
    db_out: Path | None,
    dry_run: bool,
    now: datetime,
) -> str:
    created = now.date().isoformat()
    lines = [
        "---",
        "type: report",
        "title: Wikia CMS State Migration Report",
        f"created: {created}",
        "tags:",
        "  - wikia-cms",
        "  - phase-03",
        "  - migration",
        "related:",
        "  - '[[PHASE-03-STATE]]'",
        "  - '[[CMS-CONTRACT]]'",
        "---",
        "",
        "# Wikia CMS State Migration Report",
        "",
        "## Executive Summary",
        "",
        "The migration inventoried legacy public state and built sanitized CMS records without deleting legacy files.",
        "",
        "```text",
        "legacy public repo",
        "   |",
        "   +-- raw.md / search.json / ledgers",
        "   |",
        "   v",
        "sanitized catalog + admin DB records + exposure report",
        "```",
        "",
        report_table(
            [
                ("Catalog records", len(records)),
                ("Frontmatter errors", len(frontmatter_errors)),
                ("Private raw markdown exposures", len(private_raw_exposures)),
                ("Private search index exposures", len(private_search_exposures)),
                ("Orphan search entries", len(orphan_search_entries)),
                ("Orphan HTML pages", len(orphan_html_pages)),
                ("Dry run", "yes" if dry_run else "no"),
                ("Legacy files auto-deleted", 0),
            ]
        ),
        "",
        "## Outputs",
        "",
        "| Output | Status |",
        "|---|---|",
        f"| Sanitized catalog | {'dry-run preview only' if dry_run else (catalog_out.as_posix() if catalog_out else 'not requested')} |",
        f"| Admin SQLite state | {'dry-run preview only' if dry_run else (db_out.as_posix() if db_out else 'not requested')} |",
        "| Legacy cleanup | manual only, no files deleted |",
        "",
        "## Security Findings",
        "",
    ]

    if private_raw_exposures:
        lines.extend(
            [
                "### Private Raw Markdown Exposure",
                "",
                "| Article Key | Public Raw Path | Proposed Action |",
                "|---|---|---|",
            ]
        )
        for item in private_raw_exposures:
            lines.append(f"| `{item['key']}` | `{item['raw_path']}` | {item['proposed_action']} |")
        lines.append("")
    else:
        lines.extend(["### Private Raw Markdown Exposure", "", "No gated `raw.md` files were found under the public root.", ""])

    if private_search_exposures:
        lines.extend(
            [
                "### Private Search Index Exposure",
                "",
                "| Article Key | Search URL | Exposed Field Classes |",
                "|---|---|---|",
            ]
        )
        for item in private_search_exposures:
            lines.append(f"| `{item['key']}` | `{item['search_url']}` | `{item['exposed_fields']}` |")
        lines.append("")

    if frontmatter_errors:
        lines.extend(
            [
                "## Frontmatter Errors",
                "",
                "| Raw Path | Error |",
                "|---|---|",
            ]
        )
        for item in frontmatter_errors:
            error = item["error"].replace("|", "\\|")
            lines.append(f"| `{item['path']}` | {error} |")
        lines.append("")

    if orphan_search_entries:
        lines.extend(["## Orphan Search Entries", "", "| Key |", "|---|"])
        for key in orphan_search_entries:
            lines.append(f"| `{key}` |")
        lines.append("")

    if orphan_html_pages:
        lines.extend(["## Orphan HTML Pages", "", "| HTML Path |", "|---|"])
        for path in orphan_html_pages:
            lines.append(f"| `{path}` |")
        lines.append("")

    lines.extend(
        [
            "## Sanitization Rules Applied",
            "",
            "| Data Class | Rule |",
            "|---|---|",
            "| Article body / markdown | Never written to catalog, DB, JSON summary, or report |",
            "| Private title | Stored as hidden state only; public catalog receives `null` |",
            "| Private tags | Hidden from public catalog records |",
            "| Passwords / vault payloads | Not parsed or emitted |",
            "| Raw hash | SHA-256 only, no plaintext body |",
            "",
            "## Images Analyzed",
            "",
            "0",
            "",
        ]
    )
    return "\n".join(lines)


def build_summary(
    *,
    records: list[LegacyRecord],
    frontmatter_errors: list[dict[str, str]],
    private_raw_exposures: list[dict[str, str]],
    private_search_exposures: list[dict[str, str]],
    orphan_search_entries: list[str],
    orphan_html_pages: list[str],
    catalog_out: Path | None,
    db_out: Path | None,
    report_out: Path | None,
    dry_run: bool,
) -> dict[str, Any]:
    return {
        "ok": True,
        "dry_run": dry_run,
        "records": len(records),
        "frontmatter_errors": len(frontmatter_errors),
        "private_raw_markdown_exposures": len(private_raw_exposures),
        "private_search_index_exposures": len(private_search_exposures),
        "orphan_search_entries": len(orphan_search_entries),
        "orphan_html_pages": len(orphan_html_pages),
        "plaintext_private_content_public_after_migration": bool(private_raw_exposures),
        "legacy_files_auto_deleted": 0,
        "catalog_written": None if dry_run or catalog_out is None else catalog_out.as_posix(),
        "db_written": None if dry_run or db_out is None else db_out.as_posix(),
        "report_written": report_out.as_posix() if report_out else None,
    }


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Inventory legacy wikia public state and produce sanitized CMS catalog data."
    )
    parser.add_argument(
        "legacy_repo_root",
        help="Legacy wikia repository root, or the public gitpages root if docs/gitpages is not present.",
    )
    parser.add_argument("--public-root", help="Override the public gitpages root.")
    parser.add_argument("--catalog-out", help="Write sanitized public catalog JSON here when not in dry-run.")
    parser.add_argument("--db-out", help="Write sanitized admin SQLite state here when not in dry-run.")
    parser.add_argument("--report-out", help="Write the migration report markdown here.")
    parser.add_argument("--dry-run", action="store_true", help="Do not write catalog or SQLite state.")
    parser.add_argument("--json", action="store_true", help="Print machine-readable summary.")
    return parser


def run(args: argparse.Namespace) -> dict[str, Any]:
    repo_root = Path(args.legacy_repo_root).expanduser().resolve()
    public_root = public_root_for(repo_root, args.public_root)
    now = utc_now()

    released_state = read_json(public_root / "_released.json", [])
    pending_state = read_json(public_root / "_pending-changes.json", {})
    search_index = read_json(public_root / "search.json", [])

    released_keys = normalize_release_keys(released_state)
    search_entries = collect_search_urls(search_index)

    records, frontmatter_errors = collect_records(public_root, repo_root, released_keys)
    records_by_key = {record.key: record for record in records}

    private_raw_exposures = detect_private_raw_exposures(records, public_root, repo_root)
    private_search_exposures = detect_private_search_exposures(records, search_entries)
    orphan_search_entries = sorted(key for key in search_entries if key not in records_by_key)
    orphan_html_pages = collect_html_orphans(public_root, records_by_key)

    catalog_out = Path(args.catalog_out).expanduser().resolve() if args.catalog_out else None
    db_out = Path(args.db_out).expanduser().resolve() if args.db_out else None
    report_out = Path(args.report_out).expanduser().resolve() if args.report_out else None

    catalog = build_catalog(records, repo_root, public_root, now)

    if not args.dry_run:
        if catalog_out:
            write_json(catalog_out, catalog)
        if db_out:
            write_admin_db(db_out, records)

    report = render_report(
        records=records,
        frontmatter_errors=frontmatter_errors,
        private_raw_exposures=private_raw_exposures,
        private_search_exposures=private_search_exposures,
        orphan_search_entries=orphan_search_entries,
        orphan_html_pages=orphan_html_pages,
        catalog_out=catalog_out,
        db_out=db_out,
        dry_run=args.dry_run,
        now=now,
    )
    if report_out:
        report_out.parent.mkdir(parents=True, exist_ok=True)
        report_out.write_text(report, encoding="utf-8")

    summary = build_summary(
        records=records,
        frontmatter_errors=frontmatter_errors,
        private_raw_exposures=private_raw_exposures,
        private_search_exposures=private_search_exposures,
        orphan_search_entries=orphan_search_entries,
        orphan_html_pages=orphan_html_pages,
        catalog_out=catalog_out,
        db_out=db_out,
        report_out=report_out,
        dry_run=args.dry_run,
    )
    summary["pending_state_type"] = type(pending_state).__name__
    summary["catalog_preview"] = catalog if args.dry_run else None
    return summary


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)

    try:
        summary = run(args)
    except (OSError, sqlite3.Error, ValueError, RuntimeError) as exc:
        print(f"ERR: {exc}", file=sys.stderr)
        return 1

    if args.json:
        print(json.dumps(summary, ensure_ascii=False, indent=2, sort_keys=True))
    else:
        print(
            "migrate-to-cms-state: "
            f"{summary['records']} records, "
            f"{summary['private_raw_markdown_exposures']} private raw exposures, "
            f"{summary['legacy_files_auto_deleted']} legacy files deleted"
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
