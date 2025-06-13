# ResultAnalyzer.ps1
# Test result analysis functionality for the TestAutoFixer module

function Get-TestStatistics {
    <#
    .SYNOPSIS
    Analyzes test result statistics from Pester output

    .DESCRIPTION
    Processes Pester XML or NUnit result files to extract key statistics including
    pass/fail rates, execution times, and failure patterns.

    .PARAMETER ResultsPath
    Path to the test results file (XML format)

    .EXAMPLE
    Get-TestStatistics -ResultsPath "TestResults.xml" 
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)






]
        [string]$ResultsPath
    )

    if (-not (Test-Path $ResultsPath)) {
        Write-Error "Test results file not found: $ResultsPath"
        return $null
    }

    try {
        # Load the XML file
        $testResults = [xml](Get-Content $ResultsPath)
        
        # Extract key metrics
        $totalTests = $testResults.SelectNodes("//test-case").Count
        $passedTests = $testResults.SelectNodes("//test-case[@result='Success']").Count
        $failedTests = $testResults.SelectNodes("//test-case[@result='Failure']").Count
        $skippedTests = $testResults.SelectNodes("//test-case[@result='Skipped']").Count
        $inconclusiveTests = $totalTests - $passedTests - $failedTests - $skippedTests
        
        # Calculate pass rate
        $passRate = if ($totalTests -gt 0) { [math]::Round(($passedTests / $totalTests) * 100, 2)    } else { 0    }
        
        # Get execution time information
        $testSuites = $testResults.SelectNodes("//test-suite[@type='TestFixture']")
        $totalTime = [double]$testResults.SelectSingleNode("//test-results/@time").Value
        
        # Find longest running tests
        $testCases = $testResults.SelectNodes("//test-case")
        $longestRunningTests = $testCases | 
            Select-Object @{Name="Name"; Expression={$_.name}}, 
                          @{Name="Time"; Expression={[double]$_.time}},
                          @{Name="Result"; Expression={$_.result}} |
            Sort-Object -Property Time -Descending |
            Select-Object -First 5
        
        # Return statistics object
        return [PSCustomObject]@{
            TotalTests = $totalTests
            PassedTests = $passedTests
            FailedTests = $failedTests
            SkippedTests = $skippedTests
            InconclusiveTests = $inconclusiveTests
            PassRate = $passRate
            TotalExecutionTime = $totalTime
            TestSuiteCount = $testSuites.Count
            LongestRunningTests = $longestRunningTests
            ResultsFile = $ResultsPath
            AnalysisDate = Get-Date
        }
    }
    catch {
        Write-Error "Failed to analyze test results: $_"
        return $null
    }
}

