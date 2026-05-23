#!/usr/bin/env python3
"""apply-pending.py — Apply admin queue (releases / rotations / removals) to vault + releases.

Queue format (_pending-changes.json):
    {
        "release": ["slug1", "slug2"],
        "rotate":  ["slug3"],
        "remove":  ["slug4"]
    }

Effects:
    - release: slug appended to _released.json array (dedupe).
    - rotate:  new random password generated and stored in vault via vault.mjs set.
    - remove:  slug deleted from vault AND from _released.json.

Every change logged to stderr. Pending file is truncated to '{}' at the end.

Usage:
    python3 apply-pending.py <pending_path> <vault_path> <released_path> [masterpass|-]
"""
from __future__ import annotations

import json
import os
import secrets
import string
import subprocess
import sys
from pathlib import Path
from typing import Any

import public_catalog

ROTATE_PASSWORD_ALPHABET = string.ascii_letters + string.digits
ROTATE_PASSWORD_LEN = 16
VAULT_SCRIPT = Path(__file__).resolve().parent / "vault.mjs"
ENV_MASTERPASS = "WIKIA_MASTERPASS"


def gen_password() -> str:
    return "".join(
        secrets.choice(ROTATE_PASSWORD_ALPHABET) for _ in range(ROTATE_PASSWORD_LEN)
    )


def vault_env(masterpass: str) -> dict[str, str]:
    env = os.environ.copy()
    env[ENV_MASTERPASS] = masterpass
    return env


def vault_set(vault_path: Path, masterpass: str, slug: str, password: str) -> None:
    subprocess.run(
        ["node", str(VAULT_SCRIPT), "set", str(vault_path), slug, password],
        check=True,
        stdout=subprocess.DEVNULL,
        env=vault_env(masterpass),
    )


def vault_remove(vault_path: Path, masterpass: str, slug: str) -> None:
    subprocess.run(
        ["node", str(VAULT_SCRIPT), "remove", str(vault_path), slug],
        check=True,
        stdout=subprocess.DEVNULL,
        env=vault_env(masterpass),
    )


def load_released(released_path: Path) -> list[str]:
    if not released_path.is_file():
        return []
    txt = released_path.read_text(encoding="utf-8").strip()
    if not txt:
        return []
    data = json.loads(txt)
    if not isinstance(data, list):
        raise SystemExit(f"ERR: {released_path} must contain a JSON array")
    return data


def save_released(released_path: Path, slugs: list[str]) -> None:
    released_path.write_text(json.dumps(sorted(set(slugs)), indent=2) + "\n", encoding="utf-8")


def as_list(value: Any) -> list[Any]:
    return value if isinstance(value, list) else []


def normalize_token(value: Any) -> str:
    if value is None:
        return ""
    return str(value).strip().strip("/")


def intent_key(intent: Any) -> str:
    if isinstance(intent, str):
        return normalize_token(intent)
    if not isinstance(intent, dict):
        return ""
    if intent.get("key"):
        return normalize_token(intent["key"])
    if intent.get("bu") and intent.get("project") and intent.get("slug"):
        return f"{normalize_token(intent['bu'])}/{normalize_token(intent['project'])}/{normalize_token(intent['slug'])}"
    if intent.get("output_url"):
        return normalize_token(intent["output_url"])
    return normalize_token(intent.get("slug"))


def intent_slug(intent: Any) -> str:
    if isinstance(intent, dict) and intent.get("slug"):
        return normalize_token(intent["slug"])
    key = intent_key(intent)
    if "/" in key:
        return key.split("/")[-1]
    return key


def intent_vault_keys(intent: Any) -> list[str]:
    keys: list[str] = []
    if isinstance(intent, dict):
        keys.extend(
            normalize_token(intent.get(field))
            for field in ("vault_key", "slug", "key", "output_url", "article_id")
        )
    else:
        keys.append(intent_slug(intent))
    keys.append(intent_slug(intent))

    out: list[str] = []
    seen: set[str] = set()
    for key in keys:
        if key and key not in seen:
            seen.add(key)
            out.append(key)
    return out


def released_tokens_for(intent: Any) -> list[str]:
    tokens = [intent_key(intent), intent_slug(intent)]
    if isinstance(intent, dict):
        tokens.append(normalize_token(intent.get("output_url")))
    out: list[str] = []
    seen: set[str] = set()
    for token in tokens:
        if token and token not in seen:
            seen.add(token)
            out.append(token)
    return out


