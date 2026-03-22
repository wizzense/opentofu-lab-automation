# State-of-the-Art Testing Patterns Guide

## Overview

This guide provides modern, state-of-the-art testing patterns for the OpenTofu Lab Automation project using Pester 5.7.1+.

## Table of Contents

1. [Test Structure Best Practices](#test-structure-best-practices)
2. [Parameterized Tests](#parameterized-tests)
3. [Advanced Mocking Patterns](#advanced-mocking-patterns)
4. [Edge Case Testing](#edge-case-testing)
5. [Performance Testing](#performance-testing)
6. [Test Data Builders](#test-data-builders)
7. [Integration Testing Patterns](#integration-testing-patterns)

## Test Structure Best Practices

### AAA Pattern (Arrange-Act-Assert)

Always structure tests using the AAA pattern for clarity:

```powershell
Describe "Module-FunctionName" {
    Context "When function receives valid input" {
        It "Should return expected result" {
            # Arrange - Set up test conditions
            $input = "test-value"
            $expected = "expected-result"
            
            # Act - Execute the function
            $result = Invoke-Function -Input $input
            
            # Assert - Verify expected outcomes
            $result | Should -Be $expected
        }
    }
}
```

### BeforeAll/BeforeEach/AfterEach/AfterAll

Use lifecycle hooks appropriately:

```powershell
Describe "Module Tests" {
    BeforeAll {
        # Run once before all tests in this Describe block
        $projectRoot = $env:PROJECT_ROOT
        Import-Module "$projectRoot/core-runner/modules/TestingFramework" -Force
        
        # Create shared test resources
        $script:testConfig = @{
            Setting1 = "Value1"
            Setting2 = "Value2"
        }
    }
    
    BeforeEach {
        # Run before each test
        $script:testData = @{
            Timestamp = Get-Date
            TestId = [guid]::NewGuid()
        }
    }
    
    AfterEach {
        # Clean up after each test
        if ($script:testData) {
            Remove-Variable -Name testData -Scope Script -ErrorAction SilentlyContinue
        }
    }
    
    AfterAll {
        # Run once after all tests
        Remove-Module TestingFramework -Force -ErrorAction SilentlyContinue
    }
}
```

## Parameterized Tests

### Data-Driven Testing with TestCases

Use `-TestCases` for parameterized tests to reduce duplication:

```powershell
Describe "Input Validation" {
    It "Should validate <Description>" -TestCases @(
        @{ Description = "valid email"; Input = "test@example.com"; Expected = $true }
        @{ Description = "invalid email"; Input = "invalid-email"; Expected = $false }
        @{ Description = "empty string"; Input = ""; Expected = $false }
        @{ Description = "null value"; Input = $null; Expected = $false }
        @{ Description = "whitespace"; Input = "   "; Expected = $false }
    ) {
        param($Description, $Input, $Expected)
        
        $result = Test-EmailAddress -Email $Input
        $result | Should -Be $Expected
    }
}
```

### Complex Test Cases

For more complex scenarios:

```powershell
Describe "Module Configuration" {
    BeforeAll {
        $testCases = @(
            @{
                Name = "Minimal Configuration"
                Config = @{ Name = "Test"; Version = "1.0" }
                ExpectedValid = $true
                ExpectedWarnings = 0
            }
            @{
                Name = "Full Configuration"
                Config = @{
                    Name = "Test"
                    Version = "1.0"
                    Author = "Team"
                    Description = "Test module"
                }
                ExpectedValid = $true
                ExpectedWarnings = 0
            }
            @{
                Name = "Missing Required Field"
                Config = @{ Version = "1.0" }
                ExpectedValid = $false
                ExpectedWarnings = 1
            }
        )
    }
    
    It "Should handle <Name>" -TestCases $testCases {
        param($Name, $Config, $ExpectedValid, $ExpectedWarnings)
        
        $result = Test-ModuleConfiguration -Config $Config
        
        $result.IsValid | Should -Be $ExpectedValid
        $result.Warnings.Count | Should -Be $ExpectedWarnings
    }
}
```

## Advanced Mocking Patterns

### Scoped Mocks

Use mocks within appropriate scopes:

```powershell
Describe "External Dependency Tests" {
    BeforeAll {
        # Module-level mock
        Mock Write-CustomLog { } -ModuleName "LabRunner"
    }
    
    Context "When API call succeeds" {
        BeforeAll {
            # Context-level mock
            Mock Invoke-RestMethod {
                return @{
                    StatusCode = 200
                    Data = @{ Result = "Success" }
                }
            }
        }
        
        It "Should process API response correctly" {
            $result = Get-ExternalData -Endpoint "https://api.example.com"
            
            $result.Result | Should -Be "Success"
            Should -Invoke Invoke-RestMethod -Times 1 -Exactly
        }
    }
    
    Context "When API call fails" {
        BeforeAll {
            Mock Invoke-RestMethod {
                throw "Network error"
            }
        }
        
        It "Should handle API failure gracefully" {
            { Get-ExternalData -Endpoint "https://api.example.com" } | Should -Throw "Network error"
            Should -Invoke Invoke-RestMethod -Times 1 -Exactly
        }
    }
}
```

### Partial Mocking

Mock specific parameter combinations:

```powershell
Describe "Selective Mocking" {
    BeforeAll {
        # Mock specific calls only
        Mock Invoke-WebRequest -ParameterFilter {
            $Uri -like "*/api/test*"
        } {
            return @{
                StatusCode = 200
                Content = '{"status":"ok"}'
            }
        }
        
        # Different mock for other calls
        Mock Invoke-WebRequest -ParameterFilter {
            $Uri -like "*/api/prod*"
        } {
            return @{
                StatusCode = 403
                Content = '{"error":"forbidden"}'
            }
        }
    }
    
    It "Should use test endpoint successfully" {
        $result = Invoke-WebRequest -Uri "https://example.com/api/test/data"
        $result.StatusCode | Should -Be 200
    }
    
    It "Should fail on prod endpoint" {
        $result = Invoke-WebRequest -Uri "https://example.com/api/prod/data"
        $result.StatusCode | Should -Be 403
    }
}
```

### Mock Verification

Verify mock calls with detailed assertions:

```powershell
It "Should call external service with correct parameters" {
    Mock Invoke-RestMethod { return @{ Status = "OK" } }
    
    $result = Send-DataToAPI -Data @{ Key = "Value" } -Retry 3
    
    Should -Invoke Invoke-RestMethod -Times 1 -Exactly -ParameterFilter {
        $Uri -eq "https://api.example.com/data" -and
        $Method -eq "POST" -and
        $Body.Key -eq "Value"
    }
}
```

## Edge Case Testing

### Boundary Value Analysis

Test boundaries explicitly:

```powershell
Describe "Boundary Value Testing" {
    Context "When testing numeric ranges" {
        It "Should handle minimum value" -TestCases @(
            @{ Value = 0; Expected = $true }
            @{ Value = -1; Expected = $false }
        ) {
            param($Value, $Expected)
            $result = Test-PositiveNumber -Number $Value
            $result | Should -Be $Expected
        }
        
        It "Should handle maximum value" -TestCases @(
            @{ Value = 100; Expected = $true }
            @{ Value = 101; Expected = $false }
        ) {
            param($Value, $Expected)
            $result = Test-WithinRange -Number $Value -Max 100
            $result | Should -Be $Expected
        }
    }
}
```

### Null and Empty Handling

Comprehensive null/empty tests:

```powershell
Describe "Null and Empty Handling" {
    Context "When processing input" {
        It "Should handle <InputType> appropriately" -TestCases @(
            @{ InputType = "null"; Input = $null; ShouldThrow = $true }
            @{ InputType = "empty string"; Input = ""; ShouldThrow = $true }
            @{ InputType = "whitespace"; Input = "   "; ShouldThrow = $true }
            @{ InputType = "empty array"; Input = @(); ShouldThrow = $true }
            @{ InputType = "empty hashtable"; Input = @{}; ShouldThrow = $true }
            @{ InputType = "valid data"; Input = "data"; ShouldThrow = $false }
        ) {
            param($InputType, $Input, $ShouldThrow)
            
            if ($ShouldThrow) {
                { Process-Input -Data $Input } | Should -Throw
            } else {
                { Process-Input -Data $Input } | Should -Not -Throw
            }
        }
    }
}
```

### Concurrent Access Tests

Test thread safety:

```powershell
Describe "Thread Safety" {
    It "Should handle concurrent access safely" {
        $jobs = 1..10 | ForEach-Object {
            Start-Job -ScriptBlock {
                param($Id)
                Add-ItemToCache -Key "item$Id" -Value "value$Id"
            } -ArgumentList $_
        }
        
        $jobs | Wait-Job | Receive-Job
        $jobs | Remove-Job
        
        $cacheCount = Get-CacheItemCount
        $cacheCount | Should -Be 10
    }
}
```

## Performance Testing

### Execution Time Benchmarks

Test performance with baselines:

```powershell
Describe "Performance Benchmarks" {
    It "Should complete within acceptable time" {
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        
        Invoke-ExpensiveOperation -InputSize 1000
        
        $stopwatch.Stop()
        $stopwatch.ElapsedMilliseconds | Should -BeLessThan 5000
    }
    
    It "Should scale linearly" {
        $baseline = Measure-Command { 
            Invoke-ScalableOperation -Size 100 
        }
        
        $scaled = Measure-Command { 
            Invoke-ScalableOperation -Size 1000 
        }
        
        # Should be roughly 10x (with 20% tolerance)
        $ratio = $scaled.TotalMilliseconds / $baseline.TotalMilliseconds
        $ratio | Should -BeGreaterThan 8
        $ratio | Should -BeLessThan 12
    }
}
```

### Memory Usage Tests

```powershell
It "Should not leak memory" {
    $beforeMem = [System.GC]::GetTotalMemory($true)
    
    1..100 | ForEach-Object {
        $data = Get-LargeDataSet
        Process-Data $data
    }
    
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
    
    $afterMem = [System.GC]::GetTotalMemory($true)
    $memIncrease = $afterMem - $beforeMem
    
    # Memory increase should be minimal (< 10MB)
    $memIncrease | Should -BeLessThan 10MB
}
```

## Test Data Builders

### Builder Pattern for Complex Objects

```powershell
class TestConfigurationBuilder {
    [hashtable] $Config = @{}
    
    [TestConfigurationBuilder] WithName([string] $name) {
        $this.Config.Name = $name
        return $this
    }
    
    [TestConfigurationBuilder] WithVersion([string] $version) {
        $this.Config.Version = $version
        return $this
    }
    
    [TestConfigurationBuilder] WithDefaults() {
        $this.Config = @{
            Name = "TestModule"
            Version = "1.0.0"
            Author = "Test Team"
            Description = "Test module"
        }
        return $this
    }
    
    [hashtable] Build() {
        return $this.Config
    }
}

Describe "Using Test Builders" {
    It "Should handle minimal config" {
        $config = [TestConfigurationBuilder]::new().
            WithName("MinimalModule").
            WithVersion("0.1.0").
            Build()
        
        $result = Test-Configuration $config
        $result.IsValid | Should -Be $true
    }
    
    It "Should handle full config" {
        $config = [TestConfigurationBuilder]::new().
            WithDefaults().
            Build()
        
        $result = Test-Configuration $config
        $result.IsValid | Should -Be $true
        $result.Warnings.Count | Should -Be 0
    }
}
```

## Integration Testing Patterns

### Multi-Step Workflows

```powershell
Describe "End-to-End Workflow" {
    BeforeAll {
        # Set up test environment
        $script:testWorkspace = Join-Path $TestDrive "workspace"
        New-Item -Path $script:testWorkspace -ItemType Directory -Force
    }
    
    It "Should complete full workflow successfully" {
        # Step 1: Initialize
        $initResult = Initialize-Project -Path $script:testWorkspace
        $initResult.Success | Should -Be $true
        
        # Step 2: Configure
        $config = @{ Setting = "Value" }
        $configResult = Set-ProjectConfiguration -Path $script:testWorkspace -Config $config
        $configResult.Success | Should -Be $true
        
        # Step 3: Build
        $buildResult = Build-Project -Path $script:testWorkspace
        $buildResult.Success | Should -Be $true
        
        # Step 4: Validate
        $validateResult = Test-ProjectBuild -Path $script:testWorkspace
        $validateResult.AllTestsPassed | Should -Be $true
    }
    
    AfterAll {
        # Clean up
        Remove-Item -Path $script:testWorkspace -Recurse -Force -ErrorAction SilentlyContinue
    }
}
```

### Service Integration Tests

```powershell
Describe "Service Integration" -Tag "Integration" {
    BeforeAll {
        # Start test service
        $script:serviceProcess = Start-TestService -Port 8080
        Start-Sleep -Seconds 2 # Wait for service to start
    }
    
    It "Should communicate with service" {
        $response = Invoke-RestMethod -Uri "http://localhost:8080/api/health"
        $response.Status | Should -Be "healthy"
    }
    
    It "Should handle service errors gracefully" {
        $result = Invoke-ServiceOperation -Endpoint "/invalid"
        $result.Error | Should -Not -BeNullOrEmpty
    }
    
    AfterAll {
        # Stop test service
        if ($script:serviceProcess) {
            Stop-Process -Id $script:serviceProcess.Id -Force
        }
    }
}
```

## Best Practices Summary

✅ **DO:**
- Use descriptive test names that explain the scenario
- Follow AAA pattern (Arrange-Act-Assert)
- Use parameterized tests for multiple similar cases
- Mock external dependencies
- Test error conditions explicitly
- Clean up test resources in AfterEach/AfterAll
- Use TestDrive for file system tests
- Verify mock calls with Should -Invoke
- Test boundary values and edge cases
- Add performance benchmarks for critical operations

❌ **DON'T:**
- Test implementation details, test behavior
- Share state between tests
- Use hardcoded paths or values
- Forget to clean up resources
- Skip error case testing
- Ignore flaky tests
- Mock too much (over-mocking)
- Create dependencies between tests
- Use Thread.Sleep (use proper waits)
- Ignore performance implications

## Coverage Goals

- **Minimum**: 70% code coverage
- **Target**: 80% code coverage
- **Excellent**: 90%+ code coverage

Focus on:
1. Critical business logic: 100%
2. Error handling paths: 90%+
3. Edge cases: 80%+
4. Happy paths: 100%

## Additional Resources

- [Pester Documentation](https://pester.dev/docs/quick-start)
- [PSScriptAnalyzer Rules](https://github.com/PowerShell/PSScriptAnalyzer)
- [PowerShell Best Practices](https://docs.microsoft.com/en-us/powershell/scripting/developer/cmdlet/cmdlet-development-guidelines)
