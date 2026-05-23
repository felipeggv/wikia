#!/usr/bin/env python3
"""Render the static admin shell.

Usage:
  render-admin.py <output-dir> <theme-json> <wiki-base> [--cms-state <path>]

Side-effects:
  - <output-dir>/admin/index.html (safe locked shell + appshell + topbar)
  - <output-dir>/_released.json (bootstrap [] se ausente)
  - <output-dir>/_pending-changes.json (bootstrap {} se ausente)
"""
import argparse
import json
import re
import sqlite3
import sys
from pathlib import Path

SCRIPT_DIR = Path(__file__).parent
SKILL_DIR = SCRIPT_DIR.parent
TEMPLATES_DIR = SKILL_DIR / 'templates'

REPO_NAME = 'wikia'
TITLE = 'wikia · admin'
DESCRIPTION = 'Painel admin do wikia — masterpass-gated.'
SIDEBAR_NAV_MARKER = '<nav class="wk-sidebar-nav">'
TREE_UL_MARKER = '<ul class="wk-tree">'
LEGACY_TEMA_MARKER = 'wk-tree-tema'
CMS_STATE_CANDIDATES = (
    '_admin.db',
    '_admin.sqlite3',
    '_cms-state.sqlite3',
    'admin-state.sqlite3',
    '_catalog.json',
    'catalog.json',
)
BU_DISPLAY = {
    'staging': 'Staging',
    'vita': 'Vitascience',
    'allin': 'AllIn',
    'aleyemma': 'Aleyemma',
    'gobbi': 'Gobbi',
}

CHEV_SVG = '<svg class="chev" viewBox="0 0 12 12" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="4 2 8 6 4 10"/></svg>'
FOLDER_SVG = '<svg class="folder-icon" viewBox="0 0 14 14" fill="currentColor"><path d="M1 3 a1 1 0 0 1 1-1 h3 l1.5 1.5 h5.5 a1 1 0 0 1 1 1 v6 a1 1 0 0 1 -1 1 h-10 a1 1 0 0 1 -1 -1 z" opacity="0.85"/></svg>'
FILE_SVG = '<svg class="file-icon" viewBox="0 0 12 12" fill="none" stroke="currentColor" stroke-width="1" stroke-linejoin="round"><path d="M3 1.5 h4 l2.5 2.5 v6.5 a0.5 0.5 0 0 1 -0.5 0.5 h-6 a0.5 0.5 0 0 1 -0.5 -0.5 v-8.5 a0.5 0.5 0 0 1 0.5 -0.5 z"/><polyline points="7 1.5 7 4 9.5 4" fill="currentColor" opacity="0.4"/></svg>'


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


def join_url(base, path):
    return f'{str(base).rstrip("/")}/{str(path).lstrip("/")}'


def normalize_output_url(row):
    output_url = str(row.get('output_url') or '').strip()
    if output_url:
        return output_url
    return f'{row["bu"]}/{row["project"]}/{row["slug"]}/'


def visible_article_title(row):
    if row.get('title_visible') and row.get('title_public'):
        return str(row['title_public'])
    return str(row['slug']).replace('-', ' ')


def title_for_bu(bu):
    return BU_DISPLAY.get(bu, str(bu).replace('-', ' ').title())


def resolve_cms_state_path(output_dir, explicit_path=None):
    if explicit_path:
        path = Path(explicit_path).expanduser().resolve()
        if not path.exists():
            raise FileNotFoundError(f'CMS state not found: {path}')
        return path

    output_root = Path(output_dir)
    for name in CMS_STATE_CANDIDATES:
        candidate = output_root / name
        if candidate.exists():
            return candidate
    return None


def sqlite_columns(conn, table_name):
    return [row[1] for row in conn.execute(f'PRAGMA table_info({table_name})')]


