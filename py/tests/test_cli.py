from pathlib import Path
from typer.testing import CliRunner
from labctl.cli import app

CONFIG_PATH = Path(__file__).resolve().parents[2] / "config_files" / "default-config.json"
assert CONFIG_PATH.exists(), f"Config file missing: {CONFIG_PATH}"


def test_hv_facts():
    runner = CliRunner()
    result = runner.invoke(app, ["hv", "facts", "--config", str(CONFIG_PATH)])
    assert result.exit_code == 0
    assert "\"Host\"" in result.output


def test_hv_deploy():
    runner = CliRunner()
    result = runner.invoke(app, ["hv", "deploy", "--config", str(CONFIG_PATH)])
    assert result.exit_code == 0
    assert "Deploying Hyper-V host" in result.output
