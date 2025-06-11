# Local testing guidelines

Use the helper scripts in `tools/` to set up everything needed for Pester and pytest.

```bash
# PowerShell
./tools/setup-tests.ps1
# or on Linux/macOS
./tools/setup-tests.sh
```

The scripts install the required PowerShell modules (`Pester`, `powershell-yaml`)
and Python packages. After running them you can execute the suites directly:

```bash
pwsh -NoLogo -NoProfile -Command "Invoke-Pester"
pytest py
```
