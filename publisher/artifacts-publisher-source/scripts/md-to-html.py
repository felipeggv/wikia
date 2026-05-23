#!/usr/bin/env python3
"""
md-to-html.py — Markdown → HTML semântico (sem deps externas).
Suporta: headings, parágrafos, listas (ul/ol), code blocks, inline (code/em/strong/link),
tables (GFM), blockquotes, hr, e blocos especiais ::: comparator, ::: accordion-seq.
"""
import sys, re, html as html_lib, json

def escape(s): return html_lib.escape(s, quote=False)
def slugify(t):
    s = re.sub(r'[^\w\s-]', '', t.lower())
    return re.sub(r'[-\s]+', '-', s).strip('-')

def render_inline(text):
    text = escape(text)
    text = re.sub(r'`([^`]+)`', lambda m: f'<code>{m.group(1)}</code>', text)
    text = re.sub(r'\*\*([^*]+)\*\*', lambda m: f'<strong>{m.group(1)}</strong>', text)
    text = re.sub(r'(?<!\*)\*([^*\n]+)\*(?!\*)', lambda m: f'<em>{m.group(1)}</em>', text)
    text = re.sub(r'\[([^\]]+)\]\(([^)]+)\)', lambda m: f'<a href="{m.group(2)}">{m.group(1)}</a>', text)
    return text

