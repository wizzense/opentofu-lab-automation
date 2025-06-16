# Copilot Instructions for OpenTofu Lab Automation

## Project Overview
You are working on the **OpenTofu Lab Automation** project - a comprehensive automation framework for setting up and managing OpenTofu lab environments with unified maintenance and validation systems.

## Project Context & Architecture

### Core Purpose
This project automates the complete setup of OpenTofu lab environments across Windows, Linux, and macOS platforms. It provides:
- Infrastructure as Code using OpenTofu/Terraform
- Cross-platform PowerShell automation
- Hyper-V virtualization management
- Comprehensive testing and validation
- Git-controlled patch management

### Technology Stack
- **Infrastructure**: OpenTofu (Terraform alternative)
- **Automation**: PowerShell 7.4+ (cross-platform)
- **Platform**: Windows (primary), Linux, macOS
- **Virtualization**: Hyper-V
- **Testing**: Pester 5.0+
- **Version Control**: Git with automated workflows

## Module Architecture

### Primary Modules

#### PatchManager (pwsh/modules/PatchManager/)
**Purpose**: Unified patch management with Git-controlled workflows
**Key Functions**:
- `Invoke-GitControlledPatch` - Main patching orchestrator
- `Invoke-QuickRollback` - Fast rollback operations
- `Invoke-ComprehensiveCleanup` - Advanced cleanup operations
- `Initialize-CrossPlatformEnvironment` - Platform initialization
- `Invoke-GitHubIssueIntegration` - Issue tracking integration

#### LabRunner (pwsh/modules/LabRunner/)
**Purpose**: Core execution framework for lab automation
**Key Functions**:
- `Invoke-LabStep` - Standard execution wrapper
- `Write-CustomLog` - Standardized logging
- `Get-Platform` - Cross-platform detection
- OpenTofu installation and management

#### CoreApp (pwsh/core_app/)
**Purpose**: Unified application interface
**Key Scripts**:
- `0007_Install-Go.ps1` - Go language installation
- `0008_Install-OpenTofu.ps1` - OpenTofu installation
- `0009_Initialize-OpenTofu.ps1` - OpenTofu initialization

### Project Structure
```
opentofu-lab-automation/
├── pwsh/
│   ├── modules/
│   │   ├── PatchManager/     # Git-controlled patch management
│   │   ├── LabRunner/        # Core execution framework
│   │   └── core_app/         # Unified application interface
│   └── runner_scripts/       # Main automation scripts (0000-0114)
├── opentofu/
│   ├── modules/              # OpenTofu/Terraform modules
│   └── examples/             # Example configurations
├── tests/                    # Pester test suites
├── configs/                  # Configuration templates
└── scripts/                  # Maintenance scripts
```

## Coding Standards & Conventions

### PowerShell Standards
1. **Version Requirement**: `#Requires -Version 7.0` for all scripts
2. **Error Handling**: Use structured error handling with proper logging
3. **Module Structure**: Follow standard PowerShell module conventions
4. **Cross-Platform**: Use forward slashes for paths, avoid Windows-specific cmdlets
5. **Logging**: Use `Write-CustomLog` for consistent logging output

### Path Conventions
- **Project Root**: `/workspaces/opentofu-lab-automation` (standardized)
- **Module Imports**: Use absolute paths with `/workspaces/opentofu-lab-automation/pwsh/modules/`
- **Cross-Platform**: Always use forward slashes in paths
- **Environment Variables**: Leverage `$env:PROJECT_ROOT`, `$env:PWSH_MODULES_PATH`

### Git & Version Control
- **No Direct Main Commits**: All changes through Pull Requests
- **Branch Naming**: `feature/`, `fix/`, `maintenance/` prefixes
- **Commit Messages**: Conventional format `type(scope): description`
- **PR Requirements**: Must include tests and validation

## Development Guidelines

