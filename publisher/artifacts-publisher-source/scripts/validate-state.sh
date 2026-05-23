#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DEFAULT_PUBLIC_ROOT="$(cd "$SOURCE_ROOT/../.." && pwd)/docs/gitpages"

PUBLIC_ROOT="${WIKIA_PUBLIC_ROOT:-$DEFAULT_PUBLIC_ROOT}"
JSON_OUTPUT="false"

usage() {
  cat <<'USAGE'
Usage: validate-state.sh [--public-root PATH] [--json]

Validates generated wikia public output for CMS invariants:
  - no plaintext private raw.md in public output
  - no plaintext password-like assignments in public output
  - no duplicated sidebar wrappers
  - no wk-tree-tema legacy marker
  - no stale sidebar article counts
  - no search/catalog mismatch
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --public-root)
      [[ $# -ge 2 ]] || { echo "ERR: --public-root requires a path" >&2; exit 2; }
      PUBLIC_ROOT="$2"
      shift 2
      ;;
    --json)
      JSON_OUTPUT="true"
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "ERR: unknown flag $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

python3 - "$PUBLIC_ROOT" "$JSON_OUTPUT" "$SCRIPT_DIR" <<'PY'
from __future__ import annotations

import json
import re
import sys
from collections import Counter, defaultdict
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import urlparse


public_root = Path(sys.argv[1]).expanduser().resolve()
json_output = sys.argv[2] == "true"
sys.path.insert(0, sys.argv[3])

import public_catalog  # noqa: E402

issues: list[dict[str, str]] = []


def rel(path: Path) -> str:
    try:
        return path.resolve().relative_to(public_root).as_posix()
    except ValueError:
        return str(path)


def add_issue(rule: str, path: Path, detail: str) -> None:
    issues.append({"rule": rule, "path": rel(path), "detail": detail})


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8", errors="ignore")


def normalize_url(value: object) -> str:
    raw = str(value or "").strip()
    if not raw:
        return ""
    parsed = urlparse(raw)
    if parsed.scheme and parsed.netloc:
        raw = parsed.path
    raw = raw.split("?", 1)[0].split("#", 1)[0]
    marker = "/gitpages/"
    if marker in raw:
        raw = raw.split(marker, 1)[1]
    raw = raw.strip("/")
    if raw.endswith("/index.html"):
        raw = raw[: -len("/index.html")]
    elif raw == "index.html":
        raw = ""
    return f"{raw}/" if raw else ""


def page_output_url(path: Path) -> str:
    path_rel = rel(path)
    if path_rel.endswith("/index.html"):
        path_rel = path_rel[: -len("/index.html")]
    elif path_rel == "index.html":
        path_rel = ""
    return f"{path_rel.strip('/')}/" if path_rel.strip("/") else ""


def frontmatter(text: str) -> dict[str, str]:
    if not text.startswith("---"):
        return {}
    match = re.match(r"^---\r?\n(.*?)\r?\n---\r?\n", text, flags=re.S)
    if not match:
        return {}
    fields: dict[str, str] = {}
    for line in match.group(1).splitlines():
        if ":" not in line or line.lstrip().startswith("#"):
            continue
        key, value = line.split(":", 1)
        fields[key.strip()] = value.strip().strip('"\'')
    return fields


SECRET_ASSIGNMENT_RE = re.compile(
    r"""(?ix)
    (?:
      ["']?(?:password|masterpass|passphrase|secret|api[_-]?key|token)["']?
      \s*[:=]\s*
      ["']([^"']{4,})["']
    )
    |
    (?:
      data-(?:password|secret|token)
      \s*=\s*
      ["']([^"']{4,})["']
    )
    """
)


def looks_like_real_secret(value: str) -> bool:
    clean = value.strip()
    lower = clean.lower()
    ignored = {
        "password",
        "secret",
        "example",
        "changeme",
        "change-me",
        "redacted",
        "masked",
        "sem senha",
        "sem senha vinculada",
    }
    if not clean or lower in ignored:
        return False
    if clean.startswith(("{{", "${")):
        return False
    if set(clean) <= {"*", "x", "X", ".", "-", "_", "•"}:
        return False
    return True


class SidebarParser(HTMLParser):
    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.stack: list[dict] = []
        self.bus: list[dict] = []
        self.projects: list[dict] = []
        self.article_hrefs: list[str] = []
        self.count_target: dict | None = None
        self.count_text: list[str] = []

    @staticmethod
    def attrs_dict(attrs: list[tuple[str, str | None]]) -> dict[str, str]:
        return {key: value or "" for key, value in attrs}

    @staticmethod
    def has_class(attrs: dict[str, str], class_name: str) -> bool:
        return class_name in attrs.get("class", "").split()

    def nearest(self, node_type: str) -> dict | None:
        for node in reversed(self.stack):
            if node.get("type") == node_type:
                return node
        return None

    def handle_starttag(self, tag: str, attrs_raw: list[tuple[str, str | None]]) -> None:
        attrs = self.attrs_dict(attrs_raw)
        if tag == "li":
            if self.has_class(attrs, "wk-tree-bu"):
                node = {
                    "type": "bu",
                    "id": attrs.get("data-bu", ""),
                    "count": None,
                    "articles": 0,
                    "projects": [],
                }
                self.bus.append(node)
                self.stack.append(node)
                return
            if self.has_class(attrs, "wk-tree-project"):
                node = {
                    "type": "project",
                    "id": attrs.get("data-project", ""),
                    "count": None,
                    "articles": 0,
                }
                bu = self.nearest("bu")
                if bu is not None:
                    bu["projects"].append(node)
                self.projects.append(node)
                self.stack.append(node)
                return
            if self.has_class(attrs, "wk-tree-article"):
                node = {"type": "article", "href": ""}
                bu = self.nearest("bu")
                project = self.nearest("project")
                if bu is not None:
                    bu["articles"] += 1
                if project is not None:
                    project["articles"] += 1
                self.stack.append(node)
                return
            self.stack.append({"type": "other"})
            return

        if tag == "span" and self.has_class(attrs, "count"):
            target = self.nearest("project") or self.nearest("bu")
            if target is not None:
                self.count_target = target
                self.count_text = []
            return

        if tag == "a":
            article = self.nearest("article")
            href = attrs.get("href", "")
            if article is not None and href:
                article["href"] = href

    def handle_data(self, data: str) -> None:
        if self.count_target is not None:
            self.count_text.append(data)

    def handle_endtag(self, tag: str) -> None:
        if tag == "span" and self.count_target is not None:
            digits = "".join(self.count_text).strip()
            if re.fullmatch(r"\d+", digits):
                self.count_target["count"] = int(digits)
            self.count_target = None
            self.count_text = []
            return

        if tag == "li" and self.stack:
            node = self.stack.pop()
            if node.get("type") == "article" and node.get("href"):
                self.article_hrefs.append(str(node["href"]))


def validate_sidebar(path: Path, text: str, records: list[dict]) -> None:
    nav_count = tag_class_count(text, "nav", "wk-sidebar-nav")
    tree_count = tag_class_count(text, "ul", "wk-tree")
    if nav_count > 1:
        add_issue("duplicated_sidebar_wrappers", path, f"wk-sidebar-nav count is {nav_count}, expected at most 1")
    if tree_count > 1:
        add_issue("duplicated_sidebar_wrappers", path, f"wk-tree root count is {tree_count}, expected at most 1")

    parser = SidebarParser()
    parser.feed(text)
    for bu in parser.bus:
        if bu["count"] is not None and bu["count"] != bu["articles"]:
            add_issue(
                "stale_article_counts",
                path,
                f"BU {bu['id']} count is {bu['count']}, but sidebar has {bu['articles']} article links",
            )
    for project in parser.projects:
        if project["count"] is not None and project["count"] != project["articles"]:
            add_issue(
                "stale_article_counts",
                path,
                f"project {project['id']} count is {project['count']}, but sidebar has {project['articles']} article links",
            )

    if not records or rel(path) == "admin/index.html":
        return

    current_url = page_output_url(path)
    current = next((record for record in records if normalize_url(record.get("output_url")) == current_url), None)
    expected_urls = {
        normalize_url(record.get("output_url"))
        for record in public_catalog.scoped_records(records, current)
        if normalize_url(record.get("output_url"))
    }
    actual_urls = {
        normalize_url(href)
        for href in parser.article_hrefs
        if normalize_url(href)
    }
    if expected_urls and actual_urls != expected_urls:
        missing = sorted(expected_urls - actual_urls)
        extra = sorted(actual_urls - expected_urls)
        detail = f"sidebar/catalog urls differ: missing={missing[:5]}, extra={extra[:5]}"
        add_issue("stale_article_counts", path, detail)


def load_catalog() -> list[dict]:
    catalog_path = public_root / "_catalog.json"
    if not catalog_path.exists():
        return []
    try:
        payload = public_catalog.load_catalog(catalog_path)
    except (json.JSONDecodeError, ValueError) as exc:
        add_issue("search_catalog_mismatch", catalog_path, f"invalid catalog JSON: {exc}")
        return []
    records = payload.get("records")
    if not isinstance(records, list):
        add_issue("search_catalog_mismatch", catalog_path, "catalog records must be an array")
        return []
    clean_records = [public_catalog.with_identity_fields(record) for record in records if isinstance(record, dict)]
    keys = Counter(public_catalog.record_key(record) for record in clean_records if public_catalog.record_key(record))
    duplicates = sorted(key for key, count in keys.items() if count > 1)
    if duplicates:
        add_issue("search_catalog_mismatch", catalog_path, f"duplicate catalog records: {duplicates[:5]}")
    return clean_records


def validate_search_catalog(records: list[dict]) -> None:
    search_path = public_root / "search.json"
    catalog_path = public_root / "_catalog.json"
    if search_path.exists() and not catalog_path.exists():
        add_issue("search_catalog_mismatch", search_path, "search.json exists but _catalog.json is missing")
        return
    if not search_path.exists() or not records:
        return
    try:
        search = json.loads(read_text(search_path))
    except json.JSONDecodeError as exc:
        add_issue("search_catalog_mismatch", search_path, f"invalid search JSON: {exc}")
        return
    if not isinstance(search, list):
        add_issue("search_catalog_mismatch", search_path, "search index must be an array")
        return

    expected_urls = sorted(
        normalize_url(record.get("output_url"))
        for record in records
        if public_catalog.is_public_record(record) and normalize_url(record.get("output_url"))
    )
    search_urls = sorted(
        normalize_url(item.get("url"))
        for item in search
        if isinstance(item, dict) and normalize_url(item.get("url"))
    )
    duplicated_search_urls = sorted(url for url, count in Counter(search_urls).items() if count > 1)
    if duplicated_search_urls:
        add_issue("search_catalog_mismatch", search_path, f"duplicate search urls: {duplicated_search_urls[:5]}")

    expected_set = set(expected_urls)
    search_set = set(search_urls)
    if expected_set != search_set:
        missing = sorted(expected_set - search_set)
        extra = sorted(search_set - expected_set)
        add_issue(
            "search_catalog_mismatch",
            search_path,
            f"public catalog/search urls differ: missing={missing[:5]}, extra={extra[:5]}",
        )


def tag_class_count(text: str, tag: str, class_name: str) -> int:
    total = 0
    for match in re.finditer(rf"<{tag}\b[^>]*>", text, flags=re.I):
        class_match = re.search(r"""class\s*=\s*["']([^"']*)["']""", match.group(0), flags=re.I)
        if class_match and class_name in class_match.group(1).split():
            total += 1
    return total


def validate_text_file(path: Path) -> None:
    text = read_text(path)
    if path.name == "raw.md" and public_catalog.is_private_gate(frontmatter(text).get("gate")):
        add_issue("plaintext_private_raw_md", path, "private-gated raw.md is present under public output")

    if "wk-tree-tema" in text:
        add_issue("legacy_wk_tree_tema", path, "legacy wk-tree-tema marker is present")

    for match in SECRET_ASSIGNMENT_RE.finditer(text):
        value = match.group(1) or match.group(2) or ""
        if looks_like_real_secret(value):
            add_issue("plaintext_passwords", path, "potential plaintext secret assignment found")
            break

    if path.suffix.lower() == ".html":
        validate_sidebar(path, text, catalog_records)


if not public_root.is_dir():
    add_issue("missing_public_root", public_root, "public root does not exist")
else:
    catalog_records = load_catalog()
    validate_search_catalog(catalog_records)
    text_suffixes = {".css", ".html", ".js", ".json", ".md", ".txt", ".xml"}
    for item in sorted(public_root.rglob("*")):
        if not item.is_file():
            continue
        if item.suffix.lower() not in text_suffixes:
            continue
        validate_text_file(item)

summary = {
    "ok": not issues,
    "public_root": str(public_root),
    "issue_count": len(issues),
    "issues": issues,
}

if json_output:
    print(json.dumps(summary, ensure_ascii=False, indent=2, sort_keys=True))
else:
    if issues:
        print(f"FAIL: validate-state found {len(issues)} issue(s) in {public_root}", file=sys.stderr)
        for issue in issues:
            print(f"- {issue['rule']}: {issue['path']} - {issue['detail']}", file=sys.stderr)
    else:
        print(f"PASS: validate-state found no public-output issues in {public_root}")

sys.exit(0 if not issues else 1)
PY
