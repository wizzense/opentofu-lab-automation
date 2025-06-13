# ValidationHelpers.ps1
# Validation functionality for the TestAutoFixer module

# Auto-added import for PSScriptAnalyzer
if (-not (Get-Module -ListAvailable PSScriptAnalyzer -ErrorAction SilentlyContinue)) { Install-Module PSScriptAnalyzer -Force -Scope CurrentUser }
Import-Module PSScriptAnalyzer -Force

function Get-TestFailures {
    <#
    .SYNOPSIS
    Extracts test failures from a Pester test results file
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)


]
        [string]$ResultsPath
    )
    
    if (-not (Test-Path $ResultsPath)) {
        Write-Error "Test results file not found: $ResultsPath"
        return @()
    }
    
    try {
        # Load the XML file
        $testResults = [xml](Get-Content $ResultsPath)
        
        # Extract all failed test cases
        $failedTests = @()
        $testSuites = $testResults.SelectNodes("//test-case[@success='False' and @result='Failure']")
        
        foreach ($test in $testSuites) {
            $sourceFile = $test.SelectSingleNode("ancestor::test-suite[@type='TestFixture']/@name").Value
            $description = $test.description
            
            # Find the failure information
            $message = $test.failure.message
            $stackTrace = $test.failure.'stack-trace'
            
            # Determine source script from the test file
            $sourceScript = $null
            if ($sourceFile -match "\.Tests\.ps1$") {
                try {
                    $testFileContent = Get-Content $sourceFile -Raw -ErrorAction SilentlyContinue
                    if ($testFileContent -match "Get-RunnerScriptPath\s+['\""]([^'\""]+)['\""]\s*\)") {
                        $sourceScript = $matches[1]
                        $sourceScript = Get-RunnerScriptPath $sourceScript -ErrorAction SilentlyContinue
                    }
                } catch {
                    # Ignore errors in extracting source script
                }
            }
            
            $failedTests += [PSCustomObject]@{
                SourceFile = $sourceFile
                Description = $description
                Message = $message
                StackTrace = $stackTrace
                SourceScript = $sourceScript
                ErrorLine = if ($stackTrace -match ":(\d+)") { $matches[1] } else { $null }
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
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)


]
        [string]$ResultsPath
    )
    
    # Auto-added import for PSScriptAnalyzer
    if (-not (Get-Module -ListAvailable PSScriptAnalyzer -ErrorAction SilentlyContinue)) { 
        Install-Module PSScriptAnalyzer -Force -Scope CurrentUser 
    }
    Import-Module PSScriptAnalyzer -Force
    
    if (-not (Test-Path $ResultsPath)) {
        Write-Error "Lint results file not found: $ResultsPath"
        return @()
    }
    
    try {
        # Load the JSON file if available
        if ($ResultsPath -match "\.json$") {
            $lintResults = Get-Content $ResultsPath -Raw | ConvertFrom-Json
        }
        # Or the XML file if that's what's available
        elseif ($ResultsPath -match "\.xml$") {
            $lintResults = [xml](Get-Content $ResultsPath)
            # Convert XML structure to objects
            $issues = @()
            foreach ($issue in $lintResults.SelectNodes("//Issue")) {
                $issues += [PSCustomObject]@{
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
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)


]
        [string]$Path,
        
        [Parameter()]
        [switch]$IncludeLint,
        
        [Parameter()]
        [switch]$IncludeTests,
        
        [Parameter()]
        [string]$OutputPath
    )
    
    # Auto-added import for PSScriptAnalyzer
    if (-not (Get-Module -ListAvailable PSScriptAnalyzer -ErrorAction SilentlyContinue)) { 
        Install-Module PSScriptAnalyzer -Force -Scope CurrentUser 
    }
    Import-Module PSScriptAnalyzer -Force
    )
    
    $results = @{
        Syntax = @{
            Total = 0
            Invalid = @()
            Valid = 0
        }
        Lint = @{
            Total = 0
            Issues = @()
        }
        Tests = @{
            Total = 0
            Failures = @()
            Passed = 0
        }
    }
    
    # Check syntax
    $files = Get-ChildItem -Path $Path -Filter "*.ps1" -Recurse
    $results.Syntax.Total = $files.Count
    
    foreach ($file in $files) {
        try {
            $errors = $null
            $null = [System.Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$null, [ref]$errors)
            
            if ($errors -and $errors.Count -gt 0) {
                $results.Syntax.Invalid += [PSCustomObject]@{
                    File = $file.FullName
                    Errors = $errors | ForEach-Object {
                        [PSCustomObject]@{
                            Line = $_.Extent.StartLineNumber
                            Message = $_.Message
                        }
                    }
                }
            } else {
                $results.Syntax.Valid++
            }
        } catch {
            $results.Syntax.Invalid += [PSCustomObject]@{
                File = $file.FullName
                Errors = @([PSCustomObject]@{
                    Line = 0
                    Message = "Failed to parse: $_"
                })
            }
        }
    }
    
    # Run PSScriptAnalyzer if requested
    if ($IncludeLint) {
        if (Get-Module -ListAvailable -Name PSScriptAnalyzer) {
            $lintResults = Invoke-ScriptAnalyzer -Path $Path -Recurse
            $results.Lint.Total = $lintResults.Count
            $results.Lint.Issues = $lintResults
        } else {
            Write-Warning "PSScriptAnalyzer not available, lint checks skipped"
        }
    }
    
    # Run Pester tests if requested
    if ($IncludeTests) {
        if (Get-Module -ListAvailable -Name Pester) {
            $pesterConfig = New-PesterConfiguration
            $pesterConfig.Run.Path = Join-Path $Path "tests"
            $pesterConfig.Run.PassThru = $true
            $pesterConfig.Output.Verbosity = 'Detailed'
            
            $pesterResults = Invoke-Pester -Configuration $pesterConfig
            
            $results.Tests.Total = $pesterResults.TotalCount
            $results.Tests.Passed = $pesterResults.PassedCount
            $results.Tests.Failures = $pesterResults.Failed | ForEach-Object {
                [PSCustomObject]@{
                    Name = $_.Name
                    Message = $_.ErrorRecord.Exception.Message
                    File = $_.ExpandedPath
                }
            }
        } else {
            Write-Warning "Pester not available, tests skipped"
        }
    }
    
    # Output results if requested
    if ($OutputPath) {
        $results | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding utf8
    }
    
    return $results
}

