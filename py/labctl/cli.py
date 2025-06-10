import json
from pathlib import Path
from importlib.resources import files
import typer
import yaml


def default_config_path() -> Path:
    return Path(files("labctl").joinpath("config_files", "default-config.json"))

app = typer.Typer()
hv_app = typer.Typer()
app.add_typer(hv_app, name="hv")


def load_config(path: Path) -> dict:
    data = path.read_text()
    if path.suffix.lower() in {".yaml", ".yml"}:
        return yaml.safe_load(data)
    return json.loads(data)


@hv_app.command()
def facts(
    config: Path = typer.Option(default_config_path(), exists=True)
):
    """Show hypervisor facts from config."""
    cfg = load_config(config)
    hv = cfg.get("HyperV", {})
    typer.echo(json.dumps(hv, indent=2))


@hv_app.command()
def deploy(
    config: Path = typer.Option(default_config_path(), exists=True)
):
    """Pretend to deploy using the hypervisor config."""
    cfg = load_config(config)
    hv = cfg.get("HyperV", {})
    typer.echo(f"Deploying Hyper-V host: {hv.get('Host', '')}")


if __name__ == "__main__":
    app()

