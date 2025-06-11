import yaml
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]

# directories to scan recursively for files
SCAN_DIRS = [
    'runner_scripts',
    'lab_utils',
    'py/labctl',
    'py/tests',
    'config_files',
]

ROOT_FILES = [
    'runner.ps1',
    'kicker-bootstrap.ps1',
    'kickstart-bootstrap.sh',
]


def build_index():
    index = {}
    for name in ROOT_FILES:
        p = REPO_ROOT / name
        if p.exists():
            index[name] = name
    for d in SCAN_DIRS:
        dir_path = REPO_ROOT / d
        if not dir_path.exists():
            continue
        for path in dir_path.rglob('*'):
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
