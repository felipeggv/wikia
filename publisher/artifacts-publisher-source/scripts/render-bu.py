#!/usr/bin/env python3
"""
render-bu.py — Wave 2: regenera a home de uma BU (centralzinha).

Caminha por `<output_dir>/<bu_slug>/<project>/<slug>/raw.md`, agrupa por
projeto, e substitui em `bu-home.html.tpl` produzindo `<bu>/index.html`.

Uso:
  render-bu.py <output-dir> <theme-json> <bu-slug> <wiki-base>

Se a BU não tem nenhum artigo válido, renderiza um stub "Nenhum artigo
publicado ainda." (usado para vita/allin/aleyemma como scaffolding).
"""

import os
import sys
import json
import html as html_lib
from pathlib import Path
from collections import defaultdict

SCRIPT_DIR = Path(__file__).parent
SKILL_DIR = SCRIPT_DIR.parent
TEMPLATES_DIR = SKILL_DIR / 'templates'

sys.path.insert(0, str(SCRIPT_DIR))
from frontmatter_parser import parse_frontmatter_optional  # noqa: E402
import public_catalog  # noqa: E402
import catalog_navigation  # noqa: E402


BU_DISPLAY = catalog_navigation.BU_DISPLAY

BU_DESCRIPTION = {
    'staging': 'Sandbox da BU — conteúdo experimental e testes.',
    'vita': 'Vitascience — health tech, suplementos, ANVISA.',
    'allin': 'AllIn — em construção.',
    'aleyemma': 'Aleyemma — marketing B2B LATAM, LSC.',
    'gobbi': 'Felipe Gobbi — notas pessoais e playbooks.',
}

RECENT_LIMIT = 8


# copy of render-wiki.py:build_theme_vars
def build_theme_vars(theme):
    return ''.join(f"  --{k}: {v};\n" for k, v in [
        ('bg-main', theme.get('bgMain', '#0c0e0c')),
        ('bg-sidebar', theme.get('bgSidebar', '#0f100f')),
        ('bg-activity', theme.get('bgActivity', '#141415')),
        ('border', theme.get('border', '#111311')),
        ('text-main', theme.get('textMain', '#f2f2c0')),
        ('text-dim', theme.get('textDim', '#cec8ba')),
        ('accent', theme.get('accent', '#5b675b')),
        ('accent-dim', theme.get('accentDim', '#262121')),
        ('accent-text', theme.get('accentText', '#ffffff')),
        ('success', theme.get('success', '#bed78e')),
        ('warning', theme.get('warning', '#d0a795')),
        ('error', theme.get('error', '#ff5555')),
    ])


def _esc(s):
    return html_lib.escape(str(s), quote=False)


def collect_bu_articles(output_dir, bu_slug):
    """Walk <output_dir>/<bu_slug>/<project>/<slug>/raw.md and collect metadata."""
    catalog_records = catalog_navigation.load_catalog_records(output_dir)
    if catalog_records:
        public_records = [
            record for record in catalog_records
            if public_catalog.is_public_record(record)
        ]
        return catalog_navigation.articles_from_records(
            public_records,
            bu_slug=bu_slug,
            public_root=output_dir,
        )

    base = Path(output_dir) / bu_slug
    articles = []
    if not base.is_dir():
        return articles
    for project_dir in base.iterdir():
        if not project_dir.is_dir():
            continue
        project = project_dir.name
        for art_dir in project_dir.iterdir():
            if not art_dir.is_dir():
                continue
            raw = art_dir / 'raw.md'
            if not raw.is_file():
                continue
            fm = parse_frontmatter_optional(str(raw))
            if not fm:
                continue
            if fm.get('bu') != bu_slug or fm.get('project') != project:
                continue
            articles.append({
                'bu': bu_slug,
                'project': project,
                'slug': fm.get('slug') or art_dir.name,
                'title': fm.get('title') or art_dir.name,
                'date': fm.get('date') or '',
                'gate': fm.get('gate'),
                'url': f'{bu_slug}/{project}/{art_dir.name}/',
            })
    return articles


def build_projects_list_html(articles, wiki_base, bu_slug):
    by_project = defaultdict(list)
    for a in articles:
        by_project[a['project']].append(a)
    if not by_project:
        return '<p class="wk-empty">Nenhum artigo publicado ainda.</p>'
    items = []
    for project in sorted(by_project.keys()):
        arts = by_project[project]
        count = len(arts)
        title = catalog_navigation.humanize_slug(project)
        items.append(
            f'<li><a href="{wiki_base}/{bu_slug}/{project}/">'
            f'<span class="wk-bu-project-title">{_esc(title)}</span>'
            f'<span class="wk-bu-project-count">{count}</span>'
            f'</a></li>'
        )
    return '<ul class="wk-bu-projects-list">\n' + '\n'.join(items) + '\n</ul>'


