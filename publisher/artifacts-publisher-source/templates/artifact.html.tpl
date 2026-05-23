<!DOCTYPE html>
<html lang="pt-BR" data-slug="{{SLUG}}" data-repo="{{REPO_NAME}}" data-wiki-base="{{WIKI_BASE}}">
<head>
{{HEAD_HTML}}
</head>
<body>

{{TOPBAR_HTML}}

<div class="wk-shell">
  {{SIDEBAR_HTML}}

  <main class="wk-main">
    <div class="wk-content wk-article">

      {{GATE_BLOCK}}

      <template id="ap-content-tpl">

        <nav class="wk-breadcrumb" aria-label="Breadcrumb">
          <a href="{{WIKI_BASE}}/">wikia</a><span class="sep">›</span>
          <a href="{{WIKI_BASE}}/research/{{TEMA}}/">{{TEMA_TITLE}}</a><span class="sep">›</span>
          <span class="current">{{SLUG}}</span>
        </nav>

        <header class="wk-article-header">
          <div class="wk-eyebrow">{{TEMA_TITLE}}</div>
          <h1>{{TITLE}}</h1>
          {{LEAD_PARAGRAPH}}
          <div class="wk-meta-row">
            <span>{{DATE_HUMAN}}</span>
            <span class="dot">·</span>
            <span>{{READING_TIME}} min</span>
            {{TAGS_HTML}}
          </div>
        </header>

        {{CONTENT_HTML}}

        <footer class="wk-article-footer">
          <div class="tags">
            {{TAGS_FOOTER_HTML}}
          </div>
          <div class="meta">
            <span><span class="accent">{{DATE}}</span></span>
            <span>·</span>
            <span>{{MODELS_USED}}</span>
          </div>
        </footer>

      </template>

    </div>
  </main>
</div>

{{APPSHELL_HTML}}

</body>
</html>
