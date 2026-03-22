# DevEnvironment Module

Development environment setup and management for OpenTofu Lab Automation with pre-commit hooks, emoji sanitization, and module import diagnostics.

## Overview

The DevEnvironment module provides tools for setting up and managing development environments, ensuring code quality through pre-commit hooks, handling PowerShell 5.1 compatibility issues, and resolving module import problems.

## Features

- **Pre-commit hooks** - Automated validation before commits
- **Emoji/Unicode sanitization** - Ensure PowerShell 5.1 compatibility
- **Module import diagnostics** - Debug and fix module loading issues
- **Development environment setup** - Automated configuration
- **Environment validation** - Verify development setup
- **Cross-platform** - Works on Windows, Linux, and macOS

## Installation

```powershell
Import-Module "./core-runner/modules/DevEnvironment" -Force
```

## Functions

### Initialize-DevelopmentEnvironment

Sets up a complete development environment.

```powershell
# Initialize development environment
Initialize-DevelopmentEnvironment

# Initialize with custom settings
Initialize-DevelopmentEnvironment -SkipPreCommitHooks -SkipGitConfig

# Initialize with specific IDE
Initialize-DevelopmentEnvironment -IDE "VSCode"
```

**Sets up:**
- Git configuration
- Pre-commit hooks
- VS Code settings (if applicable)
- Module paths
- Logging configuration

### Set-DevelopmentEnvironment

Configures development environment settings.

```powershell
# Set development mode
Set-DevelopmentEnvironment -Mode "Development"

# Set production mode
Set-DevelopmentEnvironment -Mode "Production"

# Configure with custom paths
Set-DevelopmentEnvironment -ProjectRoot "C:/Projects/lab-automation" -LogLevel "DEBUG"
```

### Test-DevelopmentSetup

Validates development environment configuration.

```powershell
# Test current setup
$isValid = Test-DevelopmentSetup

if (-not $isValid) {
    Write-Warning "Development environment needs configuration"
    Initialize-DevelopmentEnvironment
}

# Test with detailed output
Test-DevelopmentSetup -Verbose
```

**Checks:**
- Git configuration
- Module availability
- Pre-commit hooks
- Required tools (pwsh, gh, git)
- Directory structure

## Pre-Commit Hook Functions

### Install-PreCommitHook

Installs pre-commit hook for automated validation.

```powershell
# Install default pre-commit hook
Install-PreCommitHook

# Install with custom script
Install-PreCommitHook -HookScript {
    # Custom validation
    Write-Host "Running custom pre-commit checks..."
    
    # Check for emoji
    $files = git diff --cached --name-only
    foreach ($file in $files) {
        if ((Get-Content $file -Raw) -match '[\p{So}]') {
            Write-Error "Emoji found in $file"
            exit 1
        }
    }
}

# Install with specific checks
Install-PreCommitHook -EnableEmojiCheck -EnableSyntaxCheck -EnableTestCheck
```

**Default checks:**
- PowerShell syntax validation
- Emoji/Unicode detection
- Module manifest validation
- Basic test execution

### Remove-PreCommitHook

Removes pre-commit hook.

```powershell
# Remove pre-commit hook
Remove-PreCommitHook

# Remove with backup
Remove-PreCommitHook -CreateBackup
```

### Test-PreCommitHook

Tests pre-commit hook functionality.

```powershell
# Test pre-commit hook
$result = Test-PreCommitHook

if ($result.Success) {
    Write-Host "Pre-commit hook working correctly" -ForegroundColor Green
} else {
    Write-Warning "Pre-commit hook issues: $($result.Issues -join ', ')"
}

# Test with specific files
Test-PreCommitHook -Files @("./Module.psm1", "./Module.psd1")
```

## Emoji and Unicode Functions

### Remove-ProjectEmojis

Removes emoji and problematic Unicode from project files.

