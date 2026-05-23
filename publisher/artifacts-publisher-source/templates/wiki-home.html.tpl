<!DOCTYPE html>
<html lang="pt-BR" data-wiki-base="{{WIKI_BASE}}">
<head>
{{HEAD_HTML}}
</head>
<body>

{{GATE_BLOCK}}

<template id="ap-content-tpl">
{{TOPBAR_HTML}}

<div class="wk-shell">
  {{SIDEBAR_HTML}}

  <main class="wk-main">
    <div class="wk-content wk-article">

      <header class="wk-article-header">
        <div class="wk-eyebrow">wikia · knowledge</div>
        <h1>Notas do Felipe</h1>
        <p class="wk-lead">Wiki interno. Estratégia, design, decisões e experimentos publicados como nós navegáveis. Use a barra lateral à esquerda para explorar por tema, ou <kbd style="background:var(--accent-dim);border:1px solid var(--border);padding:2px 6px;border-radius:3px;font-size:11px;color:var(--text-main)">⌘K</kbd> para buscar.</p>
      </header>

      <ul class="wk-feed">
        {{FEED_HTML}}
      </ul>

      <footer class="wk-article-footer" style="margin-top:64px">
        <div class="meta">
          <span><span class="accent">wikia</span></span>
          <span>·</span>
          <span>maestro theme</span>
          <span>·</span>
          <span>artifacts-publisher</span>
        </div>
      </footer>

    </div>
  </main>
</div>

{{APPSHELL_HTML}}
</template>

<script>
(function() {
  const tpl = document.getElementById('ap-content-tpl');
  if (!tpl) return;
  const mount = document.getElementById('ap-content-mount');
  if (mount) {
    mount.innerHTML = tpl.innerHTML;
    mount.querySelectorAll('script').forEach(old => {
      const s = document.createElement('script');
      if (old.src) s.src = old.src; else s.textContent = old.textContent;
      old.replaceWith(s);
    });
    mount.style.display = 'block';
  } else {
    document.body.appendChild(tpl.content.cloneNode(true));
  }
})();
</script>

</body>
</html>
