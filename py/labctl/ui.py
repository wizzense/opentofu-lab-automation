from __future__ import annotations

import json
import os
from pathlib import Path

from .path_index import resolve_path

from textual.app import App, ComposeResult
from textual.widgets import Header, Footer, DataTable, TextLog, TabPane, TabbedContent, Markdown


class LabUI(App):
    """Simple Textual interface for labctl."""

    CSS_PATH = None
    TITLE = "labctl UI"

    def __init__(self, scripts: list[str], log_path: Path, default_config: Path, recommended_config: Path) -> None:
        super().__init__()
        self.scripts = scripts
        self.log_path = log_path
        self.default_config = default_config
        self.recommended_config = recommended_config

    def compose(self) -> ComposeResult:
        yield Header()
        yield TabbedContent(
            TabPane(self.build_scripts_table(), title="Scripts"),
            TabPane(self.build_log_view(), title="Log"),
            TabPane(self.build_config_view(self.default_config), title="Default Config"),
            TabPane(self.build_config_view(self.recommended_config), title="Recommended Config"),
        )
        yield Footer()

    # --- Widget builders -------------------------------------------------

    def build_scripts_table(self) -> DataTable:
        table = DataTable(zebra_stripes=True)
        table.add_columns("Prefix", "Script")
        for name in self.scripts:
            table.add_row(name[:4], name)
        return table

    def build_log_view(self) -> TextLog:
        log = TextLog(highlight=False, wrap=False)
        if self.log_path.exists():
            log.write(self.log_path.read_text())
        return log

    def build_config_view(self, path: Path) -> Markdown:
        text = path.read_text() if path.exists() else ""
        if path.suffix.lower() == ".json":
            try:
                text = json.dumps(json.loads(text), indent=2)
            except json.JSONDecodeError:
                pass
        return Markdown(text)


def run_ui() -> None:
    """Launch the Textual UI."""
    repo_root = Path(__file__).resolve().parents[2]

    script_dir = resolve_path("pwsh/runner_scripts")
    if script_dir is None:
        script_dir = repo_root / "pwsh" / "runner_scripts"
    scripts = sorted(p.name for p in script_dir.glob("????_*.ps1"))

    log_dir = Path(os.environ.get("LAB_LOG_DIR", Path.cwd()))
    log_path = log_dir / "lab.log"

    default_cfg = resolve_path("configs/config_files/default-config.json")
    if default_cfg is None:
        default_cfg = repo_root / "configs" / "config_files" / "default-config.json"

    recommended_cfg = resolve_path("configs/config_files/recommended-config.json")
    if recommended_cfg is None:
        recommended_cfg = repo_root / "configs" / "config_files" / "recommended-config.json"

    LabUI(scripts, log_path, default_cfg, recommended_cfg).run()