### When Adding New Features
1. **Create Tests First**: Follow TDD approach with Pester tests
2. **Cross-Platform Testing**: Validate on Windows, Linux, macOS
3. **Documentation**: Update README and inline documentation
4. **Module Integration**: Ensure proper module dependencies
5. **Error Handling**: Include comprehensive error scenarios

### When Fixing Issues
1. **Identify Root Cause**: Use diagnostic logging and testing
2. **Minimal Changes**: Make surgical fixes without breaking existing functionality
3. **Regression Testing**: Run full test suite after changes
4. **Documentation Updates**: Update any affected documentation

### Code Quality Requirements
- **PSScriptAnalyzer**: All PowerShell code must pass analysis
- **Pester Tests**: Minimum 80% test coverage for new code
- **Cross-Platform**: Test on multiple platforms
- **Performance**: Consider resource usage and execution time

## Common Patterns & Examples

### Standard Module Import
```powershell
#Requires -Version 7.0
Import-Module "/workspaces/opentofu-lab-automation/pwsh/modules/LabRunner/" -Force
Import-Module "/workspaces/opentofu-lab-automation/pwsh/modules/PatchManager/" -Force
```

### Standard Function Structure
```powershell
function Invoke-ExampleFunction {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$RequiredParam,
        
        [Parameter()]
        [switch]$OptionalSwitch
    )
    
    begin {
        Write-CustomLog "Starting $($MyInvocation.MyCommand)"
        # Initialization logic
    }
    
    process {
        try {
            if ($PSCmdlet.ShouldProcess($RequiredParam, "Example Operation")) {
                # Main logic here
                Write-CustomLog "Processing $RequiredParam"
            }
        }
        catch {
            Write-CustomLog "Error in $($MyInvocation.MyCommand): $($_.Exception.Message)" -Level ERROR
            throw
        }
    }
    
    end {
        Write-CustomLog "Completed $($MyInvocation.MyCommand)"
    }
}
```

### Error Handling Pattern
```powershell
try {
    # Operation that might fail
    $result = Invoke-SomeOperation
    Write-CustomLog "Operation successful: $result" -Level SUCCESS
}
catch {
    $errorMsg = "Failed to complete operation: $($_.Exception.Message)"
    Write-CustomLog $errorMsg -Level ERROR
    
    # Determine if this is recoverable
    if ($_.Exception -is [System.IO.FileNotFoundException]) {
        Write-CustomLog "Attempting recovery..." -Level WARN
        # Recovery logic
    }
    else {
        throw  # Re-throw if not recoverable
    }
}
```

## Testing Requirements

### Pester Test Structure
```powershell
#Requires -Module Pester
#Requires -Version 7.0

Describe "ModuleName Tests" {
    BeforeAll {
        # Setup - import modules, create test data
        Import-Module "/workspaces/opentofu-lab-automation/pwsh/modules/TestModule/" -Force
    }
    
    Context "When testing basic functionality" {
        It "Should perform expected operation" {
            # Arrange
            $testParam = "TestValue"
            
            # Act
            $result = Invoke-TestFunction -Parameter $testParam
            
            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Success | Should -Be $true
        }
    }
    
    AfterAll {
        # Cleanup
    }
}
```

## Security & Best Practices

### Security Guidelines
1. **No Hardcoded Credentials**: Use secure parameter handling
2. **Validate Inputs**: Always validate and sanitize user inputs
3. **Least Privilege**: Run with minimum required permissions
4. **Secure Communications**: Use HTTPS and certificate validation
5. **Audit Logging**: Log all significant operations

### Performance Considerations
1. **Parallel Processing**: Use `ForEach-Object -Parallel` where appropriate
2. **Memory Management**: Dispose of large objects properly
3. **Network Efficiency**: Batch network operations
4. **Caching**: Cache expensive operations when possible

## Integration Points

