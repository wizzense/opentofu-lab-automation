# labctl Python CLI

The `labctl` command line tool exposes cross-platform helpers written in Python. It reads its settings from a JSON or YAML configuration file, loading `configs/config_files/default-config.json` when no explicit path is given.
All important scripts and modules are listed in `path-index.yaml` at the repository root. The file is kept up to date by a workflow that runs on each push to `main`, but you can run `python scripts/update_index.py` to rebuild it manually. The `labctl.path_index` module loads the file and provides `load_index()` and `resolve_path(key)` helpers.

Set the `LAB_REPO_ROOT` environment variable to your repository root if a packaged install cannot locate `path-index.yaml`.

## Subcommands

### `hv facts`
Display the Hyper-V section from the configuration file:

```bash
poetry run labctl hv facts
```

Specify an alternative config file with `--config`:

```bash
poetry run labctl hv facts --config my-config.yaml
```

### `hv deploy`
Simulate deploying using the Hyper-V configuration:

```bash
poetry run labctl hv deploy
```

Provide a custom configuration path the same way:

```bash
poetry run labctl hv deploy --config path/to/config.json
```

Both commands simply parse the configuration and print details to the console at this stage.

### Repository helpers

The `repo` group wraps a few common GitHub tasks. These commands require the `gh` CLI to be installed and authenticated:

```bash
poetry run labctl repo close-pr 123
poetry run labctl repo close-issue 42
poetry run labctl repo view-issue 99
poetry run labctl repo parse-issue 99
poetry run labctl repo cleanup
```

---

See [pester-test-failures.md](pester-test-failures.md) for a tracked list of current test failures.

