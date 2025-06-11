from pathlib import Path
import sys
from types import SimpleNamespace

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

    def fake_issue(title, body):
        calls.append(SimpleNamespace(title=title, body=body))

    monkeypatch.setattr(pester_failures, "create_issue", fake_issue)
    monkeypatch.setenv("RUN_URL", "http://run")
    monkeypatch.setenv("COMMIT_SHA", "deadbeef")
    monkeypatch.setenv("BRANCH_NAME", "feat")
    pester_failures.report_failures(xml)

    assert len(calls) == 1
    assert calls[0].title == "Fail.Test"
    assert "boom" in calls[0].body
    assert "http://run" in calls[0].body


def test_summarize_failures(tmp_path):
    xml = tmp_path / "testResults.xml"
    xml.write_text(
        """
<test-results>
  <test-suite>
    <results>
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
    summary = pester_failures.summarize_failures(xml)
    assert summary.strip() == "- **Fail.Test**: boom"
