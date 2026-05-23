#!/usr/bin/env python3
"""strip-gate.py — Remove AES gate scaffolding from rendered HTML.

Two operating modes, auto-detected:

1) Freshly rendered HTML (rebuild loop case): the file still has
   <template id="ap-content-tpl">...</template> AND the literal
   '{{GATE_BLOCK}}' placeholder. We extract the template inner content
   via balance-scan (handles nested <template> from playgrounds), drop
   the template block, and replace the placeholder with the unwrapped
   content.

2) Already-gated HTML (defensive case): {{GATE_BLOCK}} is gone,
   template is gone, gate <script id="ap-gate-script"> + gate UI live
   in the body. We strip the gate <script> and the surrounding
   #ap-gate wrapper if present.

Usage:
    python3 strip-gate.py <html-file>
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

OPEN_MARKER = '<template id="ap-content-tpl">'
OPEN_RE = re.compile(r"<template(?:\s[^>]*)?>", re.IGNORECASE)
CLOSE_RE = re.compile(r"</template\s*>", re.IGNORECASE)
GATE_SCRIPT_RE = re.compile(
    r'<script\b[^>]*\bid=["\']ap-gate-script["\'][^>]*>.*?</script\s*>',
    re.IGNORECASE | re.DOTALL,
)


def extract_template_content(html: str) -> tuple[str, str]:
    """Balance-scan the outer <template id="ap-content-tpl">.

    Returns (content_without_template, inner_content). If no template
    is found, returns (html, "").
    """
    start = html.find(OPEN_MARKER)
    if start == -1:
        return html, ""
    content_start = start + len(OPEN_MARKER)
    depth = 1
    pos = content_start
    close_start = close_end = -1
    while depth > 0:
        o = OPEN_RE.search(html, pos)
        c = CLOSE_RE.search(html, pos)
        if not c:
            raise SystemExit("ERR: unbalanced <template> in HTML")
        if o and o.start() < c.start():
            depth += 1
            pos = o.end()
        else:
            depth -= 1
            if depth == 0:
                close_start = c.start()
                close_end = c.end()
            pos = c.end()
    inner = html[content_start:close_start]
    stripped = html[:start] + html[close_end:]
    return stripped, inner


def strip_gate(html_path: Path) -> None:
    html = html_path.read_text(encoding="utf-8")

    stripped, inner = extract_template_content(html)

    if "{{GATE_BLOCK}}" in stripped:
        # Mode 1: placeholder still present — replace with unwrapped content.
        stripped = stripped.replace("{{GATE_BLOCK}}", inner)

    # Mode 2 (also defensive): if a gate <script id="ap-gate-script"> survived
    # (e.g. file was already gated), remove it.
    stripped = GATE_SCRIPT_RE.sub("", stripped)

    html_path.write_text(stripped, encoding="utf-8")


def main() -> int:
    if len(sys.argv) != 2:
        print("Usage: strip-gate.py <html-file>", file=sys.stderr)
        return 2
    target = Path(sys.argv[1])
    if not target.is_file():
        print(f"ERR: {target} not found", file=sys.stderr)
        return 1
    strip_gate(target)
    print(f"strip-gate: {target}", file=sys.stderr)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
