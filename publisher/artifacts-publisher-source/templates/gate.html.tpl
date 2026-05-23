<div class="ap-gate-wrap">
  <div id="ap-gate">
    <div class="ap-gate-card">
      <div class="ap-gate-badge">protected · wikia</div>
      <h1 class="ap-gate-title">Acesso ao wiki</h1>
      <p class="ap-gate-lead">Conteúdo criptografado AES-256-GCM. Senha única do wiki destrava todos os artigos nesta sessão.</p>
      <form id="ap-gate-form">
        <label for="ap-gate-input">senha</label>
        <input type="password" id="ap-gate-input" autocomplete="off" autofocus spellcheck="false">
        <button type="submit">› DESTRAVAR WIKI</button>
        <div class="ap-gate-err" id="ap-gate-err"></div>
      </form>
      <div class="ap-gate-footnote">
        <div class="prompt">wikia · aes-256-gcm · pbkdf2 100k</div>
        Sua senha fica disponível apenas nesta aba/sessão. Feche a aba para deslogar.
      </div>
    </div>
  </div>

  <div id="ap-content-mount" style="display:none"></div>
</div>

<style>
  .ap-gate-wrap { display: block; width: 100%; }
  #ap-gate { display:flex; align-items:center; justify-content:center; padding: var(--s-7) var(--s-5); background: radial-gradient(ellipse at center, rgba(91,103,91,0.06) 0%, transparent 60%); }
  .ap-gate-card { background: var(--bg-sidebar); border: 1px solid var(--border); border-radius: 8px; padding: var(--s-7) var(--s-6); max-width: 420px; width: 100%; box-shadow: 0 24px 60px rgba(0,0,0,0.4); }
  .ap-gate-badge { display:inline-block; padding: 3px 10px; background: var(--accent-dim); color: var(--text-dim); font-size: 10px; font-weight: 600; letter-spacing: 0.14em; text-transform: uppercase; border: 1px solid var(--border); border-radius: 999px; margin-bottom: var(--s-4); font-family: var(--font); }
  .ap-gate-title { font-family: var(--font); font-weight: 600; font-size: 1.5em; color: var(--text-main); margin: 0 0 var(--s-2); line-height: 1.3; }
  .ap-gate-lead { color: var(--text-dim); font-size: 13px; margin: 0 0 var(--s-5); line-height: 1.6; }
  .ap-gate-card label { display:block; color: var(--text-dim); font-size: 10px; font-weight: 600; letter-spacing: 0.1em; text-transform: uppercase; margin-bottom: 6px; font-family: var(--font); }
  #ap-gate-input { width:100%; padding: 10px 12px; background: var(--bg-main); border: 1px solid var(--border); border-radius: 4px; color: var(--text-main); font: inherit; font-size: 14px; outline: none; transition: border-color 0.15s; }
  #ap-gate-input:focus { border-color: var(--accent); }
  .ap-gate-card button { width:100%; margin-top: var(--s-3); padding: 10px; background: var(--accent); color: var(--accent-text); border: 1px solid var(--accent); border-radius: 4px; font: inherit; font-weight: 600; cursor: pointer; letter-spacing: 0.06em; font-family: var(--font); transition: background 0.15s; font-size: 12px; }
  .ap-gate-card button:hover { background: #6d796d; }
  .ap-gate-err { color: var(--error); font-size: 12px; margin-top: var(--s-3); min-height: 1.2em; }
  .ap-gate-footnote { margin-top: var(--s-5); padding-top: var(--s-4); border-top: 1px solid var(--border); color: var(--text-dim); font-size: 10px; line-height: 1.6; }
  .ap-gate-footnote .prompt::before { content: "$ "; color: var(--accent); }
</style>

<script id="ap-gate-script">
(function() {
  const ENCRYPTED_PAYLOAD = "{{ENCRYPTED_PAYLOAD}}";
  const SALT_B64 = "{{SALT}}";
  const IV_B64 = "{{IV}}";
  // KEY de sessionStorage é POR BU — senha de uma BU não destrava outra (isolamento multi-tenant).
  // {{BU_SLUG}} é injetado pelo render-artifact ao gerar o HTML. Default cai em "wiki" pra páginas
  // que ainda não passam BU explícita (compat). Para gate de artefato, sempre tem BU.
  const STORAGE_KEY = "wikia-master-key-{{BU_SLUG}}";

  const gate = document.getElementById('ap-gate');
  const mount = document.getElementById('ap-content-mount');
  const form = document.getElementById('ap-gate-form');
  const input = document.getElementById('ap-gate-input');
  const err = document.getElementById('ap-gate-err');

  function b64(s) { const b = atob(s); const o = new Uint8Array(b.length); for (let i=0;i<b.length;i++) o[i] = b.charCodeAt(i); return o; }

  async function deriveKey(pwd, salt) {
    const baseKey = await crypto.subtle.importKey('raw', new TextEncoder().encode(pwd), 'PBKDF2', false, ['deriveKey']);
    return crypto.subtle.deriveKey(
      { name: 'PBKDF2', salt, iterations: 100000, hash: 'SHA-256' },
      baseKey, { name: 'AES-GCM', length: 256 }, false, ['decrypt']
    );
  }

  async function tryUnlock(pwd) {
    try {
      const salt = b64(SALT_B64), iv = b64(IV_B64), cipher = b64(ENCRYPTED_PAYLOAD);
      const key = await deriveKey(pwd, salt);
      const plain = await crypto.subtle.decrypt({ name: 'AES-GCM', iv }, key, cipher);
      const decrypted = new TextDecoder().decode(plain);
      mount.innerHTML = decrypted;
      mount.querySelectorAll('script').forEach(old => {
        const s = document.createElement('script');
        if (old.src) s.src = old.src; else s.textContent = old.textContent;
        old.replaceWith(s);
      });
      gate.style.display = 'none';
      mount.style.display = 'block';
      // sessionStorage — persiste entre páginas desta aba, mas não após fechar o browser.
      sessionStorage.setItem(STORAGE_KEY, pwd);
      // Notifica componentes (mermaid-zoom, comparator, accordion-seq) que conteúdo
      // criptografado foi injetado no DOM e podem (re)inicializar.
      document.dispatchEvent(new CustomEvent('wikia:unlocked', { detail: { html: decrypted } }));
      return true;
    } catch (e) { return false; }
  }

  // Auto-unlock: se já tem chave salva nesta sessão, tenta
  const saved = sessionStorage.getItem(STORAGE_KEY);
  if (saved) {
    tryUnlock(saved).then(ok => { if (!ok) sessionStorage.removeItem(STORAGE_KEY); });
  }

  form.addEventListener('submit', async (e) => {
    e.preventDefault();
    err.textContent = '';
    const ok = await tryUnlock(input.value);
    if (!ok) { err.textContent = '✗ senha incorreta'; input.value = ''; input.focus(); }
  });
})();
</script>
