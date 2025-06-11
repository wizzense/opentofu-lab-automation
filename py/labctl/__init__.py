
"""labctl package initializer.

Exposes the package version for tooling like ``towncrier``.
"""

from importlib import metadata

try:  # pragma: no cover - fallback for editable installs
    __version__ = metadata.version("labctl")
except metadata.PackageNotFoundError:  # pragma: no cover - not installed
    __version__ = "0.0.0"

__all__ = ["__version__"]
