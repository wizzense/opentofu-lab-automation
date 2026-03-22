# Testing Quick Reference Guide

## 🚀 Quick Start

### Run Tests Locally

```powershell
# Quick validation (fastest - recommended for development)
pwsh -File "./tests/Run-BulletproofTests.ps1" -TestSuite "Quick"

# Run all tests
pwsh -File "./tests/Run-BulletproofTests.ps1" -TestSuite "All"

# Run module tests
pwsh -File "./tests/Run-AllModuleTests.ps1"

# Run specific module tests
pwsh -File "./tests/Run-AllModuleTests.ps1" -ModuleName "LabRunner"

# Run tests with coverage
pwsh -File "./tests/Run-BulletproofTests.ps1" -TestSuite "All" -GenerateReport
```

### Before Committing

```powershell
# 1. Run quick tests
pwsh -File "./tests/Run-BulletproofTests.ps1" -TestSuite "Quick" -CI

# 2. Check code quality
Invoke-ScriptAnalyzer -Path . -Recurse -Settings './tests/config/PSScriptAnalyzerSettings.psd1' -Severity Error,Warning

# 3. Fix code quality issues (optional)
pwsh -File "./tests/helpers/Invoke-CodeQualityFixes.ps1" -Path "core-runner/modules"
```

## 📝 Writing New Tests

### 1. Use the AAA Pattern

```powershell
It "Should do something" {
    # Arrange - Set up test data
    $input = "test-value"
    
    # Act - Execute the function
    $result = Invoke-Function -Input $input
    
    # Assert - Verify the result
    $result | Should -Be "expected-value"
}
```

### 2. Parameterized Tests

```powershell
It "Should validate <Description>" -TestCases @(
    @{ Description = "valid input"; Input = "valid"; Expected = $true }
    @{ Description = "invalid input"; Input = ""; Expected = $false }
) {
    param($Description, $Input, $Expected)
    
    $result = Test-Input -Value $Input
    $result | Should -Be $Expected
}
```

### 3. Mock External Dependencies

```powershell
BeforeAll {
    Mock Write-CustomLog { }
    Mock Invoke-RestMethod { return @{ Status = "OK" } }
}

It "Should call mocked function" {
    $result = Get-Data
    Should -Invoke Invoke-RestMethod -Times 1 -Exactly
}
```

### 4. Test Error Conditions

```powershell
It "Should throw on null input" {
    { Invoke-Function -Input $null } | Should -Throw
}

It "Should throw with specific message" {
    { Invoke-Function -Input $null } | Should -Throw -ExpectedMessage "*cannot be null*"
}
```

## 🔧 Common Tasks

### Add a New Test File

1. Create file: `tests/unit/modules/YourModule/YourModule-Core.Tests.ps1`
2. Use template structure:

```powershell
#Requires -Version 7.0
#Requires -Modules Pester

BeforeAll {
    $projectRoot = $env:PROJECT_ROOT
    Import-Module "$projectRoot/core-runner/modules/YourModule" -Force
}

Describe "YourModule - Core Functions" {
    Context "YourFunction" {
        It "Should work correctly" {
            # Test implementation
        }
    }
}

AfterAll {
    Remove-Module YourModule -Force -ErrorAction SilentlyContinue
}
```

### Run Tests in VS Code

1. Press `Ctrl+Shift+P`
2. Type "Tasks: Run Task"
3. Select:
   - "Run All Pester Tests"
   - "Run Bulletproof Tests"
   - "Test Current Module"

### Debug a Failing Test

```powershell
# Run with verbose output
$config = New-PesterConfiguration
$config.Run.Path = "./tests/your-test.Tests.ps1"
$config.Output.Verbosity = "Detailed"
$config.Debug.ShowFullErrors = $true
Invoke-Pester -Configuration $config
```

## 📊 Coverage Goals

- **Minimum**: 70% code coverage
- **Target**: 80% code coverage  
- **Excellent**: 90%+ code coverage

Priority:
1. Critical business logic: 100%
2. Error handling: 90%+
3. Edge cases: 80%+
4. Happy paths: 100%

## ⚠️ Common Pitfalls

❌ **Don't:**
- Share state between tests
- Use hardcoded paths (`C:\temp\file.txt`)
- Forget to clean up test resources
- Test implementation details
- Create test dependencies

✅ **Do:**
- Use `$TestDrive` for file operations
- Mock external dependencies
- Use `BeforeEach`/`AfterEach` for cleanup
- Test behavior, not implementation
- Keep tests independent

## 🎯 Test Examples

See these files for examples:
- `tests/examples/StateOfTheArt-Patterns.Tests.ps1` - Modern patterns
- `tests/unit/modules/Logging/Logging-Core.Tests.ps1` - Module testing
- `tests/unit/modules/CoreApp/NonInteractiveMode.Tests.ps1` - Integration testing

## 📚 Documentation

- [Testing Patterns Guide](./TESTING-PATTERNS.md) - Comprehensive patterns
- [Testing Framework Evaluation](./TESTING-FRAMEWORK-EVALUATION.md) - Full analysis
- [Pester Documentation](https://pester.dev/docs/quick-start) - Official docs

## 🔍 Code Quality

### Check Your Code

```powershell
# Analyze specific file
Invoke-ScriptAnalyzer -Path "core-runner/modules/YourModule/YourModule.psm1"

# Analyze directory
Invoke-ScriptAnalyzer -Path "core-runner/modules/YourModule" -Recurse

# Use project settings
Invoke-ScriptAnalyzer -Path . -Recurse -Settings './tests/config/PSScriptAnalyzerSettings.psd1'
```

### Fix Common Issues

```powershell
# Auto-fix trailing whitespace and indentation
pwsh -File "./tests/helpers/Invoke-CodeQualityFixes.ps1" -Path "core-runner/modules"

# Preview changes without applying
pwsh -File "./tests/helpers/Invoke-CodeQualityFixes.ps1" -Path "core-runner/modules" -DryRun
```

## 🤖 CI/CD

### GitHub Actions

Tests run automatically on:
- Pull requests to main/develop
- Pushes to main/develop
- Manual workflow dispatch

**Jobs:**
1. **Code Quality** - PSScriptAnalyzer validation
2. **Unit Tests** - Cross-platform testing (Windows, Linux, macOS)
3. **Integration Tests** - End-to-end workflows
4. **Test Summary** - Consolidated results

### View Test Results

1. Go to PR or commit on GitHub
2. Click "Checks" tab
3. Select "Test Validation & Quality Assurance"
4. View detailed results and logs

## 💡 Tips

- Run tests frequently during development
- Use `-CI` flag for cleaner output
- Check test results in `tests/results/`
- Keep tests fast (unit tests < 5 min)
- Write tests before fixing bugs (TDD)
- Use descriptive test names
- One assertion per test (when possible)

## 🆘 Getting Help

- **Documentation**: Check `docs/` folder
- **Examples**: Review `tests/examples/`
- **Issues**: Create GitHub issue with `testing` label
- **Questions**: Ask in team channel

---

**Last Updated:** October 28, 2025  
**Maintained by:** Testing Guardian (Aisha Patel)