def load_sqlite_articles(db_path):
    with sqlite3.connect(str(db_path)) as conn:
        conn.row_factory = sqlite3.Row
        columns = set(sqlite_columns(conn, 'articles'))
        required = {
            'article_id',
            'bu',
            'project',
            'slug',
            'title_visible',
            'raw_source_path',
            'output_url',
            'gate_status',
            'release_status',
            'scope',
            'tags_json',
            'raw_hash',
        }
        missing = sorted(required - columns)
        if missing:
            raise ValueError(f'CMS state missing articles columns: {", ".join(missing)}')

        optional_cols = [
            'title_public' if 'title_public' in columns else 'NULL AS title_public',
            'updated_at' if 'updated_at' in columns else "'' AS updated_at",
            'created_at' if 'created_at' in columns else "'' AS created_at",
        ]
        select_cols = ', '.join([
            'article_id',
            'bu',
            'project',
            'slug',
            'title_visible',
            *optional_cols,
            'raw_source_path',
            'output_url',
            'gate_status',
            'release_status',
            'scope',
            'tags_json',
            'raw_hash',
        ])
        rows = conn.execute(
            f'''
            SELECT {select_cols}
            FROM articles
            ORDER BY bu, project, slug
            '''
        ).fetchall()
    return [dict(row) for row in rows]


def load_catalog_articles(catalog_path):
    payload = json.loads(Path(catalog_path).read_text(encoding='utf-8'))
    records = payload.get('records')
    if not isinstance(records, list):
        raise ValueError(f'CMS catalog has no records array: {catalog_path}')
    articles = []
    for item in records:
        if not isinstance(item, dict):
            continue
        articles.append({
            'article_id': item.get('article_id', ''),
            'bu': item.get('bu', ''),
            'project': item.get('project', ''),
            'slug': item.get('slug', ''),
            'title_visible': bool(item.get('title_visible')),
            'title_public': item.get('title_public'),
            'updated_at': '',
            'created_at': '',
            'raw_source_path': '',
            'output_url': item.get('output_url', ''),
            'gate_status': item.get('gate_status', 'unknown'),
            'release_status': item.get('release_status', 'unreleased'),
            'scope': item.get('scope', 'article'),
            'tags_json': json.dumps(item.get('tags', []), ensure_ascii=False, separators=(',', ':')),
            'raw_hash': item.get('raw_hash', ''),
        })
    return articles


def load_cms_articles(cms_state_path):
    if cms_state_path is None:
        return []
    if cms_state_path.suffix.lower() == '.json':
        return load_catalog_articles(cms_state_path)
    return load_sqlite_articles(cms_state_path)


def build_cms_tree(articles):
    tree = {
        bu: {'title': title, 'projects': {}, 'article_count': 0}
        for bu, title in BU_DISPLAY.items()
    }
    for row in sorted(articles, key=lambda r: (r['bu'], r['project'], r['slug'])):
        bu = row['bu']
        project = row['project']
        if not bu or not project or not row.get('slug'):
            continue
        if bu not in tree:
            tree[bu] = {'title': title_for_bu(bu), 'projects': {}, 'article_count': 0}
        project_node = tree[bu]['projects'].setdefault(project, {'articles': []})
        article = dict(row)
        article['title'] = visible_article_title(row)
        article['url'] = normalize_output_url(row)
        article['gate'] = str(row.get('gate_status') or 'unknown') != 'public'
        article['sort_key'] = row.get('updated_at') or row.get('created_at') or ''
        project_node['articles'].append(article)
        tree[bu]['article_count'] += 1

    for bu_node in tree.values():
        for project_node in bu_node['projects'].values():
            project_node['articles'].sort(
                key=lambda a: (a.get('sort_key') or '', a['slug']),
                reverse=True,
            )
    return tree


