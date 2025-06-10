import json
import logging
import os
from pathlib import Path
from importlib.resources import files
import typer
import yaml


def default_config_path() -> Path:
    """Return the path to the packaged default configuration file."""

    return Path(files("labctl").joinpath("config_files", "default-config.json"))

logger = logging.getLogger("labctl")


def configure_logger() -> None:
    """Configure logging to console and optional log file."""

    handlers = [logging.StreamHandler()]
    log_dir = os.environ.get("LAB_LOG_DIR")
    if log_dir:
        log_file = Path(log_dir) / "lab.log"
        log_file.parent.mkdir(parents=True, exist_ok=True)
        handlers.append(logging.FileHandler(log_file))

    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s %(levelname)s %(message)s",
        handlers=handlers,
        force=True,
    )


app = typer.Typer()
hv_app = typer.Typer()
app.add_typer(hv_app, name="hv")


@app.callback(invoke_without_command=True)
def main(ctx: typer.Context):
    """Initialize logging before executing commands."""

    configure_logger()


def load_config(path: Path) -> dict:
    """Load and parse a JSON or YAML config file into a dictionary."""

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
    logger.info(json.dumps(hv, indent=2))


@hv_app.command()
def deploy(
    config: Path = typer.Option(default_config_path(), exists=True)
):
    """Pretend to deploy using the hypervisor config."""
    cfg = load_config(config)
    hv = cfg.get("HyperV", {})
    logger.info("Deploying Hyper-V host: %s", hv.get("Host", ""))


if __name__ == "__main__":
    app()