function Show-ValidationSummary {
    <#
    .SYNOPSIS
    Displays a formatted summary of validation results
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)






# Auto-added import for PSScriptAnalyzer
if (-not (Get-Module -ListAvailable PSScriptAnalyzer -ErrorAction SilentlyContinue)) { Install-Module PSScriptAnalyzer -Force -Scope CurrentUser }
Import-Module PSScriptAnalyzer -Force

]
        [object]$Results
    )
    
    Write-Host "`n📊 VALIDATION SUMMARY" -ForegroundColor Cyan
    Write-Host "=======================================`n" -ForegroundColor Cyan
    
    # Syntax check summary
    Write-Host "Syntax Checks:" -ForegroundColor Yellow
    $validSyntax = $Results.Syntax.Valid
    $invalidSyntax = $Results.Syntax.Invalid.Count
    $totalSyntax = $Results.Syntax.Total
    $syntaxPercent = [Math]::Round(($validSyntax / $totalSyntax) * 100)
    
    Write-Host "  Valid:   $validSyntax / $totalSyntax ($syntaxPercent%)" -ForegroundColor $$(if (invalidSyntax -eq 0) { "Green" } else { "Yellow" })
    Write-Host "  Invalid: $invalidSyntax / $totalSyntax" -ForegroundColor $$(if (invalidSyntax -gt 0) { "Red" } else { "Green" })
    
    if ($invalidSyntax -gt 0) {
        Write-Host "`nInvalid Syntax Files:" -ForegroundColor Yellow
        foreach ($file in $Results.Syntax.Invalid) {
            Write-Host "  $($file.File)" -ForegroundColor Red
            foreach ($error in $file.Errors | Select-Object -First 3) {
                Write-Host "    Line $($error.Line): $($error.Message)" -ForegroundColor DarkRed
            }
            if ($file.Errors.Count -gt 3) {
                Write-Host "    ... and $($file.Errors.Count - 3) more errors" -ForegroundColor DarkRed
            }
        }
    }
    
    # Lint issues summary
    if ($Results.Lint.Total -gt 0) {
        Write-Host "`nLint Issues:" -ForegroundColor Yellow
        $errorCount = ($Results.Lint.Issues | Where-Object { $_.Severity -eq 'Error' }).Count
        $warningCount = ($Results.Lint.Issues | Where-Object { $_.Severity -eq 'Warning' }).Count
        $infoCount = ($Results.Lint.Issues | Where-Object { $_.Severity -eq 'Information' }).Count
        
        Write-Host "  Errors:   $errorCount" -ForegroundColor $$(if (errorCount -gt 0) { "Red" } else { "Green" })
        Write-Host "  Warnings: $warningCount" -ForegroundColor $$(if (warningCount -gt 0) { "Yellow" } else { "Green" })
        Write-Host "  Info:     $infoCount" -ForegroundColor "Cyan"
        
        if ($errorCount -gt 0) {
            Write-Host "`nTop Error Issues:" -ForegroundColor Yellow
            foreach ($issue in ($Results.Lint.Issues | Where-Object { $_.Severity -eq 'Error' } | Select-Object -First 5)) {
                Write-Host "  $($issue.ScriptName):$($issue.Line) - $($issue.RuleName)" -ForegroundColor Red
                Write-Host "    $($issue.Message)" -ForegroundColor DarkRed
            }
            
            if ($errorCount -gt 5) {
                Write-Host "  ... and $($errorCount - 5) more errors" -ForegroundColor DarkRed
            }
        }
    }
    
    # Test results summary
    if ($Results.Tests.Total -gt 0) {
        Write-Host "`nTest Results:" -ForegroundColor Yellow
        $passedTests = $Results.Tests.Passed
        $failedTests = $Results.Tests.Failures.Count
        $totalTests = $Results.Tests.Total
        $testsPercent = [Math]::Round(($passedTests / $totalTests) * 100)
        
        Write-Host "  Passed: $passedTests / $totalTests ($testsPercent%)" -ForegroundColor $$(if (failedTests -eq 0) { "Green" } else { "Yellow" })
        Write-Host "  Failed: $failedTests / $totalTests" -ForegroundColor $$(if (failedTests -gt 0) { "Red" } else { "Green" })
        
        if ($failedTests -gt 0) {
            Write-Host "`nFailed Tests:" -ForegroundColor Yellow
            foreach ($failure in ($Results.Tests.Failures | Select-Object -First 5)) {
                Write-Host "  $($failure.Name)" -ForegroundColor Red
                Write-Host "    $($failure.Message)" -ForegroundColor DarkRed
            }
            
            if ($failedTests -gt 5) {
                Write-Host "  ... and $($failedTests - 5) more failures" -ForegroundColor DarkRed
            }
        }
    }
    
    # Overall assessment
    Write-Host "`nOverall Assessment:" -ForegroundColor Cyan
    if ($invalidSyntax -eq 0 -and ($Results.Lint.Total -eq 0 -or ($Results.Lint.Issues | Where-Object { $_.Severity -eq 'Error' }).Count -eq 0) -and $Results.Tests.Failures.Count -eq 0) {
        Write-Host "  ✅ PASSED - All validation checks successful" -ForegroundColor Green
    } else {
        $hasErrors = $invalidSyntax -gt 0 -or ($Results.Lint.Issues | Where-Object { $_.Severity -eq 'Error' }).Count -gt 0
        if ($hasErrors) {
            Write-Host "  ❌ FAILED - Critical issues found that need to be fixed" -ForegroundColor Red
        } else {
            Write-Host "  ⚠️ WARNINGS - Non-critical issues found that should be addressed" -ForegroundColor Yellow
        }
        
        # Suggest fixes
        Write-Host "`nSuggested Actions:" -ForegroundColor Cyan
        
        if ($invalidSyntax -gt 0) {
            Write-Host "  • Run syntax fixes: Invoke-SyntaxFix -Path '$Path' -FixTypes All" -ForegroundColor Yellow
        }
        
        if (($Results.Lint.Issues | Where-Object { $_.Severity -eq 'Error' }).Count -gt 0) {
            Write-Host "  • Run comprehensive lint: ./comprehensive-lint.ps1" -ForegroundColor Yellow
        }
        
        if ($Results.Tests.Failures.Count -gt 0) {
            Write-Host "  • Fix failed tests and run: ./run-comprehensive-tests.ps1" -ForegroundColor Yellow
        }
    }
    
    Write-Host "`n=======================================`n" -ForegroundColor Cyan
}

