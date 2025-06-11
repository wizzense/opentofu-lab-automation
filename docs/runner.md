# runner.ps1 guide

`runner.ps1` orchestrates the numbered scripts under `runner_scripts/`.
It loads `config_files/default-config.json` by default and then prompts for script selection unless told otherwise.

## Interactive mode

Simply invoke the script with no parameters using `pwsh -File`:

```powershell
pwsh -File runner.ps1
```

You will be shown a menu to choose which scripts to run. After the selected scripts complete, the menu will appear again so you can run additional scripts without restarting the runner. Type `exit` at the prompt when you are finished.

When prompted to customize the configuration, a menu lists all available
settings. Select one or more entries to edit or choose **Apply recommended
defaults** to merge values from `config_files/recommended-config.json`.

## Non-interactive mode

Supply a comma-separated list of 4-digit script prefixes via `-Scripts` to run without prompts. Combine this with `-Auto` to skip configuration customization and cleanup confirmations.

```powershell
pwsh -File runner.ps1 -Scripts '0006,0007,0008,0009,0010' -Auto
```

To quickly gather system information, run script `0200` directly:

```powershell
pwsh -File runner.ps1 -Scripts '0200'
```

The script now calls `Get-Platform` to detect the host OS. On Windows it
collects features and hotfix data in addition to the basic facts. Linux and
macOS hosts use `uname`, `df` and networking APIs to return similar details.
If the platform cannot be recognised the script exits with code `1` and logs an
"unsupported platform" error.

To suppress informational output, use the `-Quiet` switch (equivalent to
`-Verbosity silent`). For example, to run scripts `0006` and `0007`
silently and non-interactively:

```powershell
pwsh -File runner.ps1 -Scripts '0006,0007' -Auto -Quiet
```

You can also specify the output level directly with the `-Verbosity`
parameter (`silent`, `normal`, or `detailed`).

The default configuration path (`./config_files/default-config.json`) and the `-Auto` switch are defined on lines 1-6. The logic that runs scripts directly when `-Scripts` is provided lives at lines 259-264. Prompts for editing the configuration or confirming cleanup only occur when `-Auto` is not specified, as shown on lines 135-168.

### CI usage

When running in CI or other automated environments, invoke the runner with `pwsh -File` so each step script receives a populated `$PSScriptRoot`:

```powershell
pwsh -File runner.ps1 -Scripts all -Auto
```

Use the provided full configuration file to enable every feature:

```powershell
pwsh -File runner.ps1 -ConfigFile ./config_files/full-config.json -Scripts all -Auto
```

Individual scripts can also be executed directly:

```powershell
pwsh -File runner_scripts/0001_Reset-Git.ps1 -Config ./config_files/default-config.json
```

Step scripts import a small PowerShell module that provides common helpers:

```powershell
Param([pscustomobject]$Config)
Import-Module "$PSScriptRoot/../runner_utility_scripts/LabRunner.psd1"
```

`LabRunner` exposes functions like `Invoke-LabStep`, `Write-CustomLog` and
`Get-Platform` so every script shares the same logging and platform detection
logic.
