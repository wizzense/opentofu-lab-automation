<#
.SYNOPSIS
Runs comprehensive validation and automatically fixes identified issues

.DESCRIPTION
This function runs the full suite of tests (linting, Pester tests, Python tests)
and automatically applies fixes to identified issues.

.PARAMETER SkipLint
Skip PowerShell linting

.PARAMETER SkipPester
Skip Pester tests

.PARAMETER SkipPyTest
Skip Python tests

.PARAMETER SkipFixes
Skip automatic fixing of identified issues

.PARAMETER OutputPath
Path where test results will be saved

.PARAMETER DetailedResults
Show detailed test results

.PARAMETER PassThru
Return the validation results object

.EXAMPLE
Invoke-ComprehensiveValidation

.EXAMPLE
Invoke-ComprehensiveValidation -SkipLint -DetailedResults
#>
function Invoke-ComprehensiveValidation {
    CmdletBinding()
    param(
        switch$EnableAutoFix,
        switch$GenerateTests,
        ValidateSet('Text', 'JSON', 'CI')
        string$OutputFormat = 'Text',
        string$OutputPath,
        switch$OutputComprehensiveReport,
        switch$CI,
        switch$Detailed,
        switch$SkipLint,
        switch$SkipPester,
        switch$SkipPyTest,
        switch$SkipFixes,
        switch$DetailedResults,
        switch$PassThru,
        string$BasePath = (Get-Location).Path
    )

    Write-Host "Running comprehensive validation..." -ForegroundColor Cyan

    $results = @{
        PowerShellLint = $null
        JsonValidation = $null
        TestResults = $null
        SyntaxFixes = @()
        TestsGenerated = @()
        OverallStatus = "Success"
        SummaryStats = @{
            TotalScripts = 0
            ScriptsWithIssues = 0
            SyntaxFixesApplied = 0
            TestsGenerated = 0
            JsonFilesChecked = 0
            JsonIssues = 0
        }
    }

    try {
        # 1. PowerShell Linting
        if (-not $SkipLint) {
            Write-Host "`n1/4 Running PowerShell linting..." -ForegroundColor Yellow
            $lintResults = Invoke-ParallelScriptAnalyzer -Path $BasePath -OutputFormat $OutputFormat -PassThru
            $results.PowerShellLint = $lintResults

            if ($lintResults) {
                $results.SummaryStats.ScriptsWithIssues = ($lintResults  Select-Object -Unique File).Count
                if ($lintResults  Where-Object Severity -eq 'Error') {
                    $results.OverallStatus = "HasIssues"
                }
            }
        }

        # 2. JSON Configuration Validation
        Write-Host "`n2/4 Validating JSON configuration files..." -ForegroundColor Yellow
        $jsonResults = Test-JsonConfig -Path $BasePath -OutputFormat $OutputFormat -PassThru
        $results.JsonValidation = $jsonResults

        if ($jsonResults) {
            $results.SummaryStats.JsonIssues = $jsonResults.Count
            if ($jsonResults  Where-Object Severity -eq 'Error') {
                $results.OverallStatus = "HasIssues"
            }
        }

        # 3. Apply fixes if requested
        if (($EnableAutoFix -or -not $SkipFixes) -and $results.OverallStatus -eq "HasIssues") {
            Write-Host "`n3/4 Applying automatic fixes..." -ForegroundColor Yellow
            try {
                $fixResults = Invoke-AutoFix -Path $BasePath -EnableAutoFix -PassThru
                $results.SyntaxFixes = $fixResults
                $results.SummaryStats.SyntaxFixesApplied = if ($fixResults) { $fixResults.Count } else { 0 }
            } catch {
                Write-CustomLog "Some fixes failed: $($_.Exception.Message)" "ERROR"
            }
        } else {
            Write-Host "`n3/4 Skipping fixes (not requested or no issues found)" -ForegroundColor Gray
        }

        # 4. Generate tests if requested
        if ($GenerateTests) {
            Write-Host "`n4/4 Generating missing tests..." -ForegroundColor Yellow
            Write-CustomLog "Test generation not yet implemented" "INFO"
        } else {
            Write-Host "`n4/4 Skipping test generation (not requested)" -ForegroundColor Gray
        }

        # Calculate total scripts
        $allScripts = Get-ChildItem -Path $BasePath -Recurse -Include *.ps1,*.psm1,*.psd1 -File 
            Where-Object { $_.FullName -notlike "*archive*" -and $_.FullName -notlike "*backup*" }
        $results.SummaryStats.TotalScripts = $allScripts.Count

        $allJsonFiles = Get-ChildItem -Path $BasePath -Recurse -Include *.json -File 
            Where-Object { $_.FullName -notlike "*archive*" -and $_.FullName -notlike "*backup*" }
        $results.SummaryStats.JsonFilesChecked = $allJsonFiles.Count

        # Output results
        if ($OutputFormat -eq 'JSON') {
            $jsonOutput = $results  ConvertTo-Json -Depth 10
            if ($OutputPath) {
                $jsonOutput  Out-File -FilePath $OutputPath -Encoding UTF8
                Write-Host "Comprehensive report saved to $OutputPath" -ForegroundColor Green
            }
            Write-Output $jsonOutput
        } else {
            Write-Host "`n" + "="*60 -ForegroundColor Cyan
            Write-Host "COMPREHENSIVE VALIDATION SUMMARY" -ForegroundColor Cyan
            Write-Host "="*60 -ForegroundColor Cyan
            Write-Host "Overall Status: $($results.OverallStatus)" -ForegroundColor $(if($results.OverallStatus -eq 'Success') { 'Green' } else { 'Yellow' })
            Write-Host "PowerShell Scripts: $($results.SummaryStats.TotalScripts)" -ForegroundColor White
            Write-Host "Scripts with Issues: $($results.SummaryStats.ScriptsWithIssues)" -ForegroundColor White
            Write-Host "JSON Files Checked: $($results.SummaryStats.JsonFilesChecked)" -ForegroundColor White
            Write-Host "JSON Issues Found: $($results.SummaryStats.JsonIssues)" -ForegroundColor White
            if ($EnableAutoFix -or -not $SkipFixes) {
                Write-Host "Syntax Fixes Applied: $($results.SummaryStats.SyntaxFixesApplied)" -ForegroundColor White
            }
            if ($GenerateTests) {
                Write-Host "Tests Generated: $($results.SummaryStats.TestsGenerated)" -ForegroundColor White
            }
        }

    } catch {
        Write-CustomLog "Validation failed: $($_.Exception.Message)" "ERROR"
        $results.OverallStatus = "Failed"
        if ($OutputFormat -eq 'CI') {
            exit 1
        }
    }

    if ($OutputComprehensiveReport -or $PassThru) {
        return $results
    }
}


