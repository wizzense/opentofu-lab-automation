function Show-MaintenanceReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false)]
        [string]$ProjectRoot = $PWD,
        
        [Parameter(Mandatory=$false)]
        [PSCustomObject]$HealthCheck,
        
        [Parameter(Mandatory=$false)]
        [PSCustomObject]$YamlResult,
        
        [Parameter(Mandatory=$false)]
        [PSCustomObject]$TestResults,
        
        [Parameter(Mandatory=$false)]
        [PSCustomObject]$Issues,
        
        [Parameter(Mandatory=$false)]
        [switch]$SaveToFile,
        
        [Parameter(Mandatory=$false)]
        [string]$OutputPath
    )
    
    # Normalize project root to absolute path
    $ProjectRoot = (Resolve-Path $ProjectRoot).Path
    
    # Function for centralized logging
    function Write-ReportLog {
        param (
            [string]$Message,
            [ValidateSet("INFO", "SUCCESS", "WARNING", "ERROR", "DEBUG", "HEADER")]
            [string]$Level = "INFO"
        )
        
        # Color coding based on level
        switch ($Level) {
            "INFO"    { Write-Host $Message -ForegroundColor Gray }
            "SUCCESS" { Write-Host $Message -ForegroundColor Green }
            "WARNING" { Write-Host $Message -ForegroundColor Yellow }
            "ERROR"   { Write-Host $Message -ForegroundColor Red }
            "DEBUG"   { Write-Host $Message -ForegroundColor DarkGray }
            "HEADER"  { Write-Host $Message -ForegroundColor Cyan }
        }
    }
    
    # Create report data object
    $report = [PSCustomObject]@{
        Title = "OpenTofu Lab Automation - Maintenance Report"
        Date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        HealthCheck = $HealthCheck
        YamlValidation = $YamlResult
        TestResults = $TestResults
        Issues = $Issues
        Summary = @{
            TotalIssues = 0
            FixedIssues = 0
            CriticalIssues = 0
            Status = "Healthy" # Can be "Healthy", "Warning", "Critical"
        }
    }
    
    # Determine if a custom path is provided, otherwise use default
    if (-not $OutputPath) {
        $reportFileName = "maintenance-report-$(Get-Date -Format 'yyyyMMdd-HHmmss').md"
        $OutputPath = Join-Path $ProjectRoot "reports" | Join-Path -ChildPath $reportFileName
    }
    
    # Ensure reports directory exists
    if ($SaveToFile) {
        $reportsDir = Split-Path $OutputPath -Parent
        if (-not (Test-Path $reportsDir)) {
            $null = New-Item -Path $reportsDir -ItemType Directory -Force -ErrorAction SilentlyContinue
        }
    }
    
    # Analyze issues to populate summary
    if ($Issues) {
        $report.Summary.TotalIssues = ($Issues | Measure-Object -Property Count -Sum).Sum
        $report.Summary.CriticalIssues = ($Issues | Where-Object { $_.Severity -eq "High" } | Measure-Object -Property Count -Sum).Sum
        
        if ($report.Summary.CriticalIssues -gt 0) {
            $report.Summary.Status = "Critical"
        }
        elseif ($report.Summary.TotalIssues -gt 0) {
            $report.Summary.Status = "Warning"
        }
    }
    
    # Calculate fixed issues if we have health check data
    if ($HealthCheck) {
        $report.Summary.FixedIssues = $HealthCheck.FixesApplied
    }
    
    # Generate the report content
    $reportContent = @"
# $($report.Title)

Generated: $($report.Date)

## Summary

- **Status**: $($report.Summary.Status)
- **Total Issues**: $($report.Summary.TotalIssues)
- **Critical Issues**: $($report.Summary.CriticalIssues)
- **Fixed Issues**: $($report.Summary.FixedIssues)

"@
    
    # Add health check section if available
    if ($HealthCheck) {
        $reportContent += @"
## Infrastructure Health

- **Fixes Applied**: $($HealthCheck.FixesApplied)
- **Import Paths Fixed**: $($HealthCheck.ImportPaths)
- **Test Syntax Fixes**: $($HealthCheck.TestSyntax)
- **Module Structure Fixes**: $($HealthCheck.ModuleStructure)
- **Errors**: $($HealthCheck.Errors)

"@
    }
    
    # Add YAML validation section if available
    if ($YamlResult) {
        $yamlStatus = if ($YamlResult) { "Passed" } else { "Failed" }
        
        $reportContent += @"
## YAML Validation

- **Status**: $yamlStatus

"@
    }
    
    # Add test results section if available
    if ($TestResults) {
        $reportContent += @"
## Test Results

- **Tests Run**: $($TestResults.Total)
- **Passed**: $($TestResults.Passed)
- **Failed**: $($TestResults.Failed)
- **Skipped**: $($TestResults.Skipped)

"@
        
        if ($TestResults.Failed -gt 0 -and $TestResults.FailedTests) {
            $reportContent += "### Failed Tests\n\n"
            
            foreach ($test in $TestResults.FailedTests) {
                $reportContent += "- **$($test.Name)**: $($test.FailureMessage)\n"
            }
            
            $reportContent += "\n"
        }
    }
    
    # Add recurring issues section if available
    if ($Issues -and $Issues.Count -gt 0) {
        $reportContent += @"
## Recurring Issues

"@
        
        foreach ($issue in $Issues) {
            $reportContent += @"
### $($issue.Name) (Severity: $($issue.Severity))

- **Count**: $($issue.Count)
- **Auto-Fix Command**: `$($issue.AutoFixCommand)`

"@
            
            if ($issue.Details) {
                $reportContent += "#### Details\n\n"
                
                foreach ($detail in $issue.Details) {
                    if ($detail.File) {
                        $reportContent += "- **File**: $($detail.File)"
                        
                        if ($detail.Error) {
                            $reportContent += " - Error: $($detail.Error)"
                        }
                        
                        if ($detail.ErrorCount) {
                            $reportContent += " - Errors: $($detail.ErrorCount)"
                        }
                        
                        $reportContent += "\n"
                    }
                    elseif ($detail.Directory) {
                        $reportContent += "- **Directory**: $($detail.Directory) - Items: $($detail.ItemCount)\n"
                    }
                }
                
                $reportContent += "\n"
            }
        }
    }
    
    # Add recommendations section
    $reportContent += @"
