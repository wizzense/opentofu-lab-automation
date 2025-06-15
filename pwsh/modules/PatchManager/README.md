# PatchManager PowerShell Module

The PatchManager module provides centralized management for patches, fixes, and maintenance tasks in the OpenTofu Lab Automation project.

## Structure

- **PatchManager.psd1** - Module manifest
- **PatchManager.psm1** - Module loader
- **Public/** - Public functions available to users
  - **Invoke-PatchCleanup.ps1** - Consolidates and organizes scattered patch files
  - **Invoke-TestFileFix.ps1** - Fixes common issues in test files
  - **Invoke-YamlValidation.ps1** - Validates and fixes YAML files
  - **Invoke-UnifiedMaintenance.ps1** - Single entry point for all maintenance tasks
  - **Invoke-InfrastructureFix.ps1** - Fixes infrastructure issues
  - **Invoke-RecurringIssueCheck.ps1** - Tracks and resolves known recurring issues
  - **Invoke-ArchiveCleanup.ps1** - Cleans up archive directories and files
  - **Show-MaintenanceReport.ps1** - Generates maintenance reports
- **Private/** - Private helper functions used internally
  - **Write-PatchLog.ps1** - Centralized logging function
  - **Import-FixScripts.ps1** - Imports fix scripts from archive
  - **Repair-TestFile.ps1** - Helper for fixing test files
  - **Remove-ScatteredFiles.ps1** - Helper for cleaning up scattered files
  - **Update-Changelog.ps1** - Helper for updating CHANGELOG.md

## Key Functions

### Invoke-PatchCleanup

Consolidates scattered fix scripts, imports them as module functions, and cleans up the project structure.

```powershell
# Basic usage (safe mode - archives but doesn't delete)
Invoke-PatchCleanup -Mode Safe

# Full cleanup (archives and deletes scattered files, imports as functions)
Invoke-PatchCleanup -Mode Full -UpdateChangelog

# Report only (no changes)
Invoke-PatchCleanup -Mode Report
```

### Invoke-TestFileFix

Applies standardized fixes to test files to ensure consistent execution patterns and resolve common issues.

```powershell
# Fix all common issues in test files
Invoke-TestFileFix

# Fix specific issues only
Invoke-TestFileFix -FixTypes ParamError, DotSourcing

# Generate a report of fixes
Invoke-TestFileFix -CreateReport
```

### Invoke-YamlValidation

Validates and fixes YAML files, especially GitHub workflow files.

```powershell
# Check YAML files
Invoke-YamlValidation -Path ".github/workflows" -Mode Check

# Fix YAML issues automatically
Invoke-YamlValidation -Path ".github/workflows" -Mode Fix
```

### Invoke-UnifiedMaintenance

Single entry point for all maintenance tasks, including health checks, validation, and fixes.

```powershell
# Run quick health check
Invoke-UnifiedMaintenance -Mode Quick

# Run full maintenance with fixes
Invoke-UnifiedMaintenance -Mode All -AutoFix -UpdateChangelog
```

## Integration with CI/CD

The PatchManager module is designed to integrate with CI/CD pipelines:

1. **Pre-commit Validation**: Use `Invoke-YamlValidation` to validate workflow files
2. **Pull Request Testing**: Run `Invoke-UnifiedMaintenance -Mode Quick` for quick checks
3. **Scheduled Maintenance**: Use `Invoke-PatchCleanup` to maintain project structure
4. **Issue Detection**: Use `Invoke-RecurringIssueCheck` to track recurring issues

## Best Practices

1. Always use the module functions instead of standalone scripts
2. Use `Invoke-UnifiedMaintenance` as the primary entry point
3. Use `Invoke-TestFileFix` when creating or updating test files
4. Keep the module updated by running `Invoke-PatchCleanup` periodically