def update_catalog_for_pending(catalog_path: Path, queue: dict[str, Any]) -> dict[str, int]:
    if not catalog_path or not catalog_path.exists():
        return {"catalog_records_updated": 0}

    catalog = public_catalog.load_catalog(catalog_path)
    records = [
        public_catalog.with_identity_fields(item)
        for item in catalog.get("records", [])
        if isinstance(item, dict)
    ]
    updated = 0

    def matches(record: dict[str, Any], intent: Any) -> bool:
        tokens = set(released_tokens_for(intent))
        record_tokens = {
            public_catalog.record_key(record),
            normalize_token(record.get("slug")),
            normalize_token(record.get("output_url")),
            normalize_token(record.get("article_id")),
        }
        return bool(tokens & record_tokens)

    for intent in as_list(queue.get("release")):
        for record in records:
            if not matches(record, intent):
                continue
            record["gate_status"] = "public"
            record["release_status"] = "released"
            record["scope"] = "public"
            updated += 1

    for intent in as_list(queue.get("scope")):
        target_scope = normalize_token(intent.get("to_scope") if isinstance(intent, dict) else "")
        if target_scope not in {"article", "project", "bu", "admin"}:
            continue
        for record in records:
            if not matches(record, intent):
                continue
            if record.get("release_status") == "released":
                record["scope"] = "public"
            else:
                record["scope"] = target_scope
            updated += 1

    for intent in as_list(queue.get("remove")):
        for record in records:
            if not matches(record, intent):
                continue
            record["gate_status"] = "gated"
            record["release_status"] = "removed"
            record["scope"] = "article"
            record["title_visible"] = False
            record["title_public"] = None
            record["tags"] = []
            updated += 1

    if updated:
        catalog["records"] = sorted(
            [public_catalog.with_identity_fields(record) for record in records],
            key=public_catalog.record_key,
        )
        catalog["generated_at"] = public_catalog.utc_now_iso()
        public_catalog.write_catalog(catalog_path, catalog)

    return {"catalog_records_updated": updated}


def apply(
    pending_path: Path,
    vault_path: Path,
    released_path: Path,
    masterpass: str,
    catalog_path: Path | None = None,
) -> dict[str, int]:
    if not pending_path.is_file():
        print(f"apply-pending: {pending_path} not found, nothing to do", file=sys.stderr)
        return {
            "releases": 0,
            "rotations": 0,
            "removals": 0,
            "scope_changes": 0,
            "catalog_records_updated": 0,
        }
    raw = pending_path.read_text(encoding="utf-8").strip() or "{}"
    queue = json.loads(raw)
    if not isinstance(queue, dict):
        raise SystemExit(f"ERR: {pending_path} must contain a JSON object")

    releases = as_list(queue.get("release"))
    rotations = as_list(queue.get("rotate"))
    removals = as_list(queue.get("remove"))
    scope_changes = as_list(queue.get("scope"))

    released = load_released(released_path)
    released_set = set(released)

    for intent in releases:
        key = intent_key(intent)
        if not key:
            print("apply-pending: release skip (empty intent)", file=sys.stderr)
            continue
        if key in released_set:
            print(f"apply-pending: release skip (already released) {key}", file=sys.stderr)
            continue
        released_set.add(key)
        print(f"apply-pending: release + {key}", file=sys.stderr)

    for intent in rotations:
        vault_keys = intent_vault_keys(intent)
        if not vault_keys:
            print("apply-pending: rotate skip (empty intent)", file=sys.stderr)
            continue
        vault_key = vault_keys[0]
        new_pw = gen_password()
        vault_set(vault_path, masterpass, vault_key, new_pw)
        print(f"apply-pending: rotate {vault_key}", file=sys.stderr)

    for intent in removals:
        key = intent_key(intent)
        for vault_key in intent_vault_keys(intent):
            try:
                vault_remove(vault_path, masterpass, vault_key)
                print(f"apply-pending: vault-remove {vault_key}", file=sys.stderr)
            except subprocess.CalledProcessError as exc:
                print(f"apply-pending: vault-remove FAIL {vault_key}: {exc}", file=sys.stderr)
        for token in released_tokens_for(intent):
            if token in released_set:
                released_set.discard(token)
                print(f"apply-pending: released-remove {token}", file=sys.stderr)
        if key:
            print(f"apply-pending: remove {key}", file=sys.stderr)

    catalog_result = {"catalog_records_updated": 0}
    if catalog_path is not None:
        catalog_result = update_catalog_for_pending(catalog_path, queue)

    save_released(released_path, list(released_set))
    pending_path.write_text("{}\n", encoding="utf-8")
    print(
        "apply-pending: done — "
        f"releases={len(releases)} rotations={len(rotations)} "
        f"removals={len(removals)} scope={len(scope_changes)} "
        f"catalog_updates={catalog_result['catalog_records_updated']}",
        file=sys.stderr,
    )
    return {
        "releases": len(releases),
        "rotations": len(rotations),
        "removals": len(removals),
        "scope_changes": len(scope_changes),
        "catalog_records_updated": catalog_result["catalog_records_updated"],
    }


def resolve_masterpass(explicit: str | None) -> str:
    if explicit == "-":
        value = sys.stdin.read().replace("\r\n", "\n").rstrip("\n")
    elif explicit:
        raise SystemExit(
            "ERR: plaintext masterpass argument is unsafe; pass '-' or use the environment"
        )
    else:
        value = os.environ.get(ENV_MASTERPASS, "")

    if not value:
        raise SystemExit("ERR: masterpass empty")
    return value


def main() -> int:
    args = sys.argv[1:]
    catalog_path = None
    if "--catalog-path" in args:
        idx = args.index("--catalog-path")
        try:
            catalog_path = Path(args[idx + 1])
        except IndexError:
            print("ERR: --catalog-path requires a value", file=sys.stderr)
            return 2
        del args[idx : idx + 2]

    if len(args) not in (3, 4):
        print(
            "Usage: apply-pending.py <pending_path> <vault_path> <released_path> [masterpass|-] [--catalog-path <path>]",
            file=sys.stderr,
        )
        return 2
    pending_path = Path(args[0])
    vault_path = Path(args[1])
    released_path = Path(args[2])
    masterpass = resolve_masterpass(args[3] if len(args) == 4 else None)
    apply(pending_path, vault_path, released_path, masterpass, catalog_path)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
