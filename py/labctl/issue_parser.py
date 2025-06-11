import re
from typing import Any, Dict, List


def parse_issue_body(text: str) -> Dict[str, Any]:
    """Parse issue body produced by the issue-on-fail workflow."""
    result: Dict[str, Any] = {
        "run_url": None,
        "commit": None,
        "branch": None,
        "jobs": [],
        "tests": [],
    }

    # First line: Run [url](url) for commit `sha` on branch `branch` failed.
    first_line = text.strip().splitlines()[0] if text.strip() else ""
    m = re.search(
        r"Run \[(?P<url>[^\]]+)\]\([^\)]+\) for commit `(?P<sha>[0-9a-fA-F]+)` on branch `(?P<branch>[^`]+)`",
        first_line,
    )
    if m:
        result["run_url"] = m.group("url")
        result["commit"] = m.group("sha")
        result["branch"] = m.group("branch")

    # Split sections by headings
    sections: Dict[str, List[str]] = {}
    current = None
    for line in text.splitlines():
        if line.startswith("### "):
            current = line[4:].strip()
            sections[current] = []
            continue
        if current:
            sections[current].append(line)

    # Parse jobs
    for line in sections.get("Failed jobs", []):
        m = re.search(r"- \[(?P<name>[^\]]+)\]\((?P<url>[^)]+)\) - (?P<status>.+)", line)
        if m:
            result["jobs"].append({
                "name": m.group("name"),
                "url": m.group("url"),
                "status": m.group("status"),
            })

    # Parse failing tests lines
    tests = [line for line in sections.get("Failing tests", []) if line.strip()]
    result["tests"] = tests

    return result
