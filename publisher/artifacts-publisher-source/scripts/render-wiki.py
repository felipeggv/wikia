#!/usr/bin/env python3
"""
render-wiki.py — regenera wiki home (feed) + tema homes
Uso: render-wiki.py <workdir-docs-gitpages> <theme-json> <repo-name> <wiki-base>
Side-effect: workdir/index.html + workdir/research/*/index.html
"""
import sys, json, re
from pathlib import Path
from datetime import datetime
from collections import defaultdict

SCRIPT_DIR = Path(__file__).parent
SKILL_DIR = SCRIPT_DIR.parent

sys.path.insert(0, str(SCRIPT_DIR))
from frontmatter_parser import parse_frontmatter_optional
import public_catalog
import catalog_navigation


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


BU_ENUM_FOR_COLLECT = tuple(catalog_navigation.BU_DISPLAY.keys())


def _extract_artifact(html, md, slug, tema_label, url):
    """Extract artifact metadata from rendered HTML (title clean) + raw.md (tags)."""
    txt = html.read_text(errors='ignore')
    mt = re.search(r'<title>([^<]+)</title>', txt)
    title = mt.group(1).split(' · ')[0].strip() if mt else slug
    md_desc = re.search(r'<meta name="description" content="([^"]+)"', txt)
    desc = md_desc.group(1) if md_desc else ''
    tags = []
    if md.exists():
        md_text = md.read_text(errors='ignore')
        m_tags = re.search(r'^tags:\s*\[?([^\n\]]+)\]?', md_text, re.MULTILINE)
        if m_tags:
            tags = [t.strip().strip('"\'') for t in m_tags.group(1).split(',') if t.strip()]
    mtime = datetime.fromtimestamp(html.stat().st_mtime)
    return {
        'slug': slug,
        'tema': tema_label,
        'title': title,
        'description': desc,
        'tags': tags,
        'date': mtime.strftime('%Y-%m-%d'),
        'date_human': mtime.strftime('%d %b'),
        'url': url,
        'mtime': mtime.timestamp(),
    }


def collect_artifacts(workdir):
    workdir = Path(workdir)
    catalog_records = public_catalog.load_records_from_public_root(workdir)
    if catalog_records:
        public_records = [
            record for record in catalog_records
            if public_catalog.is_public_record(record)
        ]
        return catalog_navigation.artifacts_from_records(public_records, workdir)

    artifacts = []

    # Wave 2 layout: <bu>/<project>/<slug>/
    for bu in BU_ENUM_FOR_COLLECT:
        bu_dir = workdir / bu
        if not bu_dir.is_dir():
            continue
        for proj_dir in bu_dir.iterdir():
            if not proj_dir.is_dir():
                continue
            for art_dir in proj_dir.iterdir():
                if not art_dir.is_dir():
                    continue
                html = art_dir / 'index.html'
                md = art_dir / 'raw.md'
                if not html.exists():
                    continue
                artifacts.append(_extract_artifact(
                    html, md, art_dir.name,
                    tema_label=f'{bu}/{proj_dir.name}',
                    url=f'{bu}/{proj_dir.name}/{art_dir.name}/',
                ))

    # Wave 1 legacy layout: research/<tema>/artifacts/<slug>/
    research = workdir / 'research'
    if research.exists():
        for tema_dir in research.iterdir():
            if not tema_dir.is_dir():
                continue
            arts_dir = tema_dir / 'artifacts'
            if not arts_dir.exists():
                continue
            for art_dir in arts_dir.iterdir():
                if not art_dir.is_dir():
                    continue
                html = art_dir / 'index.html'
                md = art_dir / 'raw.md'
                if not html.exists():
                    continue
                artifacts.append(_extract_artifact(
                    html, md, art_dir.name,
                    tema_label=tema_dir.name,
                    url=f'research/{tema_dir.name}/artifacts/{art_dir.name}/',
                ))

    return artifacts


