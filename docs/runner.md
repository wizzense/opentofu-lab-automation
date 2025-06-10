# runner.ps1 guide

`runner.ps1` orchestrates the numbered scripts under `runner_scripts/`. It loads `config_files/default-config.json` by default and then prompts for script selection unless told otherwise.

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

To suppress informational output, pass `-Verbosity silent`:

```powershell
./runner.ps1 -Scripts '0006,0007' -Auto -Verbosity silent
```

Use `-Force` to enable configuration flags detected in a script even when the current config sets them to `false`. The updated value is written back to the configuration file after the script completes.
