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
    index: dict[str, str] = {}

    for path in tracked_files():
        if path.name == "path-index.yaml":
            continue
        if str(path) in ROOT_FILES or any(str(path).startswith(f"{d}/") for d in SCAN_DIRS):
            index[str(path)] = str(path)

    return index


def main():
    index = build_index()
    index_path = REPO_ROOT / 'path-index.yaml'
    with index_path.open('w') as f:
        yaml.safe_dump(dict(sorted(index.items())), f)
    print(f'Wrote {index_path}')


if __name__ == '__main__':
    main()
