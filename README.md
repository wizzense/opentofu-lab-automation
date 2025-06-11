# opentofu-lab-automation
[![Lint](https://github.com/wizzense/opentofu-lab-automation/actions/workflows/lint.yml/badge.svg)](https://github.com/wizzense/opentofu-lab-automation/actions/workflows/lint.yml)
[![Pester](https://github.com/wizzense/opentofu-lab-automation/actions/workflows/pester.yml/badge.svg)](https://github.com/wizzense/opentofu-lab-automation/actions/workflows/pester.yml)
[![Pytest](https://github.com/wizzense/opentofu-lab-automation/actions/workflows/pytest.yml/badge.svg)](https://github.com/wizzense/opentofu-lab-automation/actions/workflows/pytest.yml)

## Quick start

The easiest way to bootstrap a fresh Windows host is to run the project’s
`kicker-bootstrap.ps1` script located under `pwsh/`. It installs Git and the GitHub CLI if needed,
clones this repository and then launches `runner.ps1`.


```


Powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/wizzense/opentofu-lab-automation/refs/heads/main/pwsh/kicker-bootstrap.ps1' -OutFile '.\kicker-bootstrap.ps1'; .\kicker-bootstrap.ps1 -Quiet"


```
**Note:** `runner.ps1` automatically restarts with `pwsh` when invoked from Windows PowerShell. Ensure PowerShell 7 is installed and available in `PATH`.

### Runner usage

Interactive mode:

```powershell
./pwsh/runner.ps1
```

Fully automated Hyper-V setup:

```powershell
./pwsh/runner.ps1 -Scripts '0006,0007,0008,0009,0010' -Auto
```

Silence most output:

```powershell
./pwsh/runner.ps1 -Scripts '0006,0007,0008,0009,0010' -Auto -Quiet
```

Use a custom configuration file:

```powershell

./pwsh/runner.ps1 -ConfigFile path\to\config.json -Scripts '0006,0007,0008,0009,0010' -Auto

pwsh -File pwsh/runner.ps1 -ConfigFile ./configs/config_files/full-config.json -Scripts all -Auto

```

Force optional script flags and show detailed logs:

```powershell
./pwsh/runner.ps1 -Scripts '0006,0007' -Auto -Force -Verbosity detailed
```

```powershell
pwsh -File pwsh/runner.ps1 -Scripts '0006,0007,0008,0009,0010,0100,0101,0102,0103,0105,0106,0111,0112,0113,0114'
```

### CI usage

In automation scenarios or CI jobs, call the runner using `pwsh -File` so each
child script sees a valid `$PSScriptRoot`:

```powershell
./pwsh/runner.ps1 -Scripts all -Auto
```

Individual step scripts can also be invoked this way when debugging:

```powershell
pwsh -File pwsh/runner_scripts/0001_Reset-Git.ps1 -Config ./configs/config_files/default-config.json
```

The lint workflow installs the GitHub Copilot extension and runs `gh copilot suggest`
after linting. The command scans the repository and provides additional
improvement ideas directly in the workflow logs.

`tools/iso/CustomLint.ps1` performs an additional pass with project specific
rules defined in `pwsh/PSScriptAnalyzerSettings.psd1`. Run it locally to check your
PowerShell files before pushing:

```powershell
pwsh -File tools/iso/CustomLint.ps1 -Target ./pwsh/runner_scripts
```

The script exits with code `1` when Script Analyzer reports any errors.

The optional [Copilot Auto Fix workflow](docs/copilot-auto-fix.md) can comment
on issues with suggested patches. It requires a GitHub CLI token with the
`copilot` scope stored as the repository secret `COPILOT_OAUTH_TOKEN`.

The workflow fails early if the secret is not defined.

Clone this repository and apply the lab template:

```bash
git clone https://github.com/wizzense/opentofu-lab-automation.git
cd opentofu-lab-automation
tofu init
tofu apply -var="lab_config_path=./lab_config.json"
```

The OpenTofu configuration loads its variables from a JSON file. Copy any
example in `configs/config_files/` (for instance `full-config.json`) to
`lab_config.json` and edit it with your Hyper-V credentials, switch details and
VM parameters. `main.tf` reads from this file via the `lab_config_path`
variable.

See [opentofu/examples/hyperv/README.md](opentofu/examples/hyperv/README.md) for a
detailed description of each field.

## Documentation

Detailed guides and module references are located in the [docs](docs/) directory.
Start with [docs/index.md](docs/index.md) for an overview. Direct links to the
Terraform modules:

- [Hyper-V VM module](opentofu/modules/vm/README.md)
- [Network switch module](opentofu/modules/network_switch/README.md)
- [Hyper-V provider configuration](docs/hyperv-provider.md)

## Python CLI

The optional `labctl` command line utility lives in the [py](py/) folder.
It requires Python 3.10 or newer (see [py/pyproject.toml](py/pyproject.toml)).
Install its dependencies with [Poetry](https://python-poetry.org/) and run the
subcommands via `poetry run`. Set `InstallPoetry` in your configuration to have
`runner.ps1` execute `0204_Install-Poetry.ps1` automatically. You can override
the version with `PoetryVersion`.

Important script locations are tracked in `path-index.yaml`. A GitHub workflow regenerates it on each push to `main`, but you can also run `python scripts/update_index.py` manually. Use `labctl.path_index.resolve_path()` to look up paths from Python or the helper in `runner.ps1`.

When running a packaged install, set the `LAB_REPO_ROOT` environment variable to your repository root if the CLI cannot locate `path-index.yaml` automatically.

```bash
cd py
poetry install
```

### Hyper-V helpers

```bash
poetry run labctl hv facts       # print Hyper-V configuration
poetry run labctl hv deploy      # simulate a Hyper-V deployment
```

### Repository helpers

These require the [GitHub CLI](https://cli.github.com/) to be available and
authenticated:

```bash
poetry run labctl repo close-pr 123
poetry run labctl repo close-issue 42
poetry run labctl repo view-issue 99
poetry run labctl repo cleanup
```

Launch the experimental Textual interface:

```bash
poetry run labctl ui
```

See [docs/python-cli.md](docs/python-cli.md) for further details.



The repo expects the latest stable code on the `main` branch. When running
`tools/iso/bootstrap.ps1`, you can override the branch with the `-Branch`
parameter if needed.

Linux users can run `./pwsh/kickstart-bootstrap.sh` to download the example
`kickstart.cfg` and launch a Kickstart-based install via `virt-install`.

It will prompt print the current config and prompt you to customize it interactively. 
The bootstrap script shows your current configuration and opens a simple menu
based editor so you can tweak only the settings you care about. A menu option
lets you apply the recommended defaults from `configs/config_files/recommended-config.json`
for a quick start.



Example opentofu-infra repo: https://github.com/wizzense/tofu-base-lab.git
Example config file: https://raw.githubusercontent.com/wizzense/tofu-base-lab/refs/heads/main/configs/bootstrap-config.json

To get opentofu setup, really you only need to specify these when runner.ps1 is called: 0006,0007,0008,0009,0010

The runner script can run the following: 

0000_Cleanup-Files.ps1 - Removed lab-infra opentofu infrastructure repo

0001_Reset-Git.ps1 - resets the lab-infra opentofu repository if you modify any files and want to re-pull or reset them

0002_Setup-Directories.ps1 - creates directories for Hyper-V data and ISO sharing

0006_Install-ValidationTools.ps1 - downloads the  cosign exe to C:\temp\cosign

0007_Install-Go.ps1 - downloads and installs Go

0008_Install-OpenTofu.ps1 - Downloads and installs opentofu standalone (verified with cosign). The version used comes from `OpenTofuVersion` in `default-config.json` and defaults to `latest`.

0009_Initialize-OpenTofu.ps1 - setups up opentofu and the lab-infra repo in C:\temp\base-infra

0205_Install-Sysinternals.ps1 - downloads the Sysinternals Suite to the path specified by `SysinternalsPath` and verifies `PsInfo.exe`

0010_Prepare-HyperVHost.ps1 - configures Hyper-V and downloads the provider from the registry

- Enables hyper-v if not enabled
  
- enables WinRM if not enabled
  
  - WinRS MaxMemoryPerShellMB to 1024
    
  - WinRM MaxTimeoutms to 1800000
    
  - TrustedHosts to '*'
    
  - Negotiate to True
    
- creates a self-signed RootCA Cert (prompts for password)
  
- creates self-signed host certificate (prompts for password)
  
- Configured WinRM HTTPs Listener
  
- Allows HTTP 5986 through firewall
  
- Downloads the Hyper-V provider from the Terraform registry
    
  - Copies the provider to the lab-infra
  - Converts the generated certificates to PEM files and updates `providers.tf`

**Certificate prerequisites**

- You will be prompted for passwords when creating the Root CA and host certificates. Use the same password when asked.
- Ensure WinRM HTTPS (port 5986) is allowed through the firewall.
- Typical WinRM settings set by the script: `WinRS MaxMemoryPerShellMB = 1024`, `WinRM MaxTimeoutms = 1800000`, `TrustedHosts = '*'`, `Negotiate = True`.

Scripts `0006`–`0010` form the minimal path to a working Hyper‑V provider. On Server Core 2025 you can run them non‑interactively with:

```powershell
./pwsh/runner.ps1 -Scripts '0006,0007,0008,0009,0010' -Auto -Quiet
```
You can also pass `-Verbosity` with `silent`, `normal`, or `detailed` to control
the amount of console logging.

Completely optional scripts I use for other tasks:
-a----          3/7/2025   7:08 AM            616 0100_Enable-WinRM.ps1
-a----          3/7/2025   7:08 AM            725 0101_Enable-RemoteDesktop.ps1
-a----          3/7/2025   7:08 AM            613 0102_Configure-Firewall.ps1
-a----          3/7/2025   7:08 AM           1203 0103_Change-ComputerName.ps1
-a----          3/7/2025   7:08 AM           1895 0104_Install-CA.ps1
-a----          3/7/2025   7:08 AM           1141 0105_Install-HyperV.ps1
-a----          3/7/2025   7:08 AM           2568 0106_Install-WAC.ps1
-a----          3/7/2025   7:08 AM            272 0111_Disable-TCPIP6.ps1
-a----          3/7/2025   7:08 AM            705 0112_Enable-PXE.ps1
-a----          3/7/2025   7:08 AM            351 0113_Config-DNS.ps1
-a----          3/7/2025   7:08 AM            259 0114_Config-TrustedHosts.ps1

To run ALL scripts, type 'all'.
To run one or more specific scripts, provide comma separated 4-digit prefixes (e.g. 0001,0003).
Or type 'exit' to quit this script.

## Logging

All scripts output to the console using `Write-CustomLog`. If no log file is
specified, a file named `lab.log` is created in `C:\temp` on Windows (or the
system temporary directory on other platforms). Set the `LAB_LOG_DIR`
environment variable or `$script:LogFilePath` to override the location. The
`labctl` Python CLI uses the same variable and writes to `lab.log` within that
directory.
Prompts displayed during script execution use `Read-LoggedInput`, so user
responses are recorded in the same log file (except secure inputs).

Make sure to modify the 'main.tf' so it uses your admin credentials and hostname/IP of the host machine if you don't have a customized config.json or choose not to customize.

provider "hyperv" {
  user            = "ad\\administrator"
  password        = ""
  host            = "192.168.1.121"
  port            = 5986
  https           = true
  insecure        = true  # This skips SSL validation
  use_ntlm        = true  # Use NTLM as it's enabled on the WinRM service
  tls_server_name = ""
  cacert_path     = ""    # Leave empty if skipping SSL validation
  cert_path       = ""    # Leave empty if skipping SSL validation
  key_path        = ""    # Leave empty if skipping SSL validation
  script_path     = "C:/Temp/tofu_%RAND%.cmd"
  timeout         = "30s"
}

See [docs/hyperv-provider.md](docs/hyperv-provider.md) for a description of each
argument and the matching environment variables.


variable "hyperv_host_name" {
  type    = string
  default = "192.168.1.121"
}

variable "hyperv_user" {
  type    = string
  default = "ad\\administrator"
}

variable "hyperv_password" {
  type    = string
  default = ""
}

You will also have to modify:


hyperv_vhd: Create multiple VHD objects (one per VM) with distinct paths

resource "hyperv_vhd" "control_node_vhd" {
  count = var.number_of_vms

  depends_on = [hyperv_network_switch.Lan]

  Unique path for each VHD (e.g. ...-0.vhdx, ...-1.vhdx, etc.)
  path = "B:\\hyper-v\\PrimaryControlNode\\PrimaryControlNode-Server2025-${count.index}.vhdx"
  size = 60737421312
}

And:

  dvd_drives {
    controller_number   = "0"
    controller_location = "1"
    path                = "B:\\share\\isos\\2_auto_unattend_en-us_windows_server_2025_updated_feb_2025_x64_dvd_3733c10e.iso"
  }


Will probably change repo name to just 'lab-automation'.

## Node dependency configuration

Node-related installs are controlled under the `Node_Dependencies` section of
`default-config.json`:

```json
"Node_Dependencies": {
  "InstallNode": true,
  "InstallYarn": true,
  "InstallVite": true,
  "InstallNodemon": true,
  "InstallNpm": true,
  "GlobalPackages": ["yarn", "vite", "nodemon"],
  "NpmPath": "C:\\Projects\\vde-mvp\\frontend",
  "CreateNpmPath": false,
  "Node": {
    "InstallerUrl": "https://nodejs.org/dist/v20.11.1/node-v20.11.1-x64.msi"
  }
}
```

The `GlobalPackages` array is the preferred way to list npm packages for
`0202_Install-NodeGlobalPackages.ps1`. The older boolean flags (`InstallYarn`,
`InstallVite`, `InstallNodemon`) are still honored for backward compatibility.

The scripts `0201_Install-NodeCore.ps1`, `0202_Install-NodeGlobalPackages.ps1`
and `0203_Install-npm.ps1` read these keys when installing Node, global npm
  packages, or project dependencies.

## Additional installer scripts

Several optional scripts install common development tools when their matching
flag is enabled in `default-config.json`:

- `0206_Install-Python.ps1` – install Python 3.x
- `0207_Install-Git.ps1` – install Git for Windows
- `0208_Install-DockerDesktop.ps1` – install Docker Desktop
- `0209_Install-7Zip.ps1` – install the 7-Zip archiver
- `0210_Install-VSCode.ps1` – install Visual Studio Code
- `0211_Install-VSBuildTools.ps1` – install Visual Studio Build Tools
- `0212_Install-AzureCLI.ps1` – install Azure CLI
- `0213_Install-AWSCLI.ps1` – install AWS CLI
- `0214_Install-Packer.ps1` – install HashiCorp Packer
- `0215_Install-Chocolatey.ps1` – bootstrap the Chocolatey package manager

## Directory configuration

Directories used by several scripts are defined under the `Directories` section
of `default-config.json`:

```json
"Directories": {
  "HyperVPath": "C:\\HyperV",
  "IsoSharePath": "C:\\iso_share"
}
```

`0002_Setup-Directories.ps1` ensures these locations exist before other steps
run.

## Hyper-V configuration

Hyper-V installation options are defined under the `HyperV` section of
`default-config.json`. The `EnableManagementTools` flag controls whether the
Hyper-V management tools are installed alongside the main feature.

```json
"HyperV": {
  "EnableManagementTools": true,
  "User": "",
  "Password": "",
  ...
}
```

`0105_Install-HyperV.ps1` reads this value when calling
`Install-WindowsFeature`. If the property is missing, the script defaults to
`true`.

## Troubleshooting

If you encounter `fatal: Class not registered` after a browser window briefly opens,
the Git credential manager could not launch the authentication flow.
Install the [GitHub CLI](https://cli.github.com/) and authenticate once before
running the automation scripts:

```powershell
gh auth login
gh repo clone <owner/repo>
```

Using `gh` avoids the COM initialization issues seen with some Git installations
and prevents Git from prompting for a username like `user@github.com`.

The bootstrap script automatically marks the cloned repository as a
`safe.directory` in your global Git config. If you encounter a
"detected dubious ownership" error when running Git manually,
add the path yourself:

```powershell
git config --global --add safe.directory <path>
```

## Running tests

Run `pwsh/setup-test-env.ps1` to install Python, Pester and the required dev packages automatically. Add `-UsePoetry` to prefer Poetry for managing the Python dependencies.


PowerShell 7 or later is required to run the Pester suite. Install `pwsh` with
your platform's package manager and then execute the tests:

```bash
# Windows
winget install --id Microsoft.PowerShell -e

# Debian/Ubuntu
sudo apt-get update && sudo apt-get install -y powershell

# macOS
brew install --cask powershell

pwsh -NoLogo -NoProfile -Command "Invoke-Pester"
```

Windows-specific tests must run on a Windows host. If you don't have one
available, rely on the CI pipeline and fetch the job results with
`lab_utils/Get-WindowsJobArtifacts.ps1` once the run completes. A quick
workflow is:

1. Edit your files.
2. `git commit -am "<message>"`
3. `git push`
4. Run `lab_utils/Get-WindowsJobArtifacts.ps1` to download the artifacts.

The suite includes a YAML parsing test that is skipped unless the
`powershell-yaml` module is installed. Install it (optionally) with:

```powershell
Install-Module powershell-yaml -Scope CurrentUser
```

Download the latest Windows test results with `lab_utils/Get-WindowsJobArtifacts.ps1`.
If the GitHub CLI isn't authenticated, the script falls back to public
downloads via the nightly.link service. You can also pass a specific
workflow run ID obtained from `gh run list`. Because run IDs are 64-bit
integers, wrap the value in quotes on PowerShell. Coverage archives are
only uploaded when the tests pass, so the helper will skip them if absent:

```powershell
gh run list --limit 20
lab_utils/Get-WindowsJobArtifacts.ps1 -RunId "<id>"
```

Python unit tests live under `py/`. `pwsh/setup-test-env.ps1` installs the required packages automatically, but you can also install them manually using
either Poetry or a direct `pip` install to get packages like `typer`:

```bash
# with Poetry
poetry install

# or with pip
pip install -e ./py
```

Once installed, run the pytest suite:

```bash
cd py
poetry run pytest
```

## Utility scripts

`lab_utils/Get-Platform.ps1` detects the current platform.
Load the function and call it to get `Windows`, `Linux` or `MacOS`.

```powershell
. ./lab_utils/Get-Platform.ps1
Get-Platform
```

Use this output to branch your automation logic according to the host
operating system. Check the other `lab_utils` scripts for additional
cross-platform helpers.

