import json
import importlib.resources
from pathlib import Path
from typing import Optional

import typer
import yaml

app = typer.Typer()
hv_app = typer.Typer()
app.add_typer(hv_app, name="hv")


def _read_default_config() -> str:
    """Return the bundled default configuration as text."""
    return (
        importlib.resources.files("labctl")
        .joinpath("config_files", "default-config.json")
        .read_text()
    )


def load_config(path: Optional[Path] = None) -> dict:
    """Load JSON or YAML configuration from *path* or bundled default."""
    if path is None:
        data = _read_default_config()
        suffix = ".json"
    else:
        data = path.read_text()
        suffix = path.suffix.lower()

    if suffix in {".yaml", ".yml"}:
        return yaml.safe_load(data)
    return json.loads(data)


@hv_app.command()
def facts(
    config: Optional[Path] = typer.Option(
        None, help="Path to config file (defaults to packaged config)"
    )
):
    """Show hypervisor facts from config."""
    cfg = load_config(config)
    hv = cfg.get("HyperV", {})
    typer.echo(json.dumps(hv, indent=2))


@hv_app.command()
def deploy(
    config: Optional[Path] = typer.Option(
        None, help="Path to config file (defaults to packaged config)"
    )
):
    """Pretend to deploy using the hypervisor config."""
    cfg = load_config(config)
    hv = cfg.get("HyperV", {})
    typer.echo(f"Deploying Hyper-V host: {hv.get('Host', '')}")


if __name__ == "__main__":
    app()
