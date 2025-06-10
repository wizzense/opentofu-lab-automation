# labctl Python project

This folder houses the Python CLI used for cross-platform tasks.

## Installing dependencies

Install [Poetry](https://python-poetry.org/) and run:

```bash
cd py
poetry install
```

Poetry creates a virtual environment with `labctl` and the test tools.

## Running the CLI

Invoke the helper commands through Poetry:

```bash
poetry run labctl hv facts --config ../config_files/default-config.json
```

See `labctl --help` for available options.

## Running tests

Execute the pytest suite from this directory:

```bash
cd py
pytest -q
```

