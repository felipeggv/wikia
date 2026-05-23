#!/usr/bin/env node
// vault.mjs - AES-256-GCM password vault keyed by the Wikia masterpass.
//
// Packed _passwords.enc format, base64 encoded:
//   <salt(16)><iv(12)><tag(16)><ciphertext>
//
// Compatible with the browser admin decryptor, which derives AES-GCM keys with
// PBKDF2-SHA256 at 100k iterations.

import { existsSync, readFileSync, writeFileSync } from 'node:fs';
import { createCipheriv, createDecipheriv, pbkdf2Sync, randomBytes } from 'node:crypto';

const ITERATIONS = 100000;
const KEY_LENGTH = 32;
const SALT_LENGTH = 16;
const IV_LENGTH = 12;
const TAG_LENGTH = 16;
const ENV_MASTERPASS = 'WIKIA_MASTERPASS';

function usage(exitCode = 2) {
  const out = exitCode === 0 ? console.log : console.error;
  out(`Usage:
  vault.mjs init <vault-path> [masterpass|-] [--force]
  vault.mjs list <vault-path> [masterpass|-]
  vault.mjs get  <vault-path> [masterpass|-] <slug>
  vault.mjs set  <vault-path> [masterpass|-] <slug> <password> [tema]
  vault.mjs del  <vault-path> [masterpass|-] <slug>
  vault.mjs pack-json <output-path> [masterpass|-] < plaintext.json

Masterpass resolution:
  1. explicit positional masterpass, or "-" to read stdin
  2. ${ENV_MASTERPASS} environment variable
  3. stdin when it is piped`);
  process.exit(exitCode);
}

function fail(message, exitCode = 1) {
  console.error(`ERR: ${message}`);
  process.exit(exitCode);
}

function deriveKey(masterpass, salt) {
  return pbkdf2Sync(masterpass, salt, ITERATIONS, KEY_LENGTH, 'sha256');
}

function toPlainObject(value, label) {
  if (!value || typeof value !== 'object' || Array.isArray(value)) {
    throw new Error(`${label} must be a JSON object`);
  }
  return value;
}

function orderedVault(vault) {
  return Object.fromEntries(
    Object.entries(vault).sort(([a], [b]) => a.localeCompare(b))
  );
}

function encryptVault(vault, masterpass) {
  const plaintext = Buffer.from(JSON.stringify(orderedVault(vault)), 'utf8');
  const salt = randomBytes(SALT_LENGTH);
  const iv = randomBytes(IV_LENGTH);
  const key = deriveKey(masterpass, salt);
  const cipher = createCipheriv('aes-256-gcm', key, iv);
  const ciphertext = Buffer.concat([cipher.update(plaintext), cipher.final()]);
  const tag = cipher.getAuthTag();
  return Buffer.concat([salt, iv, tag, ciphertext]).toString('base64');
}

function decryptVault(base64Vault, masterpass) {
  const packed = Buffer.from(base64Vault.trim(), 'base64');
  const minimumLength = SALT_LENGTH + IV_LENGTH + TAG_LENGTH;
  if (packed.length < minimumLength) {
    throw new Error('vault payload is too short');
  }

  const salt = packed.subarray(0, SALT_LENGTH);
  const iv = packed.subarray(SALT_LENGTH, SALT_LENGTH + IV_LENGTH);
  const tag = packed.subarray(SALT_LENGTH + IV_LENGTH, minimumLength);
  const ciphertext = packed.subarray(minimumLength);
  const key = deriveKey(masterpass, salt);
  const decipher = createDecipheriv('aes-256-gcm', key, iv);
  decipher.setAuthTag(tag);
  const plaintext = Buffer.concat([decipher.update(ciphertext), decipher.final()]);
  return toPlainObject(JSON.parse(plaintext.toString('utf8')), 'decrypted vault');
}

function loadVault(vaultPath, masterpass) {
  if (!existsSync(vaultPath)) return {};
  const raw = readFileSync(vaultPath, 'utf8').trim();
  if (!raw) return {};
  try {
    return decryptVault(raw, masterpass);
  } catch (error) {
    throw new Error(`decrypt failed; wrong masterpass or invalid vault (${error.message})`);
  }
}

function saveVault(vaultPath, vault, masterpass) {
  writeFileSync(vaultPath, `${encryptVault(vault, masterpass)}\n`, { encoding: 'utf8', mode: 0o600 });
}

function readMasterpassFromStdin() {
  if (process.stdin.isTTY) {
    fail(`masterpass required via positional arg, ${ENV_MASTERPASS}, or piped stdin`, 2);
  }
  const value = readFileSync(0, 'utf8').replace(/\r?\n$/, '');
  if (!value) {
    fail(`masterpass required via positional arg, ${ENV_MASTERPASS}, or piped stdin`, 2);
  }
  return value;
}

function resolveMasterpass(explicit) {
  if (explicit === '-') return readMasterpassFromStdin();
  if (explicit) return explicit;
  if (process.env[ENV_MASTERPASS]) return process.env[ENV_MASTERPASS];
  return readMasterpassFromStdin();
}

function resolveMasterpassWithoutStdin(explicit) {
  if (explicit === '-') fail('pack-json reads JSON from stdin; use WIKIA_MASTERPASS instead', 2);
  if (explicit) return explicit;
  if (process.env[ENV_MASTERPASS]) return process.env[ENV_MASTERPASS];
  fail(`masterpass required via positional arg or ${ENV_MASTERPASS}`, 2);
}

