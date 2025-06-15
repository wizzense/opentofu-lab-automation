---
description: Create comprehensive Pester tests for PowerShell scripts in the OpenTofu Lab Automation project
mode: agent
tools: ["filesystem", "powershell"]
---

# Generate Pester Tests

Create comprehensive Pester test files that follow the OpenTofu Lab Automation testing standards and patterns.

## Requirements

Generate Pester tests that include:

1. **Standard test structure**:
   - TestHelpers integration
   - Proper Describe/Context/It organization
   - BeforeAll/AfterAll setup and cleanup

2. **Comprehensive test coverage**:
   - Module loading tests
   - Parameter validation tests
   - Functionality tests
   - Error handling tests
   - Integration tests

3. **Proper mocking**:
   - Mock external dependencies
   - Mock LabRunner functions when appropriate
   - Use standardized mock patterns

4. **Performance testing**:
   - Include execution time limits
   - Test parallel processing when applicable

5. **Cross-platform considerations**:
   - Platform-specific test scenarios
   - Path handling validation

## Template Structure

```powershell
# Test file header - REQUIRED
. (Join-Path $PSScriptRoot 'helpers' 'TestHelpers.ps1')

Describe '${input:scriptName} Tests' {
    BeforeAll {
        # Test setup
        $script:TestScript = Join-Path $PSScriptRoot ".." "path" "to" "${input:scriptName}.ps1"
        $script:TestConfig = [pscustomobject]@{
            # Test configuration
        }
        
        # Verify test script exists
        $script:TestScript | Should -Exist
    }
    
    Context 'Module and Dependencies' {
        It 'should load required modules' {
            Get-Module LabRunner | Should -Not -BeNullOrEmpty
        }
        
        It 'should have proper script structure' {
            $content = Get-Content $script:TestScript -Raw
            $content | Should -Match 'Param\s*\(\s*.*\$Config'
            $content | Should -Match 'Import-Module.*LabRunner'
            $content | Should -Match 'Invoke-LabStep'
        }
    }
    
    Context 'Parameter Validation' {
        It 'should require Config parameter' {
            { & $script:TestScript } | Should -Throw "*Config*"
        }
        
        It 'should validate Config type' {
            { & $script:TestScript -Config "invalid" } | Should -Throw
        }
    }
    
    Context 'Functionality Tests' {
        BeforeEach {
            # Setup mocks for each test
            Mock Write-CustomLog {} -ModuleName LabRunner
            Mock Invoke-LabStep { 
                & $Args[1] # Execute the script block
            } -ModuleName LabRunner
        }
        
        It 'should execute without errors with valid config' {
            { & $script:TestScript -Config $script:TestConfig } | Should -Not -Throw
        }
        
        It 'should call expected LabRunner functions' {
            & $script:TestScript -Config $script:TestConfig
            Should -Invoke Invoke-LabStep -ModuleName LabRunner -Times 1
        }
    }
    
    Context 'Error Handling' {
        It 'should handle configuration errors gracefully' {
            $badConfig = [pscustomobject]@{ Invalid = $null }
            # Test error handling based on script requirements
        }
    }
    
    Context 'Performance' {
        It 'should complete within acceptable time' {
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            & $script:TestScript -Config $script:TestConfig
            $stopwatch.Stop()
            $stopwatch.ElapsedMilliseconds | Should -BeLessThan 10000  # 10 seconds
        }
    }
    
    Context 'Integration Tests' {
        It 'should integrate with CodeFixer when available' {
            if (Get-Module -ListAvailable CodeFixer) {
                # Test CodeFixer integration
            }
        }
    }
    
    AfterAll {
        # Cleanup test resources
        Remove-Variable -Name TestScript, TestConfig -Scope Script -ErrorAction SilentlyContinue
    }
}
```

## Test Scenarios

Include various test scenarios based on script functionality:

```powershell
# Example scenario testing
$testScenarios = @(
    @{
        Name = "Valid Configuration"
        Config = [pscustomobject]@{ Property = "ValidValue" }
        ShouldSucceed = $true
    },
    @{
        Name = "Missing Required Property"
        Config = [pscustomobject]@{ }
        ShouldSucceed = $false
        ExpectedError = "*required*"
    }
)

foreach ($scenario in $testScenarios) {
    Context "Scenario: $($scenario.Name)" {
        It "should handle scenario correctly" {
            if ($scenario.ShouldSucceed) {
                { & $script:TestScript -Config $scenario.Config } | Should -Not -Throw
            } else {
                { & $script:TestScript -Config $scenario.Config } | Should -Throw $scenario.ExpectedError
            }
        }
    }
}
```

## Input Variables

- `${input:scriptName}`: Name of the script being tested (without .ps1)
- `${input:scriptPath}`: Relative path to the script from the test file
- `${input:requirements}`: Specific testing requirements or scenarios

## Reference Instructions

This prompt references:
- [Testing Standards](../instructions/testing-standards.instructions.md)
- [PowerShell Standards](../instructions/powershell-standards.instructions.md)

Please provide:
1. The script name to test
2. The relative path to the script
3. Any specific testing requirements or scenarios
4. Expected parameters and behavior
