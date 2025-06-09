# Contributing

This project uses [Pester](https://github.com/pester/Pester) for PowerShell testing.

## Continuous Integration

The GitHub Actions workflow runs linting and Pester tests on Windows, Ubuntu and
macOS runners. Linux and macOS jobs install PowerShell before executing the lint
action and tests.

## Running tests

1. Install PowerShell and the Pester module if they are not already available.
2. From the repository root, execute:

```powershell
Invoke-Pester -Path tests
```

This runs the test suite found under the `tests/` directory. When adding
Windows‑specific tests, guard them with `-Skip:($IsLinux -or $IsMacOS)` so the
suite succeeds across all platforms.
