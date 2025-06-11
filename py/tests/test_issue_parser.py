from pathlib import Path
import sys

sys.path.append(str(Path(__file__).resolve().parents[1]))

from labctl.issue_parser import parse_issue_body


def test_parse_lint_failure():
    body = (
        "Run [https://run](https://run) for commit `deadbeef` on branch `feat` failed.\n\n"
        "### Failed jobs\n"
        "- [Lint](https://run/job/1) - failure\n\n"
        "### Failing tests\n"
    )
    data = parse_issue_body(body)
    assert data["run_url"] == "https://run"
    assert data["commit"] == "deadbeef"
    assert data["branch"] == "feat"
    assert data["jobs"] == [{"name": "Lint", "url": "https://run/job/1", "status": "failure"}]
    assert data["tests"] == []


def test_parse_failing_tests():
    body = (
        "Run [https://url](https://url) for commit `abc123` on branch `main` failed.\n\n"
        "### Failed jobs\n"
        "- [Pester](https://url/job/2) - failure\n"
        "- [Pytest](https://url/job/3) - failure\n\n"
        "### Failing tests\n"
        "- **Fail.Test**: boom\n"
        "- **pkg.TestCase.test_fail**: oops\n"
    )
    data = parse_issue_body(body)
    assert len(data["jobs"]) == 2
    assert data["tests"] == ["- **Fail.Test**: boom", "- **pkg.TestCase.test_fail**: oops"]

