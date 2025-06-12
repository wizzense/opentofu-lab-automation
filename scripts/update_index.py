"""Regenerate the repository path index."""

import subprocess
from pathlib import Path

import yaml

REPO_ROOT = Path(__file__).resolve().parents[1]

# directories to scan recursively for files
SCAN_DIRS = [
    'pwsh/runner_scripts',
    'pwsh/lab_utils',
    'py/labctl',
    'py/tests',
    'configs/config_files',
    'tools/iso',
]

ROOT_FILES = [
    'pwsh/runner.ps1',
    'pwsh/kicker-bootstrap.ps1',
    'pwsh/kickstart-bootstrap.sh',
]


def tracked_files():
    """Return a list of git-tracked files relative to the repository root."""

    out = subprocess.check_output(["git", "ls-files"], cwd=REPO_ROOT, text=True)
    return [Path(line) for line in out.splitlines()]


def build_index() -> dict[str, str]:
    """Build a dynamic index of relevant files in the repository."""
    index: dict[str, str] = {}

    # Recursively scan the repository for relevant files
    for path in REPO_ROOT.rglob("*"):
        if path.is_file() and path.suffix in {".ps1", ".py", ".yaml"}:  # Filter by file types
            relative_path = path.relative_to(REPO_ROOT)
            index[str(relative_path)] = str(relative_path)

    return index


def main():
    index = build_index()
    index_path = REPO_ROOT / 'path-index.yaml'

    # Write the index to the YAML file
    with index_path.open('w') as f:
        yaml.safe_dump(dict(sorted(index.items())), f)

    print(f'Updated {index_path} with {len(index)} entries.')


if __name__ == '__main__':
    main()
