#!/usr/bin/env python3
"""
render-artifact.py — renderiza artefato no layout wikia (topbar + sidebar + content)
Uso: render-artifact.py <md> <theme-json> <title> <slug> <tema> <repo-name> <date> <tags-csv> <models-csv> <tree-json> <recents-json> <wiki-base>
"""
import sys, json, re, importlib.util, os
import html as html_lib
from pathlib import Path
from datetime import datetime

SCRIPT_DIR = Path(__file__).parent
spec = importlib.util.spec_from_file_location("md_to_html", SCRIPT_DIR / "md-to-html.py")
md_mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(md_mod)

sys.path.insert(0, str(SCRIPT_DIR))
from frontmatter_parser import parse_frontmatter_optional
import public_catalog
import catalog_navigation

_wiki_spec = importlib.util.spec_from_file_location("render_wiki", SCRIPT_DIR / "render-wiki.py")
_wiki_mod = importlib.util.module_from_spec(_wiki_spec)
_wiki_spec.loader.exec_module(_wiki_mod)
build_bu_tree = _wiki_mod.build_bu_tree
bu_tree_html = _wiki_mod.tree_html


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


def _attr(s):
    return html_lib.escape(str(s), quote=True)


def join_url(base, path):
    return catalog_navigation.join_url(base, path)


def build_article_context_html(wiki_base, current_bu, current_project, tema, tema_title):
    if current_bu and current_project:
        bu_title = catalog_navigation.title_for_bu(current_bu)
        project_title = catalog_navigation.humanize_slug(current_project)
        return (
            f'<a href="{_attr(join_url(wiki_base, current_bu + "/"))}">{_esc(bu_title)}</a>'
            '<span class="sep">›</span>'
            f'<a href="{_attr(join_url(wiki_base, f"{current_bu}/{current_project}/"))}">'
            f'{_esc(project_title)}</a><span class="sep">›</span>'
        )
    return (
        f'<a href="{_attr(join_url(wiki_base, f"research/{tema}/"))}">{_esc(tema_title)}</a>'
        '<span class="sep">›</span>'
    )


def build_article_eyebrow(current_bu, current_project, tema_title):
    if current_bu and current_project:
        return f'{catalog_navigation.title_for_bu(current_bu)} / {catalog_navigation.humanize_slug(current_project)}'
    return tema_title


CHEV_SVG = '<svg class="chev" viewBox="0 0 12 12" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="4 2 8 6 4 10"/></svg>'
FOLDER_SVG = '<svg class="folder-icon" viewBox="0 0 14 14" fill="currentColor"><path d="M1 3 a1 1 0 0 1 1-1 h3 l1.5 1.5 h5.5 a1 1 0 0 1 1 1 v6 a1 1 0 0 1 -1 1 h-10 a1 1 0 0 1 -1 -1 z" opacity="0.85"/></svg>'
FOLDER_OPEN_SVG = '<svg class="folder-icon" viewBox="0 0 14 14" fill="currentColor"><path d="M2 3 a1 1 0 0 1 1-1 h3 l1.5 1.5 h5.5 a1 1 0 0 1 1 1 v1 h-12 z" opacity="0.7"/><path d="M0.5 5.5 h13 l-1.2 5.3 a1 1 0 0 1 -1 0.7 h-9.6 a1 1 0 0 1 -1 -0.7 z" opacity="0.95"/></svg>'
FILE_SVG = '<svg class="file-icon" viewBox="0 0 12 12" fill="none" stroke="currentColor" stroke-width="1" stroke-linejoin="round"><path d="M3 1.5 h4 l2.5 2.5 v6.5 a0.5 0.5 0 0 1 -0.5 0.5 h-6 a0.5 0.5 0 0 1 -0.5 -0.5 v-8.5 a0.5 0.5 0 0 1 0.5 -0.5 z"/><polyline points="7 1.5 7 4 9.5 4" fill="currentColor" opacity="0.4"/></svg>'


