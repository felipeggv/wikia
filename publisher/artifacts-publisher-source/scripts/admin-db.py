#!/usr/bin/env python3
"""admin-db.py - sanitized SQLite state for the wikia CMS.

This database is the canonical catalog spine for build/admin workflows. It
stores identity, routing, visibility, and state flags only. It intentionally
does not define password, secret, article body, raw markdown, or private title
columns.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import re
import sqlite3
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any


SCHEMA_VERSION = 1

ALLOWED_GATE_STATUS = ("public", "gated", "encrypted", "unknown")
ALLOWED_RELEASE_STATUS = ("unreleased", "released", "archived", "removed")
ALLOWED_SCOPE = ("public", "article", "project", "bu", "admin")

KEBAB_RE = re.compile(r"^[a-z0-9]+(-[a-z0-9]+)*$")
SHA256_RE = re.compile(r"^[a-f0-9]{64}$")

EXPECTED_ARTICLE_COLUMNS = {
    "article_id",
    "bu",
    "project",
    "slug",
    "title_visible",
    "title_public",
    "raw_source_path",
    "output_url",
    "gate_status",
    "release_status",
    "scope",
    "tags_json",
    "raw_hash",
}

FORBIDDEN_SCHEMA_TERMS = (
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

SCHEMA_SQL = """
PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS schema_meta (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS articles (
  article_id TEXT PRIMARY KEY
    CHECK (length(article_id) = 64 AND article_id NOT GLOB '*[^0-9a-f]*'),
  bu TEXT NOT NULL
    CHECK (length(bu) <= 40 AND bu GLOB '[a-z0-9]*' AND bu NOT GLOB '*[^a-z0-9-]*'),
  project TEXT NOT NULL
    CHECK (length(project) <= 80 AND project GLOB '[a-z0-9]*' AND project NOT GLOB '*[^a-z0-9-]*'),
  slug TEXT NOT NULL
    CHECK (length(slug) <= 160 AND slug GLOB '[a-z0-9]*' AND slug NOT GLOB '*[^a-z0-9-]*'),
  title_visible INTEGER NOT NULL DEFAULT 0
    CHECK (title_visible IN (0, 1)),
  title_public TEXT DEFAULT NULL,
  raw_source_path TEXT NOT NULL,
  output_url TEXT NOT NULL,
  gate_status TEXT NOT NULL DEFAULT 'unknown'
    CHECK (gate_status IN ('public', 'gated', 'encrypted', 'unknown')),
  release_status TEXT NOT NULL DEFAULT 'unreleased'
    CHECK (release_status IN ('unreleased', 'released', 'archived', 'removed')),
  scope TEXT NOT NULL DEFAULT 'article'
    CHECK (scope IN ('public', 'article', 'project', 'bu', 'admin')),
  tags_json TEXT NOT NULL DEFAULT '[]'
    CHECK (json_valid(tags_json) AND json_type(tags_json) = 'array'),
  raw_hash TEXT NOT NULL
    CHECK (length(raw_hash) = 64 AND raw_hash NOT GLOB '*[^0-9a-f]*'),
  created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now')),
  updated_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now')),
  UNIQUE (bu, project, slug),
  CHECK (title_visible = 1 OR title_public IS NULL)
);

CREATE INDEX IF NOT EXISTS idx_articles_bu_project_slug
  ON articles (bu, project, slug);

CREATE INDEX IF NOT EXISTS idx_articles_scope_release_gate
  ON articles (scope, release_status, gate_status);

CREATE INDEX IF NOT EXISTS idx_articles_raw_hash
  ON articles (raw_hash);
"""


@dataclass(frozen=True)
class ArticleRecord:
    bu: str
    project: str
    slug: str
    title_visible: bool
    title_public: str | None
    raw_source_path: str
    output_url: str
    gate_status: str
    release_status: str
    scope: str
    tags_json: str
    raw_hash: str

    @property
    def article_id(self) -> str:
        return article_id_for(self.bu, self.project, self.slug)


def article_id_for(bu: str, project: str, slug: str) -> str:
    payload = f"wikia-article:v1:{bu}/{project}/{slug}".encode("utf-8")
    return hashlib.sha256(payload).hexdigest()


def normalize_kebab(value: str, field: str, max_len: int) -> str:
    value = (value or "").strip()
    if not value:
        raise ValueError(f"{field} is required")
    if len(value) > max_len:
        raise ValueError(f"{field} length must be <= {max_len}")
    if not KEBAB_RE.match(value):
        raise ValueError(f"{field} must be kebab-case")
    return value


def normalize_enum(value: str, field: str, allowed: tuple[str, ...]) -> str:
    value = (value or "").strip()
    if value not in allowed:
        raise ValueError(f"{field} must be one of: {', '.join(allowed)}")
    return value


def normalize_tags_json(raw: str | None) -> str:
    if raw is None or raw.strip() == "":
        return "[]"
    try:
        data = json.loads(raw)
    except json.JSONDecodeError as exc:
        raise ValueError(f"tags_json must be valid JSON: {exc}") from exc
    if not isinstance(data, list):
        raise ValueError("tags_json must be a JSON array")
    for tag in data:
        if not isinstance(tag, str) or not KEBAB_RE.match(tag):
            raise ValueError("every tag must be a kebab-case string")
    return json.dumps(data, ensure_ascii=False, separators=(",", ":"))


def normalize_raw_hash(value: str) -> str:
    value = (value or "").strip().lower()
    if not SHA256_RE.match(value):
        raise ValueError("raw_hash must be a lowercase SHA-256 hex digest")
    return value


def raw_hash_from_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as fh:
        for chunk in iter(lambda: fh.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def connect(db_path: Path) -> sqlite3.Connection:
    db_path.parent.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(str(db_path))
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA foreign_keys = ON")
    return conn


def init_db(db_path: Path) -> None:
    with connect(db_path) as conn:
        conn.executescript(SCHEMA_SQL)
        conn.execute(
            """
            INSERT INTO schema_meta (key, value)
            VALUES ('schema_version', ?)
            ON CONFLICT(key) DO UPDATE SET value = excluded.value
            """,
            (str(SCHEMA_VERSION),),
        )
        audit_schema(conn)


def table_columns(conn: sqlite3.Connection, table_name: str) -> list[str]:
    return [row["name"] for row in conn.execute(f"PRAGMA table_info({table_name})")]


def audit_schema(conn: sqlite3.Connection) -> dict[str, Any]:
    article_columns = set(table_columns(conn, "articles"))
    missing = sorted(EXPECTED_ARTICLE_COLUMNS - article_columns)

    forbidden_columns: list[str] = []
    for row in conn.execute("SELECT name FROM sqlite_master WHERE type = 'table'"):
        table_name = row["name"]
        for column_name in table_columns(conn, table_name):
            lowered = column_name.lower()
            if any(term in lowered for term in FORBIDDEN_SCHEMA_TERMS):
                forbidden_columns.append(f"{table_name}.{column_name}")

    ok = not missing and not forbidden_columns
    result = {
        "ok": ok,
        "schema_version": SCHEMA_VERSION,
        "missing_article_columns": missing,
        "forbidden_columns": sorted(forbidden_columns),
        "article_columns": sorted(article_columns),
    }
    if not ok:
        raise ValueError(json.dumps(result, sort_keys=True))
    return result


def make_record(args: argparse.Namespace) -> ArticleRecord:
    title_visible = bool(args.title_visible)
    title_public = args.title_public.strip() if args.title_public else None
    if not title_visible and title_public is not None:
        raise ValueError("title_public is allowed only when title_visible is true")

    raw_hash = args.raw_hash
    if args.hash_from_file:
        raw_hash = raw_hash_from_file(Path(args.raw_source_path))

    return ArticleRecord(
        bu=normalize_kebab(args.bu, "bu", 40),
        project=normalize_kebab(args.project, "project", 80),
        slug=normalize_kebab(args.slug, "slug", 160),
        title_visible=title_visible,
        title_public=title_public,
        raw_source_path=str(args.raw_source_path),
        output_url=str(args.output_url),
        gate_status=normalize_enum(args.gate_status, "gate_status", ALLOWED_GATE_STATUS),
        release_status=normalize_enum(args.release_status, "release_status", ALLOWED_RELEASE_STATUS),
        scope=normalize_enum(args.scope, "scope", ALLOWED_SCOPE),
        tags_json=normalize_tags_json(args.tags_json),
        raw_hash=normalize_raw_hash(raw_hash),
    )


def upsert_article(db_path: Path, record: ArticleRecord) -> dict[str, Any]:
    with connect(db_path) as conn:
        audit_schema(conn)
        conn.execute(
            """
            INSERT INTO articles (
              article_id,
              bu,
              project,
              slug,
              title_visible,
              title_public,
              raw_source_path,
              output_url,
              gate_status,
              release_status,
              scope,
              tags_json,
              raw_hash
            )
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ON CONFLICT(bu, project, slug) DO UPDATE SET
              title_visible = excluded.title_visible,
              title_public = excluded.title_public,
              raw_source_path = excluded.raw_source_path,
              output_url = excluded.output_url,
              gate_status = excluded.gate_status,
              release_status = excluded.release_status,
              scope = excluded.scope,
              tags_json = excluded.tags_json,
              raw_hash = excluded.raw_hash,
              updated_at = strftime('%Y-%m-%dT%H:%M:%SZ', 'now')
            """,
            (
                record.article_id,
                record.bu,
                record.project,
                record.slug,
                1 if record.title_visible else 0,
                record.title_public,
                record.raw_source_path,
                record.output_url,
                record.gate_status,
                record.release_status,
                record.scope,
                record.tags_json,
                record.raw_hash,
            ),
        )
    return {
        "ok": True,
        "article_id": record.article_id,
        "key": f"{record.bu}/{record.project}/{record.slug}",
    }


def list_articles(db_path: Path) -> dict[str, Any]:
    with connect(db_path) as conn:
        audit_schema(conn)
        rows = [
            dict(row)
            for row in conn.execute(
                """
                SELECT
                  article_id,
                  bu,
                  project,
                  slug,
                  title_visible,
                  title_public,
                  raw_source_path,
                  output_url,
                  gate_status,
                  release_status,
                  scope,
                  tags_json,
                  raw_hash
                FROM articles
                ORDER BY bu, project, slug
                """
            )
        ]
    return {"ok": True, "entries": len(rows), "articles": rows}


def json_print(payload: dict[str, Any]) -> None:
    print(json.dumps(payload, ensure_ascii=False, indent=2, sort_keys=True))


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Create and audit the sanitized wikia CMS admin SQLite state."
    )
    sub = parser.add_subparsers(dest="command", required=True)

    init = sub.add_parser("init", help="initialize the CMS state database")
    init.add_argument("db_path")
    init.add_argument("--json", action="store_true")

    audit = sub.add_parser("audit", help="audit schema safety")
    audit.add_argument("db_path")
    audit.add_argument("--json", action="store_true")

    schema = sub.add_parser("schema", help="print the schema SQL")
    schema.add_argument("--json", action="store_true")

    upsert = sub.add_parser("upsert", help="insert or update one sanitized article record")
    upsert.add_argument("db_path")
    upsert.add_argument("--bu", required=True)
    upsert.add_argument("--project", required=True)
    upsert.add_argument("--slug", required=True)
    upsert.add_argument("--title-visible", action="store_true")
    upsert.add_argument("--title-public")
    upsert.add_argument("--raw-source-path", required=True)
    upsert.add_argument("--output-url", required=True)
    upsert.add_argument("--gate-status", default="unknown")
    upsert.add_argument("--release-status", default="unreleased")
    upsert.add_argument("--scope", default="article")
    upsert.add_argument("--tags-json", default="[]")
    upsert.add_argument("--raw-hash", default="")
    upsert.add_argument("--hash-from-file", action="store_true")
    upsert.add_argument("--json", action="store_true")

    list_cmd = sub.add_parser("list", help="list sanitized article records")
    list_cmd.add_argument("db_path")
    list_cmd.add_argument("--json", action="store_true")

    return parser


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)

    try:
        if args.command == "schema":
            payload = {"ok": True, "schema_version": SCHEMA_VERSION, "schema_sql": SCHEMA_SQL.strip()}
            json_print(payload) if args.json else print(SCHEMA_SQL.strip())
            return 0

        db_path = Path(args.db_path)

        if args.command == "init":
            init_db(db_path)
            payload = {"ok": True, "path": str(db_path), "schema_version": SCHEMA_VERSION}
            json_print(payload) if args.json else print(f"admin-db: initialized {db_path}")
            return 0

        if args.command == "audit":
            with connect(db_path) as conn:
                payload = audit_schema(conn)
            json_print(payload) if args.json else print("admin-db: schema audit ok")
            return 0

        if args.command == "upsert":
            if not args.raw_hash and not args.hash_from_file:
                raise ValueError("--raw-hash is required unless --hash-from-file is set")
            record = make_record(args)
            payload = upsert_article(db_path, record)
            json_print(payload) if args.json else print(f"admin-db: upserted {payload['key']}")
            return 0

        if args.command == "list":
            payload = list_articles(db_path)
            json_print(payload) if args.json else print(f"admin-db: {payload['entries']} articles")
            return 0

    except (OSError, sqlite3.Error, ValueError) as exc:
        print(f"ERR: {exc}", file=sys.stderr)
        return 1

    parser.error(f"unknown command: {args.command}")
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
