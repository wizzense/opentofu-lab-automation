# filepath: /workspaces/opentofu-lab-automation/docs/testing-framework.md
# Extensible Testing Framework

## Overview

This project uses an extensible, cross-platform testing framework that automatically:
- **Generates tests** for new PowerShell scripts
- **Enforces naming conventions** 
- **Categorizes tests** by functionality
- **Supports platform-specific testing**
- **Integrates with CI/CD pipelines**

## Script Naming Conventions

### Standard Scripts
- Use **PascalCase** with **Verb-Noun** pattern
- Examples: `Install-Node.ps1`, `Configure-DNS.ps1`, `Enable-WinRM.ps1`

### Runner Scripts (in `pwsh/runner_scripts/`)
- Use **4-digit sequence number** + **Verb-Noun** pattern
- Format: `nnnn_Verb-Noun.ps1`
- Examples: `0101_Install-Git.ps1`, `0201_Configure-Environment.ps1`

### Test Files
- Automatically generated as `ScriptName.Tests.ps1`
- Examples: `Install-Node.Tests.ps1`, `0101_Install-Git.Tests.ps1`

## Automatic Test Generation

### How It Works
1. **File Monitoring**: GitHub Actions detects new/modified PowerShell scripts
2. **Name Validation**: Automatically renames scripts to follow conventions
3. **Test Generation**: Creates comprehensive test files based on script analysis
4. **Platform Detection**: Determines platform compatibility and requirements
5. **Category Assignment**: Assigns tests to categories (Installer, Configuration, etc.)

### Manual Test Generation
```powershell
# Generate test for specific script
./tests/helpers/New-AutoTestGenerator.ps1 -ScriptPath "pwsh/runner_scripts/0301_Install-NewTool.ps1"

# Generate tests for all scripts in directory
./tests/helpers/New-AutoTestGenerator.ps1 -WatchDirectory "pwsh/runner_scripts"

# Start file watcher for automatic generation
./tests/helpers/New-AutoTestGenerator.ps1 -WatchMode -WatchIntervalSeconds 30
```

## Test Categories

The framework automatically categorizes tests:

### Installer Tests
- Scripts containing: `Install-`, `Download-`, `Invoke-WebRequest`
- Tests: Prerequisites, download handling, installation verification
- Platform: Often Windows-specific for `.msi`/`.exe` installers

### Configuration Tests  
- Scripts containing: `Configure-`, `Set-.*Config`, `Config-`
- Tests: Backup, validation, rollback functionality
- Platform: Cross-platform with OS-specific variations

### Service Tests
- Scripts containing: `Start-Service`, `Stop-Service`, service management
- Tests: Service status, operations, configuration
- Platform: Windows (services) or Linux (systemd)

### Feature Tests
- Scripts containing: `Enable-`, `Disable-`, Windows Features
- Tests: Feature state, dependencies, prerequisites
- Platform: Usually Windows-specific

### Maintenance Tests
- Scripts containing: `Reset-`, `Cleanup-`, `Remove-`
- Tests: Safety checks, backup verification, cleanup validation
- Platform: Cross-platform

## Running Tests

### Extensible Test Runner
```powershell
# Run all tests for current platform
./tests/helpers/Invoke-ExtensibleTests.ps1

# Run specific category
./tests/helpers/Invoke-ExtensibleTests.ps1 -Category "Installer" -Platform "Windows"

# Run with parallel execution and reporting
./tests/helpers/Invoke-ExtensibleTests.ps1 -Parallel -EnableCodeCoverage -GenerateReport

# Run tests matching pattern
./tests/helpers/Invoke-ExtensibleTests.ps1 -ScriptPattern "*Install*" -TestPattern "*prerequisite*"
```

### Traditional Pester
```powershell
# Run all tests
Invoke-Pester

# Run specific test file
Invoke-Pester -Path "tests/Install-Node.Tests.ps1"

# Run with coverage
Invoke-Pester -CodeCoverage "pwsh/runner_scripts/*.ps1"
```

## Generated Test Structure

Each auto-generated test includes:

### 1. Script Structure Validation
- PowerShell syntax validation
- Naming convention compliance
- Function definition verification

### 2. Parameter Validation
- Parameter acceptance testing
- Common parameter support (Verbose, WhatIf)
- Error handling for invalid inputs

### 3. Category-Specific Tests
- **Installers**: Prerequisites, downloads, verification
- **Configuration**: Backup, validation, rollback
- **Services**: Status checks, operations, configuration
- **Features**: State management, dependencies

### 4. Function-Specific Tests
- Individual function testing
- Parameter validation
- Return value verification

### 5. Platform Compatibility
- Automatic platform detection
- Skip conditions for incompatible platforms
- Admin privilege requirements

## Example Generated Test

