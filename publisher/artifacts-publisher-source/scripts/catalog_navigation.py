#!/usr/bin/env python3
"""Catalog-backed navigation view models shared by static renderers."""
from __future__ import annotations

from datetime import datetime
from pathlib import Path
from typing import Any

import public_catalog


BU_DISPLAY = dict(public_catalog.KNOWN_BU_DISPLAY)


def humanize_slug(slug: Any) -> str:
    return str(slug or "").replace("-", " ").strip().title()


def join_url(base: Any, path: Any) -> str:
    base_text = str(base or "").rstrip("/")
    path_text = str(path or "").lstrip("/")
    if not base_text:
        return f"/{path_text}" if path_text else "/"
    if not path_text:
        return f"{base_text}/"
    return f"{base_text}/{path_text}"


def title_for_bu(bu: Any) -> str:
    bu_slug = str(bu or "")
    return BU_DISPLAY.get(bu_slug, humanize_slug(bu_slug))


def _record_sort_key(record: dict[str, Any]) -> tuple[str, str, str]:
    return (
        str(record.get("bu") or ""),
        str(record.get("project") or ""),
        str(record.get("slug") or ""),
    )


def _article_sort_key(article: dict[str, Any]) -> tuple[float, str, str]:
    try:
        mtime = float(article.get("mtime") or 0)
    except (TypeError, ValueError):
        mtime = 0
    return (
        mtime,
        str(article.get("date") or article.get("updated_at") or article.get("created_at") or ""),
        str(article.get("slug") or ""),
    )


def _html_timestamp(public_root: str | Path | None, output_url: str) -> tuple[float, str, str]:
    if public_root is None or not output_url:
        return 0, "", ""
    html_path = Path(public_root) / output_url.strip("/") / "index.html"
    if not html_path.exists():
        return 0, "", ""
    mtime = datetime.fromtimestamp(html_path.stat().st_mtime)
    return mtime.timestamp(), mtime.strftime("%Y-%m-%d"), mtime.strftime("%d %b")


def load_catalog_records(public_root: str | Path) -> list[dict[str, Any]]:
    return public_catalog.load_records_from_public_root(public_root)


def records_for_surface(
    public_root: str | Path,
    *,
    public_only: bool = True,
    current_record: dict[str, Any] | None = None,
    bu_slug: str | None = None,
    project_slug: str | None = None,
) -> list[dict[str, Any]]:
    records = load_catalog_records(public_root)
    if not records:
        return []

    if current_record is not None:
        records = public_catalog.scoped_records(records, current_record)
    elif public_only:
        records = [record for record in records if public_catalog.is_public_record(record)]

    if bu_slug is not None:
        records = [record for record in records if record.get("bu") == bu_slug]
    if project_slug is not None:
        records = [record for record in records if record.get("project") == project_slug]

    return sorted(records, key=_record_sort_key)


def article_from_record(
    record: dict[str, Any],
    *,
    public_root: str | Path | None = None,
) -> dict[str, Any]:
    bu = str(record.get("bu") or "")
    project = str(record.get("project") or "")
    slug = str(record.get("slug") or "")
    output_url = public_catalog.normalize_output_url(
        record.get("output_url") or f"{bu}/{project}/{slug}/"
    )
    mtime, date, date_human = _html_timestamp(public_root, output_url)
    if not date:
        date = str(record.get("date") or record.get("updated_at") or record.get("created_at") or "")[:10]
    if not date_human and date:
        date_human = date
    return {
        "bu": bu,
        "project": project,
        "slug": slug,
        "title": public_catalog.public_title(record),
        "date": date,
        "date_human": date_human,
        "updated_at": str(record.get("updated_at") or ""),
        "created_at": str(record.get("created_at") or ""),
        "gate": str(record.get("gate_status") or "unknown") != "public",
        "url": output_url,
        "mtime": mtime,
        "tags": record.get("tags") or [],
    }


def articles_from_records(
    records: list[dict[str, Any]],
    *,
    bu_slug: str | None = None,
    project_slug: str | None = None,
    public_root: str | Path | None = None,
) -> list[dict[str, Any]]:
    articles = []
    for record in records:
        if bu_slug is not None and record.get("bu") != bu_slug:
            continue
        if project_slug is not None and record.get("project") != project_slug:
            continue
        article = article_from_record(record, public_root=public_root)
        if not article["bu"] or not article["project"] or not article["slug"]:
            continue
        articles.append(article)
    return sorted(articles, key=_article_sort_key, reverse=True)


def build_bu_tree(
    records: list[dict[str, Any]],
    *,
    public_root: str | Path | None = None,
) -> dict[str, dict[str, Any]]:
    tree: dict[str, dict[str, Any]] = {
        bu: {"title": title, "projects": {}, "article_count": 0}
        for bu, title in BU_DISPLAY.items()
    }

    for record in sorted(records, key=_record_sort_key):
        article = article_from_record(record, public_root=public_root)
        bu = article["bu"]
        project = article["project"]
        slug = article["slug"]
        if not bu or not project or not slug:
            continue

        if bu not in tree:
            tree[bu] = {
                "title": title_for_bu(bu),
                "projects": {},
                "article_count": 0,
            }

        project_node = tree[bu]["projects"].setdefault(
            project,
            {"auto_flatten": False, "articles": []},
        )
        project_node["articles"].append(article)
        tree[bu]["article_count"] += 1

    for bu_node in tree.values():
        for project_node in bu_node["projects"].values():
            project_node["articles"].sort(key=_article_sort_key, reverse=True)
            project_node["auto_flatten"] = len(project_node["articles"]) == 1

    return tree


def artifacts_from_records(
    records: list[dict[str, Any]],
    public_root: str | Path,
) -> list[dict[str, Any]]:
    artifacts = []
    for article in articles_from_records(records, public_root=public_root):
        artifacts.append({
            "slug": article["slug"],
            "tema": f"{article['bu']}/{article['project']}",
            "title": article["title"],
            "description": "",
            "tags": article.get("tags") or [],
            "date": article.get("date") or "",
            "date_human": article.get("date_human") or "",
            "url": article["url"],
            "mtime": article.get("mtime") or 0,
        })
    return artifacts