def tree_html(tree, wiki_base):
    import html as html_lib
    def esc(s): return html_lib.escape(str(s), quote=False)
    def attr(s): return html_lib.escape(str(s), quote=True)
    gate_icon = '<span class="wk-gate-icon" title="locked">🔒</span>'

    out = []
    for bu, node in tree.items():
        if node['article_count'] == 0:
            out.append(
                f'<li class="wk-tree-bu wk-tree-bu-empty" data-bu="{attr(bu)}">'
                f'<a class="wk-tree-bu-link" href="{attr(join_url(wiki_base, bu + "/"))}">'
                f'{FOLDER_SVG}<span class="label-text">{esc(node["title"])}</span>'
                f'<span class="count">0</span></a></li>'
            )
            continue

        project_items = []
        for project in sorted(node['projects'].keys()):
            project_node = node['projects'][project]
            article_items = []
            for article in project_node['articles']:
                gate = gate_icon if article.get('gate') else ''
                article_items.append(
                    f'<li class="wk-tree-article" data-slug="{attr(article["slug"])}">'
                    f'<a href="{attr(join_url(wiki_base, article["url"]))}">{FILE_SVG}'
                    f'<span>{esc(article["title"])}</span>{gate}</a></li>'
                )
            project_items.append(
                f'<li class="wk-tree-project" data-project="{attr(project)}" data-expanded="false">'
                f'<a class="wk-tree-project-link" href="{attr(join_url(wiki_base, f"{bu}/{project}/"))}">'
                f'{CHEV_SVG}{FOLDER_SVG}<span class="label-text">{esc(project)}</span>'
                f'<span class="count">{len(project_node["articles"])}</span></a>'
                f'<ul class="wk-tree-articles">{"".join(article_items)}</ul></li>'
            )

        out.append(
            f'<li class="wk-tree-bu" data-bu="{attr(bu)}" data-expanded="false">'
            f'<a class="wk-tree-bu-link" href="{attr(join_url(wiki_base, bu + "/"))}">'
            f'{CHEV_SVG}{FOLDER_SVG}<span class="label-text">{esc(node["title"])}</span>'
            f'<span class="count">{node["article_count"]}</span></a>'
            f'<ul class="wk-tree-projects">{"".join(project_items)}</ul></li>'
        )
    return '\n'.join(out)


def recents_html(artifacts, wiki_base, limit=6):
    import html as html_lib
    def esc(s): return html_lib.escape(str(s), quote=False)
    def attr(s): return html_lib.escape(str(s), quote=True)

    recents = sorted(
        artifacts,
        key=lambda x: (x.get('updated_at') or x.get('created_at') or '', x['slug']),
        reverse=True,
    )[:limit]
    out = []
    for r in recents:
        date_text = (r.get('updated_at') or r.get('created_at') or '')[:10].replace('-', ' ').upper()
        title = visible_article_title(r)
        out.append(
            f'<li><a href="{attr(join_url(wiki_base, normalize_output_url(r)))}">'
            f'<span class="date">{esc(date_text)}</span>{esc(title)}</a></li>'
        )
    return '\n'.join(out)


def admin_locked_tree_html():
    return (
        '<li class="wk-tree-admin-shell" data-admin-shell="locked">'
        '<div class="wk-tree-admin-shell-label">'
        f'{FOLDER_SVG}<span class="label-text">Admin bloqueado</span>'
        '</div>'
        '<p class="wk-tree-admin-shell-note">'
        'Desbloqueie com masterpass para carregar artigos e acoes.'
        '</p>'
        '</li>'
    )


def admin_locked_recents_html():
    return (
        '<li class="wk-recents-admin-shell">'
        'Nenhum catalogo e carregado antes do unlock.'
        '</li>'
    )


def read_tpl(name):
    return (TEMPLATES_DIR / name).read_text()


def strip_legacy_tema_output(text):
    text = re.sub(
        r'\n\.wk-tree-tema\b.*?(?=\n/\* ============================================================\n   WAVE 2 SIDEBAR TREE)',
        '\n',
        text,
        flags=re.S,
    )
    text = re.sub(
        r'\n\s*document\.querySelectorAll\(\'.wk-tree-tema\'\).*?\n\s*\}\);\n',
        '\n',
        text,
        flags=re.S,
    )
    text = text.replace(' just like .wk-tree-tema', '')
    text = text.replace(LEGACY_TEMA_MARKER, 'legacy-tema-tree')
    return text


def validate_sidebar_wrapper(html):
    counts = {
        'wk-sidebar-nav': html.count(SIDEBAR_NAV_MARKER),
        'wk-tree': html.count(TREE_UL_MARKER),
        LEGACY_TEMA_MARKER: html.count(LEGACY_TEMA_MARKER),
    }
    expected = {'wk-sidebar-nav': 1, 'wk-tree': 1, LEGACY_TEMA_MARKER: 0}
    mismatches = [
        f'{name}={actual}'
        for name, actual in counts.items()
        if actual != expected[name]
    ]
    if mismatches:
        raise ValueError(
            'admin sidebar wrapper count mismatch: '
            + ', '.join(mismatches)
            + '; expected wk-sidebar-nav=1, wk-tree=1'
        )
    return counts


