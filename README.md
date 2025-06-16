# OpenTofu Lab Automation

Cross-platform OpenTofu (Terraform alternative) lab automation project with PowerShell modules for infrastructure automation, YAML workflows for CI/CD, and Python scripts for cross-platform deployment.

## Features

- **Cross-Platform Support**: Windows, Linux, macOS deployment
- **Advanced PowerShell Modules**: PatchManager, LabRunner, BackupManager
- **Automated Maintenance**: Real-time validation and error correction
- **CI/CD Integration**: GitHub Actions workflows with comprehensive testing
- **Infrastructure as Code**: OpenTofu/Terraform configurations for lab environments

## Quick Start

### Prerequisites
- PowerShell 7.4+ (cross-platform)
- Git
- OpenTofu or Terraform

### Installation
`ash
git clone <repository-url>
cd opentofu-lab-automation
./scripts/setup/setup-environment.ps1
`

### Basic Usage
`powershell
# Import core modules
Import-Module "./pwsh/modules/PatchManager"
Import-Module "./pwsh/modules/LabRunner"

# Run lab automation
Invoke-ParallelLabRunner -ConfigPath "./configs/lab_config.yaml"

# Perform maintenance
./scripts/maintenance/unified-maintenance.ps1 -Mode "All" -AutoFix
`

## Documentation

- **[Project Documentation](./docs/)**: Comprehensive guides and references
- **[Contributing Guide](./docs/CONTRIBUTING.md)**: Development guidelines
- **[Testing Framework](./docs/testing-framework.md)**: Test automation details
- **[Automation Quick Reference](./docs/AUTOMATION-QUICKREF.md)**: Common commands

## Project Structure

- **/pwsh/modules/**: PowerShell modules (PatchManager, LabRunner, BackupManager)
- **/scripts/**: Automation and maintenance scripts
- **/opentofu/**: Infrastructure as Code configurations
- **/tests/**: Pester test files for validation
- **/.github/workflows/**: CI/CD automation
- **/docs/**: Project documentation

## Key Modules

### PatchManager
Advanced change management with Git integration:
`powershell
Invoke-GitControlledPatch -PatchDescription "feat: new feature" -PatchOperation { 
    # Your changes 
} -AutoCommitUncommitted -CreatePullRequest
`

### LabRunner
Parallel lab execution and testing:
`powershell
Invoke-ParallelLabRunner -ConfigPath "./configs/lab_config.yaml"
`

### BackupManager
Automated backup and maintenance:
`powershell
Invoke-BackupMaintenance -BackupPath "./backups"
`

## License

This project is licensed under the MIT License - see the LICENSE file for details.
