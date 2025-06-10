from pathlib import Path
import sys
import subprocess
from typer.testing import CliRunner

sys.path.append(str(Path(__file__).resolve().parents[1]))

from labctl import github_utils
from labctl.cli import app


def test_close_pr(monkeypatch):
    called = {}

    def fake_run(cmd, check=True):
        called["cmd"] = cmd
    monkeypatch.setattr(subprocess, "run", fake_run)

    runner = CliRunner()
    result = runner.invoke(app, ["repo", "close-pr", "5"])
    assert result.exit_code == 0
    assert called["cmd"] == ["gh", "pr", "close", "5"]


def test_cleanup(monkeypatch):
    output = (
        "2024-06-10 01:00:00 +0000\trefs/remotes/origin/feat1\n"
        "2024-06-10 01:30:00 +0000\trefs/remotes/origin/feat2\n"
        "2024-06-10 02:15:00 +0000\trefs/remotes/origin/feat3\n"
    ).encode()
    deletes = []

    monkeypatch.setattr(
        subprocess,
        "check_output",
        lambda *a, **k: output,
    )

    def fake_run(cmd, check=True):
        deletes.append(cmd)
    monkeypatch.setattr(subprocess, "run", fake_run)

    deleted = github_utils.cleanup_branches()
    assert deleted == ["feat1"]
    assert deletes == [["git", "push", "origin", "--delete", "feat1"]]


