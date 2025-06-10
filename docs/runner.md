# runner.ps1 guide

`runner.ps1` orchestrates the numbered scripts under `runner_scripts/`.
It loads `config_files/default-config.json` by default and then prompts for script selection unless told otherwise.

## Interactive mode

Simply invoke the script with no parameters:

```powershell
./runner.ps1
```

You will be shown a menu to choose which scripts to run. After the selected scripts complete, the menu will appear again so you can run additional scripts without restarting the runner. Type `exit` at the prompt when you are finished.

## Non-interactive mode

Supply a comma-separated list of 4-digit script prefixes via `-Scripts` to run without prompts. Combine this with `-Auto` to skip configuration customization and cleanup confirmations.

```powershell
./runner.ps1 -Scripts '0006,0007,0008,0009,0010' -Auto
```

To suppress informational output, append the `-Quiet` switch. For
example, to run scripts `0006` and `0007` silently and non-interactively:

```powershell
./runner.ps1 -Scripts '0006,0007' -Auto -Quiet
```

`runner.ps1` no longer accepts a `-Verbosity` parameter.

The default configuration path (`./config_files/default-config.json`) and the `-Auto` switch are defined on lines 1-6. The logic that runs scripts directly when `-Scripts` is provided lives at lines 259-264. Prompts for editing the configuration or confirming cleanup only occur when `-Auto` is not specified, as shown on lines 135-168.

