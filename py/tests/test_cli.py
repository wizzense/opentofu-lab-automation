from pathlib import Path
import sys
from typer.testing import CliRunner

sys.path.append(str(Path(__file__).resolve().parents[1]))

from labctl.cli import app, default_config_path


def test_default_config_packaged():
    assert default_config_path().exists()


def test_hv_facts():
    runner = CliRunner()
    result = runner.invoke(app, ["hv", "facts"])
    assert result.exit_code == 0
    assert "\"Host\"" in result.output


def test_hv_deploy():
    runner = CliRunner()
    result = runner.invoke(app, ["hv", "deploy"])
    assert result.exit_code == 0
    assert "Deploying Hyper-V host" in result.output
