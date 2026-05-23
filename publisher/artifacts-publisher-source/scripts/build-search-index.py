#!/usr/bin/env python3
"""
build-search-index.py — gera search.json com índice full-text dos artefatos.
Uso: python3 build-search-index.py <workdir>
Output: workdir/search.json
"""
import sys, json, re
from pathlib import Path
from datetime import datetime
import public_catalog

BU_ENUM = ('staging', 'vita', 'allin', 'aleyemma', 'gobbi')


def _extract_item(html, md, slug, tema_label, url):
    html_text = html.read_text(errors='ignore')
    m_title = re.search(r'<title>([^<]+)</title>', html_text)
    title = m_title.group(1).split(' · ')[0].strip() if m_title else slug
    m_desc = re.search(r'<meta name="description" content="([^"]+)"', html_text)
    desc = m_desc.group(1) if m_desc else ''
    tags = []
    snippet = ''
    if md.exists():
        md_text = md.read_text(errors='ignore')
        m_tags = re.search(r'^tags:\s*\[?([^\n\]]+)\]?', md_text, re.MULTILINE)
        if m_tags:
            tags = [t.strip().strip('"\'') for t in m_tags.group(1).split(',') if t.strip()]
        cleaned = re.sub(r'^---.*?---\s*', '', md_text, flags=re.DOTALL)
        cleaned = re.sub(r'[#*`>\[\]()_]+', '', cleaned)
        snippet = ' '.join(cleaned.split())[:300]
    mtime = datetime.fromtimestamp(html.stat().st_mtime)
    return {
        'title': title,
        'tema': tema_label,
        'tags': tags,
        'date': mtime.strftime('%Y-%m-%d'),
        'snippet': snippet or desc[:300],
        'url': url,
    }


def collect(workdir):
    workdir = Path(workdir)
    catalog_records = public_catalog.load_records_from_public_root(workdir)
    if catalog_records:
        return [
            _extract_catalog_item(record, workdir)
            for record in catalog_records
            if public_catalog.is_public_record(record)
        ]

    items = []

    # Wave 2 layout: <bu>/<project>/<slug>/
    for bu in BU_ENUM:
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
                items.append(_extract_item(
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
            for art in arts_dir.iterdir():
                if not art.is_dir():
                    continue
                html = art / 'index.html'
                md = art / 'raw.md'
                if not html.exists():
                    continue
                items.append(_extract_item(
                    html, md, art.name,
                    tema_label=tema_dir.name,
                    url=f'research/{tema_dir.name}/artifacts/{art.name}/',
                ))

    return items


def _extract_catalog_item(record, workdir):
    output_url = public_catalog.normalize_output_url(record.get('output_url') or '')
    html = Path(workdir) / output_url.strip('/') / 'index.html'
    if html.exists():
        mtime = datetime.fromtimestamp(html.stat().st_mtime)
        date = mtime.strftime('%Y-%m-%d')
    else:
        date = ''
    return {
        'title': public_catalog.public_title(record),
        'tema': f"{record.get('bu')}/{record.get('project')}",
        'tags': record.get('tags') or [],
        'date': date,
        'snippet': '',
        'url': output_url,
    }

if __name__ == '__main__':
    workdir = sys.argv[1]
    items = collect(workdir)
    (Path(workdir) / 'search.json').write_text(json.dumps(items, ensure_ascii=False, indent=2))
    print(f'→ search.json: {len(items)} items', file=sys.stderr)
