import yaml
from pathlib import Path

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


def build_index():
    index = {}
    for name in ROOT_FILES:
        p = REPO_ROOT / name
        if p.exists():
            index[name] = name
    excluded_dirs = {'__pycache__', '.git', '.svn'}
    for d in SCAN_DIRS:
        dir_path = REPO_ROOT / d
        if not dir_path.exists():
            continue
        for path in dir_path.rglob('*'):
            if any(part in excluded_dirs for part in path.parts):
                continue
            if path.is_file():
                rel = path.relative_to(REPO_ROOT)
                index[str(rel)] = str(rel)
    return index


def main():
    index = build_index()
    index_path = REPO_ROOT / 'path-index.yaml'
    with index_path.open('w') as f:
        yaml.safe_dump(dict(sorted(index.items())), f)
    print(f'Wrote {index_path}')


if __name__ == '__main__':
    main()
