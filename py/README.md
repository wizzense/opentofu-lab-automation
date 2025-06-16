# labctl Python project

This folder houses the Python CLI used for cross-platform tasks.

## Installing dependencies

Install Poetry(https://python-poetry.org/) or execute
`pwsh/runner_scripts/0204_Install-Poetry.ps1` to bootstrap it automatically, then run:

```bash
cd py
poetry install
```

Poetry creates a virtual environment with `labctl` and the test tools.

## Running the CLI

Invoke the helper commands through Poetry. The CLI loads
`configs/default-config.json` automatically:

```bash
poetry run labctl hv facts
```

See `labctl --help` for available options.

Further examples of the available subcommands are provided in
the Python CLI documentation(../docs/python-cli.md).

## Running tests

Execute the pytest suite from this directory:

```bash
cd py
pytest -q
```


