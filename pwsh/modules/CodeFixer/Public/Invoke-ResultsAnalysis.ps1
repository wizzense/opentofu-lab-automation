<#
.SYNOPSIS
Automatically analyzes test results and applies fixes

.DESCRIPTION
This function parses test results (Pester XML output) to identify common syntax errors
and automatically applies fixes to the failing files.

.PARAMETER TestResultsPath
Path to the Pester test results XML file

.PARAMETER ApplyFixes
Automatically apply fixes to failing tests (default is to just report issues)

.PARAMETER MaxFixAttempts
Maximum number of fix attempts for each file (default: 3)

.PARAMETER PassThru
Return the list of files that were fixed

.EXAMPLE
Invoke-ResultsAnalysis -TestResultsPath "TestResults.xml"

.EXAMPLE
Invoke-ResultsAnalysis -TestResultsPath "TestResults.xml" -ApplyFixes
#>
function Invoke-ResultsAnalysis {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$true, Position=0)






]
        [string]$TestResultsPath,
        
        [switch]$ApplyFixes,
        
        [int]$MaxFixAttempts = 3,
        
        [switch]$PassThru
    )
    
    $ErrorActionPreference = "Stop"
    
    Write-Verbose "Analyzing test results from $TestResultsPath"
    
    # Check if test results file exists
    if (-not (Test-Path $TestResultsPath)) {
        Write-Error "Test results file not found: $TestResultsPath"
        return
    }
    
    # Load test results
    try {
        [xml]$testResults = Get-Content $TestResultsPath
    } catch {
        Write-Error "Failed to load test results XML: $_"
        return
    }
    
    # Find failed tests
    $failedTests = $testResults.SelectNodes("//test-case[@result='Failure']")
    
    Write-Verbose "Found $($failedTests.Count) failed tests"
    
    if ($failedTests.Count -eq 0) {
        Write-Verbose "No failed tests found, nothing to fix"
        return
    }
    
    # Group failures by file
    $failuresByFile = @{}
    
    foreach ($test in $failedTests) {
        $failureDetails = $test.failure.message
        $stackTrace = $test.failure.'stack-trace'
        $matches = $null
        
        if ($stackTrace -match 'at\s+<ScriptBlock>,\s+(.+) line (\d+)') {
            $filePath = $matches[1]
            $lineNumber = [int]$matches[2]
            
            if (-not $failuresByFile.ContainsKey($filePath)) {
                $failuresByFile[$filePath] = @()
            }
            
            $failuresByFile[$filePath] += @{
                TestName = $test.name
                Message = $failureDetails
                LineNumber = $lineNumber
            }
        }
    }
    
    # Process failures and apply fixes
    $fixedFiles = @()
    
    foreach ($filePath in $failuresByFile.Keys) {
        Write-Verbose "Processing failures in $filePath"
        $failures = $failuresByFile[$filePath]
        
        # Group failures by type
        $ternarySyntaxIssue = $failures | Where-Object { $_.Message -match 'The term ''if'' is not recognized' }
        $skipSyntaxIssue = $failures | Where-Object { $_.Message -match 'Missing closing ''\)''' }
        $quoteSyntaxIssue = $failures | Where-Object { $_.Message -match 'Missing closing ''''' -or $_.Message -match 'Missing closing ''"''' }
        $indentationIssue = $failures | Where-Object { $_.Message -match 'Unexpected token' }
        
        if ($ternarySyntaxIssue -or $skipSyntaxIssue -or $quoteSyntaxIssue -or $indentationIssue) {
            if ($ApplyFixes) {
                $fixAttempt = 0
                $fixed = $false
                
                while (-not $fixed -and $fixAttempt -lt $MaxFixAttempts) {
                    $fixAttempt++
                    Write-Verbose "  Fix attempt $fixAttempt for $filePath"
                    
                    if ($PSCmdlet.ShouldProcess($filePath, "Apply syntax fixes")) {
                        # Apply test syntax fixes
                        Invoke-TestSyntaxFix -Path $filePath
                        
                        # Verify fix worked by checking syntax
                        try {
                            $errors = $null
                            [System.Management.Automation.Language.Parser]::ParseFile($filePath, [ref]$null, [ref]$errors)
                            if (-not $errors) {
                                Write-Verbose "  ✅ Fixed on attempt $fixAttempt - $filePath"
                                $fixed = $true
                                $fixedFiles += $filePath
                            }
                        } catch {
                            Write-Verbose "  ❌ Fix attempt $fixAttempt failed - $_"
                        }
                    } else {
                        break
                    }
                }
                
                if (-not $fixed) {
                    Write-Warning "Failed to fix $filePath after $MaxFixAttempts attempts"
                }
            } else {
                Write-Host "File needs fixes: $filePath" -ForegroundColor Yellow
                
                if ($ternarySyntaxIssue) {
                    Write-Host "  - Contains ternary syntax issues" -ForegroundColor Yellow
                }
                if ($skipSyntaxIssue) {
                    Write-Host "  - Contains -Skip parameter syntax issues" -ForegroundColor Yellow
                }
                if ($quoteSyntaxIssue) {
                    Write-Host "  - Contains quote syntax issues" -ForegroundColor Yellow
                }
                if ($indentationIssue) {
                    Write-Host "  - Contains indentation issues" -ForegroundColor Yellow
                }
                
                Write-Host "  Run with -ApplyFixes to automatically fix these issues" -ForegroundColor Yellow
            }
        } else {
            Write-Verbose "  No automatically fixable issues found in $filePath"
            Write-Host "File has failures that cannot be automatically fixed: $filePath" -ForegroundColor Red
            foreach ($failure in $failures) {
                Write-Host "  - Line $($failure.LineNumber) - $($failure.Message)" -ForegroundColor Red
            }
        }
    }
    
    Write-Verbose "Analysis complete. Fixed $($fixedFiles.Count) files."
    
    if ($PassThru) {
        return $fixedFiles
    }
}



