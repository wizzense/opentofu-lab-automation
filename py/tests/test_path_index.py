import importlib
import os
from pathlib import Path

import labctl.path_index as pi


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