def _extract_catalog_artifact(record, workdir):
    output_url = public_catalog.normalize_output_url(record.get('output_url') or '')
    html = Path(workdir) / output_url.strip('/') / 'index.html'
    if html.exists():
        mtime = datetime.fromtimestamp(html.stat().st_mtime)
        timestamp = mtime.timestamp()
        date = mtime.strftime('%Y-%m-%d')
        date_human = mtime.strftime('%d %b')
    else:
        timestamp = 0
        date = ''
        date_human = ''
    return {
        'slug': record.get('slug') or '',
        'tema': f"{record.get('bu')}/{record.get('project')}",
        'title': public_catalog.public_title(record),
        'description': '',
        'tags': record.get('tags') or [],
        'date': date,
        'date_human': date_human,
        'url': output_url,
        'mtime': timestamp,
    }


def build_tree(artifacts):
    by_tema = defaultdict(list)
    for a in artifacts: by_tema[a['tema']].append(a)
    tree = []
    for tema in sorted(by_tema.keys(), reverse=True):
        arts = sorted(by_tema[tema], key=lambda x: x['mtime'], reverse=True)
        tree.append({
            'tema': tema,
            'title': tema.replace('-', ' ').title(),
            'artifacts': [{'slug': a['slug'], 'title': a['title']} for a in arts]
        })
    return tree


BU_DISPLAY = catalog_navigation.BU_DISPLAY


def build_bu_tree_from_records(records, public_root=None):
    return catalog_navigation.build_bu_tree(records, public_root=public_root)


def build_bu_tree(gitpages_dir, public_only=True, current_record=None):
    """Walks gitpages_dir/<bu>/<project>/<slug>/raw.md.
    Returns {bu: {title, projects: {project: {auto_flatten, articles: [...]}}, article_count}}.
    """
    import os
    all_catalog_records = catalog_navigation.load_catalog_records(gitpages_dir)
    if all_catalog_records:
        catalog_records = catalog_navigation.records_for_surface(
            gitpages_dir,
            public_only=public_only,
            current_record=current_record,
        )
        return build_bu_tree_from_records(catalog_records, public_root=gitpages_dir)

    tree = {bu: {"title": disp, "projects": {}, "article_count": 0}
            for bu, disp in BU_DISPLAY.items()}
    for bu in BU_DISPLAY:
        bu_dir = os.path.join(gitpages_dir, bu)
        if not os.path.isdir(bu_dir):
            continue
        for project in sorted(os.listdir(bu_dir)):
            proj_dir = os.path.join(bu_dir, project)
            if not os.path.isdir(proj_dir):
                continue
            articles = []
            for slug in sorted(os.listdir(proj_dir)):
                raw = os.path.join(proj_dir, slug, "raw.md")
                fm = parse_frontmatter_optional(raw)
                if not fm:
                    continue
                articles.append({
                    "slug": fm["slug"],
                    "title": fm.get("title", slug),
                    "date": fm.get("date", ""),
                    "gate": fm.get("gate") is not None,
                    "url": f"{bu}/{project}/{fm['slug']}/",
                })
            articles.sort(key=lambda a: a["date"], reverse=True)
            if articles:
                tree[bu]["projects"][project] = {
                    "auto_flatten": len(articles) == 1,
                    "articles": articles,
                }
                tree[bu]["article_count"] += len(articles)
    return tree


CHEV_SVG = '<svg class="chev" viewBox="0 0 12 12" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="4 2 8 6 4 10"/></svg>'
FOLDER_SVG = '<svg class="folder-icon" viewBox="0 0 14 14" fill="currentColor"><path d="M1 3 a1 1 0 0 1 1-1 h3 l1.5 1.5 h5.5 a1 1 0 0 1 1 1 v6 a1 1 0 0 1 -1 1 h-10 a1 1 0 0 1 -1 -1 z" opacity="0.85"/></svg>'
FILE_SVG = '<svg class="file-icon" viewBox="0 0 12 12" fill="none" stroke="currentColor" stroke-width="1" stroke-linejoin="round"><path d="M3 1.5 h4 l2.5 2.5 v6.5 a0.5 0.5 0 0 1 -0.5 0.5 h-6 a0.5 0.5 0 0 1 -0.5 -0.5 v-8.5 a0.5 0.5 0 0 1 0.5 -0.5 z"/><polyline points="7 1.5 7 4 9.5 4" fill="currentColor" opacity="0.4"/></svg>'


