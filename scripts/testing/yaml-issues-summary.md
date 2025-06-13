# YAML Validation Issues Report

Generated: 2025-06-13 22:29:54

## Summary
- **Total Issues**: 4
- **Auto-fixable**: 3
- **Critical Files**: 9 workflow files affected

## Issues by Category

### YAML-001 - YAML Validation: Trailing Spaces
- **Description**: 154 trailing space errors fixed across all workflow files
- **Severity**: Medium
- **Count**: 154
- **Auto-fixable**: True
- **Files Affected**: 9
- **Prevention**: Integrate yamllint auto-fix into pre-commit hooks

### YAML-004 - YAML Validation: Truthy Values
- **Description**: GitHub Actions 'on:' keyword flagged as truthy (false positive)
- **Severity**: Low
- **Count**: 1
- **Auto-fixable**: False
- **Files Affected**: 1
- **Prevention**: Configure yamllint to ignore GitHub Actions keywords

### YAML-003 - YAML Validation: Document Start
- **Description**: Missing document start marker in release.yml fixed
- **Severity**: Low
- **Count**: 1
- **Auto-fixable**: True
- **Files Affected**: 1
- **Prevention**: Enforce YAML document start marker

### YAML-002 - YAML Validation: Indentation
- **Description**: Wrong indentation in release.yml fixed
- **Severity**: High
- **Count**: 1
- **Auto-fixable**: True
- **Files Affected**: 1
- **Prevention**: Validate YAML structure in CI pipeline

## Recommended Actions

1. **Immediate**: Run YAML auto-fix via \scripts/validation/Invoke-YamlValidation.ps1 -Mode Fix\
2. **Integration**: Add yamllint validation to unified-maintenance.ps1 (✅ Already done)
3. **Prevention**: Add pre-commit hooks for YAML validation
4. **Monitoring**: Include YAML validation in CI pipeline health checks

## Auto-Fix Command
\\\ash
pwsh -Command "./scripts/validation/Invoke-YamlValidation.ps1 -Mode Fix"
\\\

