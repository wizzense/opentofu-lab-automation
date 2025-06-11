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


def test_create_issue(monkeypatch):
    called = {}

    def fake_run(cmd, check=True):
        called["cmd"] = cmd

    monkeypatch.setattr(subprocess, "run", fake_run)
    monkeypatch.delenv("GITHUB_REPOSITORY", raising=False)

    github_utils.create_issue("title", "body")

    assert called["cmd"] == ["gh", "issue", "create", "-t", "title", "-b", "body"]


def test_create_issue_with_repo(monkeypatch):
    called = {}

    def fake_run(cmd, check=True):
        called["cmd"] = cmd

    monkeypatch.setattr(subprocess, "run", fake_run)
    monkeypatch.setenv("GITHUB_REPOSITORY", "owner/repo")

    github_utils.create_issue("title", "body")

    assert called["cmd"] == [
        "gh",
        "issue",
        "create",
        "-t",
        "title",
        "-b",
        "body",
        "-R",
        "owner/repo",
    ]


def test_view_issue(monkeypatch):
    called = {}

    def fake_check_output(cmd):
        called["cmd"] = cmd
        return b'{"title":"T","body":"B"}'

    monkeypatch.setattr(subprocess, "check_output", fake_check_output)

    runner = CliRunner()
    result = runner.invoke(app, ["repo", "view-issue", "7"])
    assert result.exit_code == 0
    assert result.stdout.strip() == '{"title":"T","body":"B"}'
    assert called["cmd"] == [
        "gh",
        "issue",
        "view",
        "7",
        "--json",
        "title,body",
    ]


