import subprocess
from datetime import datetime
from collections import defaultdict
from typing import List


def close_pull_request(pr_number: int) -> None:
    """Close a pull request using the GitHub CLI."""
    subprocess.run(["gh", "pr", "close", str(pr_number)], check=True)


def close_issue(issue_number: int) -> None:
    """Close an issue using the GitHub CLI."""
    subprocess.run(["gh", "issue", "close", str(issue_number)], check=True)


def cleanup_branches(remote: str = "origin") -> List[str]:
    """Delete remote branches keeping the newest per hour.

    Returns a list of deleted branch names.
    """
    result = subprocess.check_output(
        [
            "git",
            "for-each-ref",
            f"--format=%(committerdate:iso8601)%09%(refname)",
            f"refs/remotes/{remote}"
        ]
    )
    lines = result.decode().splitlines()

    branches = []
    prefix = f"refs/remotes/{remote}/"
    for line in lines:
        date_str, name = line.split("\t", 1)
        if not name.startswith(prefix):
            continue
        short_name = name[len(prefix):]
        if short_name in {"HEAD", "main", "master"}:
            continue
        dt = datetime.fromisoformat(date_str.replace(" ", "T"))
        branches.append((short_name, dt))

    branches.sort(key=lambda x: x[1], reverse=True)
    keep: dict[str, str] = {}
    delete: List[str] = []
    for name, dt in branches:
        key = dt.strftime("%Y-%m-%d %H")
        if key not in keep:
            keep[key] = name
        else:
            delete.append(name)

    for name in delete:
        subprocess.run(["git", "push", remote, "--delete", name], check=True)

    return delete
