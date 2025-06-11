import json
from pathlib import Path


def update_index() -> Path:
    """Generate repo file index for packaging helpers."""
    repo_root = Path(__file__).resolve().parents[2]
    data = {
        "config_files": sorted(
            str(p.relative_to(repo_root))
            for p in (repo_root / "config_files").glob("*.json")
        ),
        "runner_scripts": sorted(
            str(p.relative_to(repo_root))
            for p in (repo_root / "runner_scripts").glob("*.ps1")
        ),
    }
    index_path = repo_root / "py" / "labctl" / "config_files" / "index.json"
    index_path.write_text(json.dumps(data, indent=2))
    return index_path
