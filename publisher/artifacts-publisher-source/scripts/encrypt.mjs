#!/usr/bin/env node
// encrypt.mjs — criptografa conteúdo do <template id="ap-content-tpl"> com AES-GCM
// Output (stdout JSON): {payload, salt, iv, slug, repo}

import { readFileSync, writeFileSync } from 'fs';
import { webcrypto as crypto } from 'crypto';

const [,, htmlPath, password] = process.argv;
if (!htmlPath || !password) {
  console.error('Usage: encrypt.mjs <html-file> <password>');
  process.exit(1);
}

const html = readFileSync(htmlPath, 'utf8');
const tplRegex = /<template id="ap-content-tpl">([\s\S]*?)<\/template>/;
const match = html.match(tplRegex);
if (!match) { console.error('ERR: no <template id="ap-content-tpl">'); process.exit(1); }
const contentToEncrypt = match[1];

const slug = (html.match(/data-slug="([^"]+)"/) || [, 'artifact'])[1];
const repo = (html.match(/data-repo="([^"]+)"/) || [, 'vibework-knowledge'])[1];

function toB64(buf) { return Buffer.from(buf).toString('base64'); }

async function deriveKey(pwd, salt) {
  const baseKey = await crypto.subtle.importKey('raw', new TextEncoder().encode(pwd), 'PBKDF2', false, ['deriveKey']);
  return crypto.subtle.deriveKey(
    { name: 'PBKDF2', salt, iterations: 100000, hash: 'SHA-256' },
    baseKey, { name: 'AES-GCM', length: 256 }, false, ['encrypt']
  );
}

const salt = crypto.getRandomValues(new Uint8Array(16));
const iv = crypto.getRandomValues(new Uint8Array(12));
const key = await deriveKey(password, salt);
const cipher = await crypto.subtle.encrypt({ name: 'AES-GCM', iv }, key, new TextEncoder().encode(contentToEncrypt));

writeFileSync(htmlPath, html.replace(tplRegex, ''));
console.log(JSON.stringify({
  payload: toB64(new Uint8Array(cipher)),
  salt: toB64(salt),
  iv: toB64(iv),
  slug, repo
}));
