# TestingFramework Module

Enhanced unified testing framework serving as central orchestrator for all testing activities with module integration, parallel execution, and comprehensive reporting.

## Overview

The TestingFramework module (v2.0) is the central testing orchestrator for OpenTofu Lab Automation. It provides unified test execution, parallel processing, comprehensive reporting, and integration with multiple test types including Pester, pytest, and syntax validation.

## Features

- **Unified test execution** - Single interface for all test types
- **Parallel test execution** - Run tests concurrently for speed
- **Multiple test providers** - Pester, pytest, syntax validation
- **Comprehensive reporting** - NUnitXml, VSCode integration, custom formats
- **Test discovery** - Automatic test file discovery
- **Event system** - Subscribe to test events for custom handling
- **Module integration** - Test all project modules systematically
- **CI/CD ready** - Designed for automation pipelines

## Installation

```powershell
Import-Module "./core-runner/modules/TestingFramework" -Force
```

## Core Functions

### Invoke-UnifiedTestExecution

Main entry point for all test execution.

```powershell
# Run all tests
Invoke-UnifiedTestExecution

# Run specific test suite
Invoke-UnifiedTestExecution -TestSuite "Unit"

# Run with parallel execution
Invoke-UnifiedTestExecution -TestSuite "All" -EnableParallel

# Generate detailed report
Invoke-UnifiedTestExecution -TestSuite "Integration" -OutputFormat "NUnitXml" -OutputFile "./results/tests.xml"

# CI mode (no interactive prompts)
Invoke-UnifiedTestExecution -TestSuite "All" -CI -EnableParallel
```

**Test Suites:**
- **Unit**: Unit tests only
- **Integration**: Integration tests only
- **All**: All test types
- **Quick**: Fast smoke tests
- **Module**: Module-specific tests

### Invoke-ParallelTestExecution

Runs tests in parallel using runspaces.

```powershell
# Parallel test execution
Invoke-ParallelTestExecution -TestPaths @(
    "./tests/unit/module1.Tests.ps1"
    "./tests/unit/module2.Tests.ps1"
    "./tests/unit/module3.Tests.ps1"
) -MaxThreads 4

# With custom configuration
Invoke-ParallelTestExecution -TestPaths $testFiles -Configuration $pesterConfig
```

### Invoke-SequentialTestExecution

Runs tests sequentially when parallel isn't suitable.

```powershell
# Sequential execution for tests that can't run in parallel
Invoke-SequentialTestExecution -TestPaths @(
    "./tests/integration/database.Tests.ps1"
    "./tests/integration/network.Tests.ps1"
)
```

## Test Discovery Functions

### Get-DiscoveredModules

Discovers all modules in the project.

```powershell
# Discover all modules
$modules = Get-DiscoveredModules -ModulePath "./core-runner/modules"

# Discover with filtering
$coreModules = Get-DiscoveredModules -ModulePath "./modules" -Filter "Core*"
```

### New-TestExecutionPlan

Creates a test execution plan.

```powershell
# Generate test plan
$plan = New-TestExecutionPlan -TestSuite "Unit" -EnableParallel $true

# Review plan
$plan.TestGroups | ForEach-Object {
    Write-Host "Group: $($_.Name), Tests: $($_.Tests.Count)"
}

# Execute plan
$results = & $plan.ExecutionScript
```

## Configuration Functions

### Get-TestConfiguration

Retrieves test configuration.

```powershell
# Get default configuration
$config = Get-TestConfiguration

# Get custom configuration
$config = Get-TestConfiguration -ConfigPath "./custom-pester.config.ps1"

# Access settings
$outputPath = $config.Output.Path
$verbosity = $config.Output.Verbosity
```

## Test Provider Functions

### Invoke-PesterTests

Runs Pester tests with project configuration.

```powershell
# Run Pester tests
$results = Invoke-PesterTests -Path "./tests/unit"

# Run with custom configuration
$results = Invoke-PesterTests -Path "./tests" -Configuration $pesterConfig

# Run specific test file
$results = Invoke-PesterTests -Path "./tests/unit/MyModule.Tests.ps1"
```

