#!/usr/bin/env python3
"""
render-project.py — Wave 2: regenera a home de um projeto (centralzinha).

Caminha por `<output_dir>/<bu_slug>/<project_slug>/<slug>/raw.md`, ordena
por data desc, e substitui em `project-home.html.tpl` produzindo
`<bu>/<project>/index.html`.

Uso:
  render-project.py <output-dir> <theme-json> <bu-slug> <project-slug> <wiki-base>

Se o projeto não tem nenhum artigo válido, renderiza um stub "Nenhum
artigo publicado ainda." (mesma mensagem que BU home vazia).
"""

import os
import sys
import json
import html as html_lib
from pathlib import Path

SCRIPT_DIR = Path(__file__).parent
SKILL_DIR = SCRIPT_DIR.parent
TEMPLATES_DIR = SKILL_DIR / 'templates'

sys.path.insert(0, str(SCRIPT_DIR))
from frontmatter_parser import parse_frontmatter_optional  # noqa: E402
import public_catalog  # noqa: E402


BU_DISPLAY = {
    'staging': 'Staging',
    'vita': 'Vitascience',
    'allin': 'AllIn',
    'aleyemma': 'Aleyemma',
    'gobbi': 'Gobbi',
}


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


def collect_project_articles(output_dir, bu_slug, project_slug):
    """Walk <output_dir>/<bu_slug>/<project_slug>/<slug>/raw.md and collect metadata."""
    catalog_records = public_catalog.load_records_from_public_root(output_dir)
    if catalog_records:
        return [
            {
                'bu': bu_slug,
                'project': project_slug,
                'slug': record.get('slug') or '',
                'title': public_catalog.public_title(record),
                'date': '',
                'gate': str(record.get('gate_status') or 'unknown') != 'public',
                'url': public_catalog.normalize_output_url(record.get('output_url') or ''),
            }
            for record in catalog_records
            if record.get('bu') == bu_slug
            and record.get('project') == project_slug
            and public_catalog.is_public_record(record)
        ]

    base = Path(output_dir) / bu_slug / project_slug
    articles = []
    if not base.is_dir():
        return articles
    for art_dir in base.iterdir():
        if not art_dir.is_dir():
            continue
        raw = art_dir / 'raw.md'
        if not raw.is_file():
            continue
        fm = parse_frontmatter_optional(str(raw))
        if not fm:
            continue
        if fm.get('bu') != bu_slug or fm.get('project') != project_slug:
            continue
        articles.append({
            'bu': bu_slug,
            'project': project_slug,
            'slug': fm.get('slug') or art_dir.name,
            'title': fm.get('title') or art_dir.name,
            'date': fm.get('date') or '',
            'gate': fm.get('gate'),
            'url': f'{bu_slug}/{project_slug}/{art_dir.name}/',
        })
    return articles


def build_articles_list_html(articles, wiki_base):
    if not articles:
        return '<p class="wk-empty">Nenhum artigo publicado ainda.</p>'
    sorted_arts = sorted(articles, key=lambda x: x.get('date', ''), reverse=True)
    items = []
    for a in sorted_arts:
        gate_icon = ' 🔒' if a.get('gate') else ''
        items.append(
            f'<li><a href="{wiki_base}/{a["url"]}">'
            f'<span class="date">{_esc(a.get("date", ""))}</span>'
            f'<span class="wk-project-article-title">{_esc(a["title"])}{gate_icon}</span>'
            f'</a></li>'
        )
    return '<ul class="wk-project-articles-list">\n' + '\n'.join(items) + '\n</ul>'


