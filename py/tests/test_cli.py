from typer.testing import CliRunner
from labctl.cli import app


def test_hv_facts():
    runner = CliRunner()
    result = runner.invoke(app, ["hv", "facts", "--config", "../config_files/default-config.json"])
    assert result.exit_code == 0
    assert "\"Host\"" in result.output


def test_hv_deploy():
    runner = CliRunner()
    result = runner.invoke(app, ["hv", "deploy", "--config", "../config_files/default-config.json"])
    assert result.exit_code == 0
    assert "Deploying Hyper-V host" in result.output
