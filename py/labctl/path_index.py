from __future__ import annotations

from pathlib import Path
from typing import Optional
import yaml

_repo_root = Path(__file__).resolve().parents[2]
_index = None


def load_index() -> dict:
    """Load path-index.yaml from repository root."""
    global _index
    if _index is None:
        index_path = _repo_root / 'path-index.yaml'
        if index_path.exists():
            with index_path.open('r') as f:
                _index = yaml.safe_load(f) or {}
        else:
            _index = {}
    return _index


def resolve_path(key: str) -> Optional[Path]:
    """Return absolute path for key from index or None."""
    index = load_index()
    rel = index.get(key)
    if rel:
        return _repo_root / rel
    return None
