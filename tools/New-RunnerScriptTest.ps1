#!/usr/bin/env pwsh
<#
.SYNOPSIS
Generates a standardized test file for a runner script

.DESCRIPTION
Creates a Pester test file following the established pattern for testing runner scripts.
This ensures consistency across all test files and makes it easy to add new scripts.

.PARAMETER ScriptName
The name of the runner script (e.g., '0007_Install-Go.ps1')

.PARAMETER TestCases
Array of test case definitions. Each test case should have:
- Name: Description of the test
- Config: Configuration object to pass to the script
- Mocks: Optional hashtable of functions to mock
- ExpectedInvocations: Optional hashtable of expected function calls
- ShouldThrow: Whether the test should expect an exception
- ExpectedError: Specific error message to expect

.EXAMPLE
./tools/New-RunnerScriptTest.ps1 -ScriptName '0007_Install-Go.ps1' -TestCases @(
    @{
        Name = 'installs Go when enabled'
        Config = @{InstallGo = $true; GoVersion = '1.21.0'}
        Mocks = @{
            'Get-Command' = { $null }
            'Invoke-LabDownload' = { param($Uri, $Action) 






& $Action 'mock-installer.msi' }
        }
        ExpectedInvocations = @{
            'Invoke-LabDownload' = 1
            'Start-Process' = 1
        }
    },
    @{
        Name = 'skips when InstallGo is false'
        Config = @{InstallGo = $false}
        ExpectedInvocations = @{
            'Invoke-LabDownload' = 0
        }
    }
)
#>

param(
    Parameter(Mandatory)







    string$ScriptName,
    
    Parameter(Mandatory)
    array$TestCases,
    
    string$OutputPath
)

if (-not $OutputPath) {
    $baseName = System.IO.Path::GetFileNameWithoutExtension($ScriptName)
    $OutputPath = Join-Path $PSScriptRoot '..' 'tests' "$baseName.Tests.ps1"
}

$testContent = @"
# Generated test file for $ScriptName
. (Join-Path `$PSScriptRoot 'TestDriveCleanup.ps1')
. (Join-Path `$PSScriptRoot 'helpers' 'TestHelpers.ps1')

Describe '$($ScriptName -replace '\.ps1$', '')' {
    InModuleScope LabRunner {
        BeforeAll {
            `$script:ScriptPath = Get-RunnerScriptPath '$ScriptName'
            if (-not `$script:ScriptPath -or -not (Test-Path `$script:ScriptPath)) {
                throw "Script under test not found: $ScriptName (resolved path: `$script:ScriptPath)"
            }
        }

"@

foreach ($testCase in $TestCases) {
    $testContent += @"
        It '$($testCase.Name)' {
            `$cfg = pscustomobject@{
"@

    foreach ($key in $testCase.Config.Keys) {
        $value = $testCase.Config$key
        if ($value -is string) {
            $testContent += "`n                $key = '$value'"
        } elseif ($value -is bool) {
            $testContent += "`n                $key = `$$($value.ToString().ToLower())"
        } else {
            $testContent += "`n                $key = $value"
        }
    }

    $testContent += @"

            }
"@

    if ($testCase.Mocks) {
        foreach ($mockName in $testCase.Mocks.Keys) {
            $mockBody = $testCase.Mocks$mockName.ToString()
            $testContent += "`n            Mock $mockName { $mockBody }"
        }
    }

    $testContent += "`n`n            "

    if ($testCase.ShouldThrow) {
        if ($testCase.ExpectedError) {
            $testContent += "{ & `$script:ScriptPath -Config `$cfg }  Should -Throw '*$($testCase.ExpectedError)*'"
        } else {
            $testContent += "{ & `$script:ScriptPath -Config `$cfg }  Should -Throw"
        }
    } else {
        $testContent += "& `$script:ScriptPath -Config `$cfg"
    }

    if ($testCase.ExpectedInvocations) {
        foreach ($funcName in $testCase.ExpectedInvocations.Keys) {
            $expectedCount = $testCase.ExpectedInvocations$funcName
            $testContent += "`n            Should -Invoke -CommandName $funcName -Times $expectedCount"
        }
    }

    $testContent += @"

        }

"@
}

$testContent += @"
        AfterEach {
            # Cleanup test-specific functions
            Get-ChildItem Function:  Where-Object { `$_.Name -match '^(pythongonpmgitghtofumsiexec)$' }  Remove-Item -ErrorAction SilentlyContinue
        }
    }

    AfterAll {
        Get-Module LabRunner  Remove-Module -Force -ErrorAction SilentlyContinue
    }
}
"@

# Write the test file
$testContent  Out-File -FilePath $OutputPath -Encoding utf8
Write-Host "Generated test file: $OutputPath" -ForegroundColor Green

# Validate the generated file by running a syntax check
try {
    $null = System.Management.Automation.PSParser::Tokenize($testContent, ref$null)
    Write-Host " Syntax validation passed" -ForegroundColor Green
} catch {
    Write-Warning "Syntax validation failed: $_"
}