function Analyze-TestResults {
    <#
    .SYNOPSIS
    Performs deeper analysis on test results to identify patterns and issues

    .DESCRIPTION
    This function examines test results to identify common failure patterns,
    recurring errors, and potential root causes that can be addressed
    through automated fixes.

    .PARAMETER ResultsPath
    Path to the test results file (XML format)

    .PARAMETER IncludePreviousResults
    Whether to include previous test runs for trend analysis

    .PARAMETER PreviousResultsDirectory
    Directory containing previous test result files
    
    .EXAMPLE
    Analyze-TestResults -ResultsPath "TestResults.xml"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)






]
        [string]$ResultsPath,
        
        [Parameter()]
        [switch]$IncludePreviousResults,
        
        [Parameter()]
        [string]$PreviousResultsDirectory = "$env:TEMP\TestResults"
    )

    if (-not (Test-Path $ResultsPath)) {
        Write-Error "Test results file not found: $ResultsPath"
        return $null
    }

    try {
        # Get test failures from current results
        $failures = Get-TestFailures -ResultsPath $ResultsPath
        
        # Group failures by pattern type
        $syntaxFailures = $failures | Where-Object { $_.ErrorType -eq "SyntaxError" }
        $parameterFailures = $failures | Where-Object { $_.ErrorType -eq "ParameterBindingError" }
        $runtimeFailures = $failures | Where-Object { $_.ErrorType -eq "RuntimeException" }
        $assertionFailures = $failures | Where-Object { $_.ErrorType -eq "AssertionFailure" }
        
        # Look for common patterns in error messages
        $failurePatterns = @{
            TernarySyntax = ($failures | Where-Object { $_.ErrorMessage -match "Unexpected token '?'" }).Count
            MissingClosingBrace = ($failures | Where-Object { $_.ErrorMessage -match "Missing closing '}'" }).Count
            IncorrectParameterFormat = ($failures | Where-Object { $_.ErrorMessage -match "Parameter attribute" }).Count
            FileNotFound = ($failures | Where-Object { $_.ErrorMessage -match "Cannot find path" }).Count
            MissingFunction = ($failures | Where-Object { $_.ErrorMessage -match "The term .* is not recognized" }).Count
        }
        
        # Analyze file patterns
        $filePatterns = $failures | Group-Object -Property SourceFile | Select-Object Name, Count, Group
        
        # Build fix recommendations
        $fixRecommendations = @()
        
        if ($failurePatterns.TernarySyntax -gt 0) {
            $fixRecommendations += "Run Fix-TernarySyntax to fix ternary operator syntax issues"
        }
        
        if ($failurePatterns.IncorrectParameterFormat -gt 0) {
            $fixRecommendations += "Run Fix-ParamSyntax to fix parameter declaration issues"
        }
        
        if ($filePatterns | Where-Object { $_.Name -match "Tests.ps1" -and $_.Count -gt 2 }) {
            $fixRecommendations += "Run Fix-TestSyntax to fix Pester test syntax issues"
        }
        
        # Get trend information if requested
        $trends = $null
        if ($IncludePreviousResults -and (Test-Path $PreviousResultsDirectory)) {
            $previousResults = Get-ChildItem -Path $PreviousResultsDirectory -Filter "*.xml" |
                               Where-Object { $_.FullName -ne $ResultsPath }
                               
            if ($previousResults.Count -gt 0) {
                $trends = @{
                    ResultCount = $previousResults.Count
                    FailureRateHistory = @()
                    CommonFailures = @()
                }
                
                foreach ($result in $previousResults) {
                    $stats = Get-TestStatistics -ResultsPath $result.FullName
                    if ($stats) {
                        $trends.FailureRateHistory += [PSCustomObject]@{
                            Date = $result.LastWriteTime
                            FailRate = 100 - $stats.PassRate
                            TotalTests = $stats.TotalTests
                        }
                    }
                }
            }
        }
        
        # Return analysis report
        return [PSCustomObject]@{
            FailureCount = $failures.Count
            SyntaxFailures = $syntaxFailures.Count
            ParameterFailures = $parameterFailures.Count
            RuntimeFailures = $runtimeFailures.Count
            AssertionFailures = $assertionFailures.Count
            FailurePatterns = $failurePatterns
            ProblemFiles = $filePatterns | Sort-Object -Property Count -Descending | Select-Object -First 5
            FixRecommendations = $fixRecommendations
            Trends = $trends
            DetailedFailures = $failures
            ResultsFile = $ResultsPath
            AnalysisDate = Get-Date
        }
    }
    catch {
        Write-Error "Failed to analyze test results: $_"
        return $null
    }
}

