import platform
import sys


def get_platform() -> str:
    """Return the current operating system as 'Windows', 'Linux', 'MacOS', or 'Unknown'."""
    system = platform.system()
    if system == "Windows":
        return "Windows"
    if system == "Linux":
        return "Linux"
    if system == "Darwin":
        return "MacOS"

    sp = sys.platform
    if sp.startswith("win"):
        return "Windows"
    if sp.startswith("linux"):
        return "Linux"
    if sp.startswith("darwin"):
        return "MacOS"
    return "Unknown"
