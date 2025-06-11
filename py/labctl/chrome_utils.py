import subprocess
import shutil
import time
from typing import Sequence


_CHROME_NAMES = ["google-chrome", "chrome", "chromium", "chromium-browser"]


def _find_chrome_cmd() -> Sequence[str]:
    """Return the command list to launch Google Chrome."""
    for name in _CHROME_NAMES:
        path = shutil.which(name)
        if path:
            return [path]
    if shutil.which("open"):
        return ["open", "-a", "Google Chrome"]
    if shutil.which("cmd"):
        return ["cmd", "/c", "start", "", "chrome"]
    raise FileNotFoundError("Google Chrome executable not found")


def launch_and_close_chrome(delay: float = 1.0) -> None:
    """Launch Google Chrome and close it after *delay* seconds."""
    cmd = _find_chrome_cmd()
    proc = subprocess.Popen(cmd)
    try:
        time.sleep(delay)
    finally:
        proc.terminate()
        proc.wait(timeout=5)

