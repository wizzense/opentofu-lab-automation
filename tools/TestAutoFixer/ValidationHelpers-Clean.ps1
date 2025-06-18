# ValidationHelpers.ps1
# PowerShell module for validation checks and test failure analysis

# Auto-added import for PSScriptAnalyzer
if (-not (Get-Module -ListAvailable PSScriptAnalyzer -ErrorAction SilentlyContinue)) { 
    Install-Module PSScriptAnalyzer -Force -Scope CurrentUser 
}
Import-Module PSScriptAnalyzer -Force

function Get-TestFailures {
    <#
    .SYNOPSIS
    Extracts test failures from a Pester test results file
    #>
    CmdletBinding()
    param(
        Parameter(Mandatory=$true)
        string$ResultsPath
    )
    
    if (-not (Test-Path $ResultsPath)) {
        Write-Error "Test results file not found: $ResultsPath"
        return @()
    }
    
    try {
        # Load the XML file
        $testResults = xml(Get-Content $ResultsPath)
        $failedTests = @()
        
        # Find all failed test cases
        $testSuites = $testResults.SelectNodes("//test-case@result='Failed' or @result='Error'")
        
        foreach ($test in $testSuites) {
            $sourceFile = $test.SelectSingleNode("ancestor::test-suite@type='TestFixture'/@name").Value
            $sourceScript = $null
            
            # Try to extract the source script from test content
            if ($sourceFile -match "\.Tests\.ps1$") {
                try {
                    $testFileContent = Get-Content $sourceFile -Raw -ErrorAction SilentlyContinue
                    if ($testFileContent -match "Get-RunnerScriptPath\s+'\""(^'\""+)'\""\s*\)") {
                        $sourceScript = $matches1
                        $sourceScript = Get-RunnerScriptPath $sourceScript -ErrorAction SilentlyContinue
                    }
                } catch {
                    # Ignore errors in extracting source script
                }
            }
            
            $stackTrace = $test.failure.message
            $failedTests += PSCustomObject@{
                SourceFile = $sourceFile
                SourceScript = $sourceScript
                TestName = $test.name
                FailureMessage = $test.failure.message
                ErrorLine = if ($stackTrace -match ":(\d+)") { $matches1 } else { $null }
            }
        }
        
        return $failedTests
    }
    catch {
        Write-Error "Failed to parse test results: $_"
        return @()
    }
}

function Get-LintIssues {
    <#
    .SYNOPSIS
    Extracts lint issues from a PSScriptAnalyzer results file
    #>
    CmdletBinding()
    param(
        Parameter(Mandatory=$true)
        string$ResultsPath
    )
    
    if (-not (Test-Path $ResultsPath)) {
        Write-Error "Lint results file not found: $ResultsPath"
        return @()
    }
    
    try {
        # Load the JSON file if available
        if ($ResultsPath -match "\.json$") {
            $lintResults = Get-Content $ResultsPath -Raw | ConvertFrom-Json}
        # Or the XML file if that's what's available
        elseif ($ResultsPath -match "\.xml$") {
            $lintResults = xml(Get-Content $ResultsPath)
            # Convert XML structure to objects
            $issues = @()
            foreach ($issue in $lintResults.SelectNodes("//Issue")) {
                $issues += PSCustomObject@{
                    ScriptName = $issue.ScriptName
                    Line = $issue.Line
                    Column = $issue.Column
                    Message = $issue.Message
                    Severity = $issue.Severity
                    RuleName = $issue.RuleName
                }
            }
            return $issues
        }
        # Or try running PSScriptAnalyzer directly
        else {
            if (Get-Module -ListAvailable -Name PSScriptAnalyzer) {
                $lintResults = Invoke-ScriptAnalyzer -Path $ResultsPath
                return $lintResults
            } else {
                Write-Error "PSScriptAnalyzer module not available"
                return @()
            }
        }
        
        return $lintResults
    }
    catch {
        Write-Error "Failed to parse lint results: $_"
        return @()
    }
}

