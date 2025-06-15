function Invoke-TestFileFix {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$ProjectRoot = (Get-Location).Path,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("ParamError", "DotSourcing", "ExecutionPattern", "ModuleScope", "All")]
        [string[]]$FixTypes = @("All"),
        
        [Parameter(Mandatory = $false)]
        [string]$TestPath = "tests",
        
        [Parameter(Mandatory = $false)]
        [string[]]$Include = @("*.Tests.ps1"),
        
        [Parameter(Mandatory = $false)]
        [string[]]$Exclude = @(),
        
        [Parameter(Mandatory = $false)]
        [switch]$WhatIf,
        
        [Parameter(Mandatory = $false)]
        [string]$LogFile,
        
        [Parameter(Mandatory = $false)]
        [switch]$CreateReport
    )
    
    # Ensure we have absolute path
    $ProjectRoot = (Resolve-Path $ProjectRoot).Path
    $fullTestPath = Join-Path $ProjectRoot $TestPath
    
    if (-not (Test-Path $fullTestPath)) {
        Write-PatchLog "Test path not found: $fullTestPath" "ERROR" -LogFile $LogFile
        return $false
    }
    
    # Set up logging
    if (-not $LogFile) {
        $logDir = Join-Path $ProjectRoot "logs"
        if (-not (Test-Path $logDir)) {
            New-Item -Path $logDir -ItemType Directory -Force | Out-Null
        }
        $LogFile = Join-Path $logDir "testfix_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
    }
    
    Write-PatchLog "Starting test file fixes in $fullTestPath" "INFO" -LogFile $LogFile
    
    # Results tracking
    $results = @{
        TestFilesFound = 0
        TestFilesFixed = 0
        FixesByType = @{}
        Errors = @()
        FixedFiles = @()
    }
    
    foreach ($fixType in $FixTypes) {
        $results.FixesByType[$fixType] = 0
    }
    
    # Get test files
    $testFiles = Get-ChildItem -Path $fullTestPath -Include $Include -Exclude $Exclude -Recurse
    $results.TestFilesFound = $testFiles.Count
    
    Write-PatchLog "Found $($results.TestFilesFound) test files" "INFO" -LogFile $LogFile
    
    # Process each test file
    foreach ($testFile in $testFiles) {
        Write-PatchLog "Processing test file: $($testFile.Name)" "INFO" -LogFile $LogFile
        
        $fixApplied = $false
        foreach ($fixType in $FixTypes) {
            try {
                $fixed = Repair-TestFile -FilePath $testFile.FullName -FixType $fixType `
                         -LogFile $LogFile -WhatIf:$WhatIf
                         
                if ($fixed) {
                    $results.FixesByType[$fixType]++
                    $fixApplied = $true
                }
            }
            catch {
                $errorMessage = "Error fixing $($testFile.Name) with $fixType`: $($_.Exception.Message)"
                Write-PatchLog $errorMessage "ERROR" -LogFile $LogFile
                $results.Errors += $errorMessage
            }
        }
        
        if ($fixApplied) {
            $results.TestFilesFixed++
            $results.FixedFiles += $testFile.FullName
        }
    }
    
    # Report results
    Write-PatchLog "Test file fixes completed" "SUCCESS" -LogFile $LogFile
    Write-PatchLog "Summary:" "INFO" -LogFile $LogFile
    Write-PatchLog "- Test files found: $($results.TestFilesFound)" "INFO" -LogFile $LogFile
    Write-PatchLog "- Test files fixed: $($results.TestFilesFixed)" "INFO" -LogFile $LogFile
    
    foreach ($fixType in $FixTypes) {
        Write-PatchLog "- $fixType fixes: $($results.FixesByType[$fixType])" "INFO" -LogFile $LogFile
    }
    
    # Generate report if requested
    if ($CreateReport) {
        $reportPath = Join-Path $ProjectRoot "reports"
        if (-not (Test-Path $reportPath)) {
            New-Item -Path $reportPath -ItemType Directory -Force | Out-Null
        }
        
        $reportFile = Join-Path $reportPath "testfix-report_$(Get-Date -Format 'yyyyMMdd_HHmmss').md"
        $report = @"
# Test File Fix Report

Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

## Summary

- **Test Files Found**: $($results.TestFilesFound)
- **Test Files Fixed**: $($results.TestFilesFixed)

## Fixes Applied

$(
foreach ($fixType in $FixTypes) {
"- **$fixType**: $($results.FixesByType[$fixType]) files"
}
)

## Fixed Files

$(
foreach ($file in $results.FixedFiles) {
"- ``$file``"
}
)

## Errors

$(
if ($results.Errors.Count -gt 0) {
    foreach ($errorItem in $results.Errors) {
    "- $errorItem"
    }
} else {
    "No errors occurred during the fix process."
}
)
"@
        
        Set-Content -Path $reportFile -Value $report
        Write-PatchLog "Fix report generated at: $reportFile" "SUCCESS" -LogFile $LogFile
    }
    
    return $results
}