def build_recent_articles_html(articles, wiki_base, limit=RECENT_LIMIT):
    if not articles:
        return '<p class="wk-empty">Nenhum artigo publicado ainda.</p>'
    recents = sorted(articles, key=lambda x: x.get('date', ''), reverse=True)[:limit]
    items = []
    for a in recents:
        project_title = catalog_navigation.humanize_slug(a['project'])
        gate_icon = ' 🔒' if a.get('gate') else ''
        items.append(
            f'<li><a href="{wiki_base}/{a["url"]}">'
            f'<span class="date">{_esc(a.get("date", ""))}</span>'
            f'<span class="wk-bu-recent-title">{_esc(a["title"])}{gate_icon}</span>'
            f'<span class="wk-bu-recent-project">{_esc(project_title)}</span>'
            f'</a></li>'
        )
    return '<ul class="wk-bu-recent-list">\n' + '\n'.join(items) + '\n</ul>'


def render_bu(output_dir, theme, bu_slug, wiki_base):
    """Render <output_dir>/<bu_slug>/index.html from bu-home.html.tpl."""
    if bu_slug not in BU_DISPLAY:
        raise ValueError(
            f'unknown bu_slug {bu_slug!r}; expected one of {sorted(BU_DISPLAY)}'
        )

    tpl = (TEMPLATES_DIR / 'bu-home.html.tpl').read_text()
    head_tpl = (TEMPLATES_DIR / '_head.html.tpl').read_text()
    styles_tpl = (TEMPLATES_DIR / '_styles.css.tpl').read_text()
    topbar_tpl = (TEMPLATES_DIR / '_topbar.html.tpl').read_text()
    sidebar_tpl = (TEMPLATES_DIR / '_sidebar.html.tpl').read_text()
    appshell_tpl = (TEMPLATES_DIR / '_appshell.html.tpl').read_text()

    bu_title = BU_DISPLAY[bu_slug]
    bu_description = BU_DESCRIPTION.get(bu_slug, '')

    import theme_resolver
    styles = theme_resolver.resolve_styles(TEMPLATES_DIR, build_theme_vars(theme))
    head = (
        head_tpl
        .replace('{{TITLE}}', f'wikia · {bu_title}')
        .replace('{{REPO_NAME}}', 'wikia')
        .replace('{{DESCRIPTION}}', f'BU {bu_title} — wikia')
        .replace('{{STYLES_CSS}}', styles)
    )

    topbar = topbar_tpl.replace('{{WIKI_BASE}}', wiki_base)

    # Wave 2: populate sidebar with full BU tree + recents (current BU highlighted)
    # render-wiki.py has a dash → import via importlib
    import importlib.util as _ilu
    _spec = _ilu.spec_from_file_location("_render_wiki", SCRIPT_DIR / "render-wiki.py")
    _rw = _ilu.module_from_spec(_spec); _spec.loader.exec_module(_rw)  # type: ignore
    bu_tree = _rw.build_bu_tree(output_dir)
    tree_str = _rw.tree_html(bu_tree, current_bu=bu_slug, current_project=None, current_slug=None, wiki_base=wiki_base)
    all_artifacts = _rw.collect_artifacts(output_dir)
    recents_str = _rw.recents_html(all_artifacts, wiki_base, limit=6)

    sidebar = (
        sidebar_tpl
        .replace('{{TREE_HTML}}', tree_str)
        .replace('{{RECENTS_HTML}}', recents_str)
    )

    articles = collect_bu_articles(output_dir, bu_slug)
    projects_html = build_projects_list_html(articles, wiki_base, bu_slug)
    recent_html = build_recent_articles_html(articles, wiki_base)

    out = (
        tpl
        .replace('{{HEAD_HTML}}', head)
        .replace('{{TOPBAR_HTML}}', topbar)
        .replace('{{SIDEBAR_HTML}}', sidebar)
        .replace('{{APPSHELL_HTML}}', appshell_tpl)
        .replace('{{BU_TITLE}}', bu_title)
        .replace('{{BU_SLUG}}', bu_slug)
        .replace('{{BU_DESCRIPTION}}', _esc(bu_description))
        .replace('{{PROJECTS_LIST_HTML}}', projects_html)
        .replace('{{RECENT_ARTICLES_HTML}}', recent_html)
        .replace('{{WIKI_BASE}}', wiki_base)
        .replace('{{GATE_BLOCK}}', '')
    )

    target = Path(output_dir) / bu_slug / 'index.html'
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(out)
    return len(articles)


def _print_help():
    print(
        'Usage: render-bu.py <output-dir> <theme-json> <bu-slug> <wiki-base>\n'
        '\n'
        '  output-dir  Path to gitpages dir (parent of <bu-slug>/)\n'
        '  theme-json  Theme as JSON string (from theme-fetch.sh)\n'
        '  bu-slug     One of: staging, vita, allin, aleyemma, gobbi\n'
        '  wiki-base   Public URL base, e.g. https://felipeggv.github.io/wikia/gitpages\n'
    )


def main():
    if len(sys.argv) < 2 or sys.argv[1] in ('--help', '-h'):
        _print_help()
        sys.exit(0)
    if len(sys.argv) < 5:
        _print_help()
        sys.exit(2)
    output_dir, theme_json, bu_slug, wiki_base = sys.argv[1:5]
    theme = json.loads(theme_json)
    n = render_bu(output_dir, theme, bu_slug, wiki_base)
    print(f'→ bu {bu_slug}: {n} articles', file=sys.stderr)


if __name__ == '__main__':
    main()