function Invoke-ValidationChecks {
    <#
    .SYNOPSIS
    Runs comprehensive validation checks on PowerShell scripts
    #>
    CmdletBinding()
    param(
        Parameter(Mandatory=$true)
        string$Path,
        
        Parameter()
        switchIncludeLint,
        
        Parameter()
        switchIncludeTests,
        
        Parameter()
        string$OutputPath
    )
    
    $validationResults = @{
        SyntaxErrors = @()
        LintIssues = @()
        TestFailures = @()
        Summary = @{}
    }
    
    # Check for syntax errors
    Write-Verbose "Checking syntax for: $Path"
    try {
        $null = System.Management.Automation.PSParser::Tokenize((Get-Content $Path -Raw), ref@())
        Write-Verbose "Syntax check passed"
    }
    catch {
        $validationResults.SyntaxErrors += $_.Exception.Message
        Write-Verbose "Syntax error found: $($_.Exception.Message)"
    }
    
    # Run lint checks if requested
    if ($IncludeLint) {
        Write-Verbose "Running PSScriptAnalyzer"
        try {
            $lintResults = Invoke-ScriptAnalyzer -Path $Path
            $validationResults.LintIssues = $lintResults
        }
        catch {
            Write-Warning "Could not run PSScriptAnalyzer: $_"
        }
    }
    
    # Check for test failures if requested
    if ($IncludeTests -and $Path -match "\.Tests\.ps1$") {
        Write-Verbose "Checking for test failures"
        # This would need test results file to be meaningful
    }
    
    # Generate summary
    $validationResults.Summary = @{
        SyntaxErrorCount = $validationResults.SyntaxErrors.Count
        LintIssueCount = $validationResults.LintIssues.Count
        TestFailureCount = $validationResults.TestFailures.Count
        HasIssues = ($validationResults.SyntaxErrors.Count -gt 0) -or 
                   ($validationResults.LintIssues.Count -gt 0) -or 
                   ($validationResults.TestFailures.Count -gt 0)
    }
    
    # Output to file if requested
    if ($OutputPath) {
        validationResults | ConvertTo-Json-Depth 5  Set-Content $OutputPath
    }
    
    return $validationResults
}

function Show-ValidationSummary {
    <#
    .SYNOPSIS
    Displays a formatted summary of validation results
    #>
    CmdletBinding()
    param(
        Parameter(Mandatory=$true)
        object$ValidationResults
    )
    
    Write-Host "`n=== Validation Summary ===" -ForegroundColor Yellow
    Write-Host "Syntax Errors: $($ValidationResults.Summary.SyntaxErrorCount)" -ForegroundColor $(if ($ValidationResults.Summary.SyntaxErrorCount -gt 0) { 'Red' } else { 'Green' })
    Write-Host "Lint Issues: $($ValidationResults.Summary.LintIssueCount)" -ForegroundColor $(if ($ValidationResults.Summary.LintIssueCount -gt 0) { 'Yellow' } else { 'Green' })
    Write-Host "Test Failures: $($ValidationResults.Summary.TestFailureCount)" -ForegroundColor $(if ($ValidationResults.Summary.TestFailureCount -gt 0) { 'Red' } else { 'Green' })
    
    if ($ValidationResults.Summary.HasIssues) {
        Write-Host "`nOverall Status: ISSUES FOUND" -ForegroundColor Red
    } else {
        Write-Host "`nOverall Status: ALL CHECKS PASSED" -ForegroundColor Green
    }
    
    # Show details for syntax errors
    if ($ValidationResults.SyntaxErrors.Count -gt 0) {
        Write-Host "`n--- Syntax Errors ---" -ForegroundColor Red
        foreach ($error in $ValidationResults.SyntaxErrors) {
            Write-Host "  $error" -ForegroundColor Red
        }
    }
    
    # Show details for high-priority lint issues
    if ($ValidationResults.LintIssues.Count -gt 0) {
        $criticalIssues = $ValidationResults.LintIssues | Where-Object{ $_.Severity -eq 'Error' }
        if ($criticalIssues.Count -gt 0) {
            Write-Host "`n--- Critical Lint Issues ---" -ForegroundColor Red
            foreach ($issue in $criticalIssues) {
                Write-Host "  Line $($issue.Line): $($issue.Message)" -ForegroundColor Red
            }
        }
    }
}

function Get-RunnerScriptPath {
    <#
    .SYNOPSIS
    Resolves the path to a runner script
    #>
    CmdletBinding()
    param(
        Parameter(Mandatory=$true)
        string$ScriptName
    )
    
    # This is a placeholder function that would resolve script paths
    # In the actual implementation, this would map script names to their locations
    $possiblePaths = @(
        "/workspaces/opentofu-lab-automation/pwsh/$ScriptName",
        "/workspaces/opentofu-lab-automation/scripts/$ScriptName",
        "/workspaces/opentofu-lab-automation/$ScriptName"
    )
    
    foreach ($path in $possiblePaths) {
        if (Test-Path $path) {
            return $path
        }
    }
    
    return $ScriptName
}





