from pathlib import Path
import sys
import subprocess

sys.path.append(str(Path(__file__).resolve().parents[1]))

from labctl import pester_failures


def test_report_failures(tmp_path, monkeypatch):
    xml = tmp_path / "testResults.xml"
    xml.write_text(
        """
<test-results>
  <test-suite>
    <results>
      <test-case name='Pass.Test' result='Passed'>
        <failure/>
      </test-case>
      <test-case name='Fail.Test' result='Failed'>
        <failure>
          <message>boom</message>
        </failure>
      </test-case>
    </results>
  </test-suite>
</test-results>
"""
    )
    calls = []

    def fake_run(cmd, check=True):
        calls.append(cmd)

    monkeypatch.setattr(subprocess, "run", fake_run)
    pester_failures.report_failures(xml)

    assert calls == [["gh", "issue", "create", "-t", "Fail.Test", "-b", "boom"]]
