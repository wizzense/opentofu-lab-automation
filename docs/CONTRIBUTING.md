# Contributing

This project uses [Pester](https://github.com/pester/Pester) for PowerShell testing.

## Continuous Integration

The GitHub Actions workflow runs linting and Pester tests on Windows, Ubuntu and
macOS runners. Linux and macOS runners generally include `pwsh` already; the
workflow installs PowerShell only if the command is missing so the steps run
consistently across images.

### Test setup

Install the Python development dependencies so `pytest` and the CLI helpers are
available in a virtual environment:

```bash
cd py
poetry install --with dev
```

## Running tests

Run `pwsh/setup-test-env.ps1` to install Pester, Python and the Python dev dependencies automatically.


Run the Pester suite using PowerShell:

```bash
pwsh -NoLogo -NoProfile -Command "Invoke-Pester"
```

Python tests live under the `py` directory:

```bash
cd py && pytest
```

The `task test` shortcut (defined in InvokeBuild) wraps these commands and
executes the same steps as the CI pipeline.

Whenever paths to scripts or config files change, run:

```bash
poetry run labctl repo index
```

This regenerates the packaged index used by the CLI.

When adding Windows‑specific tests, guard them with
`-Skip:($IsLinux -or $IsMacOS)` so the suite succeeds across all platforms.

## Changelog entries

This project uses [towncrier](https://github.com/twisted/towncrier) to manage the
changelog. For each pull request, create a news fragment under `newsfragments/`
describing your change. Run `towncrier create` and commit the generated file.
The changelog is automatically updated on merges to `main`.

## CI failure issues
executes the same steps as the lint, Pester and Pytest workflows.
