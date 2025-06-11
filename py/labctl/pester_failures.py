import argparse
import os
from pathlib import Path
import xml.etree.ElementTree as ET

from .github_utils import create_issue


def summarize_failures(xml_path: Path) -> str:
    """Return a markdown list of failing tests in the results file."""
    tree = ET.parse(xml_path)
    root = tree.getroot()
    lines = []
    cases = list(root.findall(".//test-case[@result='Failed']"))
    cases += list(root.findall(".//test-case[@result='Failure']"))
    cases += list(root.findall(".//UnitTestResult[@outcome='Failed']"))

    for case in cases:
        name = case.get("name") or case.get("testName") or "Pester test failed"
        # Support both NUnitXml (<failure><message>) and VSTest (<Output><ErrorInfo><Message>)
        message = case.findtext("failure/message") or case.findtext("Output/ErrorInfo/Message") or ""
        lines.append(f"- **{name}**: {message.strip()}")
    return "\n".join(lines)


def report_failures(xml_path: Path) -> None:
    tree = ET.parse(xml_path)
    root = tree.getroot()
    run_url = os.environ.get("RUN_URL")
    commit = os.environ.get("COMMIT_SHA")
    branch = os.environ.get("BRANCH_NAME")
    os_name = xml_path.parent.name.replace("pester-results-", "")
    details = []
    if run_url:
        details.append(f"Run: {run_url}")
    if commit:
        details.append(f"Commit `{commit}` on branch `{branch}`")
    details.append(f"OS: {os_name}")
    extra = "\n".join(details)
    cases = list(root.findall(".//test-case[@result='Failed']"))
    cases += list(root.findall(".//test-case[@result='Failure']"))
    cases += list(root.findall(".//UnitTestResult[@outcome='Failed']"))

    for case in cases:
        title = case.get("name") or case.get("testName") or "Pester test failed"
        message = case.findtext("failure/message") or case.findtext("Output/ErrorInfo/Message") or ""
        body = f"{message}\n\n{extra}" if message else extra
        create_issue(title, body)


def _main(argv: list[str] | None = None) -> None:
    parser = argparse.ArgumentParser(description="Report or summarize Pester failures")
    parser.add_argument("xml", type=Path, help="Path to testResults.xml")
    parser.add_argument("--summary", action="store_true", help="Print summary instead of creating issues")
    args = parser.parse_args(argv)
    if args.summary:
        print(summarize_failures(args.xml))
    else:
        report_failures(args.xml)


if __name__ == "__main__":
    _main()