def tree_html(bu_tree, current_bu=None, current_project=None, current_slug=None, wiki_base="", scope_bu=None):
    """Render BU/project/article sidebar from build_bu_tree output.

    auto_flatten=True projects skip the project-folder layer in the UI
    (articles render directly under the BU). URL/folder stays canonical (D3).

    scope_bu (optional): when set, only render the named BU's subtree.
    Used by artifact pages to prevent cross-BU metadata leakage in the sidebar.
    """
    import html as html_lib
    def esc(s): return html_lib.escape(str(s), quote=False)
    def attr(s): return html_lib.escape(str(s), quote=True)
    GATE_ICON = '<span class="wk-gate-icon" title="locked">🔒</span>'

    def article_li(article, is_current):
        cur = ' wk-current-article' if is_current else ''
        gate = GATE_ICON if article['gate'] else ''
        return (
            f'<li class="wk-tree-article{cur}" data-slug="{attr(article["slug"])}">'
            f'<a href="{attr(catalog_navigation.join_url(wiki_base, article["url"]))}">{FILE_SVG}'
            f'<span>{esc(article["title"])}</span>{gate}</a></li>'
        )

    out = []
    for bu, node in bu_tree.items():
        if scope_bu is not None and bu != scope_bu:
            continue
        if node['article_count'] == 0:
            # Empty BU: render header only (scaffolding stub for vita/allin/aleyemma)
            bu_cur = ' wk-current-bu' if bu == current_bu else ''
            out.append(
                f'<li class="wk-tree-bu wk-tree-bu-empty{bu_cur}" data-bu="{attr(bu)}">'
                f'<a class="wk-tree-bu-link" href="{attr(catalog_navigation.join_url(wiki_base, bu + "/"))}">'
                f'{FOLDER_SVG}<span class="label-text">{esc(node["title"])}</span>'
                f'<span class="count">0</span></a></li>'
            )
            continue

        bu_cur = ' wk-current-bu' if bu == current_bu else ''
        bu_expanded = 'true' if bu == current_bu else 'false'
        children = []
        for project, proj_node in node['projects'].items():
            if proj_node['auto_flatten']:
                # D3: single-article project — render article directly, skip project layer
                article = proj_node['articles'][0]
                is_current = (
                    bu == current_bu
                    and project == current_project
                    and article['slug'] == current_slug
                )
                children.append(article_li(article, is_current))
            else:
                proj_cur = ' wk-current-project' if (bu == current_bu and project == current_project) else ''
                proj_expanded = 'true' if (bu == current_bu and project == current_project) else 'false'
                article_items = ''.join(
                    article_li(a, bu == current_bu and project == current_project and a['slug'] == current_slug)
                    for a in proj_node['articles']
                )
                children.append(
                    f'<li class="wk-tree-project{proj_cur}" data-project="{attr(project)}" data-expanded="{proj_expanded}">'
                    f'<a class="wk-tree-project-link" href="{attr(catalog_navigation.join_url(wiki_base, f"{bu}/{project}/"))}">'
                    f'{CHEV_SVG}{FOLDER_SVG}<span class="label-text">{esc(catalog_navigation.humanize_slug(project))}</span>'
                    f'<span class="count">{len(proj_node["articles"])}</span></a>'
                    f'<ul class="wk-tree-articles">{article_items}</ul></li>'
                )

        out.append(
            f'<li class="wk-tree-bu{bu_cur}" data-bu="{attr(bu)}" data-expanded="{bu_expanded}">'
            f'<a class="wk-tree-bu-link" href="{attr(catalog_navigation.join_url(wiki_base, bu + "/"))}">'
            f'{CHEV_SVG}{FOLDER_SVG}<span class="label-text">{esc(node["title"])}</span>'
            f'<span class="count">{node["article_count"]}</span></a>'
            f'<ul class="wk-tree-projects">{"".join(children)}</ul></li>'
        )
    return '\n'.join(out)


