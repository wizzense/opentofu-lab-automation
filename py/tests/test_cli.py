from pathlib import Path
import sys
from typer.testing import CliRunner

sys.path.append(str(Path(__file__).resolve().parents[1]))

from labctl.cli import app, default_config_path


def test_default_config_packaged():
    assert default_config_path().exists()


def test_hv_facts(tmp_path):
    runner = CliRunner()
    env = {"LAB_LOG_DIR": str(tmp_path)}
    result = runner.invoke(app, ["hv", "facts"], env=env)
    assert result.exit_code == 0
    log_file = tmp_path / "lab.log"
    assert log_file.exists()
    assert "\"Host\"" in log_file.read_text()


def test_hv_deploy(tmp_path):
    runner = CliRunner()
    env = {"LAB_LOG_DIR": str(tmp_path)}
    result = runner.invoke(app, ["hv", "deploy"], env=env)
    assert result.exit_code == 0
    log_file = tmp_path / "lab.log"
    assert log_file.exists()
    assert "Deploying Hyper-V host" in log_file.read_text()
