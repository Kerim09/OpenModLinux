#!/usr/bin/env python3
"""Discover native Steam libraries and installed applications.

No third-party parser is used. Valve's libraryfolders.vdf is parsed with a small
KeyValues tokenizer that handles quoted strings, braces and line comments.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Iterator


TOKEN_RE = re.compile(r'"((?:\\.|[^"\\])*)"|([{}])|//[^\n]*', re.MULTILINE)


@dataclass(frozen=True)
class SteamApp:
    appid: str
    name: str
    install_dir: str
    manifest: str
    library: str


def decode_quoted(value: str) -> str:
    return value.replace(r"\"", '"').replace(r"\\", "\\")


def tokenize(text: str) -> Iterator[str]:
    for match in TOKEN_RE.finditer(text):
        if match.group(1) is not None:
            yield decode_quoted(match.group(1))
        elif match.group(2) is not None:
            yield match.group(2)


def parse_object(tokens: list[str], position: int = 0) -> tuple[dict[str, object], int]:
    result: dict[str, object] = {}
    while position < len(tokens):
        token = tokens[position]
        if token == "}":
            return result, position + 1
        if token == "{":
            raise ValueError("Unexpected opening brace")
        key = token
        position += 1
        if position >= len(tokens):
            result[key] = ""
            break
        value = tokens[position]
        if value == "{":
            child, position = parse_object(tokens, position + 1)
            result[key] = child
        elif value == "}":
            result[key] = ""
            return result, position + 1
        else:
            result[key] = value
            position += 1
    return result, position


def parse_vdf(path: Path) -> dict[str, object]:
    text = path.read_text(encoding="utf-8", errors="replace")
    tokens = list(tokenize(text))
    parsed, _ = parse_object(tokens)
    return parsed


def steam_root_candidates(home: Path) -> list[Path]:
    env_root = os.environ.get("OPENMODLINUX_STEAM_ROOT")
    candidates = [
        Path(env_root).expanduser() if env_root else None,
        home / ".local/share/Steam",
        home / ".steam/steam",
        home / ".var/app/com.valvesoftware.Steam/.local/share/Steam",
        home / ".var/app/com.valvesoftware.Steam/data/Steam",
    ]
    result: list[Path] = []
    seen: set[Path] = set()
    for candidate in candidates:
        if candidate is None:
            continue
        resolved = candidate.resolve(strict=False)
        if resolved in seen:
            continue
        if (resolved / "steamapps").is_dir():
            seen.add(resolved)
            result.append(resolved)
    return result


def extract_library_paths(root: Path) -> list[Path]:
    libraries = [root]
    vdf = root / "steamapps/libraryfolders.vdf"
    if not vdf.is_file():
        return libraries

    try:
        parsed = parse_vdf(vdf)
    except (OSError, ValueError):
        return libraries

    folders = parsed.get("libraryfolders", parsed)
    if not isinstance(folders, dict):
        return libraries

    for key, value in folders.items():
        if not str(key).isdigit():
            continue
        path_value: object | None = None
        if isinstance(value, dict):
            path_value = value.get("path")
        elif isinstance(value, str):
            path_value = value
        if not isinstance(path_value, str) or not path_value:
            continue
        candidate = Path(path_value.replace("\\\\", "\\")).expanduser().resolve(strict=False)
        if (candidate / "steamapps").is_dir() and candidate not in libraries:
            libraries.append(candidate)
    return libraries


def manifest_value(data: dict[str, object], key: str) -> str:
    app_state = data.get("AppState", data)
    if isinstance(app_state, dict):
        value = app_state.get(key, "")
        return str(value) if value is not None else ""
    return ""


def discover(home: Path) -> dict[str, object]:
    roots = steam_root_candidates(home)
    libraries: list[Path] = []
    for root in roots:
        for library in extract_library_paths(root):
            if library not in libraries:
                libraries.append(library)

    apps: list[SteamApp] = []
    seen_appids: set[str] = set()
    for library in libraries:
        steamapps = library / "steamapps"
        for manifest in sorted(steamapps.glob("appmanifest_*.acf")):
            try:
                data = parse_vdf(manifest)
            except (OSError, ValueError):
                continue
            appid = manifest_value(data, "appid") or manifest.stem.removeprefix("appmanifest_")
            install_dir = manifest_value(data, "installdir")
            name = manifest_value(data, "name") or f"Steam app {appid}"
            game_path = steamapps / "common" / install_dir
            if not appid or not install_dir or not game_path.is_dir() or appid in seen_appids:
                continue
            seen_appids.add(appid)
            apps.append(
                SteamApp(
                    appid=appid,
                    name=name,
                    install_dir=install_dir,
                    manifest=str(manifest.resolve()),
                    library=str(library.resolve()),
                )
            )

    return {
        "steam_roots": [str(path) for path in roots],
        "libraries": [str(path) for path in libraries],
        "apps": [asdict(app) for app in apps],
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--home", default=os.environ.get("HOME", str(Path.home())))
    parser.add_argument("--pretty", action="store_true")
    args = parser.parse_args()

    payload = discover(Path(args.home).expanduser())
    json.dump(payload, sys.stdout, ensure_ascii=False, indent=2 if args.pretty else None)
    sys.stdout.write("\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
