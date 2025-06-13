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
    [CmdletBinding()]
    param(
        [switch]$ApplyFixes,
        [switch]$GenerateTests,
        [ValidateSet('Text', 'JSON', 'CI')]
        [string]$OutputFormat = 'Text',
        [string]$OutputPath,
        [switch]$OutputComprehensiveReport,
        [switch]$CI,
        [switch]$Detailed,
        [switch]$SkipLint,
        [switch]$SkipPester,
        [switch]$SkipPyTest,
        [switch]$SkipFixes,
        [switch]$DetailedResults,
        [switch]$PassThru
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
            Write-Host "`n[1/4] Running PowerShell linting..." -ForegroundColor Yellow
            $lintResults = Invoke-PowerShellLint -Path "." -OutputFormat $OutputFormat -PassThru
            $results.PowerShellLint = $lintResults
            
            if ($lintResults) {
                $results.SummaryStats.ScriptsWithIssues = ($lintResults | Select-Object -Unique File).Count
                if ($lintResults | Where-Object Severity -eq 'Error') {
                    $results.OverallStatus = "HasIssues"
                }
            }
        }
        
        # 2. JSON Configuration Validation
        Write-Host "`n[2/4] Validating JSON configuration files..." -ForegroundColor Yellow
        $jsonResults = Test-JsonConfig -Path "." -OutputFormat $OutputFormat -PassThru
        $results.JsonValidation = $jsonResults
        
        if ($jsonResults) {
            $results.SummaryStats.JsonIssues = $jsonResults.Count
            if ($jsonResults | Where-Object Severity -eq 'Error') {
                $results.OverallStatus = "HasIssues"
            }
        }
        
        # 3. Apply fixes if requested
        if (($ApplyFixes -or -not $SkipFixes) -and $results.OverallStatus -eq "HasIssues") {
            Write-Host "`n[3/4] Applying automatic fixes..." -ForegroundColor Yellow
            try {
                $fixResults = Invoke-AutoFix -ApplyFixes -PassThru
                $results.SyntaxFixes = $fixResults
                $results.SummaryStats.SyntaxFixesApplied = if ($fixResults) { $fixResults.Count } else { 0 }
            } catch {
                Write-Warning "Some fixes failed: $_"
            }
        } else {
            Write-Host "`n[3/4] Skipping fixes (not requested or no issues found)" -ForegroundColor Gray
        }
        
        # 4. Generate tests if requested
        if ($GenerateTests) {
            Write-Host "`n[4/4] Generating missing tests..." -ForegroundColor Yellow
            # This would call test generation logic
            Write-Host "Test generation not yet implemented" -ForegroundColor Yellow
        } else {
            Write-Host "`n[4/4] Skipping test generation (not requested)" -ForegroundColor Gray
        }
        
        # Calculate total scripts
        $allScripts = Get-ChildItem -Path "." -Recurse -Include *.ps1,*.psm1,*.psd1 -File | 
            Where-Object { $_.FullName -notlike "*archive*" -and $_.FullName -notlike "*backup*" }
        $results.SummaryStats.TotalScripts = $allScripts.Count
        
        $allJsonFiles = Get-ChildItem -Path "." -Recurse -Include *.json -File |
            Where-Object { $_.FullName -notlike "*archive*" -and $_.FullName -notlike "*backup*" }
        $results.SummaryStats.JsonFilesChecked = $allJsonFiles.Count
        
        # Output results
        if ($OutputFormat -eq 'JSON') {
            $jsonOutput = $results | ConvertTo-Json -Depth 10
            if ($OutputPath) {
                $jsonOutput | Out-File -FilePath $OutputPath -Encoding UTF8
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
            if ($ApplyFixes -or -not $SkipFixes) {
                Write-Host "Syntax Fixes Applied: $($results.SummaryStats.SyntaxFixesApplied)" -ForegroundColor White
            }
            if ($GenerateTests) {
                Write-Host "Tests Generated: $($results.SummaryStats.TestsGenerated)" -ForegroundColor White
            }
        }
        
    } catch {
        Write-Host "Validation failed: $($_.Exception.Message)" -ForegroundColor Red
        $results.OverallStatus = "Failed"
        if ($OutputFormat -eq 'CI') {
            exit 1
        }
    }
    
    if ($OutputComprehensiveReport -or $PassThru) {
        return $results
    }
    
    $ErrorActionPreference = "Stop"
    
    $startTime = Get-Date
    $rootDir = $PSScriptRoot
    while (-not (Test-Path (Join-Path $rootDir "CHANGELOG.md")) -and $rootDir -ne "/") {
        $rootDir = Split-Path $rootDir -Parent
    }
    
    if (-not (Test-Path (Join-Path $rootDir "CHANGELOG.md"))) {
        $rootDir = Get-Location
    }
    
    Write-Host "Starting comprehensive validation at $(Get-Date)" -ForegroundColor Cyan
    Write-Host "=============================================" -ForegroundColor Cyan
    
    # Ensure output directory exists
    if (-not (Test-Path $OutputPath)) {
        New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
    }
    
    $results = @{
        Lint = "SKIPPED"
        Pester = "SKIPPED"
        PyTest = "SKIPPED"
        SystemHealth = "SKIPPED"
        FixedFiles = @()
        TotalErrors = 0
        StartTime = $startTime
        EndTime = $null
        Duration = $null
    }
    
    # Fix known syntax issues before running tests if not skipping fixes
    if (-not $SkipFixes) {
        Write-Host "`nApplying pre-test syntax fixes..." -ForegroundColor Green
        try {
            # Fix ternary syntax issues
            $ternarySyntaxFixed = Invoke-TernarySyntaxFix -Path (Join-Path $rootDir "pwsh") -PassThru
            if ($ternarySyntaxFixed) {
                $results.FixedFiles += @{ Phase = "Pre-Test"; Type = "Ternary Syntax"; Files = $ternarySyntaxFixed }
            }
            
            # Fix test syntax issues
            $testSyntaxFixed = Invoke-TestSyntaxFix -Path (Join-Path $rootDir "tests") -PassThru
            if ($testSyntaxFixed) {
                $results.FixedFiles += @{ Phase = "Pre-Test"; Type = "Test Syntax"; Files = $testSyntaxFixed }
            }
        } catch {
            Write-Warning "Pre-test syntax fixes encountered errors: $_"
        }
    }
    
    # Run PowerShell linting
    if (-not $SkipLint) {
        Write-Host "`nRunning PowerShell linting..." -ForegroundColor Green
        try {
            $lintResultsPath = Join-Path $OutputPath "LintResults.xml"
            $lintScript = Join-Path $rootDir "comprehensive-lint.ps1"
            
            if (Test-Path $lintScript) {
                $lintProcess = Start-Process -FilePath "pwsh" -ArgumentList "-File", $lintScript, "-OutputFormat", "XML", "-OutputPath", $lintResultsPath -NoNewWindow -PassThru -Wait
                
                if ($lintProcess.ExitCode -eq 0) {
                    Write-Host "✅ Linting completed successfully" -ForegroundColor Green
                    $results.Lint = "PASSED"
                } else {
                    Write-Host "⚠️ Linting completed with warnings (code: $($lintProcess.ExitCode))" -ForegroundColor Yellow
                    $results.Lint = "WARNING"
                    
                    if (-not $SkipFixes) {
                        Write-Host "  Applying automatic lint fixes..." -ForegroundColor Yellow
                        # Future: Implement lint auto-fixes
                    }
                }
            } else {
                Write-Warning "Lint script not found: $lintScript"
                $results.Lint = "MISSING"
                $results.TotalErrors++
            }
        } catch {
            Write-Host "❌ Linting failed: $_" -ForegroundColor Red
            $results.Lint = "ERROR"
            $results.TotalErrors++
        }
    }
    
    # Run Pester tests
    if (-not $SkipPester) {
        Write-Host "`nRunning Pester tests..." -ForegroundColor Green
        try {
            $pesterResultsPath = Join-Path $OutputPath "TestResults.xml"
            
            # Configure Pester
            $pesterConfig = New-PesterConfiguration
            $pesterConfig.Run.Path = Join-Path $rootDir "tests"
            $pesterConfig.Run.PassThru = $true
            $pesterConfig.TestResult.Enabled = $true
            $pesterConfig.TestResult.OutputFormat = "NUnitXml"
            $pesterConfig.TestResult.OutputPath = $pesterResultsPath
            $pesterConfig.Output.Verbosity = if ($DetailedResults) { "Detailed" } else { "Normal" }
            
            # Run tests
            $pesterResult = Invoke-Pester -Configuration $pesterConfig
            
            # Process results
            if ($pesterResult.FailedCount -eq 0) {
                Write-Host "✅ All Pester tests passed! ($($pesterResult.PassedCount) passed, $($pesterResult.SkippedCount) skipped)" -ForegroundColor Green
                $results.Pester = "PASSED"
            } else {
                Write-Host "❌ Some Pester tests failed: $($pesterResult.FailedCount) failed, $($pesterResult.PassedCount) passed, $($pesterResult.SkippedCount) skipped" -ForegroundColor Red
                $results.Pester = "FAILED"
                $results.TotalErrors++
                
                if (-not $SkipFixes) {
                    Write-Host "  Applying automatic fixes for test failures..." -ForegroundColor Yellow
                    $fixedPesterFiles = Invoke-ResultsAnalysis -TestResultsPath $pesterResultsPath -ApplyFixes -PassThru
                    
                    if ($fixedPesterFiles) {
                        $results.FixedFiles += @{ Phase = "Post-Test"; Type = "Pester Fixes"; Files = $fixedPesterFiles }
                        
                        # Re-run Pester tests to see if fixes resolved the issues
                        Write-Host "`nRe-running Pester tests after fixes..." -ForegroundColor Green
                        $pesterResult = Invoke-Pester -Configuration $pesterConfig
                        
                        if ($pesterResult.FailedCount -eq 0) {
                            Write-Host "✅ All Pester tests now passing after fixes! ($($pesterResult.PassedCount) passed, $($pesterResult.SkippedCount) skipped)" -ForegroundColor Green
                            $results.Pester = "FIXED"
                        } else {
                            Write-Host "⚠️ Some Pester tests still failing after fixes: $($pesterResult.FailedCount) failed" -ForegroundColor Yellow
                        }
                    }
                }
            }
        } catch {
            Write-Host "❌ Pester execution failed: $_" -ForegroundColor Red
            $results.Pester = "ERROR"
            $results.TotalErrors++
        }
    }
    
    # Run Python tests
    if (-not $SkipPyTest) {
        Write-Host "`nRunning Python tests..." -ForegroundColor Green
        try {
            $pythonTestResultsPath = Join-Path $OutputPath "PyTestResults.xml"
            
            if (Test-Path (Join-Path $rootDir "py")) {
                $pytestProcess = Start-Process -FilePath "python" -ArgumentList "-m", "pytest", "py", "--junitxml=$pythonTestResultsPath" -NoNewWindow -PassThru -Wait
                
                if ($pytestProcess.ExitCode -eq 0) {
                    Write-Host "✅ Python tests completed successfully" -ForegroundColor Green
                    $results.PyTest = "PASSED"
                } else {
                    Write-Host "❌ Python tests failed (code: $($pytestProcess.ExitCode))" -ForegroundColor Red
                    $results.PyTest = "FAILED"
                    $results.TotalErrors++
                }
            } else {
                Write-Warning "Python directory not found, skipping pytest"
                $results.PyTest = "SKIPPED"
            }
        } catch {
            Write-Host "❌ Python test execution failed: $_" -ForegroundColor Red
            $results.PyTest = "ERROR"
            $results.TotalErrors++
        }
    }
    
    # Run system health check
    try {
        Write-Host "`nRunning system health check..." -ForegroundColor Green
        $healthCheckScript = Join-Path $rootDir "comprehensive-health-check.ps1"
        
        if (Test-Path $healthCheckScript) {
            $healthResultsPath = Join-Path $OutputPath "HealthResults.json"
            $healthProcess = Start-Process -FilePath "pwsh" -ArgumentList "-File", $healthCheckScript, "-OutputFormat", "JSON" -NoNewWindow -PassThru -Wait
            
            if ($healthProcess.ExitCode -eq 0) {
                Write-Host "✅ System health check completed successfully" -ForegroundColor Green
                $results.SystemHealth = "HEALTHY"
            } else {
                Write-Host "⚠️ System health check detected issues (code: $($healthProcess.ExitCode))" -ForegroundColor Yellow
                $results.SystemHealth = "WARNING"
            }
        } else {
            Write-Warning "Health check script not found: $healthCheckScript"
            $results.SystemHealth = "MISSING"
        }
    } catch {
        Write-Host "❌ Health check failed: $_" -ForegroundColor Red
        $results.SystemHealth = "ERROR"
    }
    
    # Calculate duration
    $results.EndTime = Get-Date
    $results.Duration = $results.EndTime - $results.StartTime
    
    # Summary
    Write-Host "`n============== VALIDATION SUMMARY ==============" -ForegroundColor Cyan
    Write-Host "Lint:          $($results.Lint)" -ForegroundColor $(if ($results.Lint -eq "PASSED") { "Green" } elseif ($results.Lint -eq "WARNING") { "Yellow" } elseif ($results.Lint -eq "ERROR" -or $results.Lint -eq "FAILED") { "Red" } else { "White" })
    Write-Host "Pester Tests:  $($results.Pester)" -ForegroundColor $(if ($results.Pester -eq "PASSED" -or $results.Pester -eq "FIXED") { "Green" } elseif ($results.Pester -eq "WARNING") { "Yellow" } elseif ($results.Pester -eq "ERROR" -or $results.Pester -eq "FAILED") { "Red" } else { "White" })
    Write-Host "Python Tests:  $($results.PyTest)" -ForegroundColor $(if ($results.PyTest -eq "PASSED") { "Green" } elseif ($results.PyTest -eq "WARNING") { "Yellow" } elseif ($results.PyTest -eq "ERROR" -or $results.PyTest -eq "FAILED") { "Red" } else { "White" })
    Write-Host "System Health: $($results.SystemHealth)" -ForegroundColor $(if ($results.SystemHealth -eq "HEALTHY") { "Green" } elseif ($results.SystemHealth -eq "WARNING") { "Yellow" } elseif ($results.SystemHealth -eq "ERROR") { "Red" } else { "White" })
    
    if ($results.FixedFiles.Count -gt 0) {
        Write-Host "`nFiles automatically fixed:" -ForegroundColor Cyan
        foreach ($fixGroup in $results.FixedFiles) {
            Write-Host "  $($fixGroup.Phase) - $($fixGroup.Type): $($fixGroup.Files.Count) files" -ForegroundColor Green
        }
    }
    
    Write-Host "`nTotal Errors:  $($results.TotalErrors)" -ForegroundColor $$(if (results.TotalErrors -eq 0) { "Green" } else { "Red" })
    Write-Host "Duration:      $($results.Duration.ToString('hh\:mm\:ss'))" -ForegroundColor Cyan
    Write-Host "===============================================" -ForegroundColor Cyan
    
    # Save results
    $resultsJson = ConvertTo-Json $results -Depth 5
    $resultsJson | Out-File (Join-Path $OutputPath "ValidationSummary.json") -Encoding utf8
    
    if ($PassThru) {
        return $results
    }
}


