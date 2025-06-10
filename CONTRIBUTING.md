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

When adding Windows‑specific tests, guard them with
`-Skip:($IsLinux -or $IsMacOS)` so the suite succeeds across all platforms.

## CI failure issues

If the `CI` workflow fails, the `issue-on-fail.yml` workflow automatically opens a GitHub issue summarizing which jobs failed. This helps track flaky tests without manual intervention.
