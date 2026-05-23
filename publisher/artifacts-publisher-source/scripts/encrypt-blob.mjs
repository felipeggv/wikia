#!/usr/bin/env node
// encrypt-blob.mjs — criptografa um arquivo plaintext (extraído previamente)
// com AES-GCM e devolve JSON com payload/salt/iv/slug/repo (compatível com
// gate.html.tpl).
//
// Uso:
//   node encrypt-blob.mjs <plaintext-file> <html-file> <password>
//     - <plaintext-file>: conteúdo já extraído (por extract-template.mjs)
//     - <html-file>: HTML de origem (usado só para pegar data-slug/data-repo)
//     - <password>: senha do gate
//   stdout: JSON {payload, salt, iv, slug, repo}
//
// Existe em paralelo ao encrypt.mjs porque extract-template.mjs faz balance-scan
// e produz um plaintext correto (incluindo <template> aninhados de playgrounds).
// encrypt.mjs original usa regex non-greedy e tem bug com nested templates;
// encrypt.mjs fica preservado intocado (anti-scope), e este wrapper toma seu
// lugar quando o gate.sh roda a pipeline corrigida.
//
// Crypto idêntica a encrypt.mjs: PBKDF2-SHA-256 (100k iter) → AES-GCM-256.

import { readFileSync } from 'fs';
import { webcrypto as crypto } from 'crypto';

const [, , plainPath, htmlPath, password] = process.argv;
if (!plainPath || !htmlPath || !password) {
  console.error('Usage: encrypt-blob.mjs <plaintext-file> <html-file> <password>');
  process.exit(1);
}

const plaintext = readFileSync(plainPath, 'utf8');
const html = readFileSync(htmlPath, 'utf8');

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
const cipher = await crypto.subtle.encrypt({ name: 'AES-GCM', iv }, key, new TextEncoder().encode(plaintext));

console.log(JSON.stringify({
  payload: toB64(new Uint8Array(cipher)),
  salt: toB64(salt),
  iv: toB64(iv),
  slug, repo
}));
