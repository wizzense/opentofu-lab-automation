# Infrastructure Health Report - 2025-06-13

**Analysis Time**: 2025-06-13 04:33:21 
**Overall Status**: FAIL **Critical**

## Health Metrics

 Metric  Value  Status 
-----------------------
 **PowerShell Files**  350  INFO 
 **Syntax Errors**  23  FAIL 
 **Deprecated Imports**  17  WARN 
 **Missing Mocks**  1  WARN 
 **Test Files**  86  INFO 
 **Total Issues**  3  WARN 

## Issues Detected

### � **PowerShell Syntax** - High Priority
- **Count**: 23
- **Description**: PowerShell files with syntax errors
- **Fix Command**: `./scripts/maintenance/fix-test-syntax.ps1`
- **Example Files**: ./archive/legacy/test-format-function.ps1, ./archive/legacy/test-script-sample.ps1, ./archive/test-scripts/test-lint.ps1, ./cleanup-backup-20250612-065942/test-format-function.ps1, ./cleanup-backup-20250612-065942/test-script-sample.ps1

### � **Missing Test Mocks** - Medium Priority
- **Count**: 1
- **Description**: Missing mock functions in TestHelpers.ps1
- **Fix Command**: `./scripts/maintenance/fix-infrastructure-issues.ps1 -Fix MissingCommands`
- **Details**: Get-LabConfig

### � **Deprecated Import Paths** - Medium Priority
- **Count**: 17
- **Description**: Files using old lab_utils import paths
- **Fix Command**: `./scripts/maintenance/fix-infrastructure-issues.ps1 -Fix ImportPaths`
- **Example Files**: Download-Archive.ps1, Expand-All.ps1, Menu.ps1, Download-Archive.ps1, Expand-All.ps1

## Recommended Actions
- Run automated fixes: ./scripts/maintenance/fix-infrastructure-issues.ps1 -Fix All
- Fix syntax errors: ./scripts/maintenance/fix-test-syntax.ps1
- Update TestHelpers.ps1 with missing mock functions

## Quick Fix Commands

```powershell
# Run comprehensive infrastructure fixes
./scripts/maintenance/fix-infrastructure-issues.ps1 -Fix "All"

# Fix syntax errors specifically
./scripts/maintenance/fix-test-syntax.ps1

# Run this health check again
./scripts/maintenance/infrastructure-health-check.ps1 -Mode "Full"

# Generate a new report
./scripts/maintenance/infrastructure-health-check.ps1 -Mode "Report"
```

---

*This report analyzes the current state without running tests. For test-specific issues, run the comprehensive test suite.*