def validate_admin_safe_sidebar(sidebar_html):
    forbidden = [
        'wk-tree-bu',
        'wk-tree-project',
        'wk-tree-article',
        '<span class="count">',
    ]
    leaks = [marker for marker in forbidden if marker in sidebar_html]
    if leaks:
        raise ValueError(
            'admin locked sidebar leaks catalog markers before unlock: '
            + ', '.join(leaks)
        )
    return True


def render_admin(output_dir, theme, wiki_base, cms_state_path=None):
    out_root = Path(output_dir)
    out_root.mkdir(parents=True, exist_ok=True)

    admin_tpl = read_tpl('admin.html.tpl')
    head_tpl = read_tpl('_head.html.tpl')
    styles_tpl = read_tpl('_styles.css.tpl')
    admin_styles_tpl = read_tpl('_admin-styles.css.tpl')
    topbar_tpl = read_tpl('_topbar.html.tpl')
    sidebar_tpl = read_tpl('_sidebar.html.tpl')
    appshell_tpl = read_tpl('_appshell.html.tpl')
    admin_decrypt_js = read_tpl('admin-decrypt.js')

    # Theme + main styles + admin styles
    main_styles = strip_legacy_tema_output(styles_tpl).replace('{{THEME_VARS}}', build_theme_vars(theme))
    admin_styles_css = main_styles + '\n\n/* === admin overrides === */\n' + admin_styles_tpl

    # Head — STYLES_CSS empty (we use ADMIN_STYLES_CSS); keep title/desc
    head = (head_tpl
        .replace('{{TITLE}}', TITLE)
        .replace('{{REPO_NAME}}', REPO_NAME)
        .replace('{{DESCRIPTION}}', DESCRIPTION)
        .replace('{{STYLES_CSS}}', ''))

    cms_state = resolve_cms_state_path(out_root, cms_state_path)
    if cms_state is not None:
        # Validate that the state is readable, but never emit article metadata
        # into the locked admin paint. The client loads _admin.enc after unlock.
        load_cms_articles(cms_state)

    th = admin_locked_tree_html()
    rh = admin_locked_recents_html()

    topbar = topbar_tpl.replace('{{WIKI_BASE}}', wiki_base)
    sidebar = sidebar_tpl.replace('{{TREE_HTML}}', th).replace('{{RECENTS_HTML}}', rh)
    validate_admin_safe_sidebar(sidebar)
    appshell = strip_legacy_tema_output(appshell_tpl)

    html = (admin_tpl
        .replace('{{HEAD_HTML}}', head)
        .replace('{{TOPBAR_HTML}}', topbar)
        .replace('{{SIDEBAR_HTML}}', sidebar)
        .replace('{{APPSHELL_HTML}}', appshell)
        .replace('{{ADMIN_STYLES_CSS}}', admin_styles_css)
        .replace('{{ADMIN_DECRYPT_JS}}', admin_decrypt_js)
        .replace('{{WIKI_BASE}}', wiki_base)
        .replace('{{TITLE}}', TITLE))
    validate_sidebar_wrapper(html)

    admin_dir = out_root / 'admin'
    admin_dir.mkdir(parents=True, exist_ok=True)
    (admin_dir / 'index.html').write_text(html)

    # Bootstrap ledgers if absent
    released_path = out_root / '_released.json'
    if not released_path.exists():
        released_path.write_text('[]\n')

    pending_path = out_root / '_pending-changes.json'
    if not pending_path.exists():
        pending_path.write_text('{}\n')

    return admin_dir / 'index.html'


def build_parser():
    parser = argparse.ArgumentParser(
        description='Render the static wikia admin shell from sanitized CMS state.'
    )
    parser.add_argument('output_dir')
    parser.add_argument('theme_json')
    parser.add_argument('wiki_base')
    parser.add_argument(
        '--cms-state',
        help='Optional sanitized CMS SQLite/catalog path. Defaults to known state files in output-dir.',
    )
    return parser


def main(argv=None):
    parser = build_parser()
    args = parser.parse_args(argv)
    theme = json.loads(args.theme_json)
    out_path = render_admin(args.output_dir, theme, args.wiki_base, args.cms_state)
    print(f'→ admin: {out_path}', file=sys.stderr)


if __name__ == '__main__':
    main()
