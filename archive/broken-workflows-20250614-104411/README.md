# Archived Broken Workflows - 2025-06-14 10:44:11

## Reason for Archival
These workflow files contained fundamental YAML syntax errors that prevented proper parsing.
The corruption was caused by flawed auto-fix logic in the YAML validation script.

## Status
- **Total archived**: 8 files
- **Working workflows remaining**: 2 files
- **Auto-fix logic**: DISABLED to prevent future corruption

## Archived Files
- archive-legacy-workflows.yml
- auto-merge.yml
- changelog.yml
- copilot-auto-fix.yml
- issue-on-fail.yml
- package-labctl.yml
- release.yml
- validate-workflows.yml


## Recovery Options
1. **Recommended**: Use the working mega-consolidated workflows
2. **Manual fix**: Restore individual files and manually fix YAML structure
3. **Rewrite**: Create new workflow files following YAML standards

## Working Workflows
The following workflows remain active and are YAML-valid:
- mega-consolidated.yml
- mega-consolidated-fixed.yml


## Prevention
- YAML auto-fix logic has been disabled in Invoke-YamlValidation.ps1
- Manual validation only: Use yamllint directly for checking
- Follow YAML standards in .github/instructions/yaml-standards.instructions.md