def convert(md):
    lines = md.split('\n')
    # Strip YAML frontmatter if present — prevents it from leaking into rendered body.
    if lines and lines[0].strip() == '---':
        end = next((j for j in range(1, len(lines)) if lines[j].strip() == '---'), None)
        if end is not None:
            lines = lines[end + 1:]
    out = []
    i = 0
    in_list = None
    list_buf = []
    in_code = False
    code_lang = ''
    code_buf = []
    in_table = False
    table_buf = []
    para = []
    in_special = None  # comparator | accordion-seq | mermaid-zoom | callout | playground
    special_meta = ''  # title or variant of special block
    special_buf = []

    def flush_para():
        nonlocal para
        if para:
            t = ' '.join(para).strip()
            if t: out.append(f'<p>{render_inline(t)}</p>')
            para = []

    def flush_list():
        nonlocal in_list, list_buf
        if list_buf:
            items = ''.join(f'<li>{render_inline(it)}</li>' for it in list_buf)
            out.append(f'<{in_list}>{items}</{in_list}>')
            list_buf = []
        in_list = None

    def flush_table():
        nonlocal in_table, table_buf
        if not table_buf:
            in_table = False; return
        rows = [r for r in table_buf if r.strip()]
        if len(rows) < 2:
            in_table = False; table_buf = []; return
        def split(r):
            r = r.strip()
            if r.startswith('|'): r = r[1:]
            if r.endswith('|'): r = r[:-1]
            return [c.strip() for c in r.split('|')]
        header = split(rows[0])
        body = [split(r) for r in rows[2:]]
        thead = '<thead><tr>' + ''.join(f'<th>{render_inline(c)}</th>' for c in header) + '</tr></thead>'
        tbody = '<tbody>' + ''.join('<tr>' + ''.join(f'<td>{render_inline(c)}</td>' for c in row) + '</tr>' for row in body) + '</tbody>'
        out.append(f'<table>{thead}{tbody}</table>')
        table_buf = []; in_table = False

    while i < len(lines):
        line = lines[i]

        # Special block ::: comparator / accordion-seq / mermaid-zoom / callout / playground
        m_special = re.match(r'^:::\s*(comparator|accordion-seq|mermaid-zoom|callout|playground)(?:\s+(.+?))?\s*$', line)
        if m_special and not in_special:
            flush_para(); flush_list(); flush_table()
            in_special = m_special.group(1)
            special_meta = (m_special.group(2) or '').strip()
            special_buf = []
            i += 1; continue
        if line.strip() == ':::' and in_special:
            # Render special block
            if in_special == 'comparator':
                # Normaliza linhas: se vier "\n" literal no buffer, expande
                norm_buf = []
                for ln in special_buf:
                    # Se a linha contém \n literal (vindo de escape em pipeline), expande
                    if '\\n' in ln:
                        norm_buf.extend(ln.replace('\\n', '\n').split('\n'))
                    else:
                        norm_buf.append(ln)

                # Buffer format: each option = `### Option Name` then content
                parts = []
                current = None
                cur_buf = []
                for ln in norm_buf:
                    mh = re.match(r'^###\s+(.+)$', ln)
                    if mh:
                        if current is not None: parts.append((current, cur_buf))
                        current = mh.group(1).strip(); cur_buf = []
                    elif current is not None:
                        cur_buf.append(ln)
                if current is not None: parts.append((current, cur_buf))

                tabs = ''
                panels = ''
                for idx, (name, buf) in enumerate(parts):
                    tid = f'cmp-{slugify(name)}-{idx}'
                    active = 'active' if idx == 0 else ''
                    # Renderiza cada panel via convert() em string com quebras reais
                    panel_md = '\n'.join(buf)
                    panel_html = convert(panel_md)
                    tabs += f'<button data-target="{tid}" class="{active}">{escape(name)}</button>'
                    panels += f'<div class="ap-comp-panel {active}" id="{tid}">{panel_html}</div>'
                out.append(f'<div class="ap-comparator" data-comparator><div class="ap-comp-tabs">{tabs}</div><div class="ap-comp-panels">{panels}</div></div>')
            elif in_special == 'accordion-seq':
                # Mesma normalização de \n literais
                norm_buf = []
                for ln in special_buf:
                    if '\\n' in ln:
                        norm_buf.extend(ln.replace('\\n', '\n').split('\n'))
                    else:
                        norm_buf.append(ln)

                parts = []
                current = None
                cur_buf = []
                for ln in norm_buf:
                    mh = re.match(r'^###\s+(.+)$', ln)
                    if mh:
                        if current is not None: parts.append((current, cur_buf))
                        current = mh.group(1).strip(); cur_buf = []
                    elif current is not None:
                        cur_buf.append(ln)
                if current is not None: parts.append((current, cur_buf))

                items_html = ''
                for step_n, (name, buf) in enumerate(parts, start=1):
                    body_md = '\n'.join(buf)
                    body_html = convert(body_md)
                    items_html += f'<li><button class="ap-acc-trigger">{step_n}. {escape(name)}</button><div class="ap-acc-body">{body_html}</div></li>'
                out.append(f'<ol class="ap-accordion-seq" data-accordion-seq>{items_html}</ol>')
            elif in_special == 'mermaid-zoom':
                # Normaliza \n literais também
                lines_clean = []
                for ln in special_buf:
                    if '\\n' in ln:
                        lines_clean.extend(ln.replace('\\n', '\n').split('\n'))
                    else:
                        lines_clean.append(ln)
                code = '\n'.join(lines_clean).strip()
                # Auto-inject config: curve: linear (visual mais "retinho")
                # Só se não já tem config:--- no início
                if not code.startswith('---'):
                    config_block = (
                        '---\n'
                        'config:\n'
                        '  flowchart:\n'
                        '    curve: linear\n'
                        '    htmlLabels: true\n'
                        '  sequence:\n'
                        '    diagramMarginX: 30\n'
                        '---\n'
                    )
                    code = config_block + code
                # Mermaid syntax usa `-->` `==>` `--x` etc. Escapar `>` quebra o parser
                # (vira `&gt;` no DOM e o mermaid não reconhece a seta). Escapamos só `<`
                # e `&` que são necessários pra HTML válido; `>` fica literal.
                mermaid_safe = code.replace('&', '&amp;').replace('<', '&lt;')
                out.append(f'<div class="ap-mermaid-zoom" data-mermaid-zoom><pre class="mermaid">{mermaid_safe}</pre></div>')
            elif in_special == 'callout':
                # Variant via special_meta: info | tip | warn | success | quote (default: info)
                variant = special_meta.split()[0].lower() if special_meta else 'info'
                if variant not in ('info', 'tip', 'warn', 'success', 'quote'):
                    variant = 'info'
                # Título opcional (resto da linha após variant)
                title = ' '.join(special_meta.split()[1:]).strip() if ' ' in special_meta else ''
                # Normaliza \n literais
                norm_buf = []
                for ln in special_buf:
                    if '\\n' in ln:
                        norm_buf.extend(ln.replace('\\n', '\n').split('\n'))
                    else:
                        norm_buf.append(ln)
                body_md = '\n'.join(norm_buf)
                body_html = convert(body_md)
                title_html = f'<div class="ap-callout-title">{render_inline(title)}</div>' if title else ''
                out.append(f'<aside class="ap-callout" data-variant="{variant}">{title_html}<div class="ap-callout-body">{body_html}</div></aside>')
            elif in_special == 'playground':
                # Playground vai num drawer lateral direito
                # Markup capturado vai pra <template> que o JS injeta no drawer
                # special_meta = título do playground
                title = special_meta or 'Teste interativo'
                norm_buf = []
                for ln in special_buf:
                    if '\\n' in ln:
                        norm_buf.extend(ln.replace('\\n', '\n').split('\n'))
                    else:
                        norm_buf.append(ln)
                # Conteúdo do playground é HTML puro (controles, sliders, JS)
                # passa direto, sem markdown conversion
                playground_html = '\n'.join(norm_buf)
                # Inline trigger button no body do artigo + template invisível com conteúdo
                pg_id = f'pg-{slugify(title)}'
                out.append(f'''<div class="ap-playground-trigger" data-playground-trigger="{pg_id}">
  <div class="ap-playground-trigger-icon">⚙</div>
  <div class="ap-playground-trigger-body">
    <div class="ap-playground-trigger-label">TESTE INTERATIVO</div>
    <div class="ap-playground-trigger-title">{escape(title)}</div>
  </div>
  <div class="ap-playground-trigger-cta">abrir →</div>
</div>
<template id="{pg_id}" data-playground-content data-title="{escape(title)}">{playground_html}</template>''')
            in_special = None; special_meta = ''; special_buf = []
            i += 1; continue
        if in_special:
            special_buf.append(line); i += 1; continue

        # Code fence
        if line.startswith('```'):
            if not in_code:
                flush_para(); flush_list(); flush_table()
                in_code = True; code_lang = line[3:].strip(); code_buf = []
            else:
                content = escape('\n'.join(code_buf))
                cls = f' class="language-{code_lang}"' if code_lang else ''
                out.append(f'<pre><code{cls}>{content}</code></pre>')
                in_code = False; code_lang = ''; code_buf = []
            i += 1; continue
        if in_code:
            code_buf.append(line); i += 1; continue

        # HTML passthrough — bloco começa com <tag>, <!--, ou <svg
        # Captura até a tag de fechamento correspondente OU até a próxima linha em branco se for inline simples
        html_block = re.match(r'^\s*<(!--|[a-zA-Z][a-zA-Z0-9]*)', line)
        if html_block:
            flush_para(); flush_list(); flush_table()
            tag = html_block.group(1)
            if tag == '!--':
                # comment: vai até -->
                buf = [line]
                while '-->' not in buf[-1] and i+1 < len(lines):
                    i += 1
                    buf.append(lines[i])
                out.append('\n'.join(buf))
                i += 1
                continue
            else:
                # <script> e <style> são tratados como blocos self-contained:
                # seu conteúdo (JS/CSS) pode conter strings literais tipo
                # "<script>" ou "</script>", comparações tipo "x < 3", regex, etc,
                # que confundem o contador de balanceamento. Lê até o PRIMEIRO
                # </script> ou </style> em line-start ou após whitespace,
                # sem tentar balancear depth.
                tag_lower = tag.lower()
                if tag_lower in ('script', 'style'):
                    closer_re = re.compile(r'</' + tag_lower + r'\s*>', re.IGNORECASE)
                    buf = [line]
                    # Se a tag de fechamento já está na mesma linha, emite e sai.
                    if not closer_re.search(line):
                        while i+1 < len(lines):
                            i += 1
                            ln = lines[i]
                            buf.append(ln)
                            if closer_re.search(ln):
                                break
                    out.append('\n'.join(buf))
                    i += 1
                    continue
                # bloco HTML genérico: balanceia <tag>...</tag>
                opener = re.compile(r'<' + re.escape(tag) + r'(\s|>|/)', re.IGNORECASE)
                closer = re.compile(r'</' + re.escape(tag) + r'\s*>', re.IGNORECASE)
                # Self-closing detection
                if re.search(r'/>\s*$', line) and not closer.search(line):
                    out.append(line); i += 1; continue
                buf = [line]
                depth = len(opener.findall(line)) - len(closer.findall(line))
                while depth > 0 and i+1 < len(lines):
                    i += 1
                    ln = lines[i]
                    buf.append(ln)
                    depth += len(opener.findall(ln)) - len(closer.findall(ln))
                out.append('\n'.join(buf))
                i += 1
                continue

        # Headings
        m = re.match(r'^(#{1,6})\s+(.+)$', line)
        if m:
            flush_para(); flush_list(); flush_table()
            level = len(m.group(1))
            text = m.group(2).strip()
            sid = slugify(text)
            out.append(f'<h{level} id="{sid}">{render_inline(text)}</h{level}>')
            i += 1; continue

        # Hr
        if re.match(r'^[-*_]{3,}\s*$', line):
            flush_para(); flush_list(); flush_table()
            out.append('<hr>'); i += 1; continue

        # Table
        if '|' in line and re.match(r'^\s*\|?.+\|.+\|?\s*$', line):
            if i+1 < len(lines) and re.match(r'^\s*\|?[\s\-:|]+\|?\s*$', lines[i+1]) and '|' in lines[i+1]:
                flush_para(); flush_list()
                in_table = True; table_buf = [line, lines[i+1]]; i += 2
                while i < len(lines) and '|' in lines[i] and lines[i].strip():
                    table_buf.append(lines[i]); i += 1
                flush_table(); continue

        # Blockquote
        if line.startswith('>'):
            flush_para(); flush_list(); flush_table()
            qbuf = [re.sub(r'^>\s?', '', line)]; i += 1
            while i < len(lines) and lines[i].startswith('>'):
                qbuf.append(re.sub(r'^>\s?', '', lines[i])); i += 1
            out.append(f'<blockquote>{render_inline(" ".join(qbuf))}</blockquote>')
            continue

        # Lists
        ul_m = re.match(r'^\s*[-*]\s+(.+)$', line)
        ol_m = re.match(r'^\s*\d+\.\s+(.+)$', line)
        if ul_m:
            flush_para(); flush_table()
            if in_list != 'ul': flush_list(); in_list = 'ul'
            list_buf.append(ul_m.group(1)); i += 1; continue
        if ol_m:
            flush_para(); flush_table()
            if in_list != 'ol': flush_list(); in_list = 'ol'
            list_buf.append(ol_m.group(1)); i += 1; continue

        if not line.strip():
            flush_para(); flush_list(); flush_table()
            i += 1; continue

        para.append(line.strip()); i += 1

    flush_para(); flush_list(); flush_table()
    return '\n'.join(out)

