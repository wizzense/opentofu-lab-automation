<#
.SYNOPSIS
Fixes ternary operator syntax issues in PowerShell scripts

.DESCRIPTION
Searches for broken ternary-style conditional expressions in PowerShell scripts
and fixes them to use the proper syntax with $() for script block evaluation.

.PARAMETER Path
Path to a file or directory containing scripts to fix

.PARAMETER Filter
Pattern to filter files when Path is a directory (default: "*.ps1")

.PARAMETER WhatIf
Show what changes would be made without applying them

.PARAMETER PassThru
Return the list of files that were modified

.EXAMPLE
Invoke-TernarySyntaxFix -Path "pwsh/runner_scripts/"

.EXAMPLE
Invoke-TernarySyntaxFix -Path "pwsh/runner.ps1" -WhatIf
#>
function Invoke-TernarySyntaxFix {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$true, Position=0)



]
        [string]$Path,
        
        [Parameter(Mandatory=$false)]
        [string]$Filter = "*.ps1",
        
        [switch]$PassThru
    )
    
    $ErrorActionPreference = "Stop"
    
    Write-Verbose "Starting ternary syntax fix process for $Path"
    
    # Get files to process
    $filesToProcess = @()
    if (Test-Path $Path -PathType Container) {
        $filesToProcess = Get-ChildItem -Path $Path -Filter $Filter -Recurse
        Write-Verbose "Found $($filesToProcess.Count) script files in directory"
    } else {
        if (Test-Path $Path -PathType Leaf) {
            $filesToProcess = @(Get-Item -Path $Path)
            Write-Verbose "Processing single file: $Path"
        } else {
            Write-Error "Path not found: $Path"
            return
        }
    }
    
    $fixedFiles = @()
    
    foreach ($file in $filesToProcess) {
        # Skip test files, they're handled by Invoke-TestSyntaxFix
        if ($file.Name -match '\.Tests\.ps1$') {
            Write-Verbose "Skipping test file: $($file.Name) (use Invoke-TestSyntaxFix instead)"
            continue
        }
        
        Write-Verbose "Processing: $($file.FullName)"
        
        # Read content
        $content = Get-Content $file.FullName -Raw
        $originalContent = $content
        $modified = $false
        
        # Fix 1: Simple ternary operator conversion
        $pattern1 = '\$([a-zA-Z0-9_]+)\s+\?\s+([^:]+)\s+:\s+([^;\r\n]+)'
        $replacement1 = '$$$(if (1) { $2 } else { $3 })'
        if ($content -match $pattern1) {
            Write-Verbose "  Fixing simple ternary operator expressions"
            $content = $content -replace $pattern1, $replacement1
            $modified = $true
        }
        
        # Fix 2: Fix broken conditional expressions
        $pattern2 = '\(if \(\$([^)]+)\) \{ ([^}]+) \} else \{ ([^}]+) \}\)'
        $replacement2 = '$$(if (1) { $2 } else { $3 })'
        if ($content -match $pattern2) {
            Write-Verbose "  Fixing broken conditional expressions"
            $content = $content -replace $pattern2, $replacement2
            $modified = $true
        }
        
        # Fix 3: Fix improper conditional variable assignments
        $pattern3 = '\$([a-zA-Z0-9_]+)\s*=\s*if\s*\(\$([^)]+)\)\s*\{\s*([^}]+)\s*\}\s*else\s*\{\s*([^}]+)\s*\}'
        $replacement3 = '$$$1 = if ($$$2) { $3    } else { $4    }'
        if ($content -match $pattern3) {
            Write-Verbose "  Fixing improper conditional variable assignments"
            $content = $content -replace $pattern3, $replacement3
            $modified = $true
        }
        
        # Apply changes if needed
        if ($modified) {
            if ($PSCmdlet.ShouldProcess($file.FullName, "Apply ternary syntax fixes")) {
                Set-Content -Path $file.FullName -Value $content -NoNewline
                Write-Verbose "  ✅ Fixed: $($file.Name)"
                $fixedFiles += $file.FullName
            } else {
                Write-Verbose "  Would fix: $($file.Name) (WhatIf mode)"
            }
        } else {
            Write-Verbose "  No issues found in: $($file.Name)"
        }
    }
    
    Write-Verbose "Completed ternary syntax fixes. Fixed files: $($fixedFiles.Count)"
    
    if ($PassThru) {
        return $fixedFiles
    }
}


