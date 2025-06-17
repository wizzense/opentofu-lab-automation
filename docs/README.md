# OpenTofu Lab Automation

Kicker script for a fresh Windows Server Core setup with robust error handling and cross-platform support.

## Quick Start - Bootstrap Installation

For a fresh Windows Server Core setup, run this one-liner to get started:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/wizzense/opentofu-lab-automation/refs/heads/main/pwsh/kicker-bootstrap.ps1' -OutFile '.\kicker-bootstrap.ps1'; .\kicker-bootstrap.ps1"
```

## What the Bootstrap Does

1) **Configuration**: Downloads and loads `default-config.json` from the same folder by default (override with `-ConfigFile`).
2) **Git Setup**: Checks if command-line Git is installed and in PATH.
   - Prompts to install a minimal version if missing.
   - Updates PATH if installed but not found in PATH.
3) **GitHub CLI Setup**: Checks if GitHub CLI is installed and in PATH.
   - Prompts to install GitHub CLI if missing.
   - Updates PATH if installed but not found in PATH.
   - Prompts for authentication if not already authenticated.
4) **Repository Clone**: Clones this repository from `config.json -> RepoUrl` to `config.json -> LocalPath` (or a default path).
5) **Runner Execution**: Invokes `runner.ps1` from this repo. Runner can be run with optional parameters to automatically run, but it will prompt you to manually select which scripts to run by default.
   - Use `-ConfigFile <path>` to specify an alternative configuration file. If omitted, `runner.ps1` loads `configs/default-config.json`.

The bootstrap will print the current config and prompt you to customize it interactively.

**Example Infrastructure Repo**: https://github.com/wizzense/tofu-base-lab.git  
**Example Config File**: https://raw.githubusercontent.com/wizzense/tofu-base-lab/refs/heads/main/configs/bootstrap-config.json

## OpenTofu Setup - Essential Scripts

To get OpenTofu setup, you only need to specify these when `runner.ps1` is called: **0006,0007,0008,0009,0010**

## Available Runner Scripts

The runner script can execute the following automation scripts:

### Core Infrastructure Scripts
- **0000_Cleanup-Files.ps1** - Removes lab-infra OpenTofu infrastructure repo
- **0001_Reset-Git.ps1** - Resets lab-infra OpenTofu infrastructure repo (re-pulls files/resets if you modify any files)
- **0006_Install-ValidationTools.ps1** - Downloads the cosign exe to C:\temp\cosign
- **0007_Install-Go.ps1** - Downloads and installs Go
- **0008_Install-OpenTofu.ps1** - Downloads and installs OpenTofu standalone (verified with cosign)
- **0009_Initialize-OpenTofu.ps1** - Sets up OpenTofu and the lab-infra repo in C:\temp\base-infra
- **0010_Prepare-HyperVHost.ps1** - Comprehensive Hyper-V host configuration

### 0010_Prepare-HyperVHost.ps1 Details

This script performs extensive Hyper-V host preparation:

**Hyper-V Configuration:**
- Enables Hyper-V if not enabled
- Enables WinRM if not enabled
  - Sets WinRS MaxMemoryPerShellMB to 1024
  - Sets WinRM MaxTimeoutms to 1800000
  - Sets TrustedHosts to '*'
  - Sets Negotiate to True

**Certificate Management:**
- Creates a self-signed RootCA Certificate (prompts for password)
- Creates self-signed host certificate (prompts for password)
- Configures WinRM HTTPS Listener
- Allows HTTPS 5986 through firewall

**Go Workspace & Provider Setup:**
- Creates a Go workspace in C:\GoWorkspace
- Builds the hyperv-provider for OpenTofu from Taliesins git
- Copies the provider to the lab-infra

> **Note**: Certificate validation for the hyperv provider is currently disabled by default. I am still working out how to get it to use the certificates properly (they may need to be converted to .pem first).

### Optional Administrative Scripts
- **0100_Enable-WinRM.ps1** - Basic WinRM enablement
- **0101_Enable-RemoteDesktop.ps1** - Remote Desktop configuration
- **0102_Configure-Firewall.ps1** - Firewall rule management
- **0103_Change-ComputerName.ps1** - Computer name configuration
- **0104_Install-CA.ps1** - Certificate Authority installation
- **0105_Install-HyperV.ps1** - Hyper-V feature installation
- **0106_Install-WAC.ps1** - Windows Admin Center installation
- **0111_Disable-TCPIP6.ps1** - IPv6 configuration
- **0112_Enable-PXE.ps1** - PXE boot configuration
- **0113_Config-DNS.ps1** - DNS configuration
- **0114_Config-TrustedHosts.ps1** - Trusted hosts configuration

## Usage Instructions

**Run ALL scripts**: Type `all`  
**Run specific scripts**: Provide comma-separated 4-digit prefixes (e.g., `0001,0003,0006,0007,0008,0009,0010`)  
**Exit**: Type `exit` to quit the script

## Configuration Requirements

### OpenTofu Provider Configuration

Make sure to modify the `main.tf` so it uses your admin credentials and hostname/IP of the host machine if you don't have a customized config.json or choose not to customize:

```hcl
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
  script_path     = "C:/Temp/terraform_%RAND%.cmd"
  timeout         = "30s"
}

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
```

### VHD Configuration

You will also need to modify the VHD configuration to create multiple VHD objects with distinct paths:

```hcl
resource "hyperv_vhd" "control_node_vhd" {
  count = var.number_of_vms

  depends_on = [hyperv_network_switch.Lan]

  # Unique path for each VHD (e.g. ...-0.vhdx, ...-1.vhdx, etc.)
  path = "B:\\hyper-v\\PrimaryControlNode\\PrimaryControlNode-Server2025-${count.index}.vhdx"
  size = 60737421312
}
```

### DVD Drive Configuration

```hcl
dvd_drives {
  controller_number   = "0"
  controller_location = "1"
  path                = "B:\\share\\isos\\2_auto_unattend_en-us_windows_server_2025_updated_feb_2025_x64_dvd_3733c10e.iso"
}
```

## Advanced Features

### Cross-Platform Support
- **Windows, Linux, macOS** deployment capability
- **PowerShell 7.4+** cross-platform compatibility
- **Advanced PowerShell Modules**: PatchManager, LabRunner, BackupManager

### Automation & Maintenance
- **Real-time validation** and error correction
- **CI/CD Integration**: GitHub Actions workflows with comprehensive testing
- **Infrastructure as Code**: OpenTofu/Terraform configurations for lab environments

### Module Usage
```powershell
# Import core modules
Import-Module "./pwsh/modules/PatchManager"
Import-Module "./pwsh/modules/LabRunner"

# Run lab automation
Invoke-ParallelLabRunner -ConfigPath "./configs/lab_config.yaml"

# Perform maintenance
./scripts/maintenance/unified-maintenance.ps1 -Mode "All" 
```

## Project Structure

- **/pwsh/modules/**: PowerShell modules (PatchManager, LabRunner, BackupManager)
- **/pwsh/runner_scripts/**: Core automation scripts (0000-0114 series)
- **/scripts/**: Additional automation and maintenance scripts
- **/opentofu/**: Infrastructure as Code configurations
- **/tests/**: Pester test files for validation
- **/.github/workflows/**: CI/CD automation
- **/configs/**: Configuration files and templates

## Future Plans

Will probably change repo name to just 'lab-automation'.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
