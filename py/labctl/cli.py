import json
import logging
import os
from pathlib import Path
from importlib.resources import files
import typer
import yaml

from . import github_utils, issue_parser


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
repo_app = typer.Typer(help="Simple GitHub repository utilities")
app.add_typer(hv_app, name="hv")
app.add_typer(repo_app, name="repo")


@app.command()
def ui() -> None:
    """Launch the Textual user interface."""
    from .ui import run_ui

    run_ui()


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


@repo_app.command("close-pr")
def close_pr(pr_number: int):
    """Close a pull request."""
    github_utils.close_pull_request(pr_number)
    logger.info("Closed pull request #%s", pr_number)


@repo_app.command("close-issue")
def close_issue(issue_number: int):
    """Close an issue."""
    github_utils.close_issue(issue_number)
    logger.info("Closed issue #%s", issue_number)


@repo_app.command("view-issue")
def view_issue(issue_number: int):
    """Output issue details as JSON."""
    data = github_utils.view_issue(issue_number)
    typer.echo(data)


@repo_app.command("parse-issue")
def parse_issue(issue_number: int):
    """Parse an issue created by the failure workflow."""
    raw = github_utils.view_issue(issue_number)
    info = json.loads(raw)
    parsed = issue_parser.parse_issue_body(info.get("body", ""))
    typer.echo(json.dumps(parsed))


@repo_app.command()
def cleanup(
    remote: str = typer.Option("origin", help="Remote name"),
):
    """Delete merged branches while keeping the newest per hour."""
    deleted = github_utils.cleanup_branches(remote=remote)
    for name in deleted:
        logger.info("Deleted branch %s", name)


if __name__ == "__main__":
    app()

