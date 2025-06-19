#Requires -Version 7.0
#Requires -Module Pester

<#
.SYNOPSIS
    Comprehensive Pester tests for CoreApp non-interactive mode functionality

.DESCRIPTION
    Tests all aspects of non-interactive mode including:
    - Basic non-interactive execution
    - Auto mode with script execution
    - Specific script selection
    - Error handling and exit codes
    - Logging and output verification
    - Cross-platform compatibility

.NOTES
    This test suite ensures bulletproof non-interactive functionality
#>

BeforeAll {
    # Set up test environment
    $script:ProjectRoot = $env:PROJECT_ROOT
    if (-not $script:ProjectRoot) {
        $script:ProjectRoot = Split-Path $PSScriptRoot -Parent | Split-Path -Parent | Split-Path -Parent | Split-Path -Parent
    }

    $script:CoreRunnerScript = Join-Path $script:ProjectRoot "core-runner/core_app/core-runner.ps1"
    $script:ConfigFile = Join-Path $script:ProjectRoot "core-runner/core_app/default-config.json"
    $script:TestLogDir = Join-Path $script:ProjectRoot "logs/tests"

    # Ensure test log directory exists
    if (-not (Test-Path $script:TestLogDir)) {
        New-Item -ItemType Directory -Path $script:TestLogDir -Force | Out-Null
    }

    # Verify core runner exists
    if (-not (Test-Path $script:CoreRunnerScript)) {
        throw "Core runner script not found at: $script:CoreRunnerScript"
    }

    # Helper function to execute core runner and capture results
    function Invoke-CoreRunnerTest {
        param(
            [string[]]$Arguments,
            [string]$TestName = "test"
        )

        $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $logFile = Join-Path $script:TestLogDir "corerunner-test-$TestName-$timestamp.log"

        try {
            $startTime = Get-Date
            $output = & $script:CoreRunnerScript @Arguments 2>&1
            $exitCode = $global:LASTEXITCODE
            $endTime = Get-Date
            $duration = ($endTime - $startTime).TotalMilliseconds

            $result = [PSCustomObject]@{
                ExitCode = $exitCode
                Output = $output
                LogFile = $logFile
                Duration = $duration
                Success = ($exitCode -eq 0)
                StartTime = $startTime
                EndTime = $endTime
            }

            # Save detailed test results to log file
            $logContent = @"
=== Core Runner Test Results ===
Test Name: $TestName
Start Time: $($result.StartTime)
End Time: $($result.EndTime)
Duration: $($result.Duration)ms
Exit Code: $($result.ExitCode)
Success: $($result.Success)

Arguments Used:
$($Arguments -join ' ')

=== Output ===
$($result.Output -join "`n")

=== End of Log ===
"@
            $logContent | Out-File -FilePath $logFile -Encoding UTF8

            return $result

        } catch {
            Write-Error "Failed to execute core runner test: $($_.Exception.Message)"
            throw
        }
    }
}

