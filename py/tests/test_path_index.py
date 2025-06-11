from pathlib import Path
from labctl import path_index


def test_load_index_contains_runner():
    idx = path_index.load_index()
    assert "runner.ps1" in idx


def test_resolve_path_missing(monkeypatch):
    monkeypatch.setattr(path_index, "_index", {})
    p = path_index.resolve_path("does-not-exist")
    assert p is None


def test_default_config_fallback(monkeypatch):
    monkeypatch.setattr(path_index, "_index", {})
    from labctl.cli import default_config_path
    path = default_config_path()
    assert path.exists()


def test_no_pycache_paths():
    idx = path_index.load_index()
    assert not any("__pycache__" in key for key in idx)
