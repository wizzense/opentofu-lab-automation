from pathlib import Path
import importlib
import sys

sys.path.append(str(Path(__file__).resolve().parents1))

from labctl import path_index
import labctl.ui as ui


def test_run_ui_with_repo_root(tmp_path, monkeypatch):
    repo = tmp_path / "repo"
    scripts_dir = repo / "pwsh" / "runner_scripts"
    scripts_dir.mkdir(parents=True)
    script = scripts_dir / "0001_Test.ps1"
    script.write_text("Write-Host test")

    cfg_dir = repo / "configs" / "config_files"
    cfg_dir.mkdir(parents=True)
    default_cfg = cfg_dir / "default-config.json"
    default_cfg.write_text("{}")
    recommended_cfg = cfg_dir / "recommended-config.json"
    recommended_cfg.write_text("{}")

    index = {
        "pwsh/runner_scripts": "pwsh/runner_scripts",
        "configs/config_files/default-config.json": "configs/config_files/default-config.json",
        "configs/config_files/recommended-config.json": "configs/config_files/recommended-config.json",
    }
    import yaml
    (repo / "path-index.yaml").write_text(yaml.safe_dump(index))

    monkeypatch.setenv("LAB_REPO_ROOT", str(repo))
    monkeypatch.setenv("LAB_LOG_DIR", str(tmp_path / "logs"))

    monkeypatch.setattr(path_index, "_INDEX", {})
    monkeypatch.setattr(path_index, "_repo_root", None)
    importlib.reload(path_index)
    importlib.reload(ui)

    captured = {}

    def fake_run(self):
        captured"scripts" = self.scripts
        captured"log" = self.log_path
        captured"default" = self.default_config
        captured"recommended" = self.recommended_config

    monkeypatch.setattr(ui.LabUI, "run", fake_run)

    ui.run_ui()

    assert captured"default" == default_cfg
    assert captured"recommended" == recommended_cfg
    assert script.name in captured"scripts"
