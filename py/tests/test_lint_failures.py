from pathlib import Path
import sys
from types import SimpleNamespace

sys.path.append(str(Path(__file__).resolve().parents[1]))

from labctl import lint_failures


def test_summarize_warnings(tmp_path):
    log = tmp_path / "lint.txt"
    log.write_text(
        "foo.py:1:1: F401 'os' imported but unused\n"
        "Warning foo.ps1 12 Use of Write-Host\n"
    )
    summary = lint_failures.summarize_warnings(log)
    lines = summary.splitlines()
    assert "foo.py:1:1: F401 'os' imported but unused" in lines
    assert any("Write-Host" in line for line in lines)


def test_report_warnings(tmp_path, monkeypatch):
    log = tmp_path / "lint.txt"
    log.write_text("foo.py:1:1: F401 'os' imported but unused\n")
    calls = []

    def fake_issue(title, body):
        calls.append(SimpleNamespace(title=title, body=body))

    monkeypatch.setattr(lint_failures, "create_issue", fake_issue)
    lint_failures.report_warnings(log)

    assert len(calls) == 1
    assert calls[0].title == "Lint warning or error"
    assert "F401" in calls[0].body