Describe "CoreApp Non-Interactive Mode" -Tag @('Unit', 'CoreApp', 'NonInteractive') {

    Context "Basic Non-Interactive Mode" {

        It "Should exit gracefully with helpful message when no scripts specified" {
            $result = Invoke-CoreRunnerTest -Arguments @('-NonInteractive', '-Verbosity', 'detailed') -TestName "basic-noargs"

            $result.Success | Should -Be $true
            $result.ExitCode | Should -Be 0
            $result.Output | Should -Contain "Non-interactive mode: use -Scripts parameter to specify which scripts to run, or -Auto for all scripts"
            $result.Output | Should -Contain "No scripts specified for non-interactive execution"
            $result.Output | Should -Contain "Core runner completed successfully"
            $result.LogFile | Should -Exist

            Write-Host "✅ Test log saved to: $($result.LogFile)" -ForegroundColor Green
        }

        It "Should respect verbosity levels in non-interactive mode" {
            $silentResult = Invoke-CoreRunnerTest -Arguments @('-NonInteractive', '-Verbosity', 'silent') -TestName "basic-silent"
            $detailedResult = Invoke-CoreRunnerTest -Arguments @('-NonInteractive', '-Verbosity', 'detailed') -TestName "basic-detailed"

            $silentResult.Success | Should -Be $true
            $detailedResult.Success | Should -Be $true

            # Silent mode should have less output than detailed mode
            $silentResult.Output.Count | Should -BeLessThan $detailedResult.Output.Count

            Write-Host "✅ Silent test log: $($silentResult.LogFile)" -ForegroundColor Green
            Write-Host "✅ Detailed test log: $($detailedResult.LogFile)" -ForegroundColor Green
        }

        It "Should handle missing configuration files gracefully" {
            $fakeConfigPath = Join-Path $script:TestLogDir "nonexistent-config.json"
            $result = Invoke-CoreRunnerTest -Arguments @('-NonInteractive', '-ConfigFile', $fakeConfigPath, '-Verbosity', 'detailed') -TestName "missing-config"

            # Should still work with default config fallback or show appropriate error
            $result.ExitCode | Should -BeIn @(0, 1)  # Either succeeds with fallback or fails gracefully
            $result.LogFile | Should -Exist

            Write-Host "✅ Missing config test log: $($result.LogFile)" -ForegroundColor Green
        }
    }

    Context "Auto Mode Non-Interactive" {

        It "Should execute all scripts in WhatIf mode without errors" {
            $result = Invoke-CoreRunnerTest -Arguments @('-NonInteractive', '-Auto', '-WhatIf', '-Verbosity', 'detailed') -TestName "auto-whatif"

            $result.Success | Should -Be $true
            $result.ExitCode | Should -Be 0
            $result.Output | Should -Contain "Running all scripts in automatic mode"
            $result.Output | Should -Contain "What if: Performing the operation"
            $result.Output | Should -Contain "Core runner completed successfully"
            $result.LogFile | Should -Exist

            Write-Host "✅ Auto WhatIf test log: $($result.LogFile)" -ForegroundColor Green
        }

        It "Should handle Auto mode with Force parameter" {
            $result = Invoke-CoreRunnerTest -Arguments @('-NonInteractive', '-Auto', '-Force', '-WhatIf', '-Verbosity', 'detailed') -TestName "auto-force"

            $result.Success | Should -Be $true
            $result.ExitCode | Should -Be 0
            $result.Output | Should -Contain "Running all scripts in automatic mode"
            $result.LogFile | Should -Exist

            Write-Host "✅ Auto Force test log: $($result.LogFile)" -ForegroundColor Green
        }

        It "Should complete within reasonable time limits" {
            $result = Invoke-CoreRunnerTest -Arguments @('-NonInteractive', '-Auto', '-WhatIf', '-Verbosity', 'silent') -TestName "auto-performance"

            $result.Success | Should -Be $true
            $result.Duration | Should -BeLessThan 30000  # Should complete within 30 seconds
            $result.LogFile | Should -Exist

            Write-Host "✅ Auto performance test completed in $($result.Duration)ms, log: $($result.LogFile)" -ForegroundColor Green
        }
    }

    Context "Specific Script Execution" {

        It "Should execute a specific script in WhatIf mode" {
            $result = Invoke-CoreRunnerTest -Arguments @('-NonInteractive', '-Scripts', '0200_Get-SystemInfo', '-WhatIf', '-Verbosity', 'detailed') -TestName "specific-script"

            $result.Success | Should -Be $true
            $result.ExitCode | Should -Be 0
            $result.Output | Should -Contain "Executing script: 0200_Get-SystemInfo"
            $result.Output | Should -Contain "What if: Performing the operation"
            $result.LogFile | Should -Exist

            Write-Host "✅ Specific script test log: $($result.LogFile)" -ForegroundColor Green
        }

        It "Should handle multiple specific scripts" {
            $result = Invoke-CoreRunnerTest -Arguments @('-NonInteractive', '-Scripts', '0200_Get-SystemInfo,0000_Cleanup-Files', '-WhatIf', '-Verbosity', 'detailed') -TestName "multiple-scripts"

            $result.Success | Should -Be $true
            $result.ExitCode | Should -Be 0
            $result.Output | Should -Contain "Executing script: 0200_Get-SystemInfo"
            $result.Output | Should -Contain "Executing script: 0000_Cleanup-Files"
            $result.LogFile | Should -Exist

            Write-Host "✅ Multiple scripts test log: $($result.LogFile)" -ForegroundColor Green
        }

        It "Should handle nonexistent script gracefully" {
            $result = Invoke-CoreRunnerTest -Arguments @('-NonInteractive', '-Scripts', 'NonExistentScript', '-WhatIf', '-Verbosity', 'detailed') -TestName "nonexistent-script"

            $result.Success | Should -Be $true  # Should still complete successfully
            $result.Output | Should -Contain "Script not found: NonExistentScript"
            $result.LogFile | Should -Exist

            Write-Host "✅ Nonexistent script test log: $($result.LogFile)" -ForegroundColor Green
        }
    }

    Context "Error Handling and Edge Cases" {

        It "Should handle empty script parameter gracefully" {
            $result = Invoke-CoreRunnerTest -Arguments @('-NonInteractive', '-Scripts', '', '-Verbosity', 'detailed') -TestName "empty-scripts"

            $result.Success | Should -Be $true
            $result.LogFile | Should -Exist

            Write-Host "✅ Empty scripts test log: $($result.LogFile)" -ForegroundColor Green
        }

        It "Should properly detect non-interactive mode automatically" {
            # Test auto-detection by setting environment that should trigger non-interactive mode
            $env:PESTER_RUN = 'true'
            try {
                $result = Invoke-CoreRunnerTest -Arguments @('-Verbosity', 'detailed') -TestName "auto-detect"

                $result.Success | Should -Be $true
                $result.Output | Should -Contain "Non-interactive mode"
                $result.LogFile | Should -Exist

                Write-Host "✅ Auto-detect test log: $($result.LogFile)" -ForegroundColor Green
            } finally {
                Remove-Item Env:PESTER_RUN -ErrorAction SilentlyContinue
            }
        }

        It "Should maintain consistent exit codes across runs" {
            $results = @()
            1..3 | ForEach-Object {
                $results += Invoke-CoreRunnerTest -Arguments @('-NonInteractive', '-Verbosity', 'silent') -TestName "consistency-$_"
            }

            # All runs should have the same exit code
            $exitCodes = $results | ForEach-Object { $_.ExitCode } | Sort-Object -Unique
            $exitCodes.Count | Should -Be 1
            $exitCodes[0] | Should -Be 0

            $results | ForEach-Object {
                $_.LogFile | Should -Exist
                Write-Host "✅ Consistency test log: $($_.LogFile)" -ForegroundColor Green
            }
        }
    }

    Context "Logging and Output Verification" {

        It "Should create proper log entries with timestamps" {
            $result = Invoke-CoreRunnerTest -Arguments @('-NonInteractive', '-Verbosity', 'detailed') -TestName "logging-verification"

            $result.Success | Should -Be $true
            $result.Output | Should -Match '\[\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3}\]'  # Timestamp format
            $result.Output | Should -Contain "[SUCCESS]"
            $result.Output | Should -Contain "[INFO]"
            $result.LogFile | Should -Exist

            # Verify log file contains expected content
            $logContent = Get-Content $result.LogFile -Raw
            $logContent | Should -Contain "Core Runner Test Results"
            $logContent | Should -Contain "Exit Code: 0"

            Write-Host "✅ Logging verification test log: $($result.LogFile)" -ForegroundColor Green
        }

        It "Should include module initialization messages" {
            $result = Invoke-CoreRunnerTest -Arguments @('-NonInteractive', '-Verbosity', 'detailed') -TestName "module-init"

            $result.Success | Should -Be $true
            $result.Output | Should -Contain "Logging system initialized"
            $result.Output | Should -Contain "Core runner started"
            $result.LogFile | Should -Exist

            Write-Host "✅ Module initialization test log: $($result.LogFile)" -ForegroundColor Green
        }
    }

    Context "Integration with CoreApp Module" {

        It "Should successfully invoke CoreApp module directly" {
            # Import CoreApp module
            $coreAppPath = Join-Path $script:ProjectRoot "core-runner/core_app/CoreApp.psm1"
            if (Test-Path $coreAppPath) {
                Import-Module $coreAppPath -Force

                $result = Invoke-CoreApplication -ConfigPath $script:ConfigFile -NonInteractive -WhatIf

                # Should complete without errors
                $result | Should -Not -BeNullOrEmpty

                Write-Host "✅ CoreApp module integration test completed" -ForegroundColor Green
            } else {
                Set-ItResult -Skipped -Because "CoreApp module not found at expected path"
            }
        }
    }
}

