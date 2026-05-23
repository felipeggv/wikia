<!DOCTYPE html>
<html lang="pt-BR" data-wiki-base="{{WIKI_BASE}}" data-bu="{{BU_SLUG}}" data-project="{{PROJECT_SLUG}}">
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

      <nav class="wk-breadcrumb">wikia &rsaquo; {{BU_TITLE}} &rsaquo; {{PROJECT_TITLE}}</nav>

      <header class="wk-article-header">
        <div class="wk-eyebrow">wikia · projeto · {{BU_SLUG}}/{{PROJECT_SLUG}}</div>
        <h1>{{PROJECT_TITLE}}</h1>
        <p class="wk-lead">{{PROJECT_DESCRIPTION}}</p>
      </header>

      <section class="wk-project-articles">
        <h2 class="wk-section-title">Artigos</h2>
        {{ARTICLES_LIST_HTML}}
      </section>

      <footer class="wk-article-footer" style="margin-top:64px">
        <div class="meta">
          <span><span class="accent">wikia</span></span>
          <span>·</span>
          <span>{{BU_TITLE}} / {{PROJECT_TITLE}}</span>
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
