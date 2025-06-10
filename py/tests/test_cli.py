from typer.testing import CliRunner
from labctl.cli import app


def test_hv_facts_default():
    runner = CliRunner()
    with runner.isolated_filesystem():
        result = runner.invoke(app, ["hv", "facts"])
    assert result.exit_code == 0
    assert "\"Host\"" in result.output


def test_hv_deploy_default():
    runner = CliRunner()
    with runner.isolated_filesystem():
        result = runner.invoke(app, ["hv", "deploy"])
    assert result.exit_code == 0
    assert "Deploying Hyper-V host" in result.output
