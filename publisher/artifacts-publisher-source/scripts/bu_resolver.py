#!/usr/bin/env python3
"""BU Resolver — Wikia Wave 2 (Phase 3).

Resolves (bu, project, slug, source) for a raw.md by applying a 3-stage
precedence chain (per D4 decision):

  Stage 0: explicit override (--bu/--project/--slug CLI flags)
  Stage 1: frontmatter inference (parse_frontmatter_optional)
  Stage 2: cwd-pattern auto-detect (BU-* directory substrings)
  Stage 3: interactive prompt fallback (stdin) or ResolverError if --no-interactive

All 4 stages are wired (override / frontmatter / cwd-pattern / prompt).

BU enum is locked per Wave 2 D1: {staging, vita, allin, aleyemma, gobbi}.
Project field is required; 'geral' is the canonical catch-all per D6.
"""

import json
import os
import re
import sys

from frontmatter_parser import parse_frontmatter_optional  # noqa: F401  used by Task 3.2

BU_ENUM = {"staging", "vita", "allin", "aleyemma", "gobbi"}

CWD_PATTERNS = [
    ("BU-VITASCIENCE", "vita"),
    ("BU-ALEYEMMA", "aleyemma"),
    ("BU-CASE", "aleyemma"),
    ("BU-PERSONAL", "gobbi"),
]


class ResolverError(Exception):
    """Raised when BU/project/slug cannot be resolved (e.g., non-interactive + no signal)."""
    pass


def resolve_bu(raw_md_path, cwd=None, interactive=True,
               bu_override=None, project_override=None, slug_override=None):
    """Resolve (bu, project, slug, source) for a raw.md.

    Returns a dict: {"bu", "project", "slug", "source"} where source ∈
    {"override", "frontmatter", "cwd-pattern", "prompt"}.

    Stage 0: explicit override (bu_override + slug_override both required).
    Stage 1: frontmatter (parse_frontmatter_optional → valid bu/project/slug).
    Stage 2: cwd-pattern (CWD_PATTERNS substring match → BU + project=geral).
    Stage 3: interactive prompt (stdin); raises ResolverError if --no-interactive.
    """
    # Stage 0: explicit override takes top precedence (D6: project defaults to 'geral').
    if bu_override and slug_override:
        return {
            "bu": bu_override,
            "project": project_override or "geral",
            "slug": slug_override,
            "source": "override",
        }

    # Stage 1: frontmatter inference. Article ships with valid bu/project/slug → done.
    fm = parse_frontmatter_optional(raw_md_path)
    if fm and fm.get("bu") in BU_ENUM and fm.get("project") and fm.get("slug"):
        return {
            "bu": fm["bu"],
            "project": fm["project"],
            "slug": fm["slug"],
            "source": "frontmatter",
        }

    # Stage 2: cwd-pattern auto-detect. Editor working from BU-typed dir but no frontmatter.
    # Substring match (not regex) for robustness against path variations.
    search_path = cwd or os.path.dirname(os.path.abspath(raw_md_path))
    for pattern, bu in CWD_PATTERNS:
        if pattern in search_path:
            # Derive slug from raw.md's parent folder basename, kebab-normalized.
            slug = os.path.basename(os.path.dirname(os.path.abspath(raw_md_path)))
            slug = re.sub(r'[^a-z0-9-]', '-', slug.lower()).strip('-')
            return {
                "bu": bu,
                "project": "geral",
                "slug": slug or "untitled",
                "source": "cwd-pattern",
            }

    # Stage 3: interactive prompt fallback. Prompts go to stderr so stdout stays clean
    # for JSON output. --no-interactive raises ResolverError instead of hanging.
    if not interactive:
        raise ResolverError(
            f"cannot infer BU for {raw_md_path}; "
            "provide --bu or add frontmatter"
        )
    print("BU? (staging/vita/allin/aleyemma/gobbi)", file=sys.stderr)
    bu = input().strip()
    if bu not in BU_ENUM:
        raise ResolverError(
            f"BU must be one of {sorted(BU_ENUM)}, got {bu!r}"
        )
    print("Project? (default: geral)", file=sys.stderr)
    project = input().strip() or "geral"
    default_slug = re.sub(
        r'[^a-z0-9-]', '-',
        os.path.basename(os.path.dirname(raw_md_path)).lower(),
    ).strip('-')
    print(f"Slug? (default: {default_slug})", file=sys.stderr)
    slug = input().strip() or default_slug
    return {"bu": bu, "project": project, "slug": slug, "source": "prompt"}


def _print_help():
    print(
        "Usage: bu_resolver.py <raw.md path> [options]\n"
        "\n"
        "Options:\n"
        "  --bu <slug>             explicit BU override (one of: "
        f"{sorted(BU_ENUM)})\n"
        "  --project <slug>        explicit project override (default: geral)\n"
        "  --slug <slug>           explicit article slug override\n"
        "  --cwd <path>            override working directory for Stage 2\n"
        "  --no-interactive        disable Stage 3 prompt (raises ResolverError instead)\n"
        "  -h, --help              show this message\n"
        "\n"
        "Output: JSON object {bu, project, slug, source} on stdout.\n"
        "Prompts (Stage 3) go to stderr."
    )


def _parse_argv(argv):
    """Minimal argv parser (no argparse to keep import surface tight).

    Returns (raw_md_path, kwargs_dict) or raises SystemExit on bad input.
    """
    if not argv or argv[0] in ("-h", "--help"):
        _print_help()
        sys.exit(0)

    raw_md_path = None
    kwargs = {
        "cwd": None,
        "interactive": True,
        "bu_override": None,
        "project_override": None,
        "slug_override": None,
    }

    i = 0
    while i < len(argv):
        tok = argv[i]
        if tok == "--bu":
            kwargs["bu_override"] = argv[i + 1]
            i += 2
        elif tok == "--project":
            kwargs["project_override"] = argv[i + 1]
            i += 2
        elif tok == "--slug":
            kwargs["slug_override"] = argv[i + 1]
            i += 2
        elif tok == "--cwd":
            kwargs["cwd"] = argv[i + 1]
            i += 2
        elif tok == "--no-interactive":
            kwargs["interactive"] = False
            i += 1
        elif tok in ("-h", "--help"):
            _print_help()
            sys.exit(0)
        elif tok.startswith("--"):
            print(f"bu_resolver: unknown flag {tok!r}", file=sys.stderr)
            sys.exit(2)
        else:
            if raw_md_path is None:
                raw_md_path = tok
            else:
                print(f"bu_resolver: unexpected positional {tok!r}", file=sys.stderr)
                sys.exit(2)
            i += 1

    if raw_md_path is None:
        print("bu_resolver: missing required raw.md path", file=sys.stderr)
        sys.exit(2)

    return raw_md_path, kwargs


if __name__ == "__main__":
    path, opts = _parse_argv(sys.argv[1:])
    # All 4 stages wired: override → frontmatter → cwd-pattern → prompt.
    result = resolve_bu(path, **opts)
    print(json.dumps(result, indent=2, sort_keys=True))
