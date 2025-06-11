from __future__ import annotations

import os
from pathlib import Path


_INDEX: dict[str, str] = {}


def repo_root() -> Path:
    """Return the repository root directory."""
    env_root = os.environ.get("LAB_REPO_ROOT")
    if env_root:
        return Path(env_root)
    return Path(__file__).resolve().parents[2]


def resolve_path(name: str) -> Path | None:
    """Return Path for *name* from the index or by searching the repo."""
    path_str = _INDEX.get(name)
    if path_str and Path(path_str).exists():
        return Path(path_str)
    found = search_for_file(name)
    if found:
        _INDEX[name] = str(found)
    return found


def search_for_file(name: str) -> Path | None:
    """Recursively search the repository for *name* and return the path."""
    root = repo_root()
    for p in root.rglob(name):
        if p.is_file() and p.name == name:
            return p
    return None
