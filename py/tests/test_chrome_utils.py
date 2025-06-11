import sys
from pathlib import Path
import pytest

sys.path.append(str(Path(__file__).resolve().parents[1]))

from labctl import chrome_utils


class DummyProc:
    def __init__(self, cmd):
        self.cmd = cmd
        self.terminated = False
        self.waited = False

    def terminate(self):
        self.terminated = True

    def wait(self, timeout=None):
        self.waited = True


def test_launch_and_close(monkeypatch):
    called = {}
    def fake_which(name):
        return '/usr/bin/google-chrome' if name == 'google-chrome' else None
    monkeypatch.setattr(chrome_utils.shutil, 'which', fake_which)
    def fake_popen(cmd):
        called['cmd'] = cmd
        return DummyProc(cmd)
    monkeypatch.setattr(chrome_utils.subprocess, 'Popen', fake_popen)
    chrome_utils.launch_and_close_chrome(delay=0)
    assert called['cmd'] == ['/usr/bin/google-chrome']


def test_launch_not_found(monkeypatch):
    monkeypatch.setattr(chrome_utils.shutil, 'which', lambda name: None)
    with pytest.raises(FileNotFoundError):
        chrome_utils.launch_and_close_chrome(delay=0)
