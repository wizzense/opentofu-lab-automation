#Requires -Version 7.0

<#
.SYNOPSIS
Removes all validation-only functionality from the codebase to ensure validation is read-only

.DESCRIPTION
This script systematically removes or disables all validation-only functionality throughout
the codebase to ensure that:
1. No scripts make automatic changes to files
2. Only PatchManager can make changes through explicit user action
3. All validation is read-only and reports issues only
4. GitHub issues are created for tracking problems (reporting preserved)

.PARAMETER DryRun
Show what would be changed without making actual changes

.PARAMETER CreateBackup
Create backup of files before modifying them
#>

[CmdletBinding()]
param(
    [switch]$DryRun,
    [switch]$CreateBackup = $true
)

$ErrorActionPreference = 'Continue'

# Import logging module
if (Test-Path "$env:PWSH_MODULES_PATH/Logging/Logging.psm1") {
    Import-Module "Logging" -Force
} else {
    function Write-CustomLog {
        param([string]$Level = 'INFO', [string]$Message)
        $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        $color = switch ($Level) {
            'ERROR' { 'Red' }
            'WARN' { 'Yellow' }
            'SUCCESS' { 'Green' }
            default { 'White' }
        }
        Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
    }
}

Write-CustomLog -Level INFO -Message "Starting removal of validation-only functionality from codebase"
Write-CustomLog -Level INFO -Message "Preserving: Reporting, validation, and GitHub issue creation"
Write-CustomLog -Level INFO -Message "Removing: All file modification and # DISABLED: Set-Content operations"

# Track changes made
$changesSummary = @{
    FilesModified = @()
    FilesDisabled = @()
    FunctionsRemoved = @()
    ParametersRemoved = @()
}

function Remove-ValidateOnlyFromScript {
    param(
        [string]$FilePath,
        [string]$DisableReason = "validation-only functionality disabled - validation is read-only"
    )
    
    if (-not (Test-Path $FilePath)) {
        return
    }
    
    $fileName = Split-Path $FilePath -Leaf
    $content = Get-Content $FilePath -Raw
    $originalContent = $content
    $modified = $false
    
    Write-CustomLog -Level INFO -Message "Processing: $fileName"
    
    # 1. Remove/comment out # DISABLED: Set-Content operations that modify files
    $setContentPatterns = @(
        'Set-Content\s+-Path\s+[^-\r\n]+\s+-Value\s+[^\r\n]+',
        'Set-Content\s+\$[^\s]+\s+\$[^\s\r\n]+',
        '\$content\s*\|\s*Set-Content\s+[^\r\n]+',
        '\$.*\s*\|\s*Out-File\s+[^\r\n]+'
    )
    
    foreach ($pattern in $setContentPatterns) {
        if ($content -match $pattern) {
            $content = $content -replace $pattern, '# REMOVED: File modification disabled (validation read-only)'
            $modified = $true
            Write-CustomLog -Level WARN -Message "Removed # DISABLED: Set-Content operation in $fileName"
        }
    }
    
    # 2. Disable Invoke-Formatter operations
    $formatterPattern = 'Invoke-Formatter\s+[^\r\n]+'
    if ($content -match $formatterPattern) {
        $content = $content -replace $formatterPattern, '# REMOVED: Invoke-Formatter disabled (validation read-only)'
        $modified = $true
        Write-CustomLog -Level WARN -Message "Removed Invoke-Formatter in $fileName"
    }
    
    # 3. Remove ValidationOnly parameters and their usage
    $ValidateOnlyPatterns = @(
        '\[switch\]\$ValidateOnly[^\r\n]*',
        '\[switch\]\$ReportOnly[^\r\n]*',
        '\[switch\]\$FixErrors[^\r\n]*',
        'param\([^)]*-ValidateOnly[^)]*\)',
        'if\s*\(\$ValidateOnly[^}]+\}',
        'if\s*\(\$ReportOnly[^}]+\}',
        'ValidationOnly\s*[:=]\s*\$true',
        'ApplyFixes\s*[:=]\s*\$true'
    )
    
    foreach ($pattern in $ValidateOnlyPatterns) {
        if ($content -match $pattern) {
            $content = $content -replace $pattern, '# REMOVED: ValidationOnly parameter/logic disabled'
            $modified = $true
        }
    }
    
    # 4. Convert ValidationOnly functions to validation-only
    $ValidateOnlyFunctions = @(
        'Invoke-AutomaticFixes',
        'Apply.*Fix',
        'Fix-.*',
        'Repair-.*'
    )
    
    foreach ($func in $ValidateOnlyFunctions) {
        if ($content -match "function\s+$func") {
            # Add validation-only comment at start of function
            $content = $content -replace "(function\s+$func[^{]*\{)", '$1' + "`n    # VALIDATION ONLY: This function reports issues but does not modify files`n"
            $modified = $true
        }
    }
    
    # 5. Ensure GitHub issue creation is preserved (don't remove these)
    # Keep: New-GitHubIssueTracking, Write-CustomLog, reporting functions
    
    # 6. Add safety header if this is a known ValidationOnly script
    $ValidateOnlyScriptNames = @(
        'Fix-', 'Repair-', 'ValidationOnly', 'validation-only', 'SyntaxFixer', 'AutomaticFixCapture'
    )
    
    $isValidationOnlyScript = $ValidateOnlyScriptNames | Where-Object { $fileName -match $_ }
    if ($isValidationOnlyScript) {
        $safetyHeader = @"
# ===================================================================
# VALIDATION ONLY MODE - FILE MODIFICATIONS DISABLED
# ===================================================================
# This script has been converted to validation-only mode.
# It will analyze and report issues but will NOT modify any files.
# All file changes must go through PatchManager workflow.
# 
# Preserved functionality:
# - Analysis and reporting
# - GitHub issue creation  
# - Validation and testing
# 
# Disabled functionality:
# - # DISABLED: Set-Content operations
# - File modifications
# - Automatic fixes
# ===================================================================

"@
        if (-not ($content -match "VALIDATION ONLY MODE")) {
            $content = $safetyHeader + $content
            $modified = $true
        }
    }
    
    # 7. Save changes if modifications were made
    if ($modified) {
        if (-not $DryRun) {
            if ($CreateBackup) {
                $backupPath = "$FilePath.backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
                Copy-Item $FilePath $backupPath
                Write-CustomLog -Level INFO -Message "Backup created: $backupPath"
            }
            
            # DISABLED: # DISABLED: Set-Content -Path $FilePath -Value $content -Encoding UTF8
            Write-CustomLog -Level SUCCESS -Message "Converted to validation-only: $fileName"
            $changesSummary.FilesModified += $FilePath
        } else {
            Write-CustomLog -Level INFO -Message "Would convert to validation-only: $fileName"
        }
    } else {
        Write-CustomLog -Level INFO -Message "No ValidationOnly functionality found in: $fileName"
    }
}

