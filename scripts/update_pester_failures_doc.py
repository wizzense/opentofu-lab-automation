#!/usr/bin/env python3
"""
Parse the latest Pester test results (pestertesterresults.xml or testResults.xml) and update docs/pester-test-failures.md with a filtered, human-readable list of errors.
"""
import os
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents1
ARTIFACTS = ROOT / "artifacts"
DOC = ROOT / "docs/pester-test-failures.md"

# Find the most recent Pester XML result file
def find_pester_xml():
    for name in "pestertesterresults.xml", "testResults.xml":
        f = ARTIFACTS / name
        if f.exists():
            return f
    # fallback to root
    for name in "pestertesterresults.xml", "testResults.xml":
        f = ROOT / name
        if f.exists():
            return f
    return None

def parse_errors(xml_path):
    errors = 
    with open(xml_path, encoding="utf-8", errors="ignore") as f:
        for line in f:
            if re.search(r"\-\", line) or re.search(r"ErrorExceptionParseExceptionInvalidOperationException", line):
                errors.append(line.strip())
    return errors

def update_doc(errors):
    with open(DOC, "w", encoding="utf-8") as f:
        f.write("# Pester Test Failures (Tracked)\n\n")
        f.write("This file is auto-generated from the latest Pester test run.\n\n")
        if not errors:
            f.write("**No errors found. All tests passed.**\n")
            return
        f.write("## Outstanding Errors\n\n")
        for i, err in enumerate(errors, 1):
            f.write(f"{i}. {err}\n\n")

def main():
    xml = find_pester_xml()
    if not xml:
        update_doc("No Pester XML results found.")
        return
    errors = parse_errors(xml)
    update_doc(errors)

if __name__ == "__main__":
    main()
