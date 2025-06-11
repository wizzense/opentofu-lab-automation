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
    for case in root.findall(".//testcase"):
        failure = case.find("failure")
        if failure is None:
            failure = case.find("error")
        if failure is None:
            continue
        classname = case.get("classname")
        name = case.get("name")
        parts = [p for p in [classname, name] if p]
        title = ".".join(parts) if parts else "Pytest test failed"
        msg = failure.get("message") or (failure.text or "")
        lines.append(f"- **{title}**: {msg.strip()}")
    return "\n".join(lines)


def report_failures(xml_path: Path) -> None:
    tree = ET.parse(xml_path)
    root = tree.getroot()
    run_url = os.environ.get("RUN_URL")
    commit = os.environ.get("COMMIT_SHA")
    branch = os.environ.get("BRANCH_NAME")
    os_name = xml_path.parent.name.replace("pytest-results-", "")
    details = []
    if run_url:
        details.append(f"Run: {run_url}")
    if commit:
        details.append(f"Commit `{commit}` on branch `{branch}`")
    details.append(f"OS: {os_name}")
    extra = "\n".join(details)
    for case in root.findall(".//testcase"):
        failure = case.find("failure")
        if failure is None:
            failure = case.find("error")
        if failure is None:
            continue
        classname = case.get("classname")
        name = case.get("name")
        parts = [p for p in [classname, name] if p]
        title = ".".join(parts) if parts else "Pytest test failed"
        message = failure.get("message") or (failure.text or "")
        body = f"{message}\n\n{extra}" if message else extra
        create_issue(title, body)


def _main(argv: list[str] | None = None) -> None:
    parser = argparse.ArgumentParser(description="Report or summarize pytest failures")
    parser.add_argument("xml", type=Path, help="Path to junit.xml")
    parser.add_argument("--summary", action="store_true", help="Print summary instead of creating issues")
    args = parser.parse_args(argv)
    if args.summary:
        print(summarize_failures(args.xml))
    else:
        report_failures(args.xml)


if __name__ == "__main__":
    _main()
