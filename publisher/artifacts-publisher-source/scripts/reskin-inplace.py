#!/usr/bin/env python3
"""
reskin-inplace.py — aplica o tema EverTool em páginas JÁ renderizadas,
SEM decifrar o conteúdo (que é cifrado dentro de <template id="ap-content-tpl">).

O CSS mora plaintext no <head>; o EverTool é um overlay que re-veste as classes
que o conteúdo já usa (.wk-article, .ap-callout, .wk-feed…). Então basta:
  1) injetar a fonte Newsreader (serif) no <head>
  2) injetar o overlay CSS antes do fechamento do <style> principal

Idempotente (marcador). Pula o painel /admin/. Reversível via git.

Uso:
  reskin-inplace.py <gitpages-dir> <overlay-css-file> [--dry-run]
"""
import sys
from pathlib import Path

MARKER = "/* ===== EVERTOOL IN-PLACE RESKIN ===== */"
NEWSREADER = (
    '<link href="https://fonts.googleapis.com/css2?'
    'family=Newsreader:ital,opsz,wght@0,6..72,400;0,6..72,500;0,6..72,600;1,6..72,400'
    '&display=swap" rel="stylesheet">'
)


def reskin(html, overlay_css):
    if "<style>" not in html or "</style>" not in html:
        return html, "skip:no-style-block"
    updated = False
    # Update: remove o overlay antigo (do MARKER até o </style> que o segue) e reinjeta.
    if MARKER in html:
        m = html.find(MARKER)
        end = html.find("</style>", m)
        if end == -1:
            return html, "skip:marker-without-style"
        html = html[:m] + html[end:]
        updated = True
    # 1) fonte serifada — antes do primeiro <style> (garante head)
    if "Newsreader" not in html:
        i = html.find("<style>")
        html = html[:i] + NEWSREADER + "\n" + html[i:]
    # 2) overlay — antes do PRIMEIRO </style> (fim do bloco principal, após :root)
    i = html.find("</style>")
    inject = "\n" + MARKER + "\n" + overlay_css.rstrip() + "\n"
    html = html[:i] + inject + html[i:]
    return html, ("updated" if updated else "reskinned")


def main():
    if len(sys.argv) < 3:
        print(__doc__)
        sys.exit(1)
    gitpages = Path(sys.argv[1])
    overlay_css = Path(sys.argv[2]).read_text()
    dry = "--dry-run" in sys.argv

    done = skipped = 0
    for p in sorted(gitpages.rglob("index.html")):
        rel = p.relative_to(gitpages)
        if rel.parts and rel.parts[0] == "admin":
            print(f"  {'skip:admin':24} {rel}")
            skipped += 1
            continue
        html = p.read_text()
        new, status = reskin(html, overlay_css)
        if status in ("reskinned", "updated"):
            if not dry:
                p.write_text(new)
            done += 1
        else:
            skipped += 1
        print(f"  {status:24} {rel}")

    tag = " (DRY RUN — nada escrito)" if dry else ""
    print(f"\n{done} written · {skipped} skipped{tag}")


if __name__ == "__main__":
    main()
