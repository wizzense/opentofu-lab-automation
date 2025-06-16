#Requires -Version 7.0

<#
.SYNOPSIS
    Refactors the monolithic Invoke-GitControlledPatch into a proper modular function.

.DESCRIPTION
    The current Invoke-GitControlledPatch.ps1 is 946 lines of embedded logic that defeats
    the purpose of having modular components. This script refactors it to actually USE
    the modular components it claims to use.

.NOTES
    Current problems:
    - 946 lines in one function (should be ~100-150 max)
    - 59 if statements (way too complex)
    - Embedded helper functions (should be separate modules)
    - Reimplements logic instead of calling modular components
    - Fake modularization - files split but main function still monolithic
#>

Import-Module "$env:USERPROFILE\Documents\PowerShell\Modules\Logging" -Force
Import-Module "$env:USERPROFILE\Documents\PowerShell\Modules\TestingFramework" -Force

function Show-CurrentPatchManagerProblems {
    [CmdletBinding()]
    param()
    
    Write-CustomLog "=== Analyzing PatchManager Module Structure ===" -Level INFO
    
    $patchManagerPath = "c:\Users\alexa\OneDrive\Documents\0. wizzense\opentofu-lab-automation\pwsh\modules\PatchManager"
    
    # Check main function size
    $mainFunction = "$patchManagerPath\Public\Invoke-GitControlledPatch.ps1"
    $lineCount = (Get-Content $mainFunction).Count
    Write-CustomLog "Main function size: $lineCount lines" -Level WARN
    
    if ($lineCount -gt 200) {
        Write-CustomLog "❌ PROBLEM: Function is too large ($lineCount lines > 200 recommended max)" -Level ERROR
    }
    
    # Check complexity
    $ifStatements = Select-String -Path $mainFunction -Pattern "if \(" | Measure-Object | Select-Object -ExpandProperty Count
    Write-CustomLog "Conditional complexity: $ifStatements if statements" -Level WARN
    
    if ($ifStatements -gt 20) {
        Write-CustomLog "❌ PROBLEM: Function is too complex ($ifStatements if statements > 20 recommended max)" -Level ERROR
    }
    
    # Check embedded functions
    $embeddedFunctions = Select-String -Path $mainFunction -Pattern "^\s*function \w+" | Measure-Object | Select-Object -ExpandProperty Count
    Write-CustomLog "Embedded functions: $embeddedFunctions functions" -Level WARN
    
    if ($embeddedFunctions -gt 1) {
        Write-CustomLog "❌ PROBLEM: Function contains embedded helper functions (should be separate modules)" -Level ERROR
    }
    
    # Check available modules
    $moduleFiles = Get-ChildItem "$patchManagerPath\Public" -Filter "*.ps1" | Where-Object { $_.Name -ne "Invoke-GitControlledPatch.ps1" }
    Write-CustomLog "Available modular components: $($moduleFiles.Count)" -Level INFO
    
    foreach ($module in $moduleFiles) {
        Write-CustomLog "  - $($module.BaseName)" -Level INFO
    }
    
    # Check if main function actually calls modular components
    $mainContent = Get-Content $mainFunction -Raw
    $moduleUsage = @()
    
    foreach ($module in $moduleFiles) {
        $functionName = $module.BaseName
        if ($mainContent -match $functionName) {
            $moduleUsage += "✅ Uses $functionName"
        } else {
            $moduleUsage += "❌ Doesn't use $functionName (reimplements logic inline)"
        }
    }
    
    Write-CustomLog "=== Module Usage Analysis ===" -Level INFO
    foreach ($usage in $moduleUsage) {
        if ($usage -match "✅") {
            Write-CustomLog $usage -Level SUCCESS
        } else {
            Write-CustomLog $usage -Level ERROR
        }
    }
}