def extract_metadata(md):
    """Extrai metadados: lead paragraph, headings, reading time."""
    lines = md.split('\n')
    title = None
    lead = None
    headings = []
    # Skip frontmatter if present
    start = 0
    if lines and lines[0].strip() == '---':
        end = next((j for j in range(1, len(lines)) if lines[j].strip() == '---'), None)
        if end: start = end + 1

    # Find first H1 as title
    for j in range(start, len(lines)):
        mh = re.match(r'^#\s+(.+)$', lines[j])
        if mh:
            title = mh.group(1).strip()
            start = j + 1
            break

    # First non-empty paragraph after H1 = lead
    para = []
    for j in range(start, len(lines)):
        ln = lines[j]
        if not ln.strip():
            if para:
                lead = ' '.join(para).strip()
                break
            continue
        if re.match(r'^[#>*\-\d`|]', ln.strip()[:1]):
            if para:
                lead = ' '.join(para).strip()
                break
            continue
        para.append(ln.strip())

    # Headings
    for ln in lines[start:]:
        mh = re.match(r'^(#{2,3})\s+(.+)$', ln)
        if mh:
            headings.append({'level': len(mh.group(1)), 'text': mh.group(2).strip(), 'id': slugify(mh.group(2).strip())})

    words = len(re.findall(r'\w+', md))
    reading_time = max(1, round(words / 200))

    return {'title': title, 'lead': lead, 'headings': headings, 'reading_time': reading_time, 'words': words}

if __name__ == '__main__':
    md = sys.stdin.read()
    if len(sys.argv) > 1:
        cmd = sys.argv[1]
        if cmd == '--metadata':
            print(json.dumps(extract_metadata(md), ensure_ascii=False))
        elif cmd == '--toc':
            for h in extract_metadata(md)['headings']:
                print(f'<li><a href="#{h["id"]}">{h["text"]}</a></li>')
        else:
            print(convert(md))
    else:
        print(convert(md))
