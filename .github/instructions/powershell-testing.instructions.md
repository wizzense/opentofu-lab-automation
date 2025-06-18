---
applyTo: "**/*.Tests.ps1"
description: "PowerShell Pester testing guidelines"
---

# PowerShell Pester Testing Instructions

## Test Structure
- Use Describe-Context-It hierarchy
- Group related tests in Context blocks
- Use descriptive test names that explain the expected behavior

## Test Setup
- Use BeforeAll for expensive setup operations
- Use BeforeEach for test-specific setup
- Clean up resources in AfterAll/AfterEach blocks
- Use TestDrive for temporary file operations

## Assertions
- Use specific Should assertions rather than generic ones
- Test both positive and negative scenarios
- Include edge cases and boundary conditions
- Validate error messages and types

## Mocking
- Mock external dependencies and system calls
- Use proper parameter filters for mocks
- Verify mock calls with Assert-MockCalled
- Mock Write-CustomLog for logging tests

## Cross-Platform Considerations
- Test path separators and file operations
- Account for different PowerShell hosts
- Test environment variable access patterns
- Validate cross-platform command availability

## Additional Guidelines

### Performance Testing
- Include tests for long-running operations.
- Use `Measure-Command` to validate execution time.

### Dependency Management
- Use `#Requires -Module` for required modules.
- Validate module availability in BeforeAll blocks.

### Test Reporting
- Generate test reports in NUnitXml format for CI/CD integration.
- Use `Invoke-Pester` with a configuration file for consistent results.

### Examples

#### Mocking External Dependencies
```powershell
Mock Get-Content { return 'Mocked Content' } -ParameterFilter { $Path -eq 'test.txt' }
Assert-MockCalled Get-Content -Exactly 1 -Scope It
```

#### Validating Logging Behavior
```powershell
Mock Write-CustomLog { }
Write-CustomLog -Level 'INFO' -Message 'Test log message'
Assert-MockCalled Write-CustomLog -Exactly 1 -Scope It -ParameterFilter { $Level -eq 'INFO' -and $Message -eq 'Test log message' }
```