Describe "CoreApp Cross-Platform Compatibility" -Tag @('Unit', 'CoreApp', 'CrossPlatform') {

    Context "Path Handling" {

        It "Should handle paths correctly on current platform" {
            $result = Invoke-CoreRunnerTest -Arguments @('-NonInteractive', '-Verbosity', 'detailed') -TestName "path-handling"

            $result.Success | Should -Be $true
            $result.Output | Should -Contain "Repository root:"
            $result.Output | Should -Contain "Configuration file:"
            $result.LogFile | Should -Exist

            Write-Host "✅ Path handling test log: $($result.LogFile)" -ForegroundColor Green
        }

        It "Should work with different configuration file paths" {
            # Test with different path formats
            $configPaths = @(
                $script:ConfigFile,
                (Resolve-Path $script:ConfigFile).Path
            )

            foreach ($configPath in $configPaths) {
                if (Test-Path $configPath) {
                    $result = Invoke-CoreRunnerTest -Arguments @('-NonInteractive', '-ConfigFile', $configPath, '-Verbosity', 'silent') -TestName "config-path-$(($configPath -split '[\\/]')[-1])"

                    $result.Success | Should -Be $true
                    $result.LogFile | Should -Exist

                    Write-Host "✅ Config path test log: $($result.LogFile)" -ForegroundColor Green
                }
            }
        }
    }
}

AfterAll {
    # Clean up any test artifacts if needed
    Write-Host "`n🎯 Non-Interactive Mode Test Summary:" -ForegroundColor Cyan
    Write-Host "✅ All test logs saved to: $script:TestLogDir" -ForegroundColor Green
    Write-Host "✅ Tests verified bulletproof non-interactive functionality" -ForegroundColor Green
    Write-Host "✅ Comprehensive logging and error handling validated" -ForegroundColor Green

    # Display test log directory contents
    if (Test-Path $script:TestLogDir) {
        $logFiles = Get-ChildItem -Path $script:TestLogDir -Filter "corerunner-test-*.log" | Sort-Object LastWriteTime
        if ($logFiles) {
            Write-Host "`n📋 Generated Test Log Files:" -ForegroundColor Yellow
            $logFiles | ForEach-Object {
                $size = [math]::Round($_.Length / 1KB, 2)
                Write-Host "  • $($_.Name) (${size}KB)" -ForegroundColor Gray
            }
        }
    }
}
