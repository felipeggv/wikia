#!/usr/bin/env bash
set -euo pipefail

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_ROOT="$(cd "${TEST_DIR}/.." && pwd)"
TMP_PARENT="${SOURCE_ROOT}/tmp/catalog-navigation-tests"

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

require_file() {
  [[ -f "$1" ]] || fail "missing required file: $1"
}

require_file "${SOURCE_ROOT}/scripts/catalog_navigation.py"
require_file "${SOURCE_ROOT}/scripts/render-wiki.py"
require_file "${SOURCE_ROOT}/scripts/render-bu.py"
require_file "${SOURCE_ROOT}/scripts/render-project.py"
require_file "${SOURCE_ROOT}/scripts/render-artifact.py"
mkdir -p "$TMP_PARENT"

RUN_DIR="$(mktemp -d "${TMP_PARENT}/run.XXXXXX")"
trap 'rm -rf "$RUN_DIR"' EXIT

PUBLIC_ROOT="${RUN_DIR}/gitpages"
WIKI_BASE="https://fixture.test/wikia/gitpages"
mkdir -p "$PUBLIC_ROOT"

python3 - "$SOURCE_ROOT" "$PUBLIC_ROOT" "$RUN_DIR" "$WIKI_BASE" <<'PY'
import importlib.util
import json
import os
import subprocess
import sys
from pathlib import Path

source_root = Path(sys.argv[1])
public_root = Path(sys.argv[2])
run_dir = Path(sys.argv[3])
wiki_base = sys.argv[4]
scripts_dir = source_root / "scripts"
sys.path.insert(0, str(scripts_dir))

import public_catalog
import catalog_navigation


