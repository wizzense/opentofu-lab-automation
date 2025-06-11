import sys
from pathlib import Path
import xml.etree.ElementTree as ET

from .github_utils import create_issue


def report_failures(xml_path: Path) -> None:
    tree = ET.parse(xml_path)
    root = tree.getroot()
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
        create_issue(title, message)


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: pytest_failures.py <junit.xml>")
        sys.exit(1)
    report_failures(Path(sys.argv[1]))
