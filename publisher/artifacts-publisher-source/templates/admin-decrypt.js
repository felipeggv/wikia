// admin-decrypt.js - Browser WebCrypto decryptor for the wikia password vault.
// Mirrors scripts/vault.mjs: AES-256-GCM, PBKDF2-SHA256, 100k iterations.
//
// Packed vault format, base64:
//   <salt(16)><iv(12)><tag(16)><ciphertext>
//
// WebCrypto AES-GCM expects ciphertext with the auth tag appended, so this
// module reassembles ciphertext + tag before decrypting.

(function (root) {
  function b64ToBytes(b64) {
    const bin = atob(b64);
    const out = new Uint8Array(bin.length);
    for (let i = 0; i < bin.length; i++) out[i] = bin.charCodeAt(i);
    return out;
  }

  async function decryptVault(b64, masterpass) {
    const buf = b64ToBytes(b64);
    const salt = buf.subarray(0, 16);
    const iv = buf.subarray(16, 16 + 12);
    const tag = buf.subarray(16 + 12, 16 + 12 + 16);
    const ct = buf.subarray(16 + 12 + 16);
    const ctWithTag = new Uint8Array(ct.length + tag.length);
    ctWithTag.set(ct, 0);
    ctWithTag.set(tag, ct.length);

    const baseKey = await crypto.subtle.importKey(
      'raw',
      new TextEncoder().encode(masterpass),
      'PBKDF2',
      false,
      ['deriveKey']
    );
    const key = await crypto.subtle.deriveKey(
      { name: 'PBKDF2', salt: salt, iterations: 100000, hash: 'SHA-256' },
      baseKey,
      { name: 'AES-GCM', length: 256 },
      false,
      ['decrypt']
    );
    const plain = await crypto.subtle.decrypt(
      { name: 'AES-GCM', iv: iv, tagLength: 128 },
      key,
      ctWithTag
    );
    return JSON.parse(new TextDecoder().decode(plain));
  }

  const api = { decryptVault: decryptVault };

  if (typeof module !== 'undefined' && module.exports) {
    module.exports = api;
  } else {
    root.WikiaVault = api;
  }
})(typeof window !== 'undefined' ? window : globalThis);
