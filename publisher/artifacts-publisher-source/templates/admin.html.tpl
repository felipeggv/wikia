<!DOCTYPE html>
<html lang="pt-BR" data-wiki-base="{{WIKI_BASE}}">
<head>
{{HEAD_HTML}}
<style>
{{ADMIN_STYLES_CSS}}
</style>
</head>
<body data-sidebar="collapsed">

{{TOPBAR_HTML}}

<div class="wk-shell">
{{SIDEBAR_HTML}}
  <main class="wk-main admin-main">
    <div class="wk-content">
      <div id="admin-state" data-state="locked">

    <!-- LOCKED STATE -->
    <section class="admin-lock">
      <div class="admin-lock-card">
        <div class="admin-lock-badge">painel protegido</div>
        <h1 class="admin-lock-title">Acesso ao painel admin</h1>
        <p class="admin-lock-lead">Insira a masterpass para abrir o catálogo administrativo. A senha fica só nesta sessão do navegador.</p>
        <form id="admin-lock-form">
          <label for="masterpass">masterpass</label>
          <input type="password" id="masterpass" autocomplete="off" autofocus spellcheck="false">
          <button type="submit" id="unlock">Destravar painel</button>
          <div class="admin-lock-err" id="admin-lock-err"></div>
        </form>
        <div class="admin-lock-footnote">
          <div class="prompt">wikia · admin seguro</div>
          O catálogo só aparece depois do desbloqueio e não é salvo no navegador.
        </div>
      </div>
    </section>

    <!-- UNLOCKED STATE -->
    <section class="admin-unlocked">
      <div class="admin-grid">
        <aside class="admin-list">
          <div class="admin-list-header">
            <span class="admin-list-title">Artigos</span>
            <span class="admin-list-count" id="admin-list-count">—</span>
          </div>
          <div class="admin-list-tools">
            <div class="admin-filter-tabs" role="group" aria-label="Filtros de artigos">
              <button type="button" class="admin-filter is-active" data-filter="all">Todos</button>
              <button type="button" class="admin-filter" data-filter="released">Liberados</button>
              <button type="button" class="admin-filter" data-filter="pending">Pendentes</button>
              <button type="button" class="admin-filter" data-filter="missing-password">Sem senha</button>
            </div>
            <select id="admin-group-filter" class="admin-group-filter" aria-label="Filtrar por BU ou projeto">
              <option value="">Todas as BUs/projetos</option>
            </select>
          </div>
          <ul id="admin-articles"></ul>
        </aside>
        <section class="admin-actions" id="admin-actions">
          <div class="admin-actions-empty">selecione um artigo</div>
        </section>
      </div>
    </section>

      </div>
    </div>
  </main>
</div>

<div id="admin-toast" class="admin-toast" role="status" aria-live="polite"></div>

<script>
{{ADMIN_DECRYPT_JS}}
</script>

