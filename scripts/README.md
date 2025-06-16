# Scripts Directory

This directory contains various automation and integration scripts for the OpenTofu Lab Automation project.

## Integration Scripts

- **Install-CodeFixerIntegration.ps1** - Integrates the CodeFixer module with runner scripts
- **Update-Workflows.ps1** - Updates GitHub Actions workflows to use the CodeFixer module
- **Cleanup-DeprecatedFiles.ps1** - Cleans up deprecated files and moves them to archive
- **Deploy-CodeFixerModule.ps1** - Master deployment script for the CodeFixer module
- **Organize-ProjectFiles.ps1** - Organizes and cleans up project files

## Archive Directories

- **archive/** - Contains deprecated scripts and files for reference
- **backups/** - Contains timestamped backups of files before modification

## Documentation

For more information about the project structure and testing framework, see:
- TESTING.md(../docs/TESTING.md)
- INTEGRATION-SUMMARY.md(../INTEGRATION-SUMMARY.md)