```powershell
# Remove emoji from all project files
Remove-ProjectEmojis

# Remove from specific directory
Remove-ProjectEmojis -Path "./core-runner/modules"

# Preview changes without making them
Remove-ProjectEmojis -WhatIf

# Remove with backup
Remove-ProjectEmojis -CreateBackup
```

**Targets:**
- PowerShell scripts (*.ps1, *.psm1, *.psd1)
- Markdown files (*.md)
- JSON configuration files (*.json)
- Text files (*.txt)

**Replaces:**
- ✅ → [x]
- ❌ → [ ]
- 🚀 → (removed)
- 📝 → (removed)
- Other emoji and special Unicode

## Module Import Diagnostics

### Resolve-ModuleImportIssues

Diagnoses and fixes module import problems.

```powershell
# Diagnose module import issues
Resolve-ModuleImportIssues -ModuleName "LabRunner"

# Fix issues automatically
Resolve-ModuleImportIssues -ModuleName "LabRunner" -AutoFix

# Diagnose all modules
$modules = Get-ChildItem "./core-runner/modules" -Directory
foreach ($module in $modules) {
    Resolve-ModuleImportIssues -ModuleName $module.Name -AutoFix
}
```

**Checks:**
- Module manifest syntax
- Required modules availability
- Function exports
- Path issues
- Circular dependencies

### Logging Integration

Note: The DevEnvironment module exports 'Logging' as a function name, which appears to be for module integration purposes.

## Usage Examples

### Complete Development Setup

```powershell
# Import module
Import-Module "./core-runner/modules/DevEnvironment" -Force

# Initialize development environment
Write-Host "Setting up development environment..." -ForegroundColor Cyan
Initialize-DevelopmentEnvironment

# Install pre-commit hook
Write-Host "Installing pre-commit hook..." -ForegroundColor Cyan
Install-PreCommitHook -EnableEmojiCheck -EnableSyntaxCheck

# Remove existing emoji
Write-Host "Cleaning up emoji from project..." -ForegroundColor Cyan
Remove-ProjectEmojis -CreateBackup

# Validate setup
Write-Host "Validating setup..." -ForegroundColor Cyan
$isValid = Test-DevelopmentSetup

if ($isValid) {
    Write-Host "Development environment ready!" -ForegroundColor Green
} else {
    Write-Warning "Setup incomplete - review warnings above"
}
```

### Pre-Commit Hook Installation

```powershell
# Install comprehensive pre-commit hook
Install-PreCommitHook

# The hook will run before each commit and check:
# - PowerShell syntax errors
# - Emoji and Unicode characters
# - Module manifest validity
# - Basic test execution

# Test the hook
Write-Host "Testing pre-commit hook..."
$testResult = Test-PreCommitHook

if ($testResult.Success) {
    Write-Host "✓ Pre-commit hook configured correctly" -ForegroundColor Green
} else {
    Write-Error "Pre-commit hook has issues"
}
```

### Emoji Cleanup

```powershell
# Preview what would be cleaned
Write-Host "Preview of emoji cleanup:" -ForegroundColor Cyan
Remove-ProjectEmojis -WhatIf

# Prompt for confirmation
$response = Read-Host "Proceed with cleanup? (y/n)"
if ($response -eq 'y') {
    # Clean with backup
    Remove-ProjectEmojis -CreateBackup
    Write-Host "Emoji cleanup complete. Backup created." -ForegroundColor Green
}
```

### Module Import Troubleshooting

```powershell
# Check all modules for import issues
$modules = Get-ChildItem "./core-runner/modules" -Directory

Write-Host "Checking module imports..." -ForegroundColor Cyan
foreach ($module in $modules) {
    Write-Host "  Checking $($module.Name)..." -NoNewline
    
    $issues = Resolve-ModuleImportIssues -ModuleName $module.Name
    
    if ($issues.Count -eq 0) {
        Write-Host " OK" -ForegroundColor Green
    } else {
        Write-Host " Issues found!" -ForegroundColor Yellow
        $issues | ForEach-Object {
            Write-Warning "    $_"
        }
        
        # Try to fix
        Write-Host "  Attempting auto-fix..." -ForegroundColor Cyan
        Resolve-ModuleImportIssues -ModuleName $module.Name -AutoFix
    }
}
```