def recents_html(artifacts, wiki_base, limit=4):
    """Emit RECENTES grouped by date_human.

    Output: <li class="wk-recents-day"><span class="wk-recents-date">DATE</span>
              <ul class="wk-recents-items"><li><a>...</a></li>...</ul></li>
    """
    recents = sorted(artifacts, key=lambda x: x['mtime'], reverse=True)[:limit]
    if not recents:
        return ''
    groups = []
    current_date = None
    current_items = []
    for r in recents:
        d = r['date_human'].upper()
        if d != current_date:
            if current_items:
                groups.append((current_date, current_items))
            current_date, current_items = d, []
        current_items.append(r)
    if current_items:
        groups.append((current_date, current_items))

    out = []
    for date, items in groups:
        out.append('<li class="wk-recents-day">')
        out.append(f'<span class="wk-recents-date">{date}</span>')
        out.append('<ul class="wk-recents-items">')
        for r in items:
            out.append(f'<li><a href="{catalog_navigation.join_url(wiki_base, r["url"])}">{r["title"]}</a></li>')
        out.append('</ul>')
        out.append('</li>')
    return '\n'.join(out)


def render_wiki_home(workdir, theme, repo_name, wiki_base, artifacts):
    tpl = (SKILL_DIR / 'templates' / 'wiki-home.html.tpl').read_text()
    head_tpl = (SKILL_DIR / 'templates' / '_head.html.tpl').read_text()
    styles_tpl = (SKILL_DIR / 'templates' / '_styles.css.tpl').read_text()
    topbar_tpl = (SKILL_DIR / 'templates' / '_topbar.html.tpl').read_text()
    sidebar_tpl = (SKILL_DIR / 'templates' / '_sidebar.html.tpl').read_text()
    appshell_tpl = (SKILL_DIR / 'templates' / '_appshell.html.tpl').read_text()

    import theme_resolver
    styles = theme_resolver.resolve_styles(SKILL_DIR / 'templates', build_theme_vars(theme))
    head = (head_tpl
        .replace('{{TITLE}}', 'wikia')
        .replace('{{REPO_NAME}}', repo_name)
        .replace('{{DESCRIPTION}}', 'Wiki interno do Felipe Gobbi')
        .replace('{{STYLES_CSS}}', styles))

    # Wave 2: tree_html now consumes build_bu_tree output (BU/project/article hierarchy)
    bu_tree = build_bu_tree(workdir)
    th = tree_html(bu_tree, current_bu=None, current_project=None, current_slug=None, wiki_base=wiki_base)
    rh = recents_html(artifacts, wiki_base)

    topbar = topbar_tpl.replace('{{WIKI_BASE}}', wiki_base)
    sidebar = sidebar_tpl.replace('{{TREE_HTML}}', th).replace('{{RECENTS_HTML}}', rh)
    appshell = appshell_tpl

    # Feed cronológico
    feed = sorted(artifacts, key=lambda x: x['mtime'], reverse=True)
    feed_html = ''
    for a in feed:
        tema_title = a['tema'].replace('-', ' ').title()
        snippet = (a['description'] or 'Sem descrição.')[:240]
        feed_html += f'''<li>
          <div class="feed-meta">{a['date_human'].upper()}<span class="accent">{tema_title}</span></div>
          <a href="{a['url']}" class="feed-title">{a['title']}</a>
          <p class="feed-snippet">{snippet}</p>
          <a href="{a['url']}" class="feed-link">ler →</a>
        </li>'''

    if not feed_html:
        feed_html = '<li><p class="feed-snippet">Nenhum artigo publicado ainda.</p></li>'

    out = (tpl
        .replace('{{HEAD_HTML}}', head)
        .replace('{{TOPBAR_HTML}}', topbar)
        .replace('{{SIDEBAR_HTML}}', sidebar)
        .replace('{{APPSHELL_HTML}}', appshell)
        .replace('{{FEED_HTML}}', feed_html)
        .replace('{{WIKI_BASE}}', wiki_base)
        .replace('{{GATE_BLOCK}}', ''))

    # Wiki home não tem gate por padrão (público — só lista os títulos)
    # Para gatear o feed também, mexer no publish.sh

    (Path(workdir) / 'index.html').write_text(out)
    return len(artifacts)


def main():
    workdir, theme_json, repo_name, wiki_base = sys.argv[1:5]
    theme = json.loads(theme_json)
    artifacts = collect_artifacts(workdir)
    n = render_wiki_home(workdir, theme, repo_name, wiki_base, artifacts)
    print(f'→ wiki home: {n} artifacts', file=sys.stderr)


if __name__ == '__main__':
    main()
