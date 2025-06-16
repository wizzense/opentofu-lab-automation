# Automated Testing and Validation Workflow

## Overview

The OpenTofu Lab Automation project now includes a comprehensive automated testing and validation workflow that continuously builds, tests, and validates both Pester (PowerShell) and pytest (Python) components. This workflow is designed to integrate seamlessly with our PatchManager enforcement system and provides robust quality assurance for the core application.

## Key Components

### 1. Automated Testing Script (`Invoke-AutomatedTestWorkflow.ps1`)

The main orchestrator for all testing activities, providing:

- **Comprehensive Test Execution**: Runs Pester and pytest suites
- **Test Generation**: Automatically generates missing test files
- **Integration Testing**: Validates core app module loading and cross-platform compatibility
- **Continuous Monitoring**: Watches for file changes and runs relevant tests
- **Coverage Reporting**: Generates detailed test coverage reports
- **PatchManager Integration**: All test changes go through PatchManager workflow

#### Usage Examples

```powershell
# Run all tests with coverage
./Invoke-AutomatedTestWorkflow.ps1 -TestCategory All -GenerateCoverage

# Run only Pester tests
./Invoke-AutomatedTestWorkflow.ps1 -TestCategory Pester

# Generate missing tests
./Invoke-AutomatedTestWorkflow.ps1 -GenerateTests

# Start continuous monitoring
./Invoke-AutomatedTestWorkflow.ps1 -ContinuousMode

# Run core app integration tests only
./Invoke-AutomatedTestWorkflow.ps1 -TestCategory Integration
```

### 2. VS Code Integration

#### Tasks Available

- **Test: Run All Automated Tests** - Complete test suite with coverage
- **Test: Run Pester Tests Only** - PowerShell tests only
- **Test: Run PyTest Only** - Python tests only  
- **Test: Generate Missing Tests** - Auto-generate test files
- **Test: Continuous Monitoring** - Background file watching
- **Test: Core App Integration** - Integration validation

#### Keyboard Shortcuts

Access via:

- `Ctrl+Shift+P` → "Tasks: Run Task" → Select test task
- `Ctrl+Shift+` ` (backtick) → Opens integrated terminal for manual execution

### 3. GitHub Actions Workflow (`.github/workflows/automated-testing.yml`)

#### Triggers

- **Push to main/develop branches**
- **Pull requests to main**
- **Daily scheduled run** (6 AM UTC)
- **Manual dispatch** with configurable options

#### Multi-Platform Testing

- **Windows Latest** - Native PowerShell environment
- **Ubuntu Latest** - Cross-platform PowerShell + Python
- **macOS Latest** - Cross-platform compatibility validation

#### Features

- **Automatic PowerShell installation** on non-Windows platforms
- **Dependency caching** for faster runs
- **Test result artifacts** with 30-day retention
- **Coverage report generation** and upload
- **PR comments** with test summaries
- **Deployment readiness checks** for main branch

## Test Structure

### PowerShell Tests (Pester)

```
tests/
├── CoreApp.Tests.ps1           # Core application tests
├── helpers/                    # Test helper functions
├── PesterConfiguration.psd1    # Pester configuration
└── [script-name].Tests.ps1     # Individual script tests
```

**Test Categories Available:**

- `Critical` - Essential functionality
- `CoreApp` - Core application components
- `Generated` - Auto-generated tests
- `Integration` - Cross-component tests

### Python Tests (pytest)

```
py/tests/
├── test_cli.py                 # CLI functionality
├── test_pester_failures.py     # Pester integration
├── test_pytest_failures.py     # Pytest utilities
└── test_*.py                   # Other module tests
```

**Coverage Requirements:**

- Minimum 80% test coverage for new code
- HTML and XML coverage reports generated
- Integration with CI/CD coverage tracking

## Test Generation and Maintenance

### Automated Test Generation

The workflow can automatically generate test files for:

1. **PowerShell Scripts** - Creates basic Pester test structure
2. **Python Modules** - Creates pytest test templates
3. **Missing Coverage** - Identifies untested code areas

### Test Templates

#### PowerShell Test Template

```powershell
#Requires -Version 7.0
#Requires -Module Pester

Describe "ScriptName Tests" -Tag @('Generated', 'CoreApp') {
    Context "File Structure Validation" {
        It "should exist and be readable" {
            # Basic file validation
        }
        
        It "should have valid PowerShell syntax" {
            # Syntax validation
        }
    }
    
    Context "Functional Tests" {
        # Customized based on script analysis
    }
}
```

#### Python Test Template

```python
#!/usr/bin/env python3
"""Automated tests for module"""

import pytest
import sys
from pathlib import Path

def test_module_import():
    """Test module can be imported"""
    # Import validation
    
def test_module_basic_functionality():
    """Test basic functionality"""
    # Functional tests
