function Invoke-PatchCleanup {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$ProjectRoot = (Get-Location).Path,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Analyze", "Archive", "Migrate", "All", "Safe", "Full", "Report")]
        [string]$Mode = "Analyze",
        
        [Parameter(Mandatory = $false)]
        [switch]$UpdateChangelog,
        
        [Parameter(Mandatory = $false)]
        [switch]$Force,
        
        [Parameter(Mandatory = $false)]
        [switch]$WhatIf,
        
        [Parameter(Mandatory = $false)]
        [string]$LogFile
    )
    
    # Ensure we have absolute path
    $ProjectRoot = (Resolve-Path $ProjectRoot).Path
    
    # If no log file is specified, create one in the logs directory
    if (-not $LogFile) {
        $logDir = Join-Path $ProjectRoot "logs"
        if (-not (Test-Path $logDir)) {
            New-Item -Path $logDir -ItemType Directory -Force | Out-Null
        }
        $LogFile = Join-Path $logDir "patchcleanup_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
    }
    
    Write-PatchLog "Starting patch cleanup in $Mode mode" "INFO" -LogFile $LogFile
    
    # Results tracking
    $results = @{
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        ScatteredFilesFound = 0
        ScatteredFilesArchived = 0
        FixScriptsImported = $false
        TestFilesFixed = 0
        ChangelogUpdated = $false
        Successful = $true
        Errors = @()
        AnalyzedFiles = @()
        MigratedFunctionality = @()
        RemainingIssues = @()
    }
    
    try {
        # Step 1: Analyze scattered files
        Write-PatchLog "Step 1: Analyzing scattered patch and fix files" "STEP" -LogFile $LogFile
        
        # Find all patch/fix related files
        $fixFiles = @()
        $fixFiles += Get-ChildItem -Path $ProjectRoot -Filter "*fix*.ps1" -File
        $fixFiles += Get-ChildItem -Path $ProjectRoot -Filter "*patch*.ps1" -File
        $fixFiles += Get-ChildItem -Path (Join-Path $ProjectRoot "scripts") -Filter "*fix*.ps1" -File -Recurse
        $fixFiles += Get-ChildItem -Path (Join-Path $ProjectRoot "scripts") -Filter "*patch*.ps1" -File -Recurse
        
        # Filter out files in approved locations (PatchManager module and standard maintenance)
        $approvedPaths = @(
            (Join-Path $ProjectRoot "pwsh\modules\PatchManager"),
            (Join-Path $ProjectRoot "scripts\maintenance\unified-maintenance.ps1"),
            (Join-Path $ProjectRoot "scripts\maintenance\patching.ps1")
        )
        
        $scatteredFiles = $fixFiles | Where-Object {
            $filePath = $_.FullName
            $inApprovedPath = $false
            
            foreach ($approvedPath in $approvedPaths) {
                if ($filePath -like "$approvedPath*") {
                    $inApprovedPath = $true
                    break
                }
            }
            
            -not $inApprovedPath
        }
        
        $results.ScatteredFilesFound = $scatteredFiles.Count
        $results.AnalyzedFiles = $scatteredFiles | ForEach-Object {
            @{
                Name = $_.Name
                Path = $_.FullName
                LastModified = $_.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
                SizeKB = [Math]::Round($_.Length / 1KB, 2)
            }
        }
        
        Write-PatchLog "Found $($results.ScatteredFilesFound) scattered patch/fix files" "INFO" -LogFile $LogFile
        
        # Step 2: Archive files if requested
        if ($Mode -in @("Archive", "All", "Safe", "Full")) {
            Write-PatchLog "Step 2: Archiving scattered fix scripts" "STEP" -LogFile $LogFile
            
            $archiveForce = $Force -or $Mode -in @("Full", "All")
            $archiveResults = Remove-ScatteredFiles -ProjectRoot $ProjectRoot -Force:$archiveForce -WhatIf:$($Mode -eq "Report" -or $WhatIf) -LogFile $LogFile
            
            $results.ScatteredFilesArchived = $archiveResults.ArchivedCount
            
            Write-PatchLog "Archived $($results.ScatteredFilesArchived) files" "INFO" -LogFile $LogFile
        }
        
        # Step 3: Migrate functionality if requested
        if ($Mode -in @("Migrate", "All", "Full")) {
            Write-PatchLog "Step 3: Migrating fix functionality into PatchManager module" "STEP" -LogFile $LogFile
            
            # Migrate test fixes
            $testFixPath = Join-Path $ProjectRoot "apply-basic-fixes.ps1"
            if (Test-Path $testFixPath) {
                $migrated = Import-TestFixFunctions -Path $testFixPath -LogFile $LogFile
                if ($migrated) {
                    $results.MigratedFunctionality += @{
                        Source = $testFixPath
                        Type = "TestFix"
                        Status = "Success"
                    }
                }
                else {
                    $results.MigratedFunctionality += @{
                        Source = $testFixPath
                        Type = "TestFix"
                        Status = "Failed"
                    }
                    $results.RemainingIssues += "Failed to migrate test fix functionality from $testFixPath"
                }
            }
            
            # Migrate infrastructure fixes
            $infraFixPath = Join-Path $ProjectRoot "scripts" "maintenance" "fix-infrastructure-issues.ps1"
            if (Test-Path $infraFixPath) {
                $migrated = Import-InfraFixFunctions -Path $infraFixPath -LogFile $LogFile
                if ($migrated) {
                    $results.MigratedFunctionality += @{
                        Source = $infraFixPath
                        Type = "InfrastructureFix"
                        Status = "Success"
                    }
                }
                else {
                    $results.MigratedFunctionality += @{
                        Source = $infraFixPath
                        Type = "InfrastructureFix"
                        Status = "Failed"
                    }
                    $results.RemainingIssues += "Failed to migrate infrastructure fix functionality from $infraFixPath"
                }
            }
            
            $results.FixScriptsImported = $results.MigratedFunctionality.Count -gt 0
            Write-PatchLog "Migrated $($results.MigratedFunctionality.Count) fix scripts to module functions" "INFO" -LogFile $LogFile
        }
        
        # Step 4: Fix test files if needed
        if ($Mode -in @("All", "Safe", "Full")) {
            Write-PatchLog "Step 4: Fixing test files with common patterns" "STEP" -LogFile $LogFile
            
            $testFixResults = Invoke-TestFileFix -ProjectRoot $ProjectRoot -Force:$Force -LogFile $LogFile
            $results.TestFilesFixed = $testFixResults.FixedFiles
            
            Write-PatchLog "Fixed $($results.TestFilesFixed) test files" "INFO" -LogFile $LogFile
        }
        
        # Step 5: Update changelog if requested
        if ($UpdateChangelog) {
            Write-PatchLog "Step 5: Updating changelog" "STEP" -LogFile $LogFile
            
            try {
                Update-Changelog -ProjectRoot $ProjectRoot -Entry @{
                    Type = "maintenance"
                    Description = "Patch cleanup: Organized scattered fix scripts into PatchManager module"
                    Details = "Archived $($results.ScatteredFilesArchived) scattered fix files, migrated $($results.MigratedFunctionality.Count) fix functions, fixed $($results.TestFilesFixed) test files"
                    Date = (Get-Date).ToString("yyyy-MM-dd")
                } -LogFile $LogFile
                
                $results.ChangelogUpdated = $true
                Write-PatchLog "Changelog updated successfully" "SUCCESS" -LogFile $LogFile
            }
            catch {
                $results.ChangelogUpdated = $false
                $results.Errors += "Failed to update changelog: $($_.Exception.Message)"
                Write-PatchLog "Failed to update changelog: $($_.Exception.Message)" "ERROR" -LogFile $LogFile
            }
        }
    }
    catch {
        $results.Successful = $false
        $results.Errors += $_.Exception.Message
        Write-PatchLog "Patch cleanup failed: $($_.Exception.Message)" "ERROR" -LogFile $LogFile
    }
    
    # Final summary
    if ($results.Successful) {
        Write-PatchLog "Patch cleanup completed successfully" "SUCCESS" -LogFile $LogFile
    }
    else {
        Write-PatchLog "Patch cleanup completed with errors" "WARNING" -LogFile $LogFile
    }
    
    Write-PatchLog "Summary: Found $($results.ScatteredFilesFound) scattered files, archived $($results.ScatteredFilesArchived), imported $($results.MigratedFunctionality.Count) functions, fixed $($results.TestFilesFixed) test files" "INFO" -LogFile $LogFile
    
    return $results
}
