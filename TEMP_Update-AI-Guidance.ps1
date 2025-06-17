#Requires -Version 7.0

<#
.SYNOPSIS
    Updates AI/automation guidance to follow proper project conventions

.DESCRIPTION
    Creates comprehensive documentation and examples for proper:
    - TEMP_ prefixed temporary/debug scripts (never committed)
    - Pester-validated changes
    - Project-specific coding standards
    - Git workflow requirements

.PARAMETER WhatIf
    Preview changes without applying them

.EXAMPLE
    .\TEMP_Update-AI-Guidance.ps1 -WhatIf
    .\TEMP_Update-AI-Guidance.ps1
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [switch]$WhatIf
)

#Requires -Version 7.0

# Import required modules
Import-Module "$env:PWSH_MODULES_PATH/LabRunner/" -Force

function Write-CustomLog {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    $logEntry = "[$timestamp] [$Level] $Message"
    Write-Host $logEntry -ForegroundColor $(
        switch ($Level) {
            "ERROR" { "Red" }
            "WARN" { "Yellow" }
            "SUCCESS" { "Green" }
            default { "White" }
        }
    )
}

function Update-AIGuidance {
    [CmdletBinding(SupportsShouldProcess)]
    param()
    
    try {
        Write-CustomLog "Updating AI/automation guidance for project conventions" "INFO"
        
        $guidanceContent = @"
# OpenTofu Lab Automation - AI/Automation Guidance

## CRITICAL CONVENTIONS

### Temporary/Debug Script Naming
- ALL temporary, debug, fix, demo, and test scripts MUST be prefixed with TEMP_
- Examples: TEMP_Fix-Syntax.ps1, TEMP_Debug-Module.ps1, TEMP_Demo-Feature.ps1
- These scripts are automatically git-ignored and never committed

### Validation Requirements
- EVERY change must be validated with Pester before applying
- Run relevant Pester tests after each modification
- Example workflow:
  ```powershell
  # Make changes
  Edit-SomeFile.ps1
  
  # Validate with Pester
  Invoke-Pester -Path './tests/unit/scripts/SomeFile.Tests.ps1'
  
  # Only commit if tests pass
  git add file.ps1
  git commit -m "Fix: Description"
  ```

### Project Standards
- Follow PowerShell 7.0+ cross-platform standards
- Use forward slashes for all paths
- Import modules with absolute paths: `Import-Module '$env:PWSH_MODULES_PATH/ModuleName/' -Force`
- Use Write-CustomLog for all logging with levels (INFO, WARN, ERROR, SUCCESS)
- Implement proper error handling with try-catch blocks
- No emojis - use clear, professional language
- Structure functions with [CmdletBinding(SupportsShouldProcess)]

### Environment Variables
- `$env:PROJECT_ROOT` - Project root directory
- `$env:PWSH_MODULES_PATH` - PowerShell modules path

### Git Workflow
- Create feature branches for related changes
- Commit stable changes frequently
- Use clear commit messages: "Fix: Description", "Add: Feature", "Update: Component"
- Never commit TEMP_*, temp-*, Fix-*, Demo-*, Test-* files

### Common PowerShell Fixes
- Array indexing: Use `$array[-1]` not `$array-1`
- Environment variables: Use `$ExecutionContext.InvokeCommand.ExpandString($path)` not `System.Environment::ExpandEnvironmentVariables($path)`
- Parameters: Use `-Force` not `-ForceWrite-CustomLog`
- Module paths: Use `$env:PWSH_MODULES_PATH/ModuleName/` not hardcoded paths

### Test Structure Requirements
```powershell
# Required test file header
. (Join-Path $PSScriptRoot 'helpers' 'TestHelpers.ps1')

Describe 'Component Tests' {
    BeforeAll {
        Import-Module "$env:PWSH_MODULES_PATH/LabRunner/" -Force
    }

    Context 'Validation' {
        It 'should have valid syntax' {
            $result | Should -BeTrue
        }
    }

    AfterAll {
        # Cleanup test resources
    }
}
```

### Example Workflow
1. Create TEMP_Fix-Issue.ps1 for any fixes
2. Run in WhatIf mode first: `.\TEMP_Fix-Issue.ps1 -WhatIf`
3. Validate with Pester: `Invoke-Pester -Path './tests/relevant/'`
4. Apply changes: `.\TEMP_Fix-Issue.ps1`
5. Validate again with Pester
6. Commit only stable, non-temporary files
7. Document all changes in commit messages

Remember: If it's temporary, debug, or experimental - prefix with TEMP_ and validate with Pester!
"@

        if ($PSCmdlet.ShouldProcess("AI Guidance Documentation", "Update")) {
            $guidancePath = Join-Path $env:PROJECT_ROOT "docs/AI-AUTOMATION-GUIDANCE.md"
            $guidanceContent | Out-File -FilePath $guidancePath -Encoding UTF8 -Force
            Write-CustomLog "Updated AI guidance documentation at $guidancePath" "SUCCESS"
        }

        Write-CustomLog "AI guidance update completed successfully" "SUCCESS"
        
    } catch {
        Write-CustomLog "Failed to update AI guidance: $($_.Exception.Message)" "ERROR"
        throw
    }
}

# Main execution
try {
    if ($WhatIf) {
        Write-CustomLog "Running in WhatIf mode - no changes will be applied" "INFO"
    }
    
    Update-AIGuidance -WhatIf:$WhatIf
    
    Write-CustomLog "TEMP_Update-AI-Guidance completed successfully" "SUCCESS"
    
} catch {
    Write-CustomLog "TEMP_Update-AI-Guidance failed: $($_.Exception.Message)" "ERROR"
    exit 1
}
