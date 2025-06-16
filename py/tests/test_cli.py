from pathlib import Path
import sys
from typer.testing import CliRunner
import json
import yaml
import pytest

sys.path.append(str(Path(__file__).resolve().parents1))

from labctl.cli import app, default_config_path, load_config
from labctl import update_index


def test_default_config_packaged():
    assert default_config_path().exists()


def test_hv_facts(tmp_path):
    runner = CliRunner()
    env = {"LAB_LOG_DIR": str(tmp_path)}
    result = runner.invoke(app, "hv", "facts", env=env)
    assert result.exit_code == 0
    log_file = tmp_path / "lab.log"
    assert log_file.exists()
    assert "\"Host\"" in log_file.read_text()


def test_hv_deploy(tmp_path):
    runner = CliRunner()
    env = {"LAB_LOG_DIR": str(tmp_path)}
    result = runner.invoke(app, "hv", "deploy", env=env)
    assert result.exit_code == 0

    log_file = tmp_path / "lab.log"
    assert log_file.exists()
    assert "Deploying Hyper-V host" in log_file.read_text()

def test_load_config_json(tmp_path):
    conf = tmp_path / "conf.json"
    conf.write_text(json.dumps({"foo": "bar"}))
    assert load_config(conf) == {"foo": "bar"}


def test_load_config_yaml(tmp_path):
    conf = tmp_path / "conf.yaml"
    conf.write_text("foo: bar")
    assert load_config(conf) == {"foo": "bar"}


def test_load_config_invalid_json(tmp_path):
    conf = tmp_path / "bad.json"
    conf.write_text("{bad json}")
    with pytest.raises(json.JSONDecodeError):
        load_config(conf)


def test_load_config_invalid_yaml(tmp_path):
    conf = tmp_path / "bad.yaml"
    conf.write_text("foo: unclosed")
    with pytest.raises(yaml.YAMLError):
        load_config(conf)


def test_ui_help():
    runner = CliRunner()
    result = runner.invoke(app, "ui", "--help")
    assert result.exit_code == 0


def test_repo_index(monkeypatch, tmp_path):
    called = {}

    def fake_update():
        called"ran" = True
        return tmp_path / "index.json"

    monkeypatch.setattr(update_index, "update_index", fake_update)
    runner = CliRunner()
    result = runner.invoke(app, "repo", "index")
    assert result.exit_code == 0
    assert called.get("ran")