### Invoke-PytestTests

Runs Python pytest tests.

```powershell
# Run pytest tests
$results = Invoke-PytestTests -Path "./tests/python"

# Run with specific markers
$results = Invoke-PytestTests -Path "./tests" -Markers "integration"

# Generate coverage
$results = Invoke-PytestTests -Path "./tests" -Coverage
```

### Invoke-SyntaxValidation

Validates PowerShell script syntax.

```powershell
# Validate all scripts
$results = Invoke-SyntaxValidation -Path "./core-runner"

# Validate specific file
$results = Invoke-SyntaxValidation -Path "./MyScript.ps1"

# Get detailed error information
if ($results.Errors.Count -gt 0) {
    $results.Errors | ForEach-Object {
        Write-Error "Syntax error in $($_.File): $($_.Message)"
    }
}
```

### Invoke-ParallelTests

Wrapper for parallel test execution with automatic provider detection.

```powershell
# Run tests in parallel (auto-detects Pester vs pytest)
Invoke-ParallelTests -TestPath "./tests" -MaxThreads 4
```

## Reporting Functions

### New-TestReport

Generates test reports in various formats.

```powershell
# Generate NUnitXml report
New-TestReport -Results $testResults -Format "NUnitXml" -OutputPath "./results/report.xml"

# Generate HTML report
New-TestReport -Results $testResults -Format "HTML" -OutputPath "./results/report.html"

# Generate JSON report
New-TestReport -Results $testResults -Format "JSON" -OutputPath "./results/report.json"
```

### Export-VSCodeTestResults

Exports results for VS Code Test Explorer.

```powershell
# Export for VS Code
Export-VSCodeTestResults -Results $testResults -OutputPath "./results/vscode-tests.json"
```

## Event System Functions

### Publish-TestEvent

Publishes test events for subscribers.

```powershell
# Publish test started event
Publish-TestEvent -EventType "TestStarted" -Data @{
    TestName = "MyModule Tests"
    StartTime = Get-Date
}

# Publish test completed event
Publish-TestEvent -EventType "TestCompleted" -Data @{
    TestName = "MyModule Tests"
    Result = "Passed"
    Duration = $duration
}
```

### Subscribe-TestEvent

Subscribes to test events.

```powershell
# Subscribe to test events
Subscribe-TestEvent -EventType "TestStarted" -Handler {
    param($Data)
    Write-Host "Test started: $($Data.TestName)"
}

# Subscribe to all events
Subscribe-TestEvent -EventType "*" -Handler {
    param($Data)
    # Log all test events
}
```

### Get-TestEvents

Retrieves test event history.

```powershell
# Get all events
$events = Get-TestEvents

# Get events by type
$startEvents = Get-TestEvents -EventType "TestStarted"

# Get recent events
$recentEvents = Get-TestEvents -Since (Get-Date).AddMinutes(-10)
```

## Provider Registration Functions

### Register-TestProvider

Registers custom test providers.

```powershell
# Register custom provider
Register-TestProvider -Name "CustomTests" -ExecutionScript {
    param($TestPath, $Configuration)
    # Custom test execution logic
} -DiscoveryScript {
    param($Path)
    # Custom test discovery logic
}
```

### Get-RegisteredTestProviders

Lists all registered test providers.

```powershell
# Get all providers
$providers = Get-RegisteredTestProviders

# Display providers
$providers | ForEach-Object {
    Write-Host "Provider: $($_.Name)"
}
```

## Usage Examples

### Basic Test Execution

```powershell
# Import module
Import-Module "./core-runner/modules/TestingFramework" -Force

# Run all tests
$results = Invoke-UnifiedTestExecution -TestSuite "All"

# Check results
if ($results.FailedCount -gt 0) {
    Write-Error "Tests failed: $($results.FailedCount) failures"
    exit 1
} else {
    Write-Host "All tests passed!" -ForegroundColor Green
}
```

### Parallel Test Execution

