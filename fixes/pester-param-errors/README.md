# Pester Parameter Error Fix Scripts

This directory contains all the scripts used to fix the "Param is not recognized" errors in the Pester test suite.

## Scripts Overview

### Working Scripts (Final Solutions)
- **`fix_numbered_tests_final.ps1`** - Main execution pattern fix for numbered test files
- **`fix_numbered_paths.ps1`** - Script path resolution using Get-RunnerScriptPath function  
- **`fix_dot_sourcing.ps1`** - Replaced dot-sourcing with proper PowerShell parsing

### Development Scripts (Historical)
- **`fix_param_tests.ps1`** - Initial attempt (basic approach)
- **`fix_remaining_numbered_tests.ps1`** - Mass fix attempt that had formatting issues
- **`fix_numbered_tests_corrected.ps1`** - Attempted fix with git restore (overly complex)

## Execution Order

For applying these fixes to a fresh repository:

1. **Main Fix**: `fix_numbered_tests_final.ps1`
2. **Path Resolution**: `fix_numbered_paths.ps1` 
3. **Final Cleanup**: `fix_dot_sourcing.ps1`

## Key Success Factors

1. **Subprocess Execution**: Using `pwsh -File` instead of `&` operator
2. **Temporary Config Files**: Converting objects to JSON files for parameter passing
3. **Proper Path Resolution**: Using helper functions instead of hardcoded paths
4. **Parser Validation**: Using `[System.Management.Automation.Language.Parser]::ParseFile()` instead of dot-sourcing

## Usage

```powershell
# Navigate to repository root
cd /workspaces/opentofu-lab-automation

# Run the working scripts in order
pwsh -NoLogo -NoProfile -File fixes/pester-param-errors/fix_numbered_tests_final.ps1
pwsh -NoLogo -NoProfile -File fixes/pester-param-errors/fix_numbered_paths.ps1  
pwsh -NoLogo -NoProfile -File fixes/pester-param-errors/fix_dot_sourcing.ps1

# Verify fixes
Invoke-Pester tests/0001_Reset-Git.Tests.ps1
```

## Results Achieved

- ✅ **681 tests discovered** across 86 files
- ✅ **285 tests passing** 
- ✅ **Zero "Param is not recognized" errors**
- ✅ **Complete elimination of discovery failures**

See `docs/pester-param-fix-report.md` for complete details.
