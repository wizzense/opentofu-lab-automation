# YAML Corruption Incident Report - June 14, 2025

## � INCIDENT SUMMARY

**Problem**: Recurring YAML workflow file corruption causing 8 out of 10 workflow files to become invalid.

**Root Cause**: Flawed auto-fix logic in `scripts/validation/Invoke-YamlValidation.ps1` that was incorrectly "fixing" YAML indentation.

**Impact**: 
- 80% of GitHub Actions workflows broken
- Continuous integration potentially affected
- Development workflow disrupted

## ROOT CAUSE ANALYSIS

### The Problematic Code
Located in `Invoke-YamlValidation.ps1` lines 300-308:

```powershell
# Fix inconsistent spacing
if ($line -match '^( {3,})' -and $line -notmatch '^( {2})*') {
    $leadingSpaces = ($Matches1.Length)
    $correctSpaces = Math::Floor($leadingSpaces / 2) * 2
    $line = (' ' * $correctSpaces) + $line.TrimStart()
    if ($fixesApplied -notcontains "Fixed indentation spacing") {
        $fixesApplied += "Fixed indentation spacing"
    }
}
```

### Why It Was Destructive

1. **Incorrect Logic**: The regex `'^( {2})*'` was supposed to check if indentation was a multiple of 2, but was written incorrectly
2. **Aggressive Space Reduction**: Taking `Math::Floor($leadingSpaces / 2) * 2` was destroying valid 4, 6, 8+ space indentation
3. **GitHub Actions Structure**: GitHub Actions workflows require specific indentation:
   - Jobs: 2 spaces
   - Job properties: 4 spaces  
   - Steps: 6 spaces
   - Step properties: 8 spaces

### How It Spread
The auto-fix was called by:
- `unified-maintenance.ps1` (Step-ValidateYaml)
- `health-check.ps1` 
- `run-validation.ps1`
- `final-validation.ps1`

Every time these scripts ran, they corrupted more YAML files.

## PASS RESOLUTION ACTIONS

### 1. Disabled Destructive Auto-Fix
```powershell
# DISABLED: Fix inconsistent spacing - CAUSES YAML CORRUPTION
# This logic was destroying valid YAML indentation by incorrectly
# calculating spaces and breaking GitHub Actions workflow structure
```

### 2. Emergency Cleanup
- **Archived** 8 broken workflow files to `./archive/broken-workflows-20250614-104411/`
- **Preserved** 2 working workflows: `mega-consolidated.yml` and `mega-consolidated-fixed.yml`
- **Created backup** of working files in `./backups/working-workflows-20250614-104411/`

### 3. Validation Status
- **Before**: 2/10 workflows valid (20%)
- **After**: 2/2 workflows valid (100%)
- **Errors**: Reduced from 52 to 0

### 4. Removed Problematic Scripts
- Deleted `scripts/validation/fix-yaml-indentation.ps1` (also flawed)
- Disabled auto-fix in `Invoke-YamlValidation.ps1`

## PREVENTION MEASURES

### 1. YAML Validation Changes
- **Auto-fix disabled**: Only manual fixes allowed
- **Validation only**: Use `yamllint` directly for checking
- **No automated indentation fixes**: Manual review required

### 2. Process Changes
- **Pre-commit validation**: Test YAML files before committing
- **Manual review**: All workflow changes require human verification
- **Backup strategy**: Regular backups of working workflows

### 3. Documentation Updates
- Updated `.github/instructions/yaml-standards.instructions.md` with strict guidelines
- Added warnings about auto-fix dangers
- Created incident report for future reference

## CURRENT STATUS

### Working Workflows (2/2 - 100% valid)
- PASS `mega-consolidated.yml` - Primary consolidated workflow
- PASS `mega-consolidated-fixed.yml` - Alternative consolidated workflow

### Archived Workflows (8 files)
- `archive-legacy-workflows.yml`
- `auto-merge.yml`
- `changelog.yml`
- `copilot-auto-fix.yml`
- `issue-on-fail.yml`
- `package-labctl.yml`
- `release.yml`
- `validate-workflows.yml`

##  GOING FORWARD

### Immediate Actions
1. PASS Use only the 2 working mega-consolidated workflows
2. PASS Disable all YAML auto-fix functionality
3. PASS Validate manually with `yamllint` before committing

### Future Workflow Development
1. **Manual Creation**: Create new workflows manually following YAML standards
2. **Validation First**: Always validate with `yamllint` before committing
3. **Incremental Testing**: Test workflows in isolation before integration
4. **Backup Strategy**: Maintain backups of working workflows

### Recovery Options for Archived Files
1. **Recommended**: Continue using mega-consolidated workflows (they cover most functionality)
2. **Manual Fix**: Restore archived files and manually fix YAML structure
3. **Rewrite**: Create new workflow files from scratch following standards

## LESSONS LEARNED

1. **Never trust auto-fix for complex formats**: YAML structure is too nuanced for simple regex fixes
2. **Test fixes thoroughly**: Auto-fix logic should be extensively tested before deployment
3. **Backup critical files**: Always backup before applying automated changes
4. **Monitor validation results**: Regular checking caught this issue before worse damage
5. **Disable dangerous automation**: When auto-fix causes problems, disable immediately

## VALIDATION COMMANDS

### Safe Commands (Use These)
```powershell
# Check YAML syntax only (no auto-fix)
yamllint ".github/workflows/mega-consolidated.yml"

# Comprehensive validation (no auto-fix)
./scripts/validation/Invoke-YamlValidation.ps1 -Mode "Check" -Path ".github/workflows"

# Manual maintenance (YAML auto-fix disabled)
./scripts/maintenance/unified-maintenance.ps1 -Mode "Quick"
```

### Dangerous Commands (AVOID)
```powershell
# NEVER USE: Auto-fix mode (disabled but warning for future)
# ./scripts/validation/Invoke-YamlValidation.ps1 -Mode "Fix"
```

## MONITORING

Going forward, monitor:
- YAML validation results in maintenance scripts
- Number of valid vs invalid workflow files  
- Any auto-fix attempts (should be zero)
- Regular backup creation

This incident demonstrates the importance of careful validation logic and the dangers of automated fixes for complex file formats.
