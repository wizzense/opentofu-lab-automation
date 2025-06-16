import platform
import sys
from pathlib import Path

# Add the PowerShell helper directory so `lab_utils` can be imported.
sys.path.append(str(Path(__file__).resolve().parents2 / "pwsh"))

from lab_utils.get_platform import get_platform


def test_get_platform_windows(monkeypatch):
    monkeypatch.setattr(platform, "system", lambda: "Windows")
    assert get_platform() == "Windows"


def test_get_platform_linux(monkeypatch):
    monkeypatch.setattr(platform, "system", lambda: "Linux")
    assert get_platform() == "Linux"


def test_get_platform_macos(monkeypatch):
    monkeypatch.setattr(platform, "system", lambda: "Darwin")
    assert get_platform() == "MacOS"


def test_get_platform_fallback(monkeypatch):
    monkeypatch.setattr(platform, "system", lambda: "SomethingElse")
    monkeypatch.setattr(sys, "platform", "win32")
    assert get_platform() == "Windows"