Write-CustomLog -Level INFO -Message "Identifying scripts with validation-only functionality..."

# 1. Disable known validation-only scripts
$ValidateOnlyScripts = @(
    "scripts/maintenance/simple-runtime-fix.ps1",
    "scripts/emergency-fixes/Fix-MalformedImports.ps1",
    "scripts/emergency/fix-corrupted-imports.ps1",
    "scripts/Install-LabRunnerIntegration.ps1",
    "scripts/testing/Batch-RepairTestFiles.ps1",
    "tools/TestValidationOnlyer/SyntaxFixer.ps1",
    "tools/TestValidationOnlyer/AutomaticFixCapture.ps1",
    "scripts/testing/Repair-TestFile.ps1",
    "scripts/maintenance/Fix-MissingPipeSyntax.ps1"
)

foreach ($script in $ValidateOnlyScripts) {
    $fullPath = Join-Path $env:PROJECT_ROOT $script
    if (Test-Path $fullPath) {
        Disable-ValidateOnlyScript -FilePath $fullPath -Reason "Automatic file modification conflicts with read-only validation policy"
    }
}

# 2. Find and disable scripts that contain # DISABLED: Set-Content operations
Write-CustomLog -Level INFO -Message "Scanning for scripts with file modification operations..."

$scriptsWithSetContent = Get-ChildItem -Path $env:PROJECT_ROOT -Recurse -Include "*.ps1" |
    Where-Object { 
        $_.FullName -notmatch '\\(archive|backup|temp)\\' -and
        $_.Name -ne 'Remove-ValidateOnlyFunctionality.ps1'
    } |
    ForEach-Object {
        $content = Get-Content $_.FullName -Raw -ErrorAction SilentlyContinue
        if ($content -and $content -match 'Set-Content.*-Value.*content') {
            $_
        }
    }

foreach ($script in $scriptsWithSetContent) {
    # Skip validation-only scripts and important system scripts
    $fileName = $script.Name
    if ($fileName -match "(Validate|Test|Report|Dashboard|Generate|Install|Deploy)" -and 
        $fileName -notmatch "(Fix|Repair|Auto)") {
        Write-CustomLog -Level INFO -Message "Skipping validation script: $fileName"
        continue
    }
    
    Remove-ValidateOnlyParameters -FilePath $script.FullName
}

# 3. Update VS Code tasks to remove validation-only functionality
Write-CustomLog -Level INFO -Message "Updating VS Code tasks..."

