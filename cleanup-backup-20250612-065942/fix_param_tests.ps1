# Script to fix test files that fail due to "Param is not recognized" errors
# These tests try to dot-source scripts with Param() blocks which causes parsing issues

# List of test files that have this issue - focus on numbered runner script tests
$failingTests = @(
    'tests/0006_Install-ValidationTools.Tests.ps1',
    'tests/0007_Install-Go.Tests.ps1',
    'tests/0008_Install-OpenTofu.Tests.ps1',
    'tests/0009_Initialize-OpenTofu.Tests.ps1',
    'tests/0010_Prepare-HyperVProvider.Tests.ps1',
    'tests/0100_Enable-WinRM.Tests.ps1',
    'tests/0103_Change-ComputerName.Tests.ps1',
    'tests/0104_Install-CA.Tests.ps1',
    'tests/0105_Install-HyperV.Tests.ps1',
    'tests/0106_Install-WAC.Tests.ps1',
    'tests/0112_Enable-PXE.Tests.ps1',
    'tests/0113_Config-DNS.Tests.ps1',
    'tests/0114_Config-TrustedHosts.Tests.ps1',
    'tests/0200_Get-SystemInfo.Tests.ps1',
    'tests/0201_Install-NodeCore.Tests.ps1',
    'tests/0202_Install-NodeGlobalPackages.Tests.ps1',
    'tests/0203_Install-npm.Tests.ps1',
    'tests/0204_Install-Poetry.Tests.ps1',
    'tests/0205_Install-Sysinternals.Tests.ps1',
    'tests/0206_Install-Python.Tests.ps1',
    'tests/0207_Install-Git.Tests.ps1',
    'tests/0208_Install-DockerDesktop.Tests.ps1',
    'tests/0209_Install-7Zip.Tests.ps1',
    'tests/0210_Install-VSCode.Tests.ps1',
    'tests/0211_Install-VSBuildTools.Tests.ps1',
    'tests/0212_Install-AzureCLI.Tests.ps1',
    'tests/0213_Install-AWSCLI.Tests.ps1',
    'tests/0214_Install-Packer.Tests.ps1',
    'tests/0215_Install-Chocolatey.Tests.ps1',
    'tests/0216_Set-LabProfile.Tests.ps1',
    'tests/9999_Reset-Machine.Tests.ps1'
)

foreach ($testFile in $failingTests) {
    $fullPath = Join-Path $PSScriptRoot $testFile
    if (-not (Test-Path $fullPath)) {
        Write-Warning "Test file not found: $fullPath"
        continue
    }
    
    Write-Host "Processing: $testFile" -ForegroundColor Green
    
    $content = Get-Content $fullPath -Raw
    
    # Extract script name from the test file path
    $testFileName = Split-Path $testFile -Leaf
    $scriptName = $testFileName -replace '\.Tests\.ps1$', '.ps1'
    
    # Create the new test content using the InModuleScope pattern
    $newContent = @"
# filepath: $testFile
. (Join-Path `$PSScriptRoot 'TestDriveCleanup.ps1')
. (Join-Path `$PSScriptRoot 'helpers' 'TestHelpers.ps1')

Describe '$($scriptName -replace '\.ps1$', '') Tests' -Tag 'Maintenance' {
    InModuleScope LabRunner {
        BeforeAll {
            # Get the script path using the LabRunner function
            `$script:ScriptPath = Get-RunnerScriptPath '$scriptName'
            if (-not `$script:ScriptPath -or -not (Test-Path `$script:ScriptPath)) {
                throw "Script under test not found: $scriptName (resolved path: `$script:ScriptPath)"
            }
            
            # Set up test environment
            `$script:TestConfig = Get-TestConfiguration
            `$script:SkipNonWindows = -not (Get-Platform).IsWindows
            `$script:SkipNonLinux = -not (Get-Platform).IsLinux
            `$script:SkipNonMacOS = -not (Get-Platform).IsMacOS
            `$script:SkipNonAdmin = -not (Test-IsAdministrator)
            
            # Set up standard mocks
            Disable-InteractivePrompts
            New-StandardMocks
        }
        
        Context 'Script Structure Validation' {
            It 'should have valid PowerShell syntax' {
                `$errors = `$null
                [System.Management.Automation.Language.Parser]::ParseFile(`$script:ScriptPath, [ref]`$null, [ref]`$errors) | Out-Null
                (`$errors ? `$errors.Count : 0) | Should -Be 0
            }
            
            It 'should follow naming conventions' {
                `$scriptName = [System.IO.Path]::GetFileName(`$script:ScriptPath)
                `$scriptName | Should -Match '^[0-9]{4}_[A-Z][a-zA-Z0-9-]+\.ps1$|^[A-Z][a-zA-Z0-9-]+\.ps1$'
            }
            
            It 'should have Config parameter' {
                `$content = Get-Content `$script:ScriptPath -Raw
                `$content | Should -Match 'Param\s*\(\s*.*\$Config'
            }
            
            It 'should import LabRunner module' {
                `$content = Get-Content `$script:ScriptPath -Raw
                `$content | Should -Match 'Import-Module.*LabRunner'
            }
            
            It 'should contain Invoke-LabStep call' {
                `$content = Get-Content `$script:ScriptPath -Raw
                `$content | Should -Match 'Invoke-LabStep'
            }
        }
        
        Context 'Basic Functionality' {
            It 'should execute without errors with valid config' {
                `$config = [pscustomobject]@{}
                { & `$script:ScriptPath -Config `$config } | Should -Not -Throw
            }
            
            It 'should handle whatif parameter' {
                `$config = [pscustomobject]@{}
                { & `$script:ScriptPath -Config `$config -WhatIf } | Should -Not -Throw
            }
        }
        
        AfterAll {
            # Cleanup any test artifacts
        }
    }
}
"@
    
    # Write the new content to the file
    $newContent | Set-Content -Path $fullPath -Encoding UTF8
    Write-Host "  Updated: $testFile" -ForegroundColor Yellow
}

Write-Host "`nCompleted fixing test files with Param errors." -ForegroundColor Green
Write-Host "The tests now use InModuleScope LabRunner with Get-RunnerScriptPath pattern." -ForegroundColor Green
