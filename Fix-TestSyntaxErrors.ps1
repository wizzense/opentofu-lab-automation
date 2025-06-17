#Requires -Version 7.0

<#
.SYNOPSIS
    Fixes common syntax errors in test files

.DESCRIPTION
    This script fixes common syntax errors found in Pester test files:
    - Missing pipe before Should assertions
    - Missing newlines in Describe blocks
    - Duplicate import statements
    - Ensures correct PWSH_MODULES_PATH setting
#>

param(
    [switch]$WhatIf
)

# Ensure correct environment variable
if (-not $env:PROJECT_ROOT) {
    $env:PROJECT_ROOT = $PSScriptRoot
}
if (-not $env:PWSH_MODULES_PATH) {
    $env:PWSH_MODULES_PATH = Join-Path $PSScriptRoot "pwsh/modules"
}

function Write-CustomLog {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    Write-Host "[$([DateTime]::Now.ToString('yyyy-MM-dd HH:mm:ss'))] [$Level] $Message"
}

function Fix-TestSyntaxErrors {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [string]$TestPath = "./tests/unit/scripts/"
    )

    $testFiles = Get-ChildItem -Path $TestPath -Filter "*.Tests.ps1" -Recurse
    $fixedCount = 0
    
    foreach ($file in $testFiles) {
        Write-CustomLog "Processing: $($file.Name)" "INFO"
        
        try {
            $content = Get-Content $file.FullName -Raw
            $originalContent = $content
            $fileFixed = $false
            
            # Fix missing pipe before Should
            $pattern1 = '(\w+)\s+Should\s+'
            if ($content -match $pattern1) {
                $content = $content -replace $pattern1, '$1 | Should '
                Write-CustomLog "  Fixed missing pipe before Should" "SUCCESS"
                $fileFixed = $true
            }
            
            # Fix duplicate import lines
            $pattern2 = '(Import-Module[^\}]+)\}\s*(Import-Module[^\}]+)\}'
            if ($content -match $pattern2) {
                $content = $content -replace $pattern2, '$1}'
                Write-CustomLog "  Fixed duplicate import statements" "SUCCESS"  
                $fileFixed = $true
            }
            
            # Fix missing newlines in Describe blocks
            $pattern3 = '(Describe[^{]+\{)\s*(BeforeAll)'
            if ($content -match $pattern3) {
                $content = $content -replace $pattern3, '$1`n    $2'
                Write-CustomLog "  Fixed newlines in Describe block" "SUCCESS"
                $fileFixed = $true
            }
            
            # Fix missing newlines between BeforeAll and Context
            $pattern4 = '(\})\s*(Context)'
            if ($content -match $pattern4) {
                $content = $content -replace $pattern4, '$1`n`n    $2'
                Write-CustomLog "  Fixed newlines between blocks" "SUCCESS"
                $fileFixed = $true
            }
            
            # Apply fixes if any were made
            if ($fileFixed) {
                if ($PSCmdlet.ShouldProcess($file.FullName, "Apply syntax fixes")) {
                    Set-Content -Path $file.FullName -Value $content -NoNewline
                    $fixedCount++
                    Write-CustomLog "  Applied fixes to $($file.Name)" "SUCCESS"
                }
            } else {
                Write-CustomLog "  No fixes needed for $($file.Name)" "INFO"
            }
            
        } catch {
            Write-CustomLog "  Error processing $($file.Name): $($_.Exception.Message)" "ERROR"
        }
    }
    
    Write-CustomLog "Fixed $fixedCount test files" "SUCCESS"
}

# Set correct environment variable globally
Write-CustomLog "Setting correct PWSH_MODULES_PATH environment variable" "INFO"
$correctPath = Join-Path $PSScriptRoot "pwsh/modules"
[Environment]::SetEnvironmentVariable("PWSH_MODULES_PATH", $correctPath, "Process")
$env:PWSH_MODULES_PATH = $correctPath
Write-CustomLog "PWSH_MODULES_PATH = $env:PWSH_MODULES_PATH" "INFO"

# Fix syntax errors in test files
if ($WhatIf) {
    Write-CustomLog "Running in WhatIf mode - no changes will be made" "INFO"
    Fix-TestSyntaxErrors -WhatIf
} else {
    Fix-TestSyntaxErrors
}

Write-CustomLog "Test syntax error fixing complete" "SUCCESS"
