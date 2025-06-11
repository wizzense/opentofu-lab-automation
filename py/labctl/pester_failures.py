import sys
from pathlib import Path
import xml.etree.ElementTree as ET

from .github_utils import create_issue


def report_failures(xml_path: Path) -> None:
    tree = ET.parse(xml_path)
    root = tree.getroot()
    for case in root.findall(".//test-case[@result='Failed']"):
        title = case.get("name", "Pester test failed")
        message = case.findtext("failure/message", default="")
        create_issue(title, message)


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: pester_failures.py <testResults.xml>")
        sys.exit(1)
    report_failures(Path(sys.argv[1]))