def build_recents_html(recents, wiki_base, limit=4):
    """Emit RECENTES grouped by date_human (mirrors render-wiki.recents_html)."""
    items = list(recents[:limit])
    if not items:
        return ''
    groups = []
    current_date = None
    current_items = []
    for r in items:
        d = (r.get('date_human') or '').upper()
        if d != current_date:
            if current_items:
                groups.append((current_date, current_items))
            current_date, current_items = d, []
        current_items.append(r)
    if current_items:
        groups.append((current_date, current_items))

    out = []
    for date, group_items in groups:
        out.append('<li class="wk-recents-day">')
        out.append(f'<span class="wk-recents-date">{date}</span>')
        out.append('<ul class="wk-recents-items">')
        for r in group_items:
            out.append(f'<li><a href="{wiki_base}/{r["url"]}">{r["title"]}</a></li>')
        out.append('</ul>')
        out.append('</li>')
    return '\n'.join(out)


def main():
    md_file, theme_json, title, slug, tema, repo_name, date, tags_csv, models_csv, tree_json, recents_json, wiki_base = sys.argv[1:13]
    skill_dir = SCRIPT_DIR.parent

    md = Path(md_file).read_text()
    theme = json.loads(theme_json)
    tags = [t.strip() for t in tags_csv.split(',') if t.strip()]
    models = [m.strip() for m in models_csv.split(',') if m.strip()] or ['claude']
    tree = json.loads(tree_json) if tree_json else []
    recents = json.loads(recents_json) if recents_json else []

    # Templates
    head_tpl = (skill_dir / "templates" / "_head.html.tpl").read_text()
    styles_tpl = (skill_dir / "templates" / "_styles.css.tpl").read_text()
    art_tpl = (skill_dir / "templates" / "artifact.html.tpl").read_text()
    topbar_tpl = (skill_dir / "templates" / "_topbar.html.tpl").read_text()
    sidebar_tpl = (skill_dir / "templates" / "_sidebar.html.tpl").read_text()
    appshell_tpl = (skill_dir / "templates" / "_appshell.html.tpl").read_text()

    meta = md_mod.extract_metadata(md)
    title_final = title or meta.get('title') or slug
    lead = meta.get('lead', '')
    reading_time = meta.get('reading_time', 1)
    public_head_title = os.environ.get('WIKIA_PUBLIC_TITLE') or title_final
    public_head_description = (
        os.environ.get('WIKIA_PUBLIC_DESCRIPTION')
        or (lead[:160] if lead else public_head_title)
    )

    content_html = md_mod.convert(md)

    # Auto-inline components
    needs_comparator = 'data-comparator' in content_html
    needs_accordion = 'data-accordion-seq' in content_html
    needs_mermaid = 'data-mermaid-zoom' in content_html

    extra_components = ''
    cd = skill_dir / "components"
    if needs_comparator and (cd / "comparator.html").exists():
        extra_components += '\n' + (cd / "comparator.html").read_text()
    if needs_accordion and (cd / "accordion-seq.html").exists():
        extra_components += '\n' + (cd / "accordion-seq.html").read_text()
    if needs_mermaid and (cd / "mermaid-zoom.html").exists():
        mz = (cd / "mermaid-zoom.html").read_text()
        mz = (mz.replace('{{TM_BG_SIDEBAR}}', theme.get('bgSidebar', '#0f100f'))
                .replace('{{TM_ACCENT_DIM}}', theme.get('accentDim', '#262121'))
                .replace('{{TM_TEXT_MAIN}}', theme.get('textMain', '#f2f2c0'))
                .replace('{{TM_ACCENT}}', theme.get('accent', '#5b675b'))
                .replace('{{TM_BG_ACTIVITY}}', theme.get('bgActivity', '#141415'))
                .replace('{{TM_BG_MAIN}}', theme.get('bgMain', '#0c0e0c')))
        extra_components += '\n' + mz

    content_html += extra_components

    # Theme
    theme_vars = build_theme_vars(theme)
    import theme_resolver
    styles = theme_resolver.resolve_styles(skill_dir / "templates", theme_vars)

    head_html = (head_tpl
        .replace('{{TITLE}}', public_head_title)
        .replace('{{REPO_NAME}}', repo_name)
        .replace('{{DESCRIPTION}}', public_head_description)
        .replace('{{STYLES_CSS}}', styles))

    # Tree (Wave 2 BU/project/slug hierarchy with D3 auto-flatten) + recents
    raw_md_path = Path(md_file)
    public_root = os.environ.get('WIKIA_PUBLIC_ROOT')
    gitpages_dir = Path(public_root) if public_root else raw_md_path.parent.parent.parent.parent
    fm = parse_frontmatter_optional(str(raw_md_path)) or {}
    current_bu = fm.get('bu')
    current_project = fm.get('project')
    current_slug = fm.get('slug') or slug
    catalog_records = public_catalog.load_records_from_public_root(gitpages_dir)
    current_record = public_catalog.find_record(catalog_records, current_bu, current_project, current_slug)
    # If the current article is missing from the catalog, fall back to public
    # records only. Treat this like an audience list with no matching segment:
    # showing less is safer than exposing a whole BU of gated metadata.
    bu_tree = build_bu_tree(
        str(gitpages_dir),
        public_only=current_record is None,
        current_record=current_record,
    )
    tree_html = bu_tree_html(
        bu_tree,
        current_bu=current_bu,
        current_project=current_project,
        current_slug=current_slug,
        wiki_base=wiki_base,
        scope_bu=current_bu,  # isolate sidebar to current BU — prevents cross-BU metadata leakage
    )
    if catalog_records:
        if current_record is not None:
            recent_records = public_catalog.scoped_records(catalog_records, current_record)
        else:
            recent_records = [
                record for record in catalog_records
                if public_catalog.is_public_record(record)
            ]
        recent_artifacts = catalog_navigation.artifacts_from_records(recent_records, gitpages_dir)
        recents_html = _wiki_mod.recents_html(recent_artifacts, wiki_base)
    else:
        recents_html = build_recents_html(recents, wiki_base)

    # Render shared blocks
    topbar_html = topbar_tpl.replace('{{WIKI_BASE}}', wiki_base)
    sidebar_html = sidebar_tpl.replace('{{TREE_HTML}}', tree_html).replace('{{RECENTS_HTML}}', recents_html)
    appshell_html = appshell_tpl

    # Tags
    tags_meta = ''
    tags_footer = ''
    for t in tags:
        tags_meta += f'<span class="dot">·</span><a href="{wiki_base}/tags/{t}/" class="tag">{t}</a>'
        tags_footer += f'<a href="{wiki_base}/tags/{t}/" class="tag">{t}</a>'

    lead_html = f'<p class="wk-lead">{lead}</p>' if lead else ''

    try:
        dt = datetime.strptime(date, '%Y-%m-%d')
        date_human = dt.strftime('%d %b %Y')
    except Exception:
        date_human = date

    tema_title = tema.replace('-', ' ').title()
    breadcrumb_context_html = build_article_context_html(
        wiki_base,
        current_bu,
        current_project,
        tema,
        tema_title,
    )
    article_eyebrow = build_article_eyebrow(current_bu, current_project, tema_title)

    final = (art_tpl
        .replace('{{HEAD_HTML}}', head_html)
        .replace('{{TOPBAR_HTML}}', topbar_html)
        .replace('{{SIDEBAR_HTML}}', sidebar_html)
        .replace('{{APPSHELL_HTML}}', appshell_html)
        .replace('{{TITLE}}', title_final)
        .replace('{{SLUG}}', slug)
        .replace('{{TEMA}}', tema)
        .replace('{{TEMA_TITLE}}', tema_title)
        .replace('{{BREADCRUMB_CONTEXT_HTML}}', breadcrumb_context_html)
        .replace('{{ARTICLE_EYEBROW}}', _esc(article_eyebrow))
        .replace('{{REPO_NAME}}', repo_name)
        .replace('{{DATE}}', date)
        .replace('{{DATE_HUMAN}}', date_human)
        .replace('{{READING_TIME}}', str(reading_time))
        .replace('{{LEAD_PARAGRAPH}}', lead_html)
        .replace('{{TAGS_HTML}}', tags_meta)
        .replace('{{TAGS_FOOTER_HTML}}', tags_footer)
        .replace('{{CONTENT_HTML}}', content_html)
        .replace('{{MODELS_USED}}', ' + '.join(models))
        .replace('{{WIKI_BASE}}', wiki_base)
    )

    sys.stdout.write(final)


if __name__ == '__main__':
    main()