### OpenTofu Integration
- Use `tofu` command-line tool (not `terraform`)
- Validate OpenTofu configurations before applying
- Support both local and remote state management
- Integrate with Hyper-V provider for virtualization

### Hyper-V Integration
- Support Windows Server and Windows 10/11 Hyper-V
- Handle both standalone and domain-joined scenarios
- Manage certificates for secure connections
- Support both PowerShell Direct and traditional remote methods

### CI/CD Integration
- GitHub Actions workflows for automated testing
- Cross-platform runner support
- Automated dependency management
- Security scanning and compliance checks

## Current Focus Areas

### Active Development
1. **Cross-Platform Enhancements**: Improving Linux and macOS support
2. **Test Coverage**: Expanding Pester test coverage across all modules
3. **Documentation**: Updating documentation for new features
4. **Performance**: Optimizing execution time for large lab environments

### Known Issues
1. **Path Handling**: Some legacy scripts still use Windows-style paths
2. **Module Dependencies**: Working to reduce circular dependencies
3. **Error Recovery**: Enhancing automatic recovery mechanisms

## Helpful Commands

### Quick Start Development
```bash
# Clone and setup
git clone <repo-url>
cd opentofu-lab-automation

# Install dependencies
./pwsh/setup-dev-environment.ps1

# Run tests
Invoke-Pester tests/

# Run main automation
./pwsh/runner.ps1 -Scripts "0006,0007,0008,0009"
```

### Common Maintenance
```powershell
# Clean up backups and archives
Invoke-ComprehensiveCleanup -CleanupMode "Standard"

# Run patch validation
Invoke-PatchValidation -Path "/workspaces/opentofu-lab-automation"

# Cross-platform environment setup
Initialize-CrossPlatformEnvironment
```

## Important Notes

1. **NO EMOJI POLICY**: This project maintains a strict no-emoji policy in code and documentation
2. **Conventional Commits**: Use conventional commit format for all changes
3. **Module Integration**: Always test module interactions thoroughly
4. **Cross-Platform**: Consider all supported platforms when making changes
5. **Backward Compatibility**: Maintain compatibility with existing configurations

When working on this project, prioritize maintainability, cross-platform compatibility, and comprehensive testing. The project serves critical infrastructure automation needs and must be reliable and robust.

## CRITICAL: PatchManager Enforcement for AI Agents

### MANDATORY: All Code Changes Must Use PatchManager

**ALL AI-GENERATED CODE CHANGES MUST GO THROUGH THE PatchManager WORKFLOW**

When making ANY file changes, edits, or modifications:

1. **NEVER edit files directly**
2. **ALWAYS use `Invoke-GitControlledPatch`**
3. **INCLUDE proper testing and validation**
4. **ENSURE change tracking and audit trails**

### Required PatchManager Workflow
```powershell
# REQUIRED pattern for ALL AI-generated changes
Invoke-GitControlledPatch -PatchDescription "AI: [Description of changes]" -PatchOperation {
    # Your file changes go here
    $content = Get-Content "path/to/file.ps1"
    $newContent = $content -replace "pattern", "replacement"
    Set-Content "path/to/file.ps1" -Value $newContent
} -AutoCommitUncommitted -CreatePullRequest -TestCommands @(
    "Invoke-Pester tests/",
    "Invoke-ScriptAnalyzer pwsh/"
)
```

### Why PatchManager is Mandatory
- **Change Control**: All modifications are tracked and logged
- **Validation**: Automatic testing prevents breaking changes
- **Rollback**: Quick recovery from failed changes
- **Audit Trail**: Complete history of who changed what and when
- **Integration**: Works with existing Git workflows and CI/CD

### Available VS Code Tasks for PatchManager
- `PatchManager: Apply Changes with DirectCommit`
- `PatchManager: Apply Changes with PR`
- `PatchManager: Emergency Rollback`

**NO EXCEPTIONS**: Even minor changes like documentation updates must use PatchManager.

## Development Guidelines