### PowerShell 5.1 Compatibility Check

```powershell
# Ensure project works with PowerShell 5.1
Write-Host "Checking PowerShell 5.1 compatibility..." -ForegroundColor Cyan

# Remove emoji that cause PS 5.1 parsing errors
Remove-ProjectEmojis

# Test import in PowerShell 5.1 (if available)
if (Get-Command "powershell.exe" -ErrorAction SilentlyContinue) {
    $testScript = {
        Import-Module "./core-runner/modules/LabRunner" -Force
        Write-Host "Import successful"
    }
    
    powershell.exe -NoProfile -Command $testScript
}
```

## Pre-Commit Hook Details

The pre-commit hook script (`.git/hooks/pre-commit`) runs these checks:

```bash
#!/bin/sh
# Pre-commit hook for OpenTofu Lab Automation

# Check PowerShell syntax
pwsh -NoProfile -Command "Get-ChildItem -Recurse -Filter '*.ps1' | ForEach-Object { \$null = [System.Management.Automation.PSParser]::Tokenize((Get-Content \$_.FullName -Raw), [ref]\$null) }"

# Check for emoji
pwsh -NoProfile -Command "Get-ChildItem -Recurse -Filter '*.ps*' | ForEach-Object { if ((Get-Content \$_.FullName -Raw) -match '[\p{So}]') { Write-Error 'Emoji found'; exit 1 } }"

# Run quick tests
pwsh -NoProfile -File "./tests/Run-BulletproofTests.ps1" -TestSuite "Quick"
```

## Configuration

The module uses these environment variables:

- `$env:PROJECT_ROOT` - Project root directory
- `$env:PWSH_MODULES_PATH` - Module search paths
- `$env:DEV_ENVIRONMENT` - Development or Production mode

## Integration with Other Tools

### VS Code Integration

```powershell
# Install VS Code settings
Install-PreCommitHook
Set-DevelopmentEnvironment -IDE "VSCode"

# VS Code tasks are configured to use DevEnvironment
```

### Git Integration

```powershell
# Configure Git for the project
Initialize-DevelopmentEnvironment

# Sets:
# - user.name and user.email (if not set)
# - core.autocrlf (platform-specific)
# - pre-commit hooks
```

## Best Practices

1. **Run Initialize-DevelopmentEnvironment** when first setting up project
2. **Install pre-commit hooks** to catch issues before committing
3. **Remove emoji regularly** to maintain PS 5.1 compatibility
4. **Test module imports** after major changes
5. **Use Test-DevelopmentSetup** to validate environment
6. **Create backups** when using emoji removal
7. **Run diagnostics** when encountering import issues

## Troubleshooting

### Pre-commit hook not running
- Ensure `.git/hooks/pre-commit` is executable
- Check Git configuration: `git config core.hooksPath`
- Verify hook script syntax

### Emoji not being detected
- Check file encoding (should be UTF-8)
- Verify regex pattern in Remove-ProjectEmojis
- Test with known emoji file

### Module import still failing
- Check module manifest syntax
- Verify all required modules exist
- Review module dependencies
- Check for circular imports

## Version History

- **1.0.0**: Initial release with pre-commit hooks and environment setup

## Related Modules

- [Logging](../Logging/) - Used for development logging
- [TestingFramework](../TestingFramework/) - Pre-commit testing
- [PatchManager](../PatchManager/) - Emoji sanitization integration

## Contributing

When adding development environment features:

1. Maintain cross-platform compatibility
2. Include comprehensive validation
3. Test with PowerShell 5.1 and 7.x
4. Update pre-commit hook template
5. Update this README with new functionality
