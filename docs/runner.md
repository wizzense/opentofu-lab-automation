# runner.ps1 Guide

`runner.ps1` orchestrates the numbered scripts under `pwsh/runner_scripts/`.
It loads `configs/config_files/default-config.json` by default and then prompts for script selection unless told otherwise. When launched from Windows PowerShell it automatically restarts itself using `pwsh` so you can simply run `./pwsh/runner.ps1`.

## Interactive Mode

Simply invoke the script from the repository root:

```powershell
./pwsh/runner.ps1
```

You will be shown a menu to choose which scripts to run. After the selected scripts complete, the menu will appear again so you can run additional scripts without restarting the runner. Type `exit` at the prompt when you are finished.

When prompted to customize the configuration, a menu lists all available settings. Select one or more entries to edit or choose **Apply recommended defaults** to merge values from `configs/config_files/recommended-config.json`.

## Non-interactive Mode

Supply a comma-separated list of 4-digit script prefixes via `-Scripts` to run without prompts. Combine this with `-Auto` to skip configuration customization and cleanup confirmations.

```powershell
./pwsh/runner.ps1 -Scripts '0006,0007,0008,0009,0010' -Auto
```

To quickly gather system information, run script `0200` directly:

```powershell
./pwsh/runner.ps1 -Scripts '0200'
```

The script now calls `Get-Platform` to detect the host OS. On Windows it collects features and hotfix data in addition to the basic facts. Linux and macOS hosts use `uname`, `df` and networking APIs to return similar details. If the platform cannot be recognised the script exits with code `1` and logs an "unsupported platform" error.

To suppress informational output, use the `-Quiet` switch (equivalent to `-Verbosity silent`). For example, to run scripts `0006` and `0007` silently and non-interactively:

```powershell
./pwsh/runner.ps1 -Scripts '0006,0007' -Auto -Quiet
```

You can also specify the output level directly with the `-Verbosity` parameter (`silent`, `normal`, or `detailed`).

---

See pester-test-failures.md(pester-test-failures.md) for a tracked list of current test failures.
