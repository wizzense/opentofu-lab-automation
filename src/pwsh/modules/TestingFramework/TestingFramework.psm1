#Requires -Version 7.0

<#
.SYNOPSIS
    Unified Testing Framework for OpenTofu Lab Automation

.DESCRIPTION
    Consolidates all scattered testing functionality into a single, coherent framework
    that integrates with VS Code, PatchManager, and UnifiedMaintenance.
#>

function Invoke-UnifiedTestExecution {
    param(
        [Parameter()]
        [ValidateSet("All", "Pester", "Pytest", "Syntax", "Parallel")]
        [string]$TestType = "All",
        
        [Parameter()]
        [string]$OutputPath = ".\test-results",
        
        [Parameter()]
        [switch]$VSCodeIntegration
    )
    
    Write-CustomLog "Starting unified test execution: $TestType" -Level INFO
    
    # Create output directory for VS Code integration
    if (-not (Test-Path $OutputPath)) {
        New-Item -Path $OutputPath -ItemType Directory -Force
    }
    
    switch ($TestType) {
        "All" {
            Invoke-PesterTests -OutputPath $OutputPath -VSCodeIntegration:$VSCodeIntegration
            Invoke-PytestTests -OutputPath $OutputPath -VSCodeIntegration:$VSCodeIntegration
            Invoke-SyntaxValidation -OutputPath $OutputPath -VSCodeIntegration:$VSCodeIntegration
        }
        "Pester" {
            Invoke-PesterTests -OutputPath $OutputPath -VSCodeIntegration:$VSCodeIntegration
        }
        "Pytest" {
            Invoke-PytestTests -OutputPath $OutputPath -VSCodeIntegration:$VSCodeIntegration
        }
        "Syntax" {
            Invoke-SyntaxValidation -OutputPath $OutputPath -VSCodeIntegration:$VSCodeIntegration
        }
        "Parallel" {
            Invoke-ParallelTests -OutputPath $OutputPath -VSCodeIntegration:$VSCodeIntegration
        }
    }
    
    Write-CustomLog "Test execution complete. Results in: $OutputPath" -Level SUCCESS
}

function Invoke-PesterTests {
    param(
        [string]$OutputPath,
        [switch]$VSCodeIntegration
    )
    
    Write-CustomLog "Running Pester tests..." -Level INFO
    
    try {
        # Import Pester
        Import-Module Pester -Force
        
        # Configure Pester for VS Code integration
        $pesterConfig = New-PesterConfiguration
        $pesterConfig.Run.Path = "./tests"
        $pesterConfig.Run.PassThru = $true
        $pesterConfig.CodeCoverage.Enabled = $true
        $pesterConfig.TestResult.Enabled = $true
        $pesterConfig.TestResult.OutputFormat = "JUnitXml"
        $pesterConfig.TestResult.OutputPath = "$OutputPath/pester-results.xml"
        $pesterConfig.Output.Verbosity = "Detailed"
        
        # Run tests
        $results = Invoke-Pester -Configuration $pesterConfig
        
        # Output results for VS Code
        if ($VSCodeIntegration) {
            $results | ConvertTo-Json -Depth 10 | Out-File "$OutputPath/pester-results.json"
        }
        
        Write-CustomLog "Pester tests completed. Passed: $($results.PassedCount), Failed: $($results.FailedCount)" -Level SUCCESS
        return $results
        
    } catch {
        Write-CustomLog "Pester test execution failed: $($_.Exception.Message)" -Level ERROR
        throw
    }
}

function Invoke-PytestTests {
    param(
        [string]$OutputPath,
        [switch]$VSCodeIntegration
    )
    
    Write-CustomLog "Running pytest tests..." -Level INFO
    
    try {
        # Check if Python and pytest are available
        $pythonAvailable = Get-Command python -ErrorAction SilentlyContinue
        if (-not $pythonAvailable) {
            Write-CustomLog "Python not available, skipping pytest" -Level WARN
            return
        }
        
        # Run pytest with proper output for VS Code
        if ($VSCodeIntegration) {
            $pytestArgs = @(
                "-v",
                "--tb=short",
                "--junit-xml=$OutputPath/pytest-results.xml",
                "--json-report",
                "--json-report-file=$OutputPath/pytest-results.json",
                "./py/tests"
            )
        } else {
            $pytestArgs = @("-v", "./py/tests")
        }
        
        & python -m pytest @pytestArgs
        
        Write-CustomLog "Pytest tests completed" -Level SUCCESS
        
    } catch {
        Write-CustomLog "Pytest execution failed: $($_.Exception.Message)" -Level ERROR
        throw
    }
}

function Invoke-SyntaxValidation {
    param(
        [string]$OutputPath,
        [switch]$VSCodeIntegration
    )
    
    Write-CustomLog "Running syntax validation..." -Level INFO
    
    try {
        # Get all PowerShell files (correct count)
        $allPS1Files = Get-ChildItem -Recurse -Filter "*.ps1" | Where-Object { 
            $_.FullName -notlike "*\archive\*" -and 
            $_.FullName -notlike "*\backups\*" 
        }
        
        Write-CustomLog "Validating syntax for $($allPS1Files.Count) PowerShell files" -Level INFO
        
        $syntaxErrors = @()
        foreach ($file in $allPS1Files) {
            try {
                $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $file.FullName -Raw), [ref]$null)
            } catch {
                $syntaxErrors += [PSCustomObject]@{
                    File = $file.FullName
                    Error = $_.Exception.Message
                }
            }
        }
        
        # Output results
        if ($VSCodeIntegration -and $syntaxErrors.Count -gt 0) {
            $syntaxErrors | ConvertTo-Json -Depth 10 | Out-File "$OutputPath/syntax-errors.json"
        }
        
        if ($syntaxErrors.Count -eq 0) {
            Write-CustomLog "All $($allPS1Files.Count) PowerShell files have valid syntax" -Level SUCCESS
        } else {
            Write-CustomLog "Found $($syntaxErrors.Count) files with syntax errors" -Level ERROR
            foreach ($error in $syntaxErrors) {
                Write-CustomLog "  ERROR: $($error.File) - $($error.Error)" -Level ERROR
            }
        }
        
        return $syntaxErrors
        
    } catch {
        Write-CustomLog "Syntax validation failed: $($_.Exception.Message)" -Level ERROR
        throw
    }
}

Export-ModuleMember -Function @(
    'Invoke-UnifiedTestExecution',
    'Invoke-PesterTests', 
    'Invoke-PytestTests',
    'Invoke-SyntaxValidation'
)
