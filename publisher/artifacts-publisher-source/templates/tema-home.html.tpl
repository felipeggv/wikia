<!DOCTYPE html>
<html lang="pt-BR">
<head>
{{HEAD_HTML}}
</head>
<body>

<header class="ap-app-header">
  <div class="ap-app-header-inner">
    <a href="{{WIKI_BASE}}/" class="ap-wordmark">{{REPO_NAME}} <span class="dim">· knowledge</span></a>
    <nav class="ap-app-nav">
      <a href="{{WIKI_BASE}}/">Wiki</a>
      <a href="#" class="active">{{TEMA_TITLE}}</a>
    </nav>
  </div>
</header>

<nav class="ap-breadcrumb">
  <a href="{{WIKI_BASE}}/">Wiki</a><span class="sep">›</span>
  <span class="current">{{TEMA_TITLE}}</span>
</nav>

<div class="ap-page" style="display:block">
  <article class="ap-article" style="max-width: var(--max-wide);">
    <header class="ap-article-header">
      <div class="ap-eyebrow">Tema</div>
      <h1>{{TEMA_TITLE}}</h1>
      <p class="ap-lead">{{TEMA_DESCRIPTION}}</p>
      <div class="ap-meta-row">
        <span>{{ARTIFACT_COUNT}} artefato(s)</span>
        <span class="dot">·</span>
        <span>Atualizado em {{LAST_UPDATE}}</span>
      </div>
    </header>

    <div style="display:flex; flex-direction:column; gap:var(--space-3);">
      {{ARTIFACTS_LIST}}
    </div>

    <footer class="ap-article-footer">
      <div class="meta">
        <span><a href="{{WIKI_BASE}}/">← Voltar pro wiki</a></span>
      </div>
    </footer>
  </article>
</div>

<style>
.tema-artifact-card { display:block; padding: var(--space-5); background: var(--bg-sidebar); border: 1px solid var(--border); border-radius: 8px; text-decoration: none; transition: all 0.15s; }
.tema-artifact-card:hover { border-color: var(--accent); transform: translateY(-2px); }
.tema-artifact-card h3 { font-family: var(--font-serif); font-weight: 500; font-size: var(--text-xl); color: var(--text-main); margin: 0 0 var(--space-2); line-height: 1.3; }
.tema-artifact-card .snippet { font-size: var(--text-sm); color: var(--text-dim); margin: 0 0 var(--space-3); line-height: 1.5; }
.tema-artifact-card .meta { font-size: var(--text-xs); color: var(--text-dim); display: flex; gap: var(--space-3); align-items: center; }
.tema-artifact-card .meta .tag { padding: 2px 8px; background: var(--accent-dim); border: 1px solid var(--border); border-radius: 999px; font-size: var(--text-xs); }
.tema-artifact-card .meta .accent { color: var(--accent); }
</style>

</body>
</html>