def render_project(output_dir, theme, bu_slug, project_slug, wiki_base):
    """Render <output_dir>/<bu_slug>/<project_slug>/index.html from project-home.html.tpl."""
    if bu_slug not in BU_DISPLAY:
        raise ValueError(
            f'unknown bu_slug {bu_slug!r}; expected one of {sorted(BU_DISPLAY)}'
        )

    tpl = (TEMPLATES_DIR / 'project-home.html.tpl').read_text()
    head_tpl = (TEMPLATES_DIR / '_head.html.tpl').read_text()
    styles_tpl = (TEMPLATES_DIR / '_styles.css.tpl').read_text()
    topbar_tpl = (TEMPLATES_DIR / '_topbar.html.tpl').read_text()
    sidebar_tpl = (TEMPLATES_DIR / '_sidebar.html.tpl').read_text()
    appshell_tpl = (TEMPLATES_DIR / '_appshell.html.tpl').read_text()

    bu_title = BU_DISPLAY[bu_slug]
    project_title = project_slug.replace('-', ' ').title()
    project_description = f'Artigos do projeto {project_title} na BU {bu_title}.'

    styles = styles_tpl.replace('{{THEME_VARS}}', build_theme_vars(theme))
    head = (
        head_tpl
        .replace('{{TITLE}}', f'wikia · {bu_title} · {project_title}')
        .replace('{{REPO_NAME}}', 'wikia')
        .replace('{{DESCRIPTION}}', f'Projeto {project_title} — {bu_title} — wikia')
        .replace('{{STYLES_CSS}}', styles)
    )

    topbar = topbar_tpl.replace('{{WIKI_BASE}}', wiki_base)

    # Wave 2: populate sidebar with full BU tree + recents (current BU+project highlighted)
    import importlib.util as _ilu
    _spec = _ilu.spec_from_file_location("_render_wiki", SCRIPT_DIR / "render-wiki.py")
    _rw = _ilu.module_from_spec(_spec); _spec.loader.exec_module(_rw)  # type: ignore
    bu_tree = _rw.build_bu_tree(output_dir)
    tree_str = _rw.tree_html(bu_tree, current_bu=bu_slug, current_project=project_slug, current_slug=None, wiki_base=wiki_base)
    all_artifacts = _rw.collect_artifacts(output_dir)
    recents_str = _rw.recents_html(all_artifacts, wiki_base, limit=6)

    sidebar = (
        sidebar_tpl
        .replace('{{TREE_HTML}}', tree_str)
        .replace('{{RECENTS_HTML}}', recents_str)
    )

    articles = collect_project_articles(output_dir, bu_slug, project_slug)
    articles_html = build_articles_list_html(articles, wiki_base)

    out = (
        tpl
        .replace('{{HEAD_HTML}}', head)
        .replace('{{TOPBAR_HTML}}', topbar)
        .replace('{{SIDEBAR_HTML}}', sidebar)
        .replace('{{APPSHELL_HTML}}', appshell_tpl)
        .replace('{{BU_TITLE}}', bu_title)
        .replace('{{BU_SLUG}}', bu_slug)
        .replace('{{PROJECT_TITLE}}', _esc(project_title))
        .replace('{{PROJECT_SLUG}}', project_slug)
        .replace('{{PROJECT_DESCRIPTION}}', _esc(project_description))
        .replace('{{ARTICLES_LIST_HTML}}', articles_html)
        .replace('{{WIKI_BASE}}', wiki_base)
        .replace('{{GATE_BLOCK}}', '')
    )

    target = Path(output_dir) / bu_slug / project_slug / 'index.html'
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(out)
    return len(articles)


def _print_help():
    print(
        'Usage: render-project.py <output-dir> <theme-json> <bu-slug> <project-slug> <wiki-base>\n'
        '\n'
        '  output-dir    Path to gitpages dir (parent of <bu-slug>/)\n'
        '  theme-json    Theme as JSON string (from theme-fetch.sh)\n'
        '  bu-slug       One of: staging, vita, allin, aleyemma, gobbi\n'
        '  project-slug  Project slug (kebab-case); use "geral" as canonical catch-all\n'
        '  wiki-base     Public URL base, e.g. https://felipeggv.github.io/wikia/gitpages\n'
    )


def main():
    if len(sys.argv) < 2 or sys.argv[1] in ('--help', '-h'):
        _print_help()
        sys.exit(0)
    if len(sys.argv) < 6:
        _print_help()
        sys.exit(2)
    output_dir, theme_json, bu_slug, project_slug, wiki_base = sys.argv[1:6]
    theme = json.loads(theme_json)
    n = render_project(output_dir, theme, bu_slug, project_slug, wiki_base)
    print(f'→ project {bu_slug}/{project_slug}: {n} articles', file=sys.stderr)


if __name__ == '__main__':
    main()