```

## Integration with PatchManager

### Enforced Workflow

All test changes **must** go through PatchManager:

```powershell
# Example: Adding new tests via PatchManager
Invoke-GitControlledPatch -PatchDescription "Add automated tests for new module" -PatchOperation {
    # Generate or modify test files
    ./Invoke-AutomatedTestWorkflow.ps1 -GenerateTests
} -AutoCommitUncommitted -CreatePullRequest -TestCommands @(
    "Invoke-Pester tests/",
    "python -m pytest py/tests/"
)
```

### Benefits

- **Change Control** - All test modifications tracked
- **Validation** - Automatic testing before commit
- **Rollback** - Quick recovery from test failures
- **Audit Trail** - Complete history of test changes

## Continuous Integration Pipeline

### Workflow Stages

1. **Validation** - Syntax and structure checks
2. **Unit Testing** - Pester and pytest execution
3. **Integration Testing** - Cross-component validation
4. **Coverage Analysis** - Code coverage verification
5. **Deployment Readiness** - Final validation for main branch

### Quality Gates

- **All tests must pass** before merge
- **Minimum 80% code coverage** for new code
- **No PowerShell syntax errors** in any script
- **All Python modules must import successfully**
- **Core app integration tests must pass**

## Performance and Optimization

### Test Execution Time

- **Typical Pester run**: 2-5 minutes
- **Typical pytest run**: 1-3 minutes
- **Full integration test**: 5-10 minutes
- **Multi-platform CI/CD**: 15-30 minutes

### Caching Strategy

- **PowerShell modules** cached by Pester configuration hash
- **Python dependencies** cached by requirements.txt hash
- **Go dependencies** cached for OpenTofu testing

### Parallel Execution

- **Cross-platform testing** runs in parallel
- **Test categories** can be run independently
- **Background monitoring** doesn't block development

## Troubleshooting

### Common Issues

#### Pester Tests Failing

```powershell
# Check module loading
Import-Module './pwsh/modules/LabRunner/' -Force
Import-Module './pwsh/modules/PatchManager/' -Force

# Validate test file syntax
Invoke-ScriptAnalyzer -Path tests/ -Recurse
```

#### Python Tests Failing

```bash
# Check Python environment
python --version
pip list

# Validate imports
python -c "import py.labctl.pester_failures"
```

#### CI/CD Pipeline Issues

- **Check platform-specific logs** in GitHub Actions
- **Verify dependency installation** in setup steps
- **Review test artifacts** for detailed error information

### Debug Mode

Enable verbose logging:

```powershell
./Invoke-AutomatedTestWorkflow.ps1 -TestCategory All -Verbose
```

## Extending the Testing Framework

### Adding New Test Categories

1. **Define tag in test files**: `#Tag @('NewCategory')`
2. **Update workflow script**: Add category to `ValidateSet`
3. **Create VS Code task**: Add new task in `tasks.json`
4. **Update documentation**: Document new category

### Custom Test Generators

```powershell
# Example: Custom test generator for specific module type
function New-ModuleSpecificTest {
    param($ModulePath, $TestPath)
    
    # Analyze module structure
    # Generate appropriate tests
    # Use PatchManager for safe creation
}
```

## Best Practices

### Test Development

1. **Follow TDD principles** - Write tests before code
2. **Use descriptive test names** - Clear intent and scope
3. **Mock external dependencies** - Isolated, reliable tests
4. **Test both success and failure scenarios**
5. **Include cross-platform considerations**

### Maintenance

1. **Keep tests in sync with code changes**
2. **Use automated generation for basic tests**
3. **Regularly review and update test coverage**
4. **Remove obsolete tests promptly**
5. **Document test-specific requirements**

### Performance

1. **Use appropriate test categories** for targeted testing
2. **Leverage caching** in CI/CD environments
3. **Parallelize independent test suites**
4. **Monitor test execution times**
5. **Optimize slow tests** or mark as long-running

## Security Considerations

### Test Data

- **No sensitive data** in test files
- **Use mock data** for authentication tests
- **Environment-specific secrets** in CI/CD only

### Permissions

- **Tests run with minimal permissions**
- **PatchManager enforces change control**
- **No direct production access** from tests

## Future Enhancements

### Planned Features

1. **Test result trending** - Historical analysis
2. **Intelligent test selection** - Run only affected tests
3. **Performance regression detection**
4. **Automated test maintenance** - Update tests when code changes
5. **Advanced coverage analysis** - Branch and condition coverage

### Integration Opportunities

1. **VS Code Test Explorer** - Native test runner integration
2. **GitHub Code Quality** - Coverage badges and PR checks
3. **Slack/Teams notifications** - Test result summaries
4. **Dependency scanning** - Security vulnerability testing

---

## Quick Reference

### Essential Commands

```powershell
# Quick test run
./Invoke-AutomatedTestWorkflow.ps1

# Generate missing tests
./Invoke-AutomatedTestWorkflow.ps1 -GenerateTests

# Start continuous monitoring
./Invoke-AutomatedTestWorkflow.ps1 -ContinuousMode

# Core app validation only
./Invoke-AutomatedTestWorkflow.ps1 -TestCategory CoreApp
```

### VS Code Tasks

- Press `Ctrl+Shift+P` → "Tasks: Run Task"
- Select from available test tasks
- Use "Test: Run All Automated Tests" for comprehensive validation

### CI/CD Monitoring

- Check GitHub Actions tab for workflow status
- Download test artifacts for detailed analysis
- Review PR comments for test summaries

**The automated testing workflow ensures robust, reliable, and maintainable code quality while integrating seamlessly with our PatchManager-enforced development process.**