## Recommendations

"@
    
    if ($report.Summary.Status -eq "Critical") {
        $reportContent += @"
1. **CRITICAL**: Address high-severity issues immediately
2. Run `./scripts/maintenance/unified-maintenance.ps1 -Mode "All" -AutoFix` to attempt automatic fixes
3. Review test failures and resolve them
"@
    }
    elseif ($report.Summary.Status -eq "Warning") {
        $reportContent += @"
1. Run `./scripts/maintenance/unified-maintenance.ps1 -Mode "All" -AutoFix` to address issues
2. Clean up archive directories if necessary
3. Update documentation if needed
"@
    }
    else {
        $reportContent += @"
1. System is healthy, continue with regular maintenance
2. Consider updating CHANGELOG.md with recent changes
3. Run tests periodically to ensure continued stability
"@
    }
    
    # Save to file if requested
    if ($SaveToFile) {
        try {
            Set-Content -Path $OutputPath -Value $reportContent -NoNewline
            Write-ReportLog "Maintenance report saved to $OutputPath" "SUCCESS"
        }
        catch {
            Write-ReportLog "Failed to save maintenance report: $_" "ERROR"
        }
    }
    
    # Display the report
    Write-ReportLog "`n$($report.Title)" "HEADER"
    Write-ReportLog "Generated: $($report.Date)" "INFO"
    Write-ReportLog "" "INFO"
    
    Write-ReportLog "SUMMARY" "HEADER"
    $statusColor = switch ($report.Summary.Status) {
        "Healthy" { "SUCCESS" }
        "Warning" { "WARNING" }
        "Critical" { "ERROR" }
        default { "INFO" }
    }
    Write-ReportLog "Status: $($report.Summary.Status)" $statusColor
    Write-ReportLog "Total Issues: $($report.Summary.TotalIssues)" "INFO"
    Write-ReportLog "Critical Issues: $($report.Summary.CriticalIssues)" "INFO"
    Write-ReportLog "Fixed Issues: $($report.Summary.FixedIssues)" "INFO"
    Write-ReportLog "" "INFO"
    
    if ($Issues -and $Issues.Count -gt 0) {
        Write-ReportLog "KEY ISSUES" "HEADER"
        
        foreach ($issue in ($Issues | Where-Object { $_.Severity -eq "High" })) {
            Write-ReportLog "$($issue.Name): $($issue.Count) issue(s)" "ERROR"
        }
        
        foreach ($issue in ($Issues | Where-Object { $_.Severity -eq "Medium" })) {
            Write-ReportLog "$($issue.Name): $($issue.Count) issue(s)" "WARNING"
        }
        
        Write-ReportLog "" "INFO"
    }
    
    Write-ReportLog "RECOMMENDATIONS" "HEADER"
    if ($report.Summary.Status -eq "Critical") {
        Write-ReportLog "1. CRITICAL: Address high-severity issues immediately" "ERROR"
        Write-ReportLog "2. Run maintenance with auto-fix to attempt automatic fixes" "INFO"
        Write-ReportLog "3. Review test failures and resolve them" "INFO"
    }
    elseif ($report.Summary.Status -eq "Warning") {
        Write-ReportLog "1. Run maintenance with auto-fix to address issues" "WARNING"
        Write-ReportLog "2. Clean up archive directories if necessary" "INFO"
        Write-ReportLog "3. Update documentation if needed" "INFO"
    }
    else {
        Write-ReportLog "1. System is healthy, continue with regular maintenance" "SUCCESS"
        Write-ReportLog "2. Consider updating CHANGELOG.md with recent changes" "INFO"
        Write-ReportLog "3. Run tests periodically to ensure continued stability" "INFO"
    }
    
    # Return the report object
    return [PSCustomObject]@{
        Summary = $report.Summary
        ReportPath = if ($SaveToFile) { $OutputPath } else { $null }
        Content = $reportContent
    }
}
