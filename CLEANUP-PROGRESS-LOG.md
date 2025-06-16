# Comprehensive Cleanup Progress Log

**Started:** 2025-06-15 at $(Get-Date -Format "HH:mm:ss")
**Branch:** feature/comprehensive-cleanup  
**Pull Request:** [#1693](https://github.com/wizzense/opentofu-lab-automation/pull/1693)

## Objectives
1. Fix cross-platform compatibility issues (hardcoded Windows paths)
2. Consolidate duplicate tools and scripts
3. Organize directory structure
4. Remove unused/outdated files
5. Update all module imports to use standardized paths
6. Ensure consistent path handling across all scripts

## Cross-Platform Path Issues Identified
- [ ] `scripts/cleanup/noninteractive-cleanup.ps1` - Hardcoded Windows path
- [ ] All test files in `/tests/` - Malformed module import paths
- [ ] Various scripts using absolute Windows paths

## Progress Tracking

### Phase 1: Cross-Platform Path Fixes
- [ ] **CRITICAL**: Fix all hardcoded Windows paths in scripts
- [ ] Update test files with correct module import paths
- [ ] Implement standardized path resolution using PROJECT-MANIFEST.json
- [ ] Validate cross-platform compatibility

### Phase 2: Module Import Standardization  
- [ ] Fix malformed Import-Module statements in test files
- [ ] Ensure all imports use `/pwsh/modules/<ModuleName>/` format
- [ ] Remove redundant module imports

### Phase 3: Directory Consolidation
- [ ] Identify duplicate tools and scripts
- [ ] Merge similar functionality
- [ ] Remove empty or unused directories
- [ ] Update PROJECT-MANIFEST.json with changes

### Phase 4: File Cleanup
- [ ] Remove outdated/unused scripts
- [ ] Consolidate maintenance tools
- [ ] Archive legacy files
- [ ] Update documentation

## Issues Found and Fixed

### ❌ Critical Path Issues
1. **scripts/cleanup/noninteractive-cleanup.ps1**
   - Issue: Hardcoded `c:\Users\alexa\OneDrive\Documents\0. wizzense\opentofu-lab-automation`
   - Fix: Use standardized path resolution
   - Status: PENDING

2. **Multiple test files (40+ files)**
   - Issue: Malformed Import-Module paths like `/C:\Users\alexa\OneDrive\Documents\0. wizzense\opentofu-lab-automation\pwsh/modules/LabRunner/" -ForceImport-Module "/C:\Users\alexa`
   - Fix: Use proper module import syntax
   - Status: PENDING

### ✅ Completed Tasks
- Created UNIFIED-PROJECT-GUIDELINES.md
- Updated VS Code settings for project guidelines
- Created this progress log

## Next Steps
1. **IMMEDIATE**: Fix cross-platform path compatibility
2. Fix all malformed module imports in test files
3. Implement standardized path resolution functions
4. Continue with comprehensive cleanup

## Revert Instructions
If cleanup needs to be reverted:
1. `git checkout main`
2. `git branch -D feature/comprehensive-cleanup`
3. Close PR #1693
4. Restore from backup: `./backups/pre-patch-20250615-*/`

---
**Last Updated:** $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
