# Recurring Issues Summary - 2025-06-14

**Last Test Results**: 2025-06-14 17:34:30 
**Analysis Time**: 2025-06-14 17:34:31

## Test Health Overview

 Metric  Value  Status 
-----------------------
 **Total Tests**  174  PASS 
 **Success Rate**  0%  FAIL 
 **Total Failures**  174  FAIL 
 **Skipped Tests**  0  INFO 

## Top Recurring Issues

### � � � **Other: This test should run but it did not** - Critical High Medium Priority
- **Occurrences**: 174
- **Prevention**: Manual investigation required
- **Example**: `This test should run but it did not. Most likely a setup in some parent block failed.`

## Quick Fix Commands

Based on the current issues, run these commands to address problems:

```powershell
# Fix missing commands (most common issue)
./scripts/maintenance/fix-infrastructure-issues.ps1 -Fix "MissingCommands"

# Fix syntax errors
./scripts/maintenance/fix-test-syntax.ps1

# Comprehensive fix
./scripts/maintenance/fix-infrastructure-issues.ps1 -Fix "All"

# Validate improvements
./scripts/maintenance/track-recurring-issues.ps1 -Mode "Analyze"
```

## Prevention Checklist

-   Add missing command mocks to TestHelpers.ps1
-   Run syntax validation before commits
-   Update test templates to avoid common errors
-   Consider adding pre-commit hooks for validation

---

*This report is auto-generated from the latest test results. Re-run tests only when needed.*
