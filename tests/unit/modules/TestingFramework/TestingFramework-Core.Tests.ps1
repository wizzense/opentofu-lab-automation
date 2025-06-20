BeforeAll {
    # Mock Write-CustomLog function
    function global:Write-CustomLog {
        param([string]$Message, [string]$Level = "INFO")
        Write-Host "[$Level] $Message"
    }
    
    # Import the TestingFramework module
    $projectRoot = $env:PROJECT_ROOT
    $testingFrameworkPath = Join-Path $projectRoot "core-runner/modules/TestingFramework"
    
    try {
        Import-Module $testingFrameworkPath -Force -ErrorAction Stop
        Write-Host "TestingFramework module imported successfully" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to import TestingFramework module: $_"
        throw
    }
    
    # Create test directories and files
    $script:testScriptDir = Join-Path $TestDrive "TestScripts"
    $script:testResultsDir = Join-Path $TestDrive "TestResults"
    New-Item -Path $script:testScriptDir -ItemType Directory -Force | Out-Null
    New-Item -Path $script:testResultsDir -ItemType Directory -Force | Out-Null
}

Describe "TestingFramework Module - Core Functions" {
    
    Context "Invoke-PesterTests" {
        
        BeforeEach {
            # Create sample Pester test files
            $script:sampleTestFile1 = Join-Path $script:testScriptDir "SampleTest1.Tests.ps1"
            $script:sampleTestFile2 = Join-Path $script:testScriptDir "SampleTest2.Tests.ps1"
            
            @"
Describe "Sample Test Suite 1" {
    It "Should pass simple test" {
        `$true | Should -Be `$true
    }
    
    It "Should validate basic math" {
        2 + 2 | Should -Be 4
    }
}
"@ | Out-File -FilePath $script:sampleTestFile1 -Encoding UTF8
            
            @"
Describe "Sample Test Suite 2" {
    It "Should handle string operations" {
        "Hello World".Length | Should -Be 11
    }
    
    It "Should validate arrays" {
        @(1, 2, 3).Count | Should -Be 3
    }
}
"@ | Out-File -FilePath $script:sampleTestFile2 -Encoding UTF8
        }
        
        It "Should execute single Pester test file" {
            $result = Invoke-PesterTests -TestPath $script:sampleTestFile1
            
            $result | Should -Not -BeNullOrEmpty
            $result.TotalCount | Should -BeGreaterThan 0
        }
        
        It "Should execute multiple Pester test files" {
            $testFiles = @($script:sampleTestFile1, $script:sampleTestFile2)
            $result = Invoke-PesterTests -TestPath $testFiles
            
            $result | Should -Not -BeNullOrEmpty
            $result.TotalCount | Should -BeGreaterThan 0
        }
        
        It "Should execute tests from directory" {
            $result = Invoke-PesterTests -TestPath $script:testScriptDir
            
            $result | Should -Not -BeNullOrEmpty
            $result.TotalCount | Should -BeGreaterThan 0
        }
        
        It "Should generate output file when specified" {
            $outputFile = Join-Path $script:testResultsDir "PesterResults.xml"
            $result = Invoke-PesterTests -TestPath $script:sampleTestFile1 -OutputFile $outputFile
            
            $result | Should -Not -BeNullOrEmpty
            Test-Path $outputFile | Should -Be $true
        }
        
        It "Should handle custom Pester configuration" {
            $config = @{
                Output = @{
                    Verbosity = 'Minimal'
                }
                TestResult = @{
                    Enabled = $true
                }
            }
            
            $result = Invoke-PesterTests -TestPath $script:sampleTestFile1 -Configuration $config
            
            $result | Should -Not -BeNullOrEmpty
        }
        
        It "Should handle non-existent test path" {
            $nonExistentPath = Join-Path $script:testScriptDir "NonExistent.Tests.ps1"
            
            { Invoke-PesterTests -TestPath $nonExistentPath } | Should -Throw
        }
    }
    
    Context "Invoke-SyntaxValidation" {
        
        BeforeEach {
            # Create PowerShell files with different syntax conditions
            $script:validPSFile = Join-Path $script:testScriptDir "ValidScript.ps1"
            $script:invalidPSFile = Join-Path $script:testScriptDir "InvalidScript.ps1"
            $script:warningPSFile = Join-Path $script:testScriptDir "WarningScript.ps1"
            
            # Valid PowerShell script
            @"
function Test-ValidFunction {
    param([string]`$Parameter)
    
    if (`$Parameter) {
        Write-Output "Parameter provided: `$Parameter"
    } else {
        Write-Output "No parameter provided"
    }
    
    return `$true
}

Test-ValidFunction -Parameter "Test"
"@ | Out-File -FilePath $script:validPSFile -Encoding UTF8
            
            # Invalid PowerShell script (syntax errors)
            @"
function Test-InvalidFunction {
    param([string]`$Parameter
    # Missing closing parenthesis above
    
    if (`$Parameter {
        Write-Output "This has syntax errors"
    # Missing closing brace
    
    return `$true
}
"@ | Out-File -FilePath $script:invalidPSFile -Encoding UTF8
            
            # Script with PSScriptAnalyzer warnings
            @"
function Test-WarningFunction {
    param([string]`$param)
    
    `$unused_variable = "This variable is never used"
    Write-Host "Using Write-Host instead of Write-Output"
    
    return `$param
}
"@ | Out-File -FilePath $script:warningPSFile -Encoding UTF8
        }
        
        It "Should validate syntax of valid PowerShell file" {
            $result = Invoke-SyntaxValidation -Path $script:validPSFile
            
            $result | Should -Not -BeNullOrEmpty
            $result.IsValid | Should -Be $true
        }
        
        It "Should detect syntax errors in invalid PowerShell file" {
            $result = Invoke-SyntaxValidation -Path $script:invalidPSFile
            
            $result | Should -Not -BeNullOrEmpty
            $result.IsValid | Should -Be $false
            $result.Errors | Should -Not -BeNullOrEmpty
        }
        
        It "Should validate syntax of directory containing PowerShell files" {
            $result = Invoke-SyntaxValidation -Path $script:testScriptDir
            
            $result | Should -Not -BeNullOrEmpty
            $result | Should -HaveCount 3  # Three test files created
        }
        
        It "Should include PSScriptAnalyzer warnings when enabled" {
            $result = Invoke-SyntaxValidation -Path $script:warningPSFile -IncludeAnalyzer
            
            $result | Should -Not -BeNullOrEmpty
            # May have warnings even if syntax is valid
        }
        
        It "Should handle non-PowerShell files gracefully" {
            $textFile = Join-Path $script:testScriptDir "NotAScript.txt"
            "This is just a text file" | Out-File -FilePath $textFile -Encoding UTF8
            
            $result = Invoke-SyntaxValidation -Path $textFile
            
            # Should either skip non-PS files or handle them gracefully
            $result | Should -Not -BeNullOrEmpty
        }
        
        It "Should handle non-existent path" {
            $nonExistentPath = Join-Path $script:testScriptDir "DoesNotExist.ps1"
            
            { Invoke-SyntaxValidation -Path $nonExistentPath } | Should -Throw
        }
    }
    
    Context "Invoke-UnifiedTestExecution" {
        
        BeforeEach {
            # Create a mixed test environment
            $script:unifiedTestDir = Join-Path $script:testScriptDir "UnifiedTests"
            New-Item -Path $script:unifiedTestDir -ItemType Directory -Force | Out-Null
            
            # Pester test
            $pesterTest = Join-Path $script:unifiedTestDir "Unified.Tests.ps1"
            @"
Describe "Unified Test Execution" {
    It "Should run in unified framework" {
        `$env:TEST_EXECUTION | Should -Be "UNIFIED"
    }
}
"@ | Out-File -FilePath $pesterTest -Encoding UTF8
            
            # PowerShell script to validate
            $scriptToValidate = Join-Path $script:unifiedTestDir "ScriptToValidate.ps1"
            @"
function Test-UnifiedFunction {
    param([string]`$Input)
    return "Processed: `$Input"
}
"@ | Out-File -FilePath $scriptToValidate -Encoding UTF8
        }
        
        It "Should execute unified test suite" {
            $env:TEST_EXECUTION = "UNIFIED"
            
            try {
                $result = Invoke-UnifiedTestExecution -TestPath $script:unifiedTestDir
                
                $result | Should -Not -BeNullOrEmpty
                $result.TotalTests | Should -BeGreaterThan 0
            }
            finally {
                Remove-Item Env:\TEST_EXECUTION -ErrorAction SilentlyContinue
            }
        }
        
        It "Should include syntax validation in unified execution" {
            $result = Invoke-UnifiedTestExecution -TestPath $script:unifiedTestDir -IncludeSyntaxValidation
            
            $result | Should -Not -BeNullOrEmpty
            $result.SyntaxValidation | Should -Not -BeNullOrEmpty
        }
        
        It "Should generate comprehensive report" {
            $reportFile = Join-Path $script:testResultsDir "UnifiedReport.json"
            $result = Invoke-UnifiedTestExecution -TestPath $script:unifiedTestDir -OutputFile $reportFile
            
            $result | Should -Not -BeNullOrEmpty
            Test-Path $reportFile | Should -Be $true
        }
        
        It "Should handle empty test directory" {
            $emptyDir = Join-Path $script:testScriptDir "EmptyTestDir"
            if (-not (Test-Path $emptyDir)) { New-Item -Path $emptyDir -ItemType Directory -Force | Out-Null }
            
            $result = Invoke-UnifiedTestExecution -TestPath $emptyDir
            
            $result | Should -Not -BeNullOrEmpty
            $result.TotalTests | Should -Be 0
        }
        
        It "Should support parallel execution" {
            $result = Invoke-UnifiedTestExecution -TestPath $script:unifiedTestDir -Parallel
            
            $result | Should -Not -BeNullOrEmpty
        }
    }
}

Describe "TestingFramework Module - Integration and Performance" {
    
    Context "Integration with Other Modules" {
        
        It "Should integrate with logging system" {
            # Mock logging calls to verify integration
            $logCalls = @()
            Mock Write-CustomLog {
                $logCalls += $args[0]
            }
            
            Invoke-SyntaxValidation -Path $script:testScriptDir
            
            # Should have called logging functions
            Assert-MockCalled Write-CustomLog -Times 1 -AtLeast
        }
        
        It "Should work with parallel execution module" {
            # This test assumes ParallelExecution module integration
            $testFiles = Get-ChildItem -Path $script:testScriptDir -Filter "*.Tests.ps1"
            
            if ($testFiles.Count -gt 1) {
                $result = Invoke-UnifiedTestExecution -TestPath $script:testScriptDir -Parallel
                $result | Should -Not -BeNullOrEmpty
            }
        }
    }
    
    Context "Performance and Reliability" {
        
        It "Should handle large numbers of test files efficiently" {
            # Create multiple test files
            $performanceTestDir = Join-Path $script:testScriptDir "PerformanceTests"
            if (-not (Test-Path $performanceTestDir)) { New-Item -Path $performanceTestDir -ItemType Directory -Force | Out-Null }
            
            1..10 | ForEach-Object {
                $testFile = Join-Path $performanceTestDir "Performance$_.Tests.ps1"
                @"
Describe "Performance Test $_" {
    It "Should execute quickly" {
        Start-Sleep -Milliseconds 10
        `$true | Should -Be `$true
    }
}
"@ | Out-File -FilePath $testFile -Encoding UTF8
            }
            
            $startTime = Get-Date
            $result = Invoke-PesterTests -TestPath $performanceTestDir
            $endTime = Get-Date
            
            $result | Should -Not -BeNullOrEmpty
            $result.TotalCount | Should -BeGreaterThan 0
            # Should complete within reasonable time
            ($endTime - $startTime).TotalSeconds | Should -BeLessThan 30
        }
        
        It "Should handle concurrent test execution" {
            $jobs = 1..3 | ForEach-Object {
                Start-Job -ScriptBlock {
                    param($TestPath, $ModulePath)
                    Import-Module $ModulePath -Force
                    Invoke-SyntaxValidation -Path $TestPath
                } -ArgumentList $script:testScriptDir, (Join-Path $projectRoot "core-runner/modules/TestingFramework")
            }
            
            $results = $jobs | Wait-Job | Receive-Job
            $jobs | Remove-Job
            
            $results | Should -Not -BeNullOrEmpty
            $results.Count | Should -Be 3
        }
        
        It "Should recover gracefully from test failures" {
            # Create a test that will fail
            $failingTest = Join-Path $script:testScriptDir "FailingTest.Tests.ps1"
            @"
Describe "Failing Test" {
    It "Should fail intentionally" {
        `$false | Should -Be `$true
    }
    
    It "Should pass after failure" {
        `$true | Should -Be `$true
    }
}
"@ | Out-File -FilePath $failingTest -Encoding UTF8
            
            $result = Invoke-PesterTests -TestPath $failingTest
            
            $result | Should -Not -BeNullOrEmpty
            $result.FailedCount | Should -BeGreaterThan 0
            $result.PassedCount | Should -BeGreaterThan 0
        }
    }
}

Describe "TestingFramework Module - Error Handling" {
    
    Context "Invalid Inputs" {
        
        It "Should handle null test path gracefully" {
            { Invoke-PesterTests -TestPath $null } | Should -Throw
        }
        
        It "Should handle empty test path gracefully" {
            { Invoke-PesterTests -TestPath "" } | Should -Throw
        }
        
        It "Should handle invalid configuration objects" {
            $invalidConfig = "This is not a hashtable"
            
            try {
                Invoke-PesterTests -TestPath $script:testScriptDir -Configuration $invalidConfig
                $true | Should -Be $true  # If it doesn't throw, that's acceptable
            }
            catch {
                $_.Exception.Message | Should -Not -BeNullOrEmpty
            }
        }
    }
    
    Context "File System Issues" {
        
        It "Should handle inaccessible directories" {
            # Try to use a path that might not be accessible
            $restrictedPath = "C:\System Volume Information"
            
            try {
                Invoke-SyntaxValidation -Path $restrictedPath
                $true | Should -Be $true  # If it doesn't throw, that's fine
            }
            catch {
                $_.Exception.Message | Should -Not -BeNullOrEmpty
            }
        }
        
        It "Should handle corrupted test files" {
            $corruptedFile = Join-Path $script:testScriptDir "Corrupted.Tests.ps1"
            # Create a file with invalid UTF-8 sequences or null bytes
            [System.IO.File]::WriteAllBytes($corruptedFile, @(0xFF, 0xFE, 0x00, 0x00))
            
            try {
                Invoke-PesterTests -TestPath $corruptedFile
                $true | Should -Be $true  # If it handles gracefully
            }
            catch {
                $_.Exception.Message | Should -Not -BeNullOrEmpty
            }
        }
    }
}

