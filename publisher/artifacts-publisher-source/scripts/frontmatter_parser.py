#!/usr/bin/env python3
"""
frontmatter_parser.py — Wave 2 frontmatter parser + schema validator.

Single source of truth for reading YAML front matter from any `raw.md` and
validating it against the Wave 2 schema.

Schema (Wave 2):
  - bu       (required): enum [staging|vita|allin|aleyemma|gobbi]
  - project  (required): kebab-case, len <= 60; "geral" is canonical catch-all
  - slug     (required): kebab-case, len <= 120 (URL leaf)
  - title    (required): non-empty string
  - date     (required): ISO YYYY-MM-DD
  - tags     (optional): list of kebab-case strings
  - gate     (optional): string | None | omitted (null = released/gateless)

Public API:
  parse_frontmatter(path)          -> dict (strict; raises ValueError on missing/invalid)
  parse_frontmatter_optional(path) -> dict | None (graceful; for legacy inference)

CLI:
  frontmatter_parser.py --help
  frontmatter_parser.py <raw.md path>   # prints parsed dict as JSON
"""

import sys
import json
import os
import re

try:
    import yaml  # type: ignore
    _HAS_YAML = True
except ImportError:
    yaml = None  # type: ignore
    _HAS_YAML = False


# ---- Schema constants ---------------------------------------------------

_BU_ENUM = ("staging", "vita", "allin", "aleyemma", "gobbi")
_KEBAB_RE = re.compile(r"^[a-z0-9]+(-[a-z0-9]+)*$")
_DATE_RE = re.compile(r"^\d{4}-\d{2}-\d{2}$")
_PROJECT_MAX = 60
_SLUG_MAX = 120


# ---- Fallback YAML mini-parser ------------------------------------------
# Handles only the 7 schema fields we care about. Keys are top-level
# `key: value` lines plus an inline-list form `tags: [a, b]`. Block-style
# YAML lists are NOT supported in the fallback — but our schema uses only
# inline lists, so that's the contract.

def _strip_quotes(s):
    s = s.strip()
    if len(s) >= 2 and s[0] == s[-1] and s[0] in ('"', "'"):
        return s[1:-1]
    return s


def _coerce_scalar(value):
    v = value.strip()
    if v == "" or v.lower() == "null" or v == "~":
        return None
    if v.lower() == "true":
        return True
    if v.lower() == "false":
        return False
    # Inline list: [a, b, c]
    if v.startswith("[") and v.endswith("]"):
        inner = v[1:-1].strip()
        if not inner:
            return []
        return [_strip_quotes(item) for item in inner.split(",")]
    return _strip_quotes(v)


def _fallback_yaml_parse(block):
    """Stdlib mini-parser for the Wave 2 frontmatter subset."""
    data = {}
    for raw_line in block.splitlines():
        line = raw_line.rstrip()
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        if ":" not in line:
            raise ValueError(f"frontmatter line missing ':' delimiter: {raw_line!r}")
        key, _, value = line.partition(":")
        key = key.strip()
        if not key:
            raise ValueError(f"frontmatter line missing key: {raw_line!r}")
        data[key] = _coerce_scalar(value)
    return data


# ---- Schema validation --------------------------------------------------

