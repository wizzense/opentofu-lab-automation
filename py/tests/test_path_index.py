import importlib
import os
from pathlib import Path

import labctl.path_index as pi
from labctl import path_index


def test_resolve_after_move(tmp_path, monkeypatch):
    repo = tmp_path / "repo"
    repo.mkdir()
    sub1 = repo / "one"
    sub1.mkdir()
    file = sub1 / "file.txt"
    file.write_text("hi")

    monkeypatch.setenv("LAB_REPO_ROOT", str(repo))
    importlib.reload(pi)

    path1 = pi.resolve_path("file.txt")
    assert path1 == file

    new_dir = repo / "two"
    new_dir.mkdir()
    file.rename(new_dir / "file.txt")
    path2 = pi.resolve_path("file.txt")
    assert path2 == new_dir / "file.txt"


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
    assert path.exists()

