#Requires -Version 7.0

<#
.SYNOPSIS
    Fixes common syntax errors in test files - improved version

.DESCRIPTION
    This script fixes common syntax errors found in Pester test files:
    - Missing pipe before Should assertions
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
            
            # Fix missing pipe before Should - more precise pattern
            $shouldPattern = '(\s+)(\w+)\s+Should\s+'
            if ($content -match $shouldPattern) {
                $content = $content -replace $shouldPattern, '$1$2 | Should '
                Write-CustomLog "  Fixed missing pipe before Should" "SUCCESS"
                $fileFixed = $true
            }
            
            # Fix duplicate import lines - look for exact duplicates
            $lines = $content -split "`r?`n"
            $newLines = @()
            $seenImports = @{}
            
            foreach ($line in $lines) {
                if ($line -match '^\s*Import-Module.*LabRunner.*-Force') {
                    $trimmedLine = $line.Trim()
                    if (-not $seenImports.ContainsKey($trimmedLine)) {
                        $seenImports[$trimmedLine] = $true
                        $newLines += $line
                        Write-CustomLog "  Keeping import: $trimmedLine" "INFO"
                    } else {
                        Write-CustomLog "  Removed duplicate import" "SUCCESS"
                        $fileFixed = $true
                    }
                } else {
                    $newLines += $line
                }
            }
            
            if ($fileFixed) {
                $content = $newLines -join "`r`n"
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
