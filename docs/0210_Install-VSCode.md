# 0210_Install-VSCode.ps1 – Script Documentation

This script automates the installation of Visual Studio Code on a Windows system as part of the OpenTofu Lab Automation environment.

## Usage

```powershell
Param([object]$Config)
Import-Module "$PSScriptRoot/../lab_utils/LabRunner/LabRunner.psd1"
```
- The script expects a configuration object (`$Config`) as input.
- It must be run in a context where the LabRunner module is available.

## What It Does
- Checks if the `InstallVSCode` flag is set in the config.
- If set and VS Code is not already installed, downloads and installs the latest stable VS Code for Windows.
- Uses `Invoke-LabDownload` and `Start-Process` for installation.
- Logs progress and completion using `Write-CustomLog`.
- If VS Code is already installed, logs and skips installation.
- If the flag is not set, logs and skips installation.

## Example
```powershell
# Example usage in a runner context
$Config = @{ InstallVSCode = $true }
& "$PSScriptRoot/0210_Install-VSCode.ps1" -Config $Config
```

## Exit Codes & Errors
- Errors during download or installation are surfaced via the error stream.
- All actions are logged for troubleshooting.

## Related
- See other runner scripts in `/pwsh/runner_scripts/` for similar automation tasks.
- See the [testing documentation](../docs/testing.md) for how this script is tested with Pester.
