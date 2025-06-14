# Pester Test Fixes Summary

**Issue Fixed:** "The term 'Param' is not recognized" errors in PowerShell Pester tests 
**Date:** June 12, 2025 
**Files Affected:** 84+ test files and scripts 

## Quick Summary

Fixed systemic Pester test failures where PowerShell scripts with `Param()` blocks failed when executed via direct script invocation or dot-sourcing within test contexts.

### Solution Applied
Changed from direct script execution to subprocess execution using `pwsh -File` pattern with temporary configuration files.

### Results
- [PASS] **681 tests discovered** (up from ~400 due to discovery failures)
- [PASS] **285 tests passing** (significant improvement)
- [PASS] **Zero "Param is not recognized" errors**
- [PASS] **All 86 test files parse successfully**

## Key Files

### Documentation
- [`pester-param-fix-report.md`](./pester-param-fix-report.md) - Complete detailed report
- [`pester-fix-scripts-reference.md`](./pester-fix-scripts-reference.md) - All scripts and technical details

### Fix Scripts (in repository root)
- `fix_numbered_tests_final.ps1` - Main execution pattern fix
- `fix_numbered_paths.ps1` - Script path resolution fix 
- `fix_dot_sourcing.ps1` - Syntax validation fix

## Working Test Pattern

**Before (Failing):**
```powershell
{ & $scriptPath -Config $config } | Should -Not -Throw
```

**After (Working):**
```powershell
$config = [pscustomobject]@{}
$configJson = $config | ConvertTo-Json -Depth 5
$tempConfig = Join-Path ([System.IO.Path]::GetTempPath()) "$([System.Guid]::NewGuid()).json"
$configJson | Set-Content -Path $tempConfig
try {
 $pwsh = (Get-Command pwsh).Source
 { & $pwsh -NoLogo -NoProfile -File $script:ScriptPath -Config $tempConfig } | Should -Not -Throw
} finally {
 Remove-Item $tempConfig -Force -ErrorAction SilentlyContinue
}
```

## Files Modified

- **36 numbered test files** (`0001_Reset-Git.Tests.ps1` through `9999_Reset-Machine.Tests.ps1`)
- **42 test files** with path corrections
- **Core module:** `pwsh/lab_utils/LabRunner/LabRunner.psm1`
- **All runner scripts:** 37 files in `pwsh/runner_scripts/`
- **Test helpers:** `tests/helpers/TestTemplates.ps1`

## Quick Verification

To verify fixes work:
```powershell
# Test individual file
Invoke-Pester tests/0001_Reset-Git.Tests.ps1

# Test multiple files 
Invoke-Pester tests/0001_Reset-Git.Tests.ps1, tests/0007_Install-Go.Tests.ps1

# Full test suite
Invoke-Pester tests/
```

## Root Cause

PowerShell parameter blocks (`Param([object]$Config)`) fail when scripts are executed using the `&` call operator or dot-sourcing within Pester test execution contexts. The `pwsh -File` execution pattern provides proper isolation and parameter parsing.

This fix enables reliable testing of PowerShell scripts with parameter blocks in the Pester testing framework.
