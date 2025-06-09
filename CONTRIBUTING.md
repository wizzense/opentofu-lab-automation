# Contributing

This project uses [Pester](https://github.com/pester/Pester) for PowerShell testing.

## Running tests

1. Install PowerShell and the Pester module if they are not already available.
2. From the repository root, execute:

```powershell
Invoke-Pester -Path tests
```

This runs the test suite found under the `tests/` directory.