# Private helper function
function Get-RunnerScriptPath {
    <#
    .SYNOPSIS
    Gets the path to a runner script
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)






# Auto-added import for PSScriptAnalyzer
if (-not (Get-Module -ListAvailable PSScriptAnalyzer -ErrorAction SilentlyContinue)) { Install-Module PSScriptAnalyzer -Force -Scope CurrentUser }
Import-Module PSScriptAnalyzer -Force

]
        [string]$ScriptName,
        
        [Parameter()]
        [string]$BasePath
    )
    
    if (-not $BasePath) {
        $BasePath = $PSScriptRoot
    }
    
    # Look for the script in the standard locations
    $possiblePaths = @(
        # Direct path if provided
        $ScriptName,
        # Runner scripts directory
        (Join-Path $BasePath ".." ".." "pwsh" "runner_scripts" $ScriptName),
        (Join-Path $BasePath ".." ".." ".." "pwsh" "runner_scripts" $ScriptName)
    )
    
    foreach ($path in $possiblePaths) {
        if (Test-Path $path) {
            return (Get-Item $path).FullName
        }
    }
    
    # If not found and no base number, try to find by name
    if (-not ($ScriptName -match "^[0-9]{4}_")) {
        $pattern = "*_$ScriptName"
        $foundScripts = Get-ChildItem (Join-Path $BasePath ".." ".." "pwsh" "runner_scripts" $pattern) -ErrorAction SilentlyContinue
        
        if ($foundScripts -and $foundScripts.Count -gt 0) {
            return $foundScripts[0].FullName
        }
    }
    
    return $null
}



