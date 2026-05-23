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
        <div class="admin-lock-badge">admin · masterpass</div>
        <h1 class="admin-lock-title">Acesso ao painel admin</h1>
        <p class="admin-lock-lead">Insira a masterpass para destravar lista de artigos, senhas e ações administrativas. A masterpass nunca persiste no browser.</p>
        <form id="admin-lock-form">
          <label for="masterpass">masterpass</label>
          <input type="password" id="masterpass" autocomplete="off" autofocus spellcheck="false">
          <button type="submit" id="unlock">› Destravar Admin</button>
          <div class="admin-lock-err" id="admin-lock-err"></div>
        </form>
        <div class="admin-lock-footnote">
          <div class="prompt">wikia · admin · aes-256-gcm · pbkdf2 100k</div>
          A masterpass derruba o gate de TODOS os artigos via vault decifrado in-memory.
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

  // ---------- DOM ----------
  var stateRoot = document.getElementById('admin-state');
  var form = document.getElementById('admin-lock-form');
  var input = document.getElementById('masterpass');
  var err = document.getElementById('admin-lock-err');
  var listEl = document.getElementById('admin-articles');
  var countEl = document.getElementById('admin-list-count');
  var actionsEl = document.getElementById('admin-actions');
  var toastEl = document.getElementById('admin-toast');

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
    var parts = compactUnique([article.bu, article.project || article.tema, article.scope]);
    return parts.length ? parts.join(' / ') : '—';
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
    return labels;
  }

  // ---------- Unlock flow ----------
  async function unlock(masterpass) {
    err.textContent = '';
    if (!masterpass) { err.textContent = 'masterpass vazia'; return false; }
    try {
      var adminB64 = (await fetchText(WIKI_BASE + '/_admin.enc')).trim();
      adminMetadata = await window.WikiaVault.decryptVault(adminB64, masterpass);
      adminArticles = normalizeAdminArticles(adminMetadata);
      if (!adminArticles.length) throw new Error('_admin.enc sem artigos');

      try {
        var vaultB64 = (await fetchText(WIKI_BASE + '/_passwords.enc')).trim();
        var plain = await window.WikiaVault.decryptVault(vaultB64, masterpass);
        vault = (plain && typeof plain === 'object') ? plain : {};
        vaultWarning = '';
      } catch (vaultErr) {
        vault = {};
        vaultWarning = vaultErr.message || 'vault indisponível';
      }
      released = await fetchJsonOrDefault(WIKI_BASE + '/_released.json', []);
      pending = await fetchJsonOrDefault(WIKI_BASE + '/_pending-changes.json', {});
      stateRoot.dataset.state = 'unlocked';
      enableGlobalSearchAfterUnlock();
      renderList();
      return true;
    } catch (e) {
      err.textContent = '✗ masterpass incorreta ou metadata admin inválida';
      vault = null; adminMetadata = null; adminArticles = [];
      return false;
    }
  }

  // ---------- List ----------
  function renderList() {
    var articles = sortedAdminArticles();
    countEl.textContent = articles.length + (articles.length === 1 ? ' artigo' : ' artigos');
    if (!articles.length) {
      listEl.innerHTML = '<li class="admin-empty">metadata admin vazia</li>';
      return;
    }
    var html = '';
    for (var i = 0; i < articles.length; i++) {
      var article = articles[i];
      var key = articleKey(article);
      var slug = article.slug;
      var metaText = metaTextForArticle(article);
      var pwdInfo = passwordInfoForArticle(article);
      var isReleased = isArticleReleased(article);
      var isCurrent = selectedKey === key;
      var isRevealed = !!revealed[key];
      var queuedActions = queuedActionsForArticle(article);
      var pwdMasked = !pwdInfo.exists ? 'sem senha no vault' : (isRevealed ? escapeHtml(pwdInfo.password) : '••••••••');
      var releasedBadge = isReleased ? '<span class="admin-row-released">liberado</span>' : '';
      var pendingBadge = queuedActions.length ? '<span class="admin-row-released">pendente: ' + escapeHtml(queuedActions.join(', ')) + '</span>' : '';
      var title = article.title || slug;
      var copyDisabled = pwdInfo.exists ? '' : ' disabled';

      html += '<li class="admin-row ' + (isCurrent ? 'current' : '') + '" data-key="' + escapeHtml(key) + '" data-slug="' + escapeHtml(slug) + '">'
        + '  <div class="admin-row-main">'
        + '    <div class="admin-row-slug">' + escapeHtml(title) + releasedBadge + pendingBadge + '</div>'
        + '    <div class="admin-row-tema">' + escapeHtml(metaText) + '</div>'
        + '  </div>'
        + '  <div class="admin-row-pwd">'
        + '    <code class="pwd" data-key="' + escapeHtml(key) + '">' + pwdMasked + '</code>'
        + '    <button class="iconbtn" data-action="toggle" data-key="' + escapeHtml(key) + '" title="Mostrar/ocultar senha"' + copyDisabled + '>'
        + '      ' + (isRevealed ? '🙈' : '👁')
        + '    </button>'
        + '    <button class="iconbtn" data-action="copy" data-key="' + escapeHtml(key) + '" title="Copiar senha"' + copyDisabled + '>⎘</button>'
        + '  </div>'
        + '  <div class="admin-row-actions">'
        + '    <button class="btn" data-action="release" data-key="' + escapeHtml(key) + '" ' + (isReleased ? 'disabled' : '') + '>Liberar</button>'
        + '    <button class="btn" data-action="rotate" data-key="' + escapeHtml(key) + '">Rotacionar senha</button>'
        + '    <button class="btn btn-secondary" data-action="remove" data-key="' + escapeHtml(key) + '">Remover</button>'
        + '  </div>'
        + '</li>';
    }
    if (vaultWarning) {
      html += '<li class="admin-empty">senhas indisponíveis: ' + escapeHtml(vaultWarning) + '</li>';
    }
    listEl.innerHTML = html;
  }

  function selectArticle(key) {
    var article = articleByKey(key);
    if (!article) { toast('artigo não encontrado no metadata admin', 'error'); return; }
    selectedKey = key;
    selectedSlug = article.slug;
    renderList();
    var pwdInfo = passwordInfoForArticle(article);
    var pwd = pwdInfo.exists ? pwdInfo.password : 'sem senha vinculada';
    var metaText = metaTextForArticle(article);
    var title = article.title || article.slug;
    actionsEl.innerHTML = ''
      + '<div class="admin-actions-header">'
      + '  <div class="admin-actions-slug">' + escapeHtml(title) + '</div>'
      + '  <div class="admin-actions-tema">' + escapeHtml(metaText) + '</div>'
      + '</div>'
      + '<div class="admin-actions-pwd"><code>' + escapeHtml(pwd) + '</code></div>'
      + '<p class="admin-actions-hint">A lista vem de _admin.enc; _passwords.enc só anexa senhas quando houver correspondência.</p>'
      + '<div class="admin-actions-buttons">'
      + '  <button class="btn" data-action="release" data-key="' + escapeHtml(key) + '" ' + (isArticleReleased(article) ? 'disabled' : '') + '>Liberar</button>'
      + '  <button class="btn" data-action="rotate" data-key="' + escapeHtml(key) + '">Rotacionar senha</button>'
      + '  <button class="btn btn-secondary" data-action="remove" data-key="' + escapeHtml(key) + '">Remover</button>'
      + '</div>'
      + '<div class="admin-actions-buttons">'
      + '  <button class="btn btn-secondary" data-action="scope-article" data-key="' + escapeHtml(key) + '">Escopo artigo</button>'
      + '  <button class="btn btn-secondary" data-action="scope-project" data-key="' + escapeHtml(key) + '">Escopo projeto</button>'
      + '  <button class="btn btn-secondary" data-action="scope-bu" data-key="' + escapeHtml(key) + '">Escopo BU</button>'
      + '</div>';
  }

  // ---------- Mutations ----------
  function togglePasswordVisibility(key) {
    revealed[key] = !revealed[key];
    renderList();
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

  // ---------- Pending panel (copy-paste commit) ----------
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

    var script = ''
      + 'cd /tmp/wikia-clone && \\\n'
      + "cat > docs/gitpages/_pending-changes.json <<'WIKIA_PENDING_JSON'\n"
      + pendingJson + "\n"
      + "WIKIA_PENDING_JSON\n"
      + "git add docs/gitpages/_pending-changes.json && \\\n"
      + "git commit -m '" + msg + "' && git push";

    actionsEl.innerHTML = ''
      + '<div class="admin-actions-header">'
      + '  <div class="admin-actions-slug">' + escapeHtml(slug || 'pending') + '</div>'
      + '  <div class="admin-actions-tema">' + escapeHtml(msg) + '</div>'
      + '</div>'
      + '<details open><summary>_pending-changes.json</summary><textarea readonly>' + escapeHtml(pendingJson) + '</textarea></details>'
      + '<details open><summary>commit script (copy + paste)</summary><textarea readonly id="admin-commit-script">' + escapeHtml(script) + '</textarea></details>'
      + '<div class="admin-actions-buttons">'
      + '  <button class="btn" data-action="copy-commit-script">Copy commit script</button>'
      + '</div>'
      + '<p class="admin-actions-hint">Modo seguro: o browser só grava intenção pendente. O apply/rebuild decide a mutação real.</p>';
  }

  // ---------- Event wiring ----------
  form.addEventListener('submit', async function (e) {
    e.preventDefault();
    var ok = await unlock(input.value);
    if (!ok) { input.value = ''; input.focus(); }
  });

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
    }
    if (row && row.dataset.key) selectArticle(row.dataset.key);
  });

  actionsEl.addEventListener('click', async function (e) {
    var btn = e.target.closest('[data-action]');
    if (!btn) return;
    var action = btn.dataset.action;
    var key = btn.dataset.key || selectedKey;
    if (action === 'release') return releaseArticle(key);
    if (action === 'rotate') return rotatePassword(key);
    if (action === 'remove') return removeArticle(key);
    if (action === 'scope-article') return changeArticleScope(key, 'article');
    if (action === 'scope-project') return changeArticleScope(key, 'project');
    if (action === 'scope-bu') return changeArticleScope(key, 'bu');
    if (action === 'copy-commit-script') {
      var ta = document.getElementById('admin-commit-script');
      if (!ta) return;
      try {
        await navigator.clipboard.writeText(ta.value);
        toast('commit script copiado', 'success');
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
    renderList: renderList,
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
