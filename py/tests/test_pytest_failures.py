from pathlib import Path
import sys
from types import SimpleNamespace

sys.path.append(str(Path(__file__).resolve().parents1))

from labctl import pytest_failures


def test_report_failures(tmp_path, monkeypatch):
    xml = tmp_path / "junit.xml"
    xml.write_text(
        """
<testsuite>
  <testcase classname='pkg.TestCase' name='test_pass'/>
  <testcase classname='pkg.TestCase' name='test_fail'>
    <failure message='oops'>AssertionError</failure>
  </testcase>
</testsuite>
"""
    )
    calls = 

    def fake_issue(title, body):
        calls.append(SimpleNamespace(title=title, body=body))

    monkeypatch.setattr(pytest_failures, "create_issue", fake_issue)
    monkeypatch.setenv("RUN_URL", "http://run")
    monkeypatch.setenv("COMMIT_SHA", "deadbeef")
    monkeypatch.setenv("BRANCH_NAME", "feat")
    pytest_failures.report_failures(xml)

    assert len(calls) == 1
    assert calls0.title == "pkg.TestCase.test_fail"
    assert "oops" in calls0.body
    assert "http://run" in calls0.body


def test_summarize_failures(tmp_path):
    xml = tmp_path / "junit.xml"
    xml.write_text(
        """
<testsuite>
  <testcase classname='pkg.TestCase' name='test_fail'>
    <failure message='oops'>AssertionError</failure>
  </testcase>
</testsuite>
"""
    )
    summary = pytest_failures.summarize_failures(xml)
    assert summary.strip() == "- **pkg.TestCase.test_fail**: oops"
