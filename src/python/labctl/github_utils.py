import os
import subprocess
from datetime import datetime
from typing import List


def close_pull_request(pr_number: int) -> None:
    """Close a pull request using the GitHub CLI."""
    subprocess.run("gh", "pr", "close", str(pr_number), check=True)


def close_issue(issue_number: int) -> None:
    """Close an issue using the GitHub CLI."""
    subprocess.run("gh", "issue", "close", str(issue_number), check=True)


def create_issue(title: str, body: str) -> None:
    """Create a GitHub issue using the CLI."""
    repo = os.environ.get("GITHUB_REPOSITORY")
    cmd = "gh", "issue", "create", "-t", title, "-b", body
    if repo:
        cmd.extend("-R", repo)
    subprocess.run(cmd, check=True)


def cleanup_branches(remote: str = "origin") -> Liststr:
    """Delete remote branches keeping the newest per hour.

    Returns a list of deleted branch names.
    """
    result = subprocess.check_output(
        
            "git",
            "for-each-ref",
            "--format=%(committerdate:iso8601)%09%(refname)",
            f"refs/remotes/{remote}"
        
    )
    lines = result.decode().splitlines()

    branches = 
    prefix = f"refs/remotes/{remote}/"
    for line in lines:
        date_str, name = line.split("\t", 1)
        if not name.startswith(prefix):
            continue
        short_name = namelen(prefix):
        if short_name in {"HEAD", "main", "master"}:
            continue
        dt = datetime.fromisoformat(date_str.replace(" ", "T"))
        branches.append((short_name, dt))

    branches.sort(key=lambda x: x1, reverse=True)
    keep: dictstr, str = {}
    delete: Liststr = 
    for name, dt in branches:
        key = dt.strftime("%Y-%m-%d %H")
        if key not in keep:
            keepkey = name
        else:
            delete.append(name)

    for name in delete:
        subprocess.run("git", "push", remote, "--delete", name, check=True)

    return delete


def view_issue(issue_number: int) -> str:
    """Return the issue title and body as a JSON string."""
    result = subprocess.check_output(
        "gh", "issue", "view", str(issue_number), "--json", "title,body"
    )
    return result.decode()
