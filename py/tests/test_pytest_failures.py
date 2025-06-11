from pathlib import Path
import sys
import subprocess

sys.path.append(str(Path(__file__).resolve().parents[1]))

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
    calls = []

    def fake_run(cmd, check=True):
        calls.append(cmd)

    monkeypatch.setattr(subprocess, "run", fake_run)
    pytest_failures.report_failures(xml)

    assert calls == [["gh", "issue", "create", "-t", "pkg.TestCase.test_fail", "-b", "oops"]]
