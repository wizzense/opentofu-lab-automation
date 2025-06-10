from pathlib import Path
import sys
from typer.testing import CliRunner
import json
import yaml
import pytest

sys.path.append(str(Path(__file__).resolve().parents[1]))

from labctl.cli import app, default_config_path, load_config


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
    conf.write_text("foo: [unclosed")
    with pytest.raises(yaml.YAMLError):
        load_config(conf)
