# GitHub Copilot Test Generation Instructions

## Test Framework Standards

Use **Pester 5.x** for all PowerShell tests with the following structure:

```powershell
#Requires -Module Pester
BeforeAll {
    # Import modules under test
    Import-Module "$PSScriptRoot/../modules/PatchManager/" -Force
    Import-Module "$PSScriptRoot/../modules/CodeFixer/" -Force
}

Describe "ModuleName" {
    Context "Function Tests" {
        It "Should perform expected operation" {
            # Arrange
            $testConfig = @{ Property = "Value" }
            
            # Act
            $result = Invoke-Function -Config $testConfig
            
            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Status | Should -Be "Success"
        }
    }
    
    Context "Error Handling" {
        It "Should handle invalid input gracefully" {
            { Invoke-Function -Config $null } | Should -Throw
        }
    }
}
```

## Test Categories

### Unit Tests

- Test individual functions in isolation
- Mock external dependencies
- Focus on single responsibility
- File pattern: `*.Tests.ps1`

### Integration Tests

- Test module interactions
- Use real dependencies where appropriate
- Validate cross-module functionality
- File pattern: `*.Integration.Tests.ps1`

### System Tests

- End-to-end scenarios
- Full environment testing
- Cross-platform validation
- File pattern: `*.System.Tests.ps1`

## Test Data Management

```powershell
BeforeAll {
    $script:TestDataPath = "$PSScriptRoot/TestData"
    $script:TestConfig = @{
        ProjectRoot = (Get-Item $PSScriptRoot).Parent.FullName
        TempPath = Join-Path $env:TEMP "PatchManagerTests"
        MockData = @{
            Files = @("test1.ps1", "test2.py", "test3.tf")
            Branches = @("main", "develop", "feature/test")
        }
    }
}

AfterAll {
    # Cleanup test artifacts
    if (Test-Path $script:TestConfig.TempPath) {
        Remove-Item $script:TestConfig.TempPath -Recurse -Force
    }
}
```

## Mock Patterns

```powershell
BeforeEach {
    Mock Write-Host { }
    Mock git { return "success" } -ParameterFilter { $args[0] -eq "status" }
    Mock Test-Path { return $true } -ParameterFilter { $Path -like "*valid*" }
}
```

## Test Validation Rules

1. **Always include negative test cases**
2. **Test parameter validation**
3. **Verify error handling**
4. **Check return values and types**
5. **Validate side effects**

## Cross-Platform Test Considerations

```powershell
It "Should work on all platforms" {
    if ($IsWindows) {
        # Windows-specific assertions
    } elseif ($IsLinux) {
        # Linux-specific assertions
    } elseif ($IsMacOS) {
        # macOS-specific assertions
    }
}
```

## Performance Testing

```powershell
It "Should complete within acceptable time" {
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    $result = Invoke-Function -Config $testConfig
    
    $stopwatch.Stop()
    $stopwatch.ElapsedMilliseconds | Should -BeLessThan 1000
}
```

## Test Documentation

Include test descriptions that clearly state:

- **What** is being tested
- **Expected** behavior
- **Conditions** under which the test runs

Example:

```powershell
It "Should create backup before applying patches when BackupEnabled is true" {
    # Test validates that backup creation is triggered
    # when the BackupEnabled configuration is set to true
}
```