```powershell
# Auto-generated test for Install-Node.ps1
Describe 'Install-Node Tests' -Tag 'Installer' {
    
    Context 'Script Structure Validation' {
        It 'should have valid PowerShell syntax' -Skip:($SkipNonWindows) {
            $scriptPath | Should -Exist
            { . $scriptPath } | Should -Not -Throw
        }
        
        It 'should follow naming conventions' {
            $scriptName | Should -Match '^[A-Z][a-zA-Z0-9-]+\.ps1$'
        }
    }
    
    Context 'Installation Tests' {
        It 'should validate prerequisites' -Skip:($SkipNonWindows) {
            # Test prerequisite checking logic
        }
        
        It 'should handle download failures gracefully' {
            # Test error handling for failed downloads
        }
        
        It 'should verify installation success' {
            # Test installation verification
        }
    }
}
```

## CI/CD Integration

### GitHub Actions Workflows

#### Auto Test Generation (`auto-test-generation.yml`)
- **Triggers**: New/modified PowerShell scripts
- **Actions**: 
  - Validates and fixes naming conventions
  - Generates tests for new scripts
  - Validates generated test syntax
  - Commits changes back to repository

#### Pester Testing (`pester.yml`)
- **Triggers**: All pushes and PRs
- **Actions**:
  - Runs extensible test framework
  - Supports multiple platforms (Windows, Linux, macOS)
  - Generates coverage reports
  - Uploads test artifacts

### Workflow Features
- **Multi-platform testing**
- **Parallel test execution**
- **Automatic artifact collection**
- **Coverage reporting**
- **Test result summaries**

## Adding New Scripts

### Quick Start
1. **Create your script** in the appropriate directory:
   ```powershell
   # Example: New installer script
   # File: pwsh/runner_scripts/install-mytool.ps1 (will be renamed automatically)
   
   param(
       [string]$Version = "latest",
       [switch]$Force
   )
   
   function Install-MyTool {
       # Implementation here
   }
   ```

2. **Commit and push** - GitHub Actions will automatically:
   - Rename to `nnnn_Install-MyTool.ps1`
   - Generate `Install-MyTool.Tests.ps1`
   - Run tests across platforms

3. **Review generated tests** and customize as needed

### Manual Process
```powershell
# 1. Generate test manually
./tests/helpers/New-AutoTestGenerator.ps1 -ScriptPath "pwsh/runner_scripts/install-mytool.ps1"

# 2. Review and customize generated test
code "tests/Install-MyTool.Tests.ps1"

# 3. Run tests locally
./tests/helpers/Invoke-ExtensibleTests.ps1 -ScriptPattern "*MyTool*"
```

## Best Practices

### Script Development
1. **Follow naming conventions** from the start
2. **Include CmdletBinding** for advanced functions
3. **Add parameter validation** and help text
4. **Handle errors gracefully** with try/catch
5. **Support WhatIf** for non-destructive testing

### Test Customization
1. **Review generated tests** - they're starting points
2. **Add specific test cases** for your script's logic
3. **Mock external dependencies** (web requests, file operations)
4. **Use platform skip conditions** appropriately
5. **Test both success and failure scenarios**

### Platform Considerations
1. **Windows**: `.msi` installers, registry, services, PowerShell modules
2. **Linux**: Package managers (`apt`, `yum`), systemd, file permissions
3. **macOS**: Homebrew, launchctl, application bundles
4. **Cross-platform**: PowerShell Core features, file paths, environment variables

## Troubleshooting

### Common Issues

#### Test Generation Fails
```powershell
# Check script syntax
$ast = [System.Management.Automation.Language.Parser]::ParseInput($content, [ref]$null, [ref]$errors)
$errors
```

#### Platform Skip Not Working
```powershell
# Verify platform detection
Get-Platform | Format-List
Test-IsAdministrator
```

#### Tests Not Found
```powershell
# Check test discovery
./tests/helpers/Invoke-ExtensibleTests.ps1 -Verbose
```

### Debug Mode
```powershell
# Enable verbose output
./tests/helpers/Invoke-ExtensibleTests.ps1 -Verbose

# Generate tests with debugging
./tests/helpers/New-AutoTestGenerator.ps1 -ScriptPath $path -Verbose
```

## Contributing

### Adding New Test Categories
1. **Modify** `Get-TestCategories` function in `New-AutoTestGenerator.ps1`
2. **Add detection logic** for your category
3. **Create test template** in `New-TestTemplate` function
4. **Update documentation**

### Extending Platform Support
1. **Add platform detection** in `Get-ScriptAnalysis`
2. **Update skip conditions** in test templates
3. **Add CI/CD workflow** support if needed

### Improving Test Generation
1. **Enhance script analysis** logic
2. **Add new test patterns** for common scenarios
3. **Improve naming convention** detection
4. **Add validation rules** for generated tests