```powershell
# Run tests in parallel for speed
$results = Invoke-UnifiedTestExecution -TestSuite "Unit" -EnableParallel -MaxThreads 4

Write-Host "Executed $($results.TotalCount) tests in $($results.Duration) seconds"
```

### CI/CD Integration

```powershell
# CI-friendly execution
$results = Invoke-UnifiedTestExecution `
    -TestSuite "All" `
    -CI `
    -EnableParallel `
    -OutputFormat "NUnitXml" `
    -OutputFile "./test-results/results.xml"

# Exit with appropriate code
exit $results.FailedCount
```

### Module Testing

```powershell
# Test all modules
$modules = Get-DiscoveredModules -ModulePath "./core-runner/modules"

foreach ($module in $modules) {
    Write-Host "Testing module: $($module.Name)"
    
    $testPath = "./tests/unit/modules/$($module.Name).Tests.ps1"
    if (Test-Path $testPath) {
        $results = Invoke-PesterTests -Path $testPath
        
        if ($results.FailedCount -gt 0) {
            Write-Warning "Module $($module.Name) has failing tests"
        }
    }
}
```

### Custom Test Reporting

```powershell
# Subscribe to test events for custom reporting
Subscribe-TestEvent -EventType "TestCompleted" -Handler {
    param($Data)
    
    # Send notification
    if ($Data.Result -eq "Failed") {
        Send-Notification -Message "Test failed: $($Data.TestName)"
    }
}

# Run tests (events will be published)
Invoke-UnifiedTestExecution -TestSuite "All"
```

## Integration with VS Code

The module integrates with VS Code tasks:

```json
{
    "label": "Run All Tests",
    "type": "shell",
    "command": "pwsh -File tests/Run-AllModuleTests.ps1 -Parallel",
    "group": "test"
}
```

## Configuration Files

TestingFramework uses:

- `./tests/config/PesterConfiguration.psd1` - Pester settings
- `./tests/config/BulletproofConfiguration.psd1` - Enhanced config
- `./pytest.ini` - Python test configuration

## Test Result Formats

Supported output formats:

- **NUnitXml**: Industry standard, CI/CD compatible
- **HTML**: Human-readable reports
- **JSON**: Programmatic analysis
- **VSCode**: Test Explorer integration
- **Console**: Terminal output

## Best Practices

1. **Use Invoke-UnifiedTestExecution** as your main entry point
2. **Enable parallel execution** for faster test runs
3. **Generate reports** for CI/CD integration
4. **Subscribe to events** for custom notifications
5. **Test modules systematically** using Get-DiscoveredModules
6. **Validate syntax** before running tests
7. **Use CI mode** in automation pipelines

## Testing Integration

Run the framework's own tests:

```powershell
# Test the testing framework
pwsh -File "./tests/unit/modules/TestingFramework.Tests.ps1"

# Run bulletproof tests
pwsh -File "./tests/Run-BulletproofTests.ps1" -TestSuite "All"
```

## Troubleshooting

### Parallel tests fail
- Check MaxThreads setting (reduce if system is overloaded)
- Verify tests don't have shared state dependencies
- Review logs for runspace errors

### Test discovery fails
- Verify test file naming: `*.Tests.ps1`
- Check test file location is in `./tests/`
- Ensure Pester test structure is correct

### Reports not generated
- Verify output directory exists
- Check permissions on output path
- Ensure correct format specified

## Version History

- **2.0.0**: Enhanced unified framework with parallel execution and comprehensive reporting
- **1.0.0**: Initial release with basic test execution

## Related Modules

- [Logging](../Logging/) - Used for all test execution logging
- [ParallelExecution](../ParallelExecution/) - Advanced parallel processing
- [LabRunner](../LabRunner/) - Lab automation integration
- [UnifiedMaintenance](../UnifiedMaintenance/) - Maintenance workflows

## Contributing

When adding testing features:

1. Maintain provider abstraction for extensibility
2. Support both parallel and sequential execution
3. Include comprehensive event publishing
4. Test on multiple platforms
5. Update this README and test documentation