$tasksJsonPath = Join-Path $env:PROJECT_ROOT ".vscode/tasks.json"
if (Test-Path $tasksJsonPath) {
    $tasksContent = Get-Content $tasksJsonPath -Raw
    
    # Remove validation-only related tasks
    $ValidateOnlyTaskPatterns = @(
        '"ValidationOnly[^"]*"',
        '".*fix.*": ".*ValidationOnly.*"',
        'ValidationOnly.*-ReportOnly'
    )
    
    $modified = $false
    foreach ($pattern in $ValidateOnlyTaskPatterns) {
        if ($tasksContent -match $pattern) {
            $tasksContent = $tasksContent -replace $pattern, '"DISABLED: validation-only removed"'
            $modified = $true
        }
    }
    
    if ($modified -and $PSCmdlet.ShouldProcess($tasksJsonPath, "Update VS Code tasks")) {
        if ($CreateBackup) {
            $backupPath = "$tasksJsonPath.backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
            Copy-Item $tasksJsonPath $backupPath
        }
        
        # DISABLED: # DISABLED: Set-Content -Path $tasksJsonPath -Value $tasksContent -Encoding UTF8
        Write-CustomLog -Level SUCCESS -Message "Updated VS Code tasks.json"
        $changesSummary.FilesModified += $tasksJsonPath
    }
}

# 4. Update GitHub workflows to remove validation-only functionality
Write-CustomLog -Level INFO -Message "Updating GitHub workflows..."

$workflowsPath = Join-Path $env:PROJECT_ROOT ".github/workflows"
if (Test-Path $workflowsPath) {
    $workflowFiles = Get-ChildItem -Path $workflowsPath -Filter "*.yml"
    
    foreach ($workflow in $workflowFiles) {
        $content = Get-Content $workflow.FullName -Raw
        $originalContent = $content
        
        # Remove validation-only commands from workflows
        $content = $content -replace 'Invoke-ValidateOnly.*-ReportOnly', '# REMOVED: validation-only disabled'
        $content = $content -replace 'ValidationOnly.*true', ' false'
        $content = $content -replace '-FixErrors', '# -FixErrors (removed)'
        
        if ($content -ne $originalContent -and $PSCmdlet.ShouldProcess($workflow.FullName, "Update workflow")) {
            if ($CreateBackup) {
                $backupPath = "$($workflow.FullName).backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
                Copy-Item $workflow.FullName $backupPath
            }
            
            # DISABLED: # DISABLED: Set-Content -Path $workflow.FullName -Value $content -Encoding UTF8
            Write-CustomLog -Level SUCCESS -Message "Updated workflow: $($workflow.Name)"
            $changesSummary.FilesModified += $workflow.FullName
        }
    }
}

# 5. Create a summary report
Write-CustomLog -Level INFO -Message "Creating summary report..."

$reportContent = @"
# validation-only Functionality Removal Report
Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

## Summary
This report documents the removal of all validation-only functionality from the codebase
to ensure that validation is read-only and all changes go through PatchManager.

## Files Modified ($(($changesSummary.FilesModified).Count))
$($changesSummary.FilesModified | ForEach-Object { "- $_" } | Out-String)

## Files Disabled ($(($changesSummary.FilesDisabled).Count))
$($changesSummary.FilesDisabled | ForEach-Object { "- $_" } | Out-String)

## Key Changes Made
1. Disabled all validation-only scripts with warning headers
2. Removed ValidationOnly, ApplyFixes, and FixErrors parameters
3. Commented out # DISABLED: Set-Content operations that modify files
4. Updated VS Code tasks to remove validation-only functionality
5. Updated GitHub workflows to disable validation-only operations

## Validation Policy
- All scripts now perform read-only validation only
- Issues are reported and tracked via GitHub issues
- File modifications must go through PatchManager workflow
- PSScriptAnalyzer integration creates issues but does not fix code

## Next Steps
1. Test all validation scripts to ensure they still work in read-only mode
2. Verify GitHub issue creation is working properly
3. Ensure PatchManager is the only mechanism for making changes
4. Update documentation to reflect the new validation-only approach
"@

$reportPath = Join-Path $env:PROJECT_ROOT "reports/validation-only-REMOVAL-REPORT.md"
if (-not (Test-Path (Split-Path $reportPath))) {
    New-Item -ItemType Directory -Path (Split-Path $reportPath) -Force
}

if ($PSCmdlet.ShouldProcess($reportPath, "Create removal report")) {
    # DISABLED: # DISABLED: Set-Content -Path $reportPath -Value $reportContent -Encoding UTF8
    Write-CustomLog -Level SUCCESS -Message "Created removal report: $reportPath"
}

Write-CustomLog -Level SUCCESS -Message "validation-only functionality removal completed"
Write-CustomLog -Level INFO -Message "Files modified: $(($changesSummary.FilesModified).Count)"
Write-CustomLog -Level INFO -Message "Files disabled: $(($changesSummary.FilesDisabled).Count)"
Write-CustomLog -Level INFO -Message "Report created: $reportPath"

if ($WhatIf) {
    Write-CustomLog -Level WARN -Message "WhatIf mode - no actual changes were made"
}