<script>
(function () {
  'use strict';

  // ---------- State ----------
  var WIKI_BASE = document.documentElement.dataset.wikiBase || '';
  var vault = null;          // password vault only; never defines article universe
  var adminMetadata = null;  // decrypted _admin.enc payload
  var adminArticles = [];    // normalized article records from encrypted admin metadata
  var released = [];          // read-only public release ledger used for status display
  var pending = {};           // _pending-changes.json intent queue only
  var selectedKey = null;
  var selectedSlug = null;
  var revealed = {};          // { articleKey: true }
  var vaultWarning = '';
  var activeFilter = 'all';
  var activeGroup = '';
  var BU_DISPLAY = {
    staging: 'Staging',
    vita: 'Vitascience',
    allin: 'AllIn',
    aleyemma: 'Aleyemma',
    gobbi: 'Gobbi'
  };
  var SCOPE_DISPLAY = {
    article: 'Artigo',
    project: 'Projeto',
    bu: 'BU',
    public: 'Publico',
    admin: 'Admin'
  };
  var ACRONYM_DISPLAY = {
    ai: 'AI',
    api: 'API',
    bu: 'BU',
    case: 'CASE',
    cms: 'CMS',
    crm: 'CRM',
    cs: 'CS',
    eli5: 'ELI5',
    html: 'HTML',
    id: 'ID',
    json: 'JSON',
    jwt: 'JWT',
    seo: 'SEO',
    ui: 'UI',
    url: 'URL',
    ux: 'UX'
  };
  var TITLE_STOPWORDS = {
    a: true,
    as: true,
    com: true,
    da: true,
    das: true,
    de: true,
    do: true,
    dos: true,
    e: true,
    em: true,
    na: true,
    nas: true,
    no: true,
    nos: true,
    o: true,
    os: true,
    para: true,
    por: true,
    que: true,
    sem: true
  };

  // ---------- DOM ----------
  var stateRoot = document.getElementById('admin-state');
  var form = document.getElementById('admin-lock-form');
  var input = document.getElementById('masterpass');
  var err = document.getElementById('admin-lock-err');
  var listEl = document.getElementById('admin-articles');
  var countEl = document.getElementById('admin-list-count');
  var actionsEl = document.getElementById('admin-actions');
  var toastEl = document.getElementById('admin-toast');
  var groupFilterEl = document.getElementById('admin-group-filter');
  var filterButtons = document.querySelectorAll ? document.querySelectorAll('[data-filter]') : [];

  // ---------- Helpers ----------
  function escapeHtml(s) {
    return String(s == null ? '' : s)
      .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;').replace(/'/g, '&#39;');
  }

  function toast(msg, kind) {
    toastEl.textContent = msg;
    toastEl.dataset.kind = kind || 'info';
    toastEl.classList.add('show');
    setTimeout(function () { toastEl.classList.remove('show'); }, 2400);
  }

  function enableGlobalSearchAfterUnlock() {
    var searchBtn = document.getElementById('wk-search-btn');
    if (!searchBtn) return;
    if (searchBtn.removeAttribute) searchBtn.removeAttribute('aria-disabled');
    if (searchBtn.setAttribute) searchBtn.setAttribute('title', 'Buscar (⌘K)');
  }

  // ---------- Network ----------
  async function fetchText(url) {
    var r = await fetch(url, { cache: 'no-store' });
    if (!r.ok) throw new Error('fetch failed: ' + url + ' (' + r.status + ')');
    return r.text();
  }

  async function fetchJsonOrDefault(url, fallback) {
    try {
      var r = await fetch(url, { cache: 'no-store' });
      if (!r.ok) return fallback;
      var txt = (await r.text()).trim();
      if (!txt) return fallback;
      return JSON.parse(txt);
    } catch (e) { return fallback; }
  }

  // ---------- Admin metadata ----------
  function compactUnique(items) {
    var out = [];
    var seen = {};
    for (var i = 0; i < items.length; i++) {
      var value = String(items[i] == null ? '' : items[i]).trim().replace(/^\/+|\/+$/g, '');
      if (!value || seen[value]) continue;
      seen[value] = true;
      out.push(value);
    }
    return out;
  }

  function titleWord(word, index) {
    var raw = String(word == null ? '' : word);
    if (!raw) return '';
    if (raw.indexOf('/') >= 0) {
      return raw.split('/').map(function (part) { return titleWord(part, index); }).join('/');
    }
    var match = raw.match(/^([^\p{L}\p{N}]*)([\p{L}\p{N}]+(?:'[\p{L}\p{N}]+)?)([^\p{L}\p{N}]*)$/u);
    if (!match) return raw;
    var prefix = match[1];
    var core = match[2];
    var suffix = match[3];
    var lower = core.toLowerCase();
    var rendered = ACRONYM_DISPLAY[lower]
      || (index > 0 && TITLE_STOPWORDS[lower]
        ? lower
        : lower.charAt(0).toUpperCase() + lower.slice(1));
    return prefix + rendered + suffix;
  }

  function titleizeText(value) {
    var raw = String(value == null ? '' : value).trim();
    if (!raw) return '';
    var text = raw.replace(/[-_]+/g, ' ').replace(/\s+/g, ' ');
    var words = text.split(' ');
    return words.map(titleWord).join(' ');
  }

  function displayToken(value, kind) {
    var token = String(value == null ? '' : value).trim();
    if (!token) return '';
    var lower = token.toLowerCase();
    if (kind === 'bu') return BU_DISPLAY[lower] || titleizeText(token);
    if (kind === 'scope') return SCOPE_DISPLAY[lower] || titleizeText(token);
    return titleizeText(token);
  }

  function displayTitleForArticle(article) {
    var raw = String(article && (article.title || article.title_public || '') || '').trim();
    if (!raw) raw = String(article && article.slug || '').replace(/-/g, ' ');
    if (!raw) return 'Artigo';
    return raw === raw.toLowerCase() ? titleizeText(raw) : raw;
  }

  function keyFromParts(article) {
    var bu = String(article.bu || '').trim();
    var project = String(article.project || article.tema || '').trim();
    var slug = String(article.slug || '').trim();
    return (bu && project && slug) ? [bu, project, slug].join('/') : slug;
  }

  function normalizeAdminArticles(payload) {
    var source = [];
    if (Array.isArray(payload)) source = payload;
    else if (payload && Array.isArray(payload.articles)) source = payload.articles;
    else if (payload && Array.isArray(payload.records)) source = payload.records;

    var normalized = [];
    for (var i = 0; i < source.length; i++) {
      var item = source[i] || {};
      var slug = String(item.slug || '').trim();
      if (!slug) continue;
      var article = Object.assign({}, item);
      article.bu = String(article.bu || '').trim();
      article.project = String(article.project || article.tema || '').trim();
      article.slug = slug;
      article.output_url = String(article.output_url || article.url || '').trim();
      article.key = String(article.key || article.article_key || keyFromParts(article)).trim();
      article.title = String(
        article.title
        || (article.title_visible && article.title_public ? article.title_public : '')
        || slug.replace(/-/g, ' ')
      );
      normalized.push(article);
    }
    return normalized;
  }

  function mergeAdminAndCatalogArticles(adminList, catalogPayload) {
    var merged = {};
    var out = [];

    function add(article, preferExisting) {
      var key = articleKey(article);
      if (!key) return;
      if (merged[key] && preferExisting) return;
      if (!merged[key]) out.push(article);
      merged[key] = article;
    }

    for (var i = 0; i < adminList.length; i++) {
      add(adminList[i], false);
    }

    var catalogList = normalizeAdminArticles(catalogPayload);
    for (var j = 0; j < catalogList.length; j++) {
      add(catalogList[j], true);
    }

    return out.map(function (article) {
      return merged[articleKey(article)] || article;
    });
  }

  function articleKey(article) {
    return String(article && (article.key || keyFromParts(article)) || '');
  }

  function articleByKey(key) {
    for (var i = 0; i < adminArticles.length; i++) {
      if (articleKey(adminArticles[i]) === key) return adminArticles[i];
    }
    return null;
  }

  function sortedAdminArticles() {
    return adminArticles.slice().sort(function (a, b) {
      var aa = [a.bu || '', a.project || '', a.slug || ''].join('/');
      var bb = [b.bu || '', b.project || '', b.slug || ''].join('/');
      return aa.localeCompare(bb);
    });
  }

  function vaultCandidates(article) {
    return compactUnique([
      article && article.slug,
      article && article.key,
      article && keyFromParts(article),
      article && article.output_url,
      article && article.article_id
    ]);
  }

  function getVaultEntry(article) {
    if (!vault || typeof vault !== 'object') return null;
    var candidates = vaultCandidates(article);
    for (var i = 0; i < candidates.length; i++) {
      if (Object.prototype.hasOwnProperty.call(vault, candidates[i])) {
        return { key: candidates[i], value: vault[candidates[i]] };
      }
    }
    return null;
  }

  function vaultKeyForArticle(article) {
    var found = getVaultEntry(article);
    return found ? found.key : String(article && article.slug || '');
  }

  function passwordInfoForArticle(article) {
    var found = getVaultEntry(article);
    if (!found) return { exists: false, password: '' };
    var entry = found.value;
    var password = (entry && typeof entry === 'object' && entry.password != null)
      ? entry.password
      : entry;
    return { exists: password != null && password !== '', password: String(password), key: found.key, entry: entry };
  }

  function metaTextForArticle(article) {
    var parts = compactUnique([
      displayToken(article.bu, 'bu'),
      displayToken(article.project || article.tema, 'project'),
      displayToken(article.scope, 'scope')
    ]);
    return parts.length ? parts.join(' / ') : '—';
  }

  function joinUrl(base, path) {
    return String(base || '').replace(/\/+$/, '') + '/' + String(path || '').replace(/^\/+/, '');
  }

  function articlePath(article) {
    var outputUrl = String(article && (article.output_url || article.url) || '').trim();
    if (!outputUrl && article && article.bu && (article.project || article.tema) && article.slug) {
      outputUrl = [article.bu, article.project || article.tema, article.slug].join('/') + '/';
    }
    return outputUrl.replace(/^\/+/, '');
  }

  function articleUrl(article) {
    var path = articlePath(article);
    if (/^https?:\/\//i.test(path)) return path;
    return joinUrl(WIKI_BASE, path);
  }

  function articleSessionStorageKey(article) {
    var bu = String(article && article.bu || 'wiki').trim() || 'wiki';
    return 'wikia-master-key-' + bu;
  }

  function storeArticlePasswordForNavigation(article) {
    var pwdInfo = passwordInfoForArticle(article);
    if (!pwdInfo.exists) return false;
    try {
      sessionStorage.setItem(articleSessionStorageKey(article), String(pwdInfo.password));
      return true;
    } catch (e) {
      return false;
    }
  }

  function releasedTokenFromItem(item) {
    if (typeof item === 'string') return item.replace(/^\/+|\/+$/g, '');
    if (!item || typeof item !== 'object') return '';
    if (item.bu && item.project && item.slug) return [item.bu, item.project, item.slug].join('/');
    if (item.url) return String(item.url).replace(/^\/+|\/+$/g, '');
    if (item.slug) return String(item.slug);
    return '';
  }

  function isArticleReleased(article) {
    if (String(article.release_status || '') === 'released') return true;
    var tokens = vaultCandidates(article);
    for (var i = 0; i < released.length; i++) {
      if (tokens.indexOf(releasedTokenFromItem(released[i])) >= 0) return true;
    }
    return false;
  }

  function releaseIntentToken(article) {
    return String(article.slug || articleKey(article));
  }

  function scopedArticleRef(article) {
    return {
      key: articleKey(article),
      article_id: String(article.article_id || ''),
      bu: String(article.bu || ''),
      project: String(article.project || article.tema || ''),
      slug: String(article.slug || ''),
      output_url: String(article.output_url || ''),
      current_scope: String(article.scope || 'article'),
      release_status: String(article.release_status || 'unreleased')
    };
  }

  function ensurePendingQueue() {
    var base = (pending && typeof pending === 'object' && !Array.isArray(pending)) ? pending : {};
    pending = Object.assign({}, base);
    pending.schema_version = pending.schema_version || 1;
    pending.release = Array.isArray(pending.release) ? pending.release : [];
    pending.rotate = Array.isArray(pending.rotate) ? pending.rotate : [];
    pending.remove = Array.isArray(pending.remove) ? pending.remove : [];
    pending.scope = Array.isArray(pending.scope) ? pending.scope : [];
    pending.intents = Array.isArray(pending.intents) ? pending.intents : [];
    return pending;
  }

  function intentArticleKey(intent) {
    if (typeof intent === 'string') return intent;
    if (!intent || typeof intent !== 'object') return '';
    if (intent.key) return String(intent.key);
    if (intent.bu && intent.project && intent.slug) return [intent.bu, intent.project, intent.slug].join('/');
    return String(intent.slug || '');
  }

  function removeQueuedArticleIntent(bucket, article) {
    var queue = ensurePendingQueue();
    var targetKey = articleKey(article);
    var targetSlug = releaseIntentToken(article);
    queue[bucket] = (queue[bucket] || []).filter(function (intent) {
      var key = intentArticleKey(intent);
      return key !== targetKey && key !== targetSlug;
    });
  }

  function rebuildIntentIndex() {
    var queue = ensurePendingQueue();
    var merged = [];
    ['release', 'rotate', 'remove', 'scope'].forEach(function (bucket) {
      (queue[bucket] || []).forEach(function (intent) {
        if (intent && typeof intent === 'object') merged.push(Object.assign({ action: bucket }, intent));
        else if (intent) merged.push({ action: bucket, slug: String(intent) });
      });
    });
    queue.intents = merged;
  }

  function queueScopedIntent(action, article, extra) {
    var queue = ensurePendingQueue();
    var ref = scopedArticleRef(article);
    var intent = Object.assign({}, ref, extra || {}, {
      queued_at: new Date().toISOString()
    });

    if (action === 'remove') {
      removeQueuedArticleIntent('release', article);
      removeQueuedArticleIntent('rotate', article);
      removeQueuedArticleIntent('scope', article);
    } else if (action === 'release') {
      removeQueuedArticleIntent('remove', article);
    } else if (action === 'scope') {
      removeQueuedArticleIntent('scope', article);
    } else if (action === 'rotate') {
      removeQueuedArticleIntent('rotate', article);
    }

    ensurePendingQueue()[action].push(intent);
    rebuildIntentIndex();
    return intent;
  }

  function queuedActionsForArticle(article) {
    var queue = ensurePendingQueue();
    var targetKey = articleKey(article);
    var targetSlug = releaseIntentToken(article);
    var labels = [];
    ['release', 'rotate', 'remove', 'scope'].forEach(function (bucket) {
      (queue[bucket] || []).forEach(function (intent) {
        var key = intentArticleKey(intent);
        if (key === targetKey || key === targetSlug) labels.push(bucket);
      });
    });
    return compactUnique(labels);
  }

  function actionLabel(action) {
    var labels = {
      release: 'liberação',
      rotate: 'rotação',
      remove: 'remoção',
      scope: 'escopo'
    };
    return labels[action] || action;
  }

  function groupValueForArticle(article, kind) {
    var bu = String(article && article.bu || '').trim();
    var project = String(article && (article.project || article.tema) || '').trim();
    if (kind === 'bu') return bu ? 'bu:' + bu : '';
    if (kind === 'project') return (bu && project) ? 'project:' + bu + '/' + project : '';
    return '';
  }

  function groupLabelForValue(value) {
    if (!value) return 'Todas as BUs/projetos';
    if (value.indexOf('bu:') === 0) return 'BU · ' + displayToken(value.slice(3), 'bu');
    if (value.indexOf('project:') === 0) {
      var parts = value.slice(8).split('/');
      return [displayToken(parts[0], 'bu'), displayToken(parts[1], 'project')].filter(Boolean).join(' / ');
    }
    return value;
  }

  function renderGroupFilter() {
    if (!groupFilterEl) return;
    var articles = sortedAdminArticles();
    var seen = {};
    var values = [];
    articles.forEach(function (article) {
      [groupValueForArticle(article, 'bu'), groupValueForArticle(article, 'project')].forEach(function (value) {
        if (value && !seen[value]) {
          seen[value] = true;
          values.push(value);
        }
      });
    });

    values.sort(function (a, b) { return groupLabelForValue(a).localeCompare(groupLabelForValue(b)); });
    if (activeGroup && !seen[activeGroup]) activeGroup = '';
    groupFilterEl.innerHTML = '<option value="">Todas as BUs/projetos</option>' + values.map(function (value) {
      return '<option value="' + escapeHtml(value) + '">' + escapeHtml(groupLabelForValue(value)) + '</option>';
    }).join('');
    groupFilterEl.value = activeGroup;
  }

  function renderFilterControls() {
    Array.prototype.forEach.call(filterButtons, function (btn) {
      var isActive = btn.dataset && btn.dataset.filter === activeFilter;
      btn.classList.toggle('is-active', !!isActive);
    });
  }

  function setViewState(nextFilter, nextGroup) {
    if (nextFilter) activeFilter = nextFilter;
    if (typeof nextGroup === 'string') activeGroup = nextGroup;
    renderGroupFilter();
    renderFilterControls();
    renderList();
    if (selectedKey) {
      var article = articleByKey(selectedKey);
      if (article) renderSelectedArticle(article);
    }
    return filteredAdminArticles().map(articleKey);
  }

  function articleMatchesGroup(article) {
    if (!activeGroup) return true;
    if (activeGroup.indexOf('bu:') === 0) return groupValueForArticle(article, 'bu') === activeGroup;
    if (activeGroup.indexOf('project:') === 0) return groupValueForArticle(article, 'project') === activeGroup;
    return true;
  }

  function articleMatchesFilter(article) {
    if (!articleMatchesGroup(article)) return false;
    var pwdInfo = passwordInfoForArticle(article);
    var queuedActions = queuedActionsForArticle(article);
    if (activeFilter === 'released') return isArticleReleased(article);
    if (activeFilter === 'pending') return queuedActions.length > 0;
    if (activeFilter === 'missing-password') return !pwdInfo.exists;
    return true;
  }

  function filteredAdminArticles() {
    return sortedAdminArticles().filter(articleMatchesFilter);
  }

  function statusBadgesForArticle(article, pwdInfo, queuedActions) {
    var badges = [];
    if (String(article.release_status || '') === 'removed') {
      badges.push('<span class="admin-badge admin-badge-removed">removido</span>');
    } else if (isArticleReleased(article)) {
      badges.push('<span class="admin-badge admin-badge-released">liberado</span>');
    } else {
      badges.push('<span class="admin-badge admin-badge-muted">restrito</span>');
    }

    if (queuedActions.length) {
      badges.push('<span class="admin-badge admin-badge-pending">pendente: '
        + escapeHtml(queuedActions.map(actionLabel).join(', ')) + '</span>');
    }

    if (pwdInfo.exists) {
      badges.push('<span class="admin-badge admin-badge-password">senha vinculada</span>');
    } else {
      badges.push('<span class="admin-badge admin-badge-risk">sem senha</span>');
    }

    return badges.join('');
  }

  // ---------- Unlock flow ----------
  async function unlock(masterpass) {
    err.textContent = '';
    if (!masterpass) { err.textContent = 'Digite a masterpass.'; return false; }
    try {
      var adminB64 = '';
      try {
        adminB64 = (await fetchText(WIKI_BASE + '/_admin.enc')).trim();
      } catch (fetchErr) {
        err.textContent = 'Não foi possível carregar o catálogo admin.';
        return false;
      }

      try {
        adminMetadata = await window.WikiaVault.decryptVault(adminB64, masterpass);
      } catch (decryptErr) {
        err.textContent = 'Não foi possível abrir o catálogo admin. Confira a masterpass.';
        return false;
      }

      var catalogMetadata = await fetchJsonOrDefault(WIKI_BASE + '/_catalog.json', null);
      adminArticles = mergeAdminAndCatalogArticles(normalizeAdminArticles(adminMetadata), catalogMetadata);
      if (!adminArticles.length) {
        err.textContent = 'Catálogo admin aberto, mas sem artigos.';
        return false;
      }

      try {
        var vaultB64 = (await fetchText(WIKI_BASE + '/_passwords.enc')).trim();
        var plain = await window.WikiaVault.decryptVault(vaultB64, masterpass);
        vault = (plain && typeof plain === 'object') ? plain : {};
        vaultWarning = '';
      } catch (vaultErr) {
        vault = {};
        vaultWarning = 'Catálogo aberto, mas senhas indisponíveis.';
        toast(vaultWarning, 'warning');
      }
      released = await fetchJsonOrDefault(WIKI_BASE + '/_released.json', []);
      pending = await fetchJsonOrDefault(WIKI_BASE + '/_pending-changes.json', {});
      stateRoot.dataset.state = 'unlocked';
      enableGlobalSearchAfterUnlock();
      renderGroupFilter();
      renderList();
      return true;
    } catch (e) {
      err.textContent = 'Não foi possível abrir o painel admin.';
      vault = null; adminMetadata = null; adminArticles = [];
      return false;
    }
  }

  // ---------- List ----------
  function renderList() {
    renderFilterControls();
    var allArticles = sortedAdminArticles();
    var articles = filteredAdminArticles();
    var totalText = allArticles.length + (allArticles.length === 1 ? ' artigo' : ' artigos');
    countEl.textContent = articles.length === allArticles.length
      ? totalText
      : articles.length + ' de ' + totalText;

    if (!allArticles.length) {
      listEl.innerHTML = '<li class="admin-empty">metadata admin vazia</li>';
      return;
    }
    if (!articles.length) {
      listEl.innerHTML = '<li class="admin-empty">nenhum artigo neste filtro</li>';
      return;
    }
    var html = '';
    for (var i = 0; i < articles.length; i++) {
      var article = articles[i];
      var key = articleKey(article);
      var slug = article.slug;
      var metaText = metaTextForArticle(article);
      var pwdInfo = passwordInfoForArticle(article);
      var isCurrent = selectedKey === key;
      var queuedActions = queuedActionsForArticle(article);
      var badges = statusBadgesForArticle(article, pwdInfo, queuedActions);
      var title = displayTitleForArticle(article);

      html += '<li class="admin-row ' + (isCurrent ? 'current' : '') + '" data-key="' + escapeHtml(key) + '" data-slug="' + escapeHtml(slug) + '" role="button" tabindex="0">'
        + '  <div class="admin-row-main">'
        + '    <div class="admin-row-slug">' + escapeHtml(title) + '</div>'
        + '    <div class="admin-row-tema">' + escapeHtml(metaText) + '</div>'
        + '  </div>'
        + '  <div class="admin-row-status">'
        +      badges
        + '    <button class="btn btn-secondary admin-row-open" type="button" data-action="open-article" data-key="' + escapeHtml(key) + '">Abrir</button>'
        + '  </div>'
        + '</li>';
    }
    if (vaultWarning) {
      html += '<li class="admin-empty">' + escapeHtml(vaultWarning) + '</li>';
    }
    listEl.innerHTML = html;
  }

  function renderSelectedArticle(article) {
    var pwdInfo = passwordInfoForArticle(article);
    var key = articleKey(article);
    var isRevealed = !!revealed[key];
    var pwd = !pwdInfo.exists ? 'sem senha vinculada' : (isRevealed ? pwdInfo.password : '••••••••••••');
    var metaText = metaTextForArticle(article);
    var title = displayTitleForArticle(article);
    var url = articleUrl(article);
    var queuedActions = queuedActionsForArticle(article);
    var copyDisabled = pwdInfo.exists ? '' : ' disabled';
    var revealDisabled = pwdInfo.exists ? '' : ' disabled';
    var releaseDisabled = isArticleReleased(article) ? 'disabled' : '';

    actionsEl.innerHTML = ''
      + '<div class="admin-actions-header">'
      + '  <div class="admin-actions-slug">' + escapeHtml(title) + '</div>'
      + '  <div class="admin-actions-tema">' + escapeHtml(metaText) + '</div>'
      + '  <div class="admin-actions-badges">' + statusBadgesForArticle(article, pwdInfo, queuedActions) + '</div>'
      + '  <div class="admin-actions-link">'
      + '    <button class="btn admin-open-primary" type="button" data-action="open-article" data-key="' + escapeHtml(key) + '">Abrir artigo</button>'
      + '    <span>' + escapeHtml(url) + '</span>'
      + '  </div>'
      + '</div>'
      + '<div class="admin-sensitive">'
      + '  <div class="admin-sensitive-label">Senha</div>'
      + '  <div class="admin-actions-pwd"><code data-sensitive="' + (isRevealed ? 'visible' : 'masked') + '">' + escapeHtml(pwd) + '</code></div>'
      + '  <div class="admin-actions-buttons admin-sensitive-controls">'
      + '    <button class="btn btn-secondary" data-action="toggle" data-key="' + escapeHtml(key) + '"' + revealDisabled + '>' + (isRevealed ? 'Ocultar senha' : 'Mostrar senha') + '</button>'
      + '    <button class="btn btn-secondary" data-action="copy" data-key="' + escapeHtml(key) + '"' + copyDisabled + '>Copiar senha</button>'
      + '  </div>'
      + '</div>'
      + '<p class="admin-actions-hint">O catálogo abre a lista; o cofre só anexa senhas quando houver correspondência.</p>'
      + '<div class="admin-actions-buttons">'
      + '  <button class="btn" data-action="release" data-key="' + escapeHtml(key) + '" ' + releaseDisabled + '>Liberar</button>'
      + '  <button class="btn" data-action="rotate" data-key="' + escapeHtml(key) + '">Rotacionar senha</button>'
      + '  <button class="btn btn-secondary" data-action="remove" data-key="' + escapeHtml(key) + '">Remover</button>'
      + '</div>'
      + '<div class="admin-actions-buttons">'
      + '  <button class="btn btn-secondary" data-action="scope-article" data-key="' + escapeHtml(key) + '">Escopo artigo</button>'
      + '  <button class="btn btn-secondary" data-action="scope-project" data-key="' + escapeHtml(key) + '">Escopo projeto</button>'
      + '  <button class="btn btn-secondary" data-action="scope-bu" data-key="' + escapeHtml(key) + '">Escopo BU</button>'
      + '</div>';
  }

  function openArticle(key) {
    var article = articleByKey(key);
    if (!article) { toast('artigo não encontrado no metadata admin', 'error'); return null; }
    var url = articleUrl(article);
    var pwdInfo = passwordInfoForArticle(article);
    var stored = storeArticlePasswordForNavigation(article);
    if (pwdInfo.exists && !stored) {
      toast('não consegui salvar a senha nesta sessão; o artigo pode pedir senha', 'warning');
    } else if (!pwdInfo.exists && String(article.gate_status || '') !== 'public') {
      toast('sem senha vinculada; abrindo, mas o artigo pode pedir senha', 'warning');
    }
    if (window.location && typeof window.location.assign === 'function') window.location.assign(url);
    else window.location.href = url;
    return { url: url, passwordStored: stored };
  }

  function selectArticle(key) {
    var article = articleByKey(key);
    if (!article) { toast('artigo não encontrado no metadata admin', 'error'); return; }
    selectedKey = key;
    selectedSlug = article.slug;
    renderList();
    renderSelectedArticle(article);
  }

  // ---------- Mutations ----------
  function togglePasswordVisibility(key) {
    revealed[key] = !revealed[key];
    renderList();
    if (selectedKey === key) {
      var article = articleByKey(key);
      if (article) renderSelectedArticle(article);
    }
  }

  async function copyPassword(key) {
    var article = articleByKey(key);
    var pwdInfo = article ? passwordInfoForArticle(article) : { exists: false };
    if (!pwdInfo.exists) { toast('sem senha no vault', 'warning'); return; }
    try {
      await navigator.clipboard.writeText(String(pwdInfo.password));
      toast('senha de ' + article.slug + ' copiada', 'success');
    } catch (e) {
      toast('clipboard bloqueada — selecione manualmente', 'warning');
    }
  }

  async function releaseArticle(key) {
    var article = articleByKey(key);
    if (!article) { toast('artigo não encontrado no metadata admin', 'error'); return; }
    if (isArticleReleased(article)) { toast('já liberado', 'info'); return; }
    if (!confirm('Enfileirar liberação de "' + article.slug + '"? O artigo só muda no próximo apply/rebuild.')) return;
    queueScopedIntent('release', article, { target_release_status: 'released' });
    await renderPendingPanel('release', article);
    renderList();
  }

  async function rotatePassword(key) {
    var article = articleByKey(key);
    if (!article) { toast('artigo não encontrado no metadata admin', 'error'); return; }
    if (!confirm('Enfileirar rotação de senha de "' + article.slug + '"? A senha nova será gerada pelo apply/rebuild, não pelo browser.')) return;
    queueScopedIntent('rotate', article, { vault_key: vaultKeyForArticle(article) });
    selectedKey = articleKey(article);
    selectedSlug = article.slug;
    await renderPendingPanel('rotate', article);
    renderList();
  }

  async function removeArticle(key) {
    var article = articleByKey(key);
    if (!article) { toast('artigo não encontrado no metadata admin', 'error'); return; }
    if (!confirm('Enfileirar remoção de "' + article.slug + '"? Nada será apagado no browser.')) return;
    queueScopedIntent('remove', article, { target_release_status: 'removed' });
    selectedKey = articleKey(article);
    selectedSlug = article.slug;
    await renderPendingPanel('remove', article);
    renderList();
  }

  async function changeArticleScope(key, targetScope) {
    var article = articleByKey(key);
    if (!article) { toast('artigo não encontrado no metadata admin', 'error'); return; }
    var allowed = { article: true, project: true, bu: true };
    if (!allowed[targetScope]) { toast('escopo inválido', 'error'); return; }
    if (String(article.scope || 'article') === targetScope) {
      toast('artigo já está nesse escopo', 'info');
      return;
    }
    if (!confirm('Enfileirar mudança de escopo de "' + article.slug + '" para "' + targetScope + '"?')) return;
    queueScopedIntent('scope', article, {
      from_scope: String(article.scope || 'article'),
      to_scope: targetScope
    });
    selectedKey = articleKey(article);
    selectedSlug = article.slug;
    await renderPendingPanel('scope-' + targetScope, article);
    renderList();
  }

  // ---------- Pending panel ----------
  async function renderPendingPanel(kind, article) {
    ensurePendingQueue();
    var pendingJson = JSON.stringify(pending, null, 2);
    var slug = article ? article.slug : '';

    var msg = '';
    if (kind === 'release') msg = 'admin: release ' + (slug || '');
    else if (kind === 'rotate') msg = 'admin: rotate ' + (slug || '');
    else if (kind === 'remove') msg = 'admin: remove ' + (slug || '');
    else if (String(kind || '').indexOf('scope-') === 0) msg = 'admin: ' + kind + ' ' + (slug || '');
    else msg = 'admin: pending changes';

    actionsEl.innerHTML = ''
      + '<div class="admin-actions-header">'
      + '  <div class="admin-actions-slug">' + escapeHtml(slug || 'pending') + '</div>'
      + '  <div class="admin-actions-tema">' + escapeHtml(msg) + '</div>'
      + '</div>'
      + '<details open class="admin-pending-json"><summary>_pending-changes.json</summary><textarea readonly id="admin-pending-json">' + escapeHtml(pendingJson) + '</textarea></details>'
      + '<div class="admin-actions-buttons">'
      + '  <button class="btn" data-action="copy-pending-json">Copiar JSON pendente</button>'
      + '  <button class="btn btn-secondary" data-action="back-to-article" data-key="' + escapeHtml(article ? articleKey(article) : selectedKey || '') + '">Voltar ao artigo</button>'
      + '</div>'
      + '<p class="admin-actions-hint">Modo seguro: o browser só gera intenção pendente para docs/gitpages/_pending-changes.json. O apply/rebuild decide a mutação real.</p>';
  }

  // ---------- Event wiring ----------
  form.addEventListener('submit', async function (e) {
    e.preventDefault();
    var ok = await unlock(input.value);
    if (!ok) { input.value = ''; input.focus(); }
  });

  Array.prototype.forEach.call(filterButtons, function (btn) {
    btn.addEventListener('click', function () {
      setViewState(btn.dataset.filter || 'all');
    });
  });

  if (groupFilterEl) {
    groupFilterEl.addEventListener('change', function () {
      setViewState(activeFilter, groupFilterEl.value || '');
    });
  }

  listEl.addEventListener('click', function (e) {
    var row = e.target.closest('.admin-row');
    var btn = e.target.closest('[data-action]');
    if (btn) {
      var action = btn.dataset.action;
      var key = btn.dataset.key || btn.dataset.slug;
      if (action === 'toggle') return togglePasswordVisibility(key);
      if (action === 'copy') return copyPassword(key);
      if (action === 'release') return releaseArticle(key);
      if (action === 'rotate') return rotatePassword(key);
      if (action === 'remove') return removeArticle(key);
      if (action === 'open-article') return openArticle(key);
    }
    if (row && row.dataset.key) selectArticle(row.dataset.key);
  });

  listEl.addEventListener('keydown', function (e) {
    if (e.key !== 'Enter' && e.key !== ' ') return;
    var row = e.target.closest('.admin-row');
    if (!row || !row.dataset.key) return;
    e.preventDefault();
    selectArticle(row.dataset.key);
  });

  actionsEl.addEventListener('click', async function (e) {
    var btn = e.target.closest('[data-action]');
    if (!btn) return;
    var action = btn.dataset.action;
    var key = btn.dataset.key || selectedKey;
    if (action === 'toggle') return togglePasswordVisibility(key);
    if (action === 'copy') return copyPassword(key);
    if (action === 'release') return releaseArticle(key);
    if (action === 'rotate') return rotatePassword(key);
    if (action === 'remove') return removeArticle(key);
    if (action === 'open-article') return openArticle(key);
    if (action === 'scope-article') return changeArticleScope(key, 'article');
    if (action === 'scope-project') return changeArticleScope(key, 'project');
    if (action === 'scope-bu') return changeArticleScope(key, 'bu');
    if (action === 'back-to-article') return selectArticle(key);
    if (action === 'copy-pending-json') {
      var ta = document.getElementById('admin-pending-json');
      if (!ta) return;
      try {
        await navigator.clipboard.writeText(ta.value);
        toast('JSON pendente copiado', 'success');
      } catch (err) {
        ta.select();
        toast('selecionado — Cmd+C', 'info');
      }
    }
  });

  // Expose for debugging / Playwright assertions
  window.__admin = {
    unlock: unlock,
    normalizeAdminArticles: normalizeAdminArticles,
    mergeAdminAndCatalogArticles: mergeAdminAndCatalogArticles,
    displayTitleForArticle: displayTitleForArticle,
    articleUrl: articleUrl,
    articleSessionStorageKey: articleSessionStorageKey,
    storeArticlePasswordForNavigation: storeArticlePasswordForNavigation,
    openArticle: openArticle,
    renderList: renderList,
    setViewState: setViewState,
    filteredArticleKeys: function () { return filteredAdminArticles().map(articleKey); },
    selectArticle: selectArticle,
    togglePasswordVisibility: togglePasswordVisibility,
    copyPassword: copyPassword,
    releaseArticle: releaseArticle,
    rotatePassword: rotatePassword,
    removeArticle: removeArticle,
    changeArticleScope: changeArticleScope,
    queueScopedIntent: queueScopedIntent,
    state: function () {
      return {
        vault: vault,
        adminMetadata: adminMetadata,
        adminArticles: adminArticles,
        released: released,
        pending: pending,
        activeFilter: activeFilter,
        activeGroup: activeGroup,
        selectedKey: selectedKey,
        selectedSlug: selectedSlug
      };
    }
  };
})();
</script>

{{APPSHELL_HTML}}

</body>
</html>