function parseInit(rest) {
  const forceIndex = rest.indexOf('--force');
  const force = forceIndex !== -1;
  const args = force ? rest.filter((_, index) => index !== forceIndex) : rest;
  if (args.length < 1 || args.length > 2) usage();
  return {
    vaultPath: args[0],
    masterpass: resolveMasterpass(args[1]),
    force,
  };
}

function parseList(rest) {
  if (rest.length < 1 || rest.length > 2) usage();
  return {
    vaultPath: rest[0],
    masterpass: resolveMasterpass(rest[1]),
  };
}

function parsePackJson(rest) {
  if (rest.length < 1 || rest.length > 2) usage();
  return {
    outputPath: rest[0],
    masterpass: resolveMasterpassWithoutStdin(rest[1]),
  };
}

function parseGetOrDelete(rest) {
  if (rest.length === 3) {
    return { vaultPath: rest[0], masterpass: resolveMasterpass(rest[1]), slug: rest[2] };
  }
  if (rest.length === 2) {
    return { vaultPath: rest[0], masterpass: resolveMasterpass(), slug: rest[1] };
  }
  usage();
}

function takeValueOption(args, flag) {
  const index = args.indexOf(flag);
  if (index === -1) return { args, value: undefined };
  if (index === args.length - 1) fail(`${flag} requires a value`, 2);
  const value = args[index + 1];
  return {
    args: args.filter((_, itemIndex) => itemIndex !== index && itemIndex !== index + 1),
    value,
  };
}

function parseSet(rest) {
  const temaParsed = takeValueOption(rest, '--tema');
  const masterpassParsed = takeValueOption(temaParsed.args, '--masterpass');
  const args = masterpassParsed.args;
  const masterpassOverride = masterpassParsed.value;
  const flaggedTema = temaParsed.value;

  if (masterpassOverride && (args.length === 3 || args.length === 4)) {
    return {
      vaultPath: args[0],
      masterpass: resolveMasterpass(masterpassOverride),
      slug: args[1],
      password: args[2],
      tema: flaggedTema ?? args[3],
    };
  }
  if ((args.length === 4 || args.length === 5) && flaggedTema == null) {
    return {
      vaultPath: args[0],
      masterpass: resolveMasterpass(args[1]),
      slug: args[2],
      password: args[3],
      tema: args[4],
    };
  }
  if (args.length === 3 || args.length === 4) {
    return {
      vaultPath: args[0],
      masterpass: resolveMasterpass(),
      slug: args[1],
      password: args[2],
      tema: flaggedTema ?? args[3],
    };
  }
  usage();
}

function normalizeEntry(entry) {
  if (entry && typeof entry === 'object' && !Array.isArray(entry)) {
    return entry;
  }
  return { password: entry };
}

function stampEntry(existing, password, tema) {
  const now = new Date().toISOString();
  const current = normalizeEntry(existing);
  return {
    ...current,
    password,
    tema: tema ?? current.tema ?? null,
    created: current.created ?? now,
    updated: now,
  };
}

function printJson(value) {
  console.log(JSON.stringify(value));
}

async function main() {
  const [, , rawCommand, ...rest] = process.argv;
  const command = rawCommand === 'remove' ? 'del' : rawCommand;
  if (!command || command === '--help' || command === '-h') usage(command ? 0 : 2);

  if (command === 'init') {
    const { vaultPath, masterpass, force } = parseInit(rest);
    if (existsSync(vaultPath) && !force) {
      fail('vault already exists; pass --force to replace it', 2);
    }
    saveVault(vaultPath, {}, masterpass);
    printJson({ ok: true, path: vaultPath, entries: 0 });
    return;
  }

  if (command === 'list') {
    const { vaultPath, masterpass } = parseList(rest);
    const vault = loadVault(vaultPath, masterpass);
    printJson({ ok: true, entries: Object.keys(vault).length, slugs: Object.keys(vault).sort() });
    return;
  }

  if (command === 'get') {
    const { vaultPath, masterpass, slug } = parseGetOrDelete(rest);
    const vault = loadVault(vaultPath, masterpass);
    if (!Object.prototype.hasOwnProperty.call(vault, slug)) {
      printJson({ ok: false, error: 'slug not found', slug });
      process.exit(1);
    }
    printJson(normalizeEntry(vault[slug]));
    return;
  }

  if (command === 'set') {
    const { vaultPath, masterpass, slug, password, tema } = parseSet(rest);
    const vault = loadVault(vaultPath, masterpass);
    vault[slug] = stampEntry(vault[slug], password, tema);
    saveVault(vaultPath, vault, masterpass);
    printJson({ ok: true, slug, entries: Object.keys(vault).length });
    return;
  }

  if (command === 'del') {
    const { vaultPath, masterpass, slug } = parseGetOrDelete(rest);
    const vault = loadVault(vaultPath, masterpass);
    const existed = Object.prototype.hasOwnProperty.call(vault, slug);
    delete vault[slug];
    saveVault(vaultPath, vault, masterpass);
    printJson({ ok: true, slug, existed, entries: Object.keys(vault).length });
    return;
  }

  if (command === 'pack-json') {
    const { outputPath, masterpass } = parsePackJson(rest);
    const raw = readFileSync(0, 'utf8').trim();
    if (!raw) fail('JSON stdin is required', 2);
    const payload = toPlainObject(JSON.parse(raw), 'JSON stdin');
    saveVault(outputPath, payload, masterpass);
    printJson({ ok: true, path: outputPath });
    return;
  }

  fail(`unknown command: ${rawCommand}`, 2);
}

main().catch((error) => {
  fail(error.message || String(error));
});
