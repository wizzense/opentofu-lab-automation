import argparse
import re
from pathlib import Path
from typing import Iterable

from .github_utils import create_issue


def _collect_lines(path: Path) -> Iterable[str]:
    if path.is_dir():
        for p in sorted(path.rglob('*.txt')):
            yield from _collect_lines(p)
        return
    with path.open('r', encoding='utf-8', errors='replace') as f:
        for line in f:
            yield line.rstrip()

def summarize_warnings(path: Path) -> str:
    pattern = re.compile(r"(warning|error)", re.IGNORECASE)
    ruff_pattern = re.compile(r".+:\d+:\d+:")
    lines = []
    for line in _collect_lines(path):
        if pattern.search(line) or ruff_pattern.match(line):
            cleaned = line.strip()
            if cleaned:
                lines.append(cleaned)
    # remove duplicates while preserving order
    unique = list(dict.fromkeys(lines))
    return "\n".join(unique)

def report_warnings(path: Path) -> None:
    summary = summarize_warnings(path)
    if not summary:
        return
    for line in summary.splitlines():
        create_issue("Lint warning or error", line)

def _main(argv: list[str] | None = None) -> None:
    parser = argparse.ArgumentParser(description="Report or summarize lint warnings")
    parser.add_argument("path", type=Path, help="Path to log file or directory")
    parser.add_argument("--summary", action="store_true", help="Print summary instead of creating issues")
    args = parser.parse_args(argv)
    if args.summary:
        print(summarize_warnings(args.path))
    else:
        report_warnings(args.path)


if __name__ == "__main__":
    _main()