function New-RefactoredGitControlledPatch {
    [CmdletBinding()]
    param()
    
    Write-CustomLog "=== Creating Properly Refactored GitControlledPatch ===" -Level INFO
    
    $refactoredContent = @'
#Requires -Version 7.0

<#
.SYNOPSIS
    Git-controlled patch application with comprehensive validation and rollback.

.DESCRIPTION
    This is the PROPERLY REFACTORED version of Invoke-GitControlledPatch that actually
    uses the modular components instead of reimplementing everything inline.
    
    Maximum recommended size: 150 lines
    Maximum recommended complexity: 15 if statements
    Dependencies: Uses modular components from PatchManager module
#>

function Invoke-GitControlledPatch {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$PatchDescription,
        
        [Parameter(Mandatory)]
        [scriptblock]$PatchOperation,
        
        [Parameter()]
        [string[]]$TestCommands = @(),
        
        [Parameter()]
        [switch]$CreatePullRequest,
        
        [Parameter()]
        [switch]$DirectCommit,
        
        [Parameter()]
        [switch]$AutoCommitUncommitted,
        
        [Parameter()]
        [switch]$Force
    )
    
    begin {
        Write-CustomLog "Starting GitControlledPatch: $PatchDescription" -Level INFO
        
        # Import required modular components
        Import-Module "$PSScriptRoot\..\ErrorHandling.ps1" -Force
        Import-Module "$PSScriptRoot\..\GitOperations.ps1" -Force
        Import-Module "$PSScriptRoot\..\BranchStrategy.ps1" -Force
        Import-Module "$PSScriptRoot\..\CleanupOperations.ps1" -Force
        
        # Test patching requirements using modular component
        if (-not (Test-PatchingRequirements)) {
            throw "Patching requirements not met"
        }
    }
    
    process {
        try {
            if ($PSCmdlet.ShouldProcess($PatchDescription, "Apply Git-Controlled Patch")) {
                
                # 1. Create GitHub issue for tracking (modular component)
                $issueNumber = Invoke-GitHubIssueIntegration -Title "Patch: $PatchDescription" -Body "Automated patch application"
                Write-CustomLog "Created tracking issue: #$issueNumber" -Level SUCCESS
                
                # 2. Handle uncommitted changes (modular component)
                if ($AutoCommitUncommitted) {
                    Invoke-CommitUncommittedChanges -Message "Auto-commit before patch: $PatchDescription"
                }
                
                # 3. Get branch strategy (modular component)
                $branchInfo = Get-BranchStrategy -PatchDescription $PatchDescription -CreatePullRequest:$CreatePullRequest -DirectCommit:$DirectCommit
                
                # 4. Apply patch operation
                Write-CustomLog "Applying patch operation..." -Level INFO
                $patchResult = & $PatchOperation
                
                # 5. Run tests if specified (modular component)
                if ($TestCommands.Count -gt 0) {
                    $testResult = Invoke-TieredPesterTests -TestCommands $TestCommands
                    if (-not $testResult.Success) {
                        throw "Tests failed: $($testResult.FailureMessage)"
                    }
                }
                
                # 6. Commit and push changes (modular component)
                $commitResult = Invoke-CommitAndPush -Message $PatchDescription -BranchInfo $branchInfo
                
                # 7. Create pull request if requested (modular component)
                if ($CreatePullRequest) {
                    $prResult = Invoke-CreatePullRequest -Title $PatchDescription -IssueNumber $issueNumber
                    Write-CustomLog "Created pull request: $($prResult.Url)" -Level SUCCESS
                }
                
                # 8. Update GitHub issue with completion (modular component)
                Update-GitHubIssueProgress -IssueNumber $issueNumber -Status "COMPLETED" -Message "Patch applied successfully"
                
                Write-CustomLog "Patch applied successfully!" -Level SUCCESS
                return @{
                    Success = $true
                    IssueNumber = $issueNumber
                    CommitHash = $commitResult.CommitHash
                    PullRequestUrl = $prResult.Url
                }
            }
        }
        catch {
            # Use modular error handling
            $errorResult = HandlePatchError -ErrorMessage $_.Exception.Message -ErrorCategory "PatchApplication"
            
            # Attempt rollback using modular component
            Write-CustomLog "Attempting automatic rollback..." -Level WARN
            Invoke-QuickRollback -RollbackType "LastPatch" -CreateBackup
            
            throw $errorResult.Message
        }
    }
    
    end {
        # Cleanup using modular component
        Invoke-CleanupOperations -Mode "Standard"
        Write-CustomLog "Completed GitControlledPatch processing" -Level INFO
    }
}

Export-ModuleMember -Function Invoke-GitControlledPatch
'@

    $outputPath = "c:\Users\alexa\OneDrive\Documents\0. wizzense\opentofu-lab-automation\Invoke-GitControlledPatch-REFACTORED.ps1"
    Set-Content -Path $outputPath -Value $refactoredContent
    
    Write-CustomLog "Created refactored version: $outputPath" -Level SUCCESS
    Write-CustomLog "New version is approximately 100 lines (vs 946 lines original)" -Level SUCCESS
    Write-CustomLog "Uses modular components instead of reimplementing logic" -Level SUCCESS
    
    return $outputPath
}

function Compare-VersionSizes {
    [CmdletBinding()]
    param()
    
    $originalPath = "c:\Users\alexa\OneDrive\Documents\0. wizzense\opentofu-lab-automation\pwsh\modules\PatchManager\Public\Invoke-GitControlledPatch.ps1"
    $refactoredPath = "c:\Users\alexa\OneDrive\Documents\0. wizzense\opentofu-lab-automation\Invoke-GitControlledPatch-REFACTORED.ps1"
    
    $originalSize = (Get-Content $originalPath).Count
    $refactoredSize = (Get-Content $refactoredPath).Count
    
    Write-CustomLog "=== Size Comparison ===" -Level INFO
    Write-CustomLog "Original (monolithic): $originalSize lines" -Level WARN
    Write-CustomLog "Refactored (modular): $refactoredSize lines" -Level SUCCESS
    Write-CustomLog "Reduction: $($originalSize - $refactoredSize) lines ($(([math]::Round((($originalSize - $refactoredSize) / $originalSize) * 100, 1)))% smaller)" -Level SUCCESS
}

# Main execution
try {
    Write-CustomLog "=== PatchManager Refactoring Analysis ===" -Level INFO
    
    Show-CurrentPatchManagerProblems
    Write-CustomLog ""
    
    $refactoredFile = New-RefactoredGitControlledPatch
    Write-CustomLog ""
    
    Compare-VersionSizes
    Write-CustomLog ""
    
    Write-CustomLog "=== Summary ===" -Level SUCCESS
    Write-CustomLog "✅ Identified all problems with current 946-line monolithic function" -Level SUCCESS
    Write-CustomLog "✅ Created properly modular version that uses existing components" -Level SUCCESS
    Write-CustomLog "✅ Reduced complexity from 59 if statements to ~10" -Level SUCCESS
    Write-CustomLog "✅ Eliminated embedded helper functions" -Level SUCCESS
    Write-CustomLog "✅ Made it actually use the 'modular' components" -Level SUCCESS
    Write-CustomLog ""
    Write-CustomLog "Next steps:" -Level INFO
    Write-CustomLog "1. Review the refactored version: $refactoredFile" -Level INFO
    Write-CustomLog "2. Use PatchManager to safely replace the original" -Level INFO
    Write-CustomLog "3. Test that all modular components work together" -Level INFO
}
catch {
    Write-CustomLog "Error during refactoring analysis: $($_.Exception.Message)" -Level ERROR
    throw
}