def load_script(name):
    path = scripts_dir / f"{name}.py"
    spec = importlib.util.spec_from_file_location(name.replace("-", "_"), path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


render_wiki = load_script("render-wiki")
render_bu = load_script("render-bu")
render_project = load_script("render-project")


def record(bu, project, slug, *, title=None, gate_status="gated", release_status="unreleased", scope="article"):
    title_visible = gate_status == "public"
    return public_catalog.with_identity_fields({
        "bu": bu,
        "project": project,
        "slug": slug,
        "title_visible": title_visible,
        "title_public": title if title_visible else None,
        "output_url": f"{bu}/{project}/{slug}/",
        "gate_status": gate_status,
        "release_status": release_status,
        "scope": scope,
        "tags": ["fixture"] if title_visible else [],
        "raw_hash": f"hash-{bu}-{project}-{slug}",
    })


records = [
    record("staging", "test-project", "public-article", title="Public Article", gate_status="public", release_status="released", scope="public"),
    record("staging", "test-project", "private-article", scope="article"),
    record("staging", "secret-project", "project-scope-article", scope="project"),
    record("staging", "secret-project", "project-colleague", scope="article"),
    record("staging", "bu-private", "bu-scope-article", scope="bu"),
    record("gobbi", "private-project", "other-bu-private", scope="bu"),
    record("gobbi", "admin-project", "admin-scope-article", scope="admin"),
]

(public_root / "_catalog.json").write_text(
    json.dumps(
        {
            "catalog_version": 1,
            "generated_at": "2026-05-23T00:00:00Z",
            "records": records,
        },
        indent=2,
        sort_keys=True,
    )
    + "\n",
    encoding="utf-8",
)

loaded_records = public_catalog.load_records_from_public_root(public_root)
by_key = {public_catalog.record_key(item): item for item in loaded_records}


def require(condition, message):
    if not condition:
        raise SystemExit(message)


def require_contains(text, marker, label):
    require(marker in text, f"missing {label}: {marker}")


def require_absent(text, marker, label):
    require(marker not in text, f"unexpected {label}: {marker}")


public_tree = render_wiki.build_bu_tree(str(public_root))
public_html = render_wiki.tree_html(public_tree, wiki_base=wiki_base)
require_contains(public_html, "public-article", "public article in public sidebar")
for marker in (
    "private-article",
    "project-scope-article",
    "project-colleague",
    "bu-scope-article",
    "other-bu-private",
    "admin-scope-article",
):
    require_absent(public_html, marker, "private record in public sidebar")
require_absent(public_html, '<nav class="wk-sidebar-nav">', "wrapper leaked from tree_html")
require_absent(public_html, '<ul class="wk-tree">', "tree root leaked from tree_html")

bu_articles = render_bu.collect_bu_articles(str(public_root), "staging")
require([item["slug"] for item in bu_articles] == ["public-article"], "BU page should list public catalog records only")
project_articles = render_project.collect_project_articles(str(public_root), "staging", "test-project")
require([item["slug"] for item in project_articles] == ["public-article"], "project page should list public catalog records only")


def scoped_sidebar(key):
    current = by_key[key]
    tree = render_wiki.build_bu_tree(str(public_root), public_only=False, current_record=current)
    return render_wiki.tree_html(
        tree,
        current_bu=current["bu"],
        current_project=current["project"],
        current_slug=current["slug"],
        wiki_base=wiki_base,
        scope_bu=current["bu"],
    )


article_html = scoped_sidebar("staging/test-project/private-article")
require_contains(article_html, "private-article", "article-scope current article")
for marker in ("public-article", "project-scope-article", "bu-scope-article", "other-bu-private"):
    require_absent(article_html, marker, "extra article in article-scope sidebar")

project_html = scoped_sidebar("staging/secret-project/project-scope-article")
require_contains(project_html, "project-scope-article", "project-scope current article")
require_contains(project_html, "project-colleague", "project-scope sibling article")
for marker in ("public-article", "private-article", "bu-scope-article", "other-bu-private"):
    require_absent(project_html, marker, "extra article in project-scope sidebar")

bu_html = scoped_sidebar("staging/bu-private/bu-scope-article")
for marker in ("public-article", "private-article", "project-scope-article", "project-colleague", "bu-scope-article"):
    require_contains(bu_html, marker, "BU-scope staging article")
require_absent(bu_html, "other-bu-private", "cross-BU article in BU-scope sidebar")

admin_tree = render_wiki.build_bu_tree(
    str(public_root),
    public_only=False,
    current_record=by_key["gobbi/admin-project/admin-scope-article"],
)
admin_html = render_wiki.tree_html(admin_tree, wiki_base=wiki_base)
for marker in ("public-article", "other-bu-private", "admin-scope-article"):
    require_contains(admin_html, marker, "admin-scope model article")

raw_md = run_dir / "private-source" / "staging" / "test-project" / "public-article" / "raw.md"
raw_md.parent.mkdir(parents=True, exist_ok=True)
raw_md.write_text(
    """---
bu: staging
project: test-project
slug: public-article
title: Public Article
date: 2026-05-23
tags: [fixture]
gate: null
---

# Public Article

Fixture body.
""",
    encoding="utf-8",
)
env = os.environ.copy()
env["WIKIA_PUBLIC_ROOT"] = str(public_root)
artifact_html = subprocess.check_output(
    [
        sys.executable,
        str(scripts_dir / "render-artifact.py"),
        str(raw_md),
        "{}",
        "Public Article",
        "public-article",
        "test-project",
        "wikia",
        "2026-05-23",
        "",
        "claude",
        "[]",
        "[]",
        wiki_base,
    ],
    env=env,
    text=True,
)
require_contains(artifact_html, f'href="{wiki_base}/staging/"', "article BU breadcrumb")
require_contains(artifact_html, f'href="{wiki_base}/staging/test-project/"', "article project breadcrumb")
require_contains(artifact_html, "Staging / Test Project", "article eyebrow")
require_absent(artifact_html, "/research/test-project/", "legacy research breadcrumb")

missing_md = run_dir / "private-source" / "staging" / "test-project" / "missing-current" / "raw.md"
missing_md.parent.mkdir(parents=True, exist_ok=True)
missing_md.write_text(
    """---
bu: staging
project: test-project
slug: missing-current
title: Missing Current
date: 2026-05-23
tags: [fixture]
gate: <vault>
---

# Missing Current

Fixture body.
""",
    encoding="utf-8",
)
missing_html = subprocess.check_output(
    [
        sys.executable,
        str(scripts_dir / "render-artifact.py"),
        str(missing_md),
        "{}",
        "Missing Current",
        "missing-current",
        "test-project",
        "wikia",
        "2026-05-23",
        "",
        "claude",
        "[]",
        "[]",
        wiki_base,
    ],
    env=env,
    text=True,
)
require_contains(missing_html, "public-article", "missing-current fallback public article")
for marker in ("private-article", "project-scope-article", "bu-scope-article", "other-bu-private"):
    require_absent(missing_html, marker, "missing-current fallback private article")

stale_root = run_dir / "stale-public-root"
stale_raw = stale_root / "staging" / "test-project" / "stale-public" / "raw.md"
stale_raw.parent.mkdir(parents=True, exist_ok=True)
stale_raw.write_text(
    """---
bu: staging
project: test-project
slug: stale-public
title: Stale Public
date: 2026-05-23
tags: [fixture]
gate: null
---

# Stale Public
""",
    encoding="utf-8",
)
(stale_root / "_catalog.json").write_text(
    json.dumps(
        {
            "catalog_version": 1,
            "generated_at": "2026-05-23T00:00:00Z",
            "records": [
                record("staging", "private-only", "private-only-article", scope="article")
            ],
        },
        indent=2,
        sort_keys=True,
    )
    + "\n",
    encoding="utf-8",
)
stale_tree = render_wiki.build_bu_tree(str(stale_root))
stale_html = render_wiki.tree_html(stale_tree, wiki_base=wiki_base)
require_absent(stale_html, "stale-public", "legacy fallback when catalog filter is empty")
require_absent(stale_html, "private-only-article", "private catalog record on public surface")

require(catalog_navigation.title_for_bu("allin") == "AllIn", "BU display contract should come from catalog helper")
PY

cat <<EOF
---
type: report
title: Catalog Navigation Model Test
created: $(date +%F)
tags:
  - wikia-cms
  - renderer
  - navigation
related:
  - '[[Wikia-CMS-Parallel-Execution]]'
  - '[[CMS-Catalog-Spine]]'
---

# Catalog Navigation Model Test

## Executive Summary

The renderer navigation layer now uses one catalog-backed view model for public,
article, project, BU, and admin-scope navigation surfaces.

\`\`\`text
_catalog.json
   |
   v
catalog_navigation.py
   |
   +-- render-wiki.py sidebar tree
   +-- render-bu.py public BU lists
   +-- render-project.py public project lists
   +-- render-artifact.py BU/project breadcrumb
\`\`\`

## Verified Checks

| Check | Result |
|---|---|
| Public sidebar shows public records only | PASS |
| Article-scope sidebar shows only the current gated article | PASS |
| Project-scope sidebar shows only the gated project slice | PASS |
| BU-scope sidebar excludes cross-BU records | PASS |
| Admin-scope model can see all records | PASS |
| BU and project pages list public catalog records only | PASS |
| Article breadcrumb points to BU/project paths, not legacy research paths | PASS |
| Missing current catalog record falls back to public sidebar rows | PASS |
| Empty public catalog filter does not fall back to stale raw files | PASS |
| Tree renderer still returns child list items only | PASS |

## Images Analyzed

0
EOF