function Format-TestResultsReport {
    <#
    .SYNOPSIS
    Creates a formatted report from test result analysis

    .DESCRIPTION
    Generates a formatted report in various formats (text, HTML, JSON) 
    from test result analysis data for documentation or display.

    .PARAMETER Analysis
    The analysis object returned from Analyze-TestResults

    .PARAMETER Format
    The output format (Text, HTML, JSON, Markdown)

    .PARAMETER OutputPath
    Path to save the report (if not specified, returns the report as a string)
    
    .EXAMPLE
    $analysis = Analyze-TestResults -ResultsPath "TestResults.xml"
    Format-TestResultsReport -Analysis $analysis -Format HTML -OutputPath "TestReport.html"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)






]
        [PSObject]$Analysis,
        
        [Parameter()]
        [ValidateSet("Text", "HTML", "JSON", "Markdown")]
        [string]$Format = "Text",
        
        [Parameter()]
        [string]$OutputPath = ""
    )
    
    switch ($Format) {
        "Text" {
            $report = @"
Test Results Analysis Report
===========================
Date: $($Analysis.AnalysisDate)
Results File: $($Analysis.ResultsFile)

Summary:
- Total Failures: $($Analysis.FailureCount)
- Syntax Failures: $($Analysis.SyntaxFailures)
- Parameter Failures: $($Analysis.ParameterFailures)
- Runtime Failures: $($Analysis.RuntimeFailures)
- Assertion Failures: $($Analysis.AssertionFailures)

Failure Patterns:
$($Analysis.FailurePatterns | ForEach-Object { "- $($_.Key): $($_.Value)" } | Out-String)

Problem Files:
$($Analysis.ProblemFiles | ForEach-Object { "- $($_.Name): $($_.Count) failures" } | Out-String)

Fix Recommendations:
$($Analysis.FixRecommendations | ForEach-Object { "- $_" } | Out-String)

"@
        }
        
        "HTML" {
            # Generate HTML report
            $report = @"
<!DOCTYPE html>
<html>
<head>
    <title>Test Results Analysis</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1, h2 { color: #333; }
        table { border-collapse: collapse; width: 100%; margin-bottom: 20px; }
        th, td { padding: 8px; text-align: left; border-bottom: 1px solid #ddd; }
        th { background-color: #f2f2f2; }
        .summary { background-color: #f9f9f9; padding: 15px; border-radius: 5px; }
    </style>
</head>
<body>
    <h1>Test Results Analysis Report</h1>
    <p>Date: $($Analysis.AnalysisDate)</p>
    <p>Results File: $($Analysis.ResultsFile)</p>
    
    <div class="summary">
        <h2>Summary</h2>
        <ul>
            <li>Total Failures: $($Analysis.FailureCount)</li>
            <li>Syntax Failures: $($Analysis.SyntaxFailures)</li>
            <li>Parameter Failures: $($Analysis.ParameterFailures)</li>
            <li>Runtime Failures: $($Analysis.RuntimeFailures)</li>
            <li>Assertion Failures: $($Analysis.AssertionFailures)</li>
        </ul>
    </div>
    
    <h2>Failure Patterns</h2>
    <table>
        <tr><th>Pattern</th><th>Count</th></tr>
        $(foreach ($pattern in $Analysis.FailurePatterns.GetEnumerator()) {
            "<tr><td>$($pattern.Key)</td><td>$($pattern.Value)</td></tr>"
        })
    </table>
    
    <h2>Problem Files</h2>
    <table>
        <tr><th>File</th><th>Failure Count</th></tr>
        $(foreach ($file in $Analysis.ProblemFiles) {
            "<tr><td>$($file.Name)</td><td>$($file.Count)</td></tr>"
        })
    </table>
    
    <h2>Fix Recommendations</h2>
    <ul>
        $(foreach ($rec in $Analysis.FixRecommendations) {
            "<li>$rec</li>"
        })
    </ul>
</body>
</html>
"@
        }
        
        "JSON" {
            # Generate JSON report
            $report = ConvertTo-Json -InputObject $Analysis -Depth 5
        }
        
        "Markdown" {
            # Generate Markdown report
            $report = @"
# Test Results Analysis Report

**Date:** $($Analysis.AnalysisDate)
**Results File:** $($Analysis.ResultsFile)

## Summary
- **Total Failures:** $($Analysis.FailureCount)
- **Syntax Failures:** $($Analysis.SyntaxFailures)
- **Parameter Failures:** $($Analysis.ParameterFailures)
- **Runtime Failures:** $($Analysis.RuntimeFailures)
- **Assertion Failures:** $($Analysis.AssertionFailures)

## Failure Patterns
$(foreach ($pattern in $Analysis.FailurePatterns.GetEnumerator()) {
    "- **$($pattern.Key):** $($pattern.Value)"
})

## Problem Files
$(foreach ($file in $Analysis.ProblemFiles) {
    "- **$($file.Name):** $($file.Count) failures"
})

## Fix Recommendations
$(foreach ($rec in $Analysis.FixRecommendations) {
    "- $rec"
})

"@
        }
    }
    
    if ([string]::IsNullOrEmpty($OutputPath)) {
        return $report
    } else {
        $report | Out-File -FilePath $OutputPath -Encoding utf8 -Force
        Write-Verbose "Report saved to $OutputPath"
    }
}

function Export-TestResults {
    <#
    .SYNOPSIS
    Exports test results to a structured format for later processing

    .DESCRIPTION
    Saves test results in a structured format (JSON or custom) that can be 
    easily loaded and processed by automated fix workflows.

    .PARAMETER ResultsPath
    Path to the test results file

    .PARAMETER OutputPath
    Path to save the exported results

    .PARAMETER Format
    Format to export (JSON, CSV, XML)
    
    .EXAMPLE
    Export-TestResults -ResultsPath "TestResults.xml" -OutputPath "results.json" -Format JSON
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)






]
        [string]$ResultsPath,
        
        [Parameter(Mandatory = $true)]
        [string]$OutputPath,
        
        [Parameter()]
        [ValidateSet("JSON", "CSV", "XML")]
        [string]$Format = "JSON"
    )
    
    if (-not (Test-Path $ResultsPath)) {
        Write-Error "Test results file not found: $ResultsPath"
        return $false
    }
    
    try {
        # Get failures and statistics
        $failures = Get-TestFailures -ResultsPath $ResultsPath
        $stats = Get-TestStatistics -ResultsPath $ResultsPath
        
        # Create export object
        $exportData = [PSCustomObject]@{
            Failures = $failures
            Statistics = $stats
            ExportDate = Get-Date
            OriginalResultsPath = $ResultsPath
        }
        
        # Export based on format
        switch ($Format) {
            "JSON" {
                $exportData | ConvertTo-Json -Depth 5 | Out-File -FilePath $OutputPath -Encoding utf8 -Force
            }
            "CSV" {
                $failures | Export-Csv -Path $OutputPath -NoTypeInformation -Force
            }
            "XML" {
                $exportData | Export-Clixml -Path $OutputPath -Force
            }
        }
        
        Write-Verbose "Exported test results to $OutputPath"
        return $true
    }
    catch {
        Write-Error "Failed to export test results: $_"
        return $false
    }
}