def _validate_schema(data, path):
    """Validate dict against Wave 2 schema.

    Valid BU slugs (D1 of AGENT_PROMPT.md): staging, vita, allin, aleyemma, gobbi.
    """
    if not isinstance(data, dict):
        raise ValueError(f"{path}: frontmatter must be a mapping, got {type(data).__name__}")

    # bu (required, enum)
    if "bu" not in data:
        raise ValueError(f"{path}: missing required field 'bu' (must be one of [staging,vita,allin,aleyemma,gobbi])")
    bu = data["bu"]
    if bu not in _BU_ENUM:
        raise ValueError(f"{path}: bu must be one of [staging,vita,allin,aleyemma,gobbi], got {bu!r}")

    # project (required, kebab, len)
    if "project" not in data:
        raise ValueError(f"{path}: missing required field 'project' (kebab-case; 'geral' is canonical catch-all)")
    project = data["project"]
    if not isinstance(project, str) or not project:
        raise ValueError(f"{path}: project must be a non-empty string, got {project!r}")
    if len(project) > _PROJECT_MAX:
        raise ValueError(f"{path}: project length must be <= {_PROJECT_MAX}, got {len(project)} for {project!r}")
    if not _KEBAB_RE.match(project):
        raise ValueError(f"{path}: project must be kebab-case (^[a-z0-9]+(-[a-z0-9]+)*$), got {project!r}")

    # slug (required, kebab, len)
    if "slug" not in data:
        raise ValueError(f"{path}: missing required field 'slug' (URL leaf, kebab-case)")
    slug = data["slug"]
    if not isinstance(slug, str) or not slug:
        raise ValueError(f"{path}: slug must be a non-empty string, got {slug!r}")
    if len(slug) > _SLUG_MAX:
        raise ValueError(f"{path}: slug length must be <= {_SLUG_MAX}, got {len(slug)} for {slug!r}")
    if not _KEBAB_RE.match(slug):
        raise ValueError(f"{path}: slug must be kebab-case (^[a-z0-9]+(-[a-z0-9]+)*$), got {slug!r}")

    # title (required, non-empty string)
    if "title" not in data:
        raise ValueError(f"{path}: missing required field 'title'")
    title = data["title"]
    if not isinstance(title, str) or not title.strip():
        raise ValueError(f"{path}: title must be a non-empty string, got {title!r}")

    # date (required, ISO YYYY-MM-DD)
    if "date" not in data:
        raise ValueError(f"{path}: missing required field 'date' (ISO YYYY-MM-DD)")
    date = data["date"]
    date_str = date if isinstance(date, str) else str(date)
    if not _DATE_RE.match(date_str):
        raise ValueError(f"{path}: date must match ^\\d{{4}}-\\d{{2}}-\\d{{2}}$, got {date!r}")
    data["date"] = date_str

    # tags (optional, list of kebab strings)
    if "tags" in data and data["tags"] is not None:
        tags = data["tags"]
        if not isinstance(tags, list):
            raise ValueError(f"{path}: tags must be a list, got {type(tags).__name__}")
        for tag in tags:
            if not isinstance(tag, str) or not _KEBAB_RE.match(tag):
                raise ValueError(f"{path}: each tag must be kebab-case string, got {tag!r}")

    # gate (optional, string | None | omitted)
    if "gate" in data and data["gate"] is not None:
        gate = data["gate"]
        if not isinstance(gate, str):
            raise ValueError(f"{path}: gate must be a string or null, got {type(gate).__name__}")

    return data


# ---- Public API ---------------------------------------------------------

def parse_frontmatter(path):
    """Read + validate frontmatter from a markdown file. Raises ValueError on failure."""
    if not os.path.isfile(path):
        raise FileNotFoundError(f"{path}: not a regular file")

    with open(path, "r", encoding="utf-8") as fh:
        lines = fh.readlines()

    if not lines or lines[0].rstrip("\r\n") != "---":
        raise ValueError(f"{path}: missing frontmatter delimiter (first line must be '---')")

    block_lines = []
    closed = False
    for line in lines[1:]:
        if line.rstrip("\r\n") == "---":
            closed = True
            break
        block_lines.append(line)

    if not closed:
        raise ValueError(f"{path}: frontmatter block not closed (missing trailing '---')")

    block = "".join(block_lines)

    try:
        if _HAS_YAML:
            data = yaml.safe_load(block) or {}
        else:
            data = _fallback_yaml_parse(block)
    except Exception as exc:
        raise ValueError(f"{path}: YAML parse error — {exc}") from exc

    return _validate_schema(data, path)


def parse_frontmatter_optional(path):
    """Read + validate frontmatter; return None instead of raising on missing/invalid.

    Used by the legacy-article inference path (Phase 3 bu_resolver) — callers
    that need to detect "no usable frontmatter, fall back to cwd-pattern".
    """
    try:
        return parse_frontmatter(path)
    except (ValueError, FileNotFoundError, OSError):
        return None


def _print_help():
    print('Usage: frontmatter_parser.py <raw.md path>')


if __name__ == '__main__':
    if len(sys.argv) < 2 or sys.argv[1] in ('--help', '-h'):
        _print_help()
        sys.exit(0)
    result = parse_frontmatter(sys.argv[1])
    print(json.dumps(result, indent=2, sort_keys=True))
