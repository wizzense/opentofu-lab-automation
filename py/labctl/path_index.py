from __future__ import annotations
import os
from pathlib import Path
from typing import Optional

try:
    import yaml
except ImportError:
    yaml = None

_INDEX: dict[str, str] = {}
_repo_root: Optional[Path] = None

def repo_root() -> Path:
    """Return the repository root directory."""
    global _repo_root
    if _repo_root is not None:
        return _repo_root
    env_root = os.environ.get("LAB_REPO_ROOT")
    if env_root:
        _repo_root = Path(env_root)
    else:
        _repo_root = Path(__file__).resolve().parents[2]
    return _repo_root

def load_index() -> dict:
    """Load path-index.yaml from repository root, if available."""
    global _INDEX
    if not _INDEX:
        root = repo_root()
        candidates = [root / 'path-index.yaml',
                      root / 'configs/project/path-index.yaml']

        for index_path in candidates:
            if index_path.exists() and yaml is not None:
                with index_path.open('r') as f:
                    data = yaml.safe_load(f) or {}
                _INDEX = dict(data)
                # also allow lookup by base filename
                for key, val in data.items():
                    basename = Path(key).name
                    _INDEX.setdefault(basename, val)
                break
        else:
            _INDEX = {}
    return _INDEX

def resolve_path(name: str) -> Optional[Path]:
    """Return Path for *name* from the index or by searching the repo."""
    index = load_index()
    rel = index.get(name)
    if rel:
        abs_path = repo_root() / rel
        if abs_path.exists():
            return abs_path
    # Fallback to search
    found = search_for_file(name)
    if found:
        _INDEX[name] = str(found.relative_to(repo_root()))
    return found

def search_for_file(name: str) -> Optional[Path]:
    """Recursively search the repository for *name* and return the path."""
    root = repo_root()
    for p in root.rglob(name):
        if p.is_file() and p.name == name:
            return p
    return None