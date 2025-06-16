# Changelog

All notable changes to this project will be documented in this file.

The format is based on Keep a Changelog(https://keepachangelog.com/en/1.1.0/) and this project adheres to Semantic Versioning(https://semver.org/spec/v2.0.0.html).

## Unreleased

### Unified Maintenance System (2025-06-13)
- ** Major Achievement**: Implemented comprehensive automated maintenance and issue tracking system
- ** Infrastructure Health**: Real-time monitoring without test dependency (350+ files analyzed)
- ** Automated Fixes**: Smart pattern recognition and automatic problem resolution
- ** Recurring Issue Tracking**: Historical analysis and prevention recommendations
- ** Time Savings**: Infrastructure health checks complete in <1 minute vs 10+ minute test runs
- ** AI Agent Ready**: All utilities designed for automated/repeatable use
- ** Comprehensive Reports**: Auto-generated summaries with specific fix commands
- ** Key Scripts**: `unified-maintenance.ps1`, `infrastructure-health-check.ps1`, `track-recurring-issues.ps1`

### Project Hygiene & Documentation (2025-06-13)
- **� Root Directory Cleanup**: Removed 18+ empty/obsolete scripts, organized project structure
- ** Agent Documentation**: Updated AGENTS.md and copilot-instructions.md with unified maintenance system
- **� Proper Organization**: Moved legacy scripts to archive/, configuration files to appropriate locations
- ** Maintenance Scripts**: All cleanup utilities designed for repeatable use and prevention
- ** Clean Project Structure**: Root directory now contains only essential files and directories

### Automated Maintenance (2025-06-13)
- **Mode**: All (with AutoFix)
- **Infrastructure**: Health check and fixes applied
- **Syntax**: PowerShell validation completed
- **Tests**: Executed and analyzed
- **Reports**: Generated and indexed
- **Status**: PASS Maintenance cycle completed
### Analysis Reports
- **Infrastructure Fixes Complete (2025-06-13)**: Successfully resolved all 5 highest priority infrastructure issues identified in comprehensive test analysis. CodeFixer module syntax validated, missing commands mocked, 85 test files repaired, import paths updated. All test containers now pass PowerShell syntax validation. See detailed report(docs/reports/test-analysis/2025-06-13-comprehensive-infrastructure-fixes-complete.md) for complete fix summary.
- **Comprehensive Test Analysis (2025-06-13)**: Conducted full test suite analysis revealing 99 Pester test failures, 1 Python test failure, and 75% GitHub Actions workflow failure rate. Primary issues identified: CodeFixer module syntax errors, missing command references, and import path problems following recent module refactoring. See detailed report(docs/reports/test-analysis/2025-06-13-comprehensive-test-analysis.md) for full remediation plan.

### Project Organization
- **Report Management System**: Implemented comprehensive report organization system with structured `/docs/reports/` directory containing test-analysis, workflow-analysis, and project-status subdirectories. All previous summary files moved from root directory to appropriate categorized locations with timestamped naming conventions.
- **Report Templates & Guidelines**: Created standardized report templates and comprehensive README with usage guidelines for future report generation.
- **Report Index**: Implemented `/docs/reports/INDEX.md` for quick navigation and overview of all project analysis reports.

### Bugfixes

- Fixed systemic Pester test failures caused by "Param is not recognized" errors affecting 36+ numbered test files. Changed execution pattern from direct script invocation to subprocess execution using `pwsh -File` pattern. This resolves PowerShell parameter block parsing issues in test contexts and enables 681 tests to be discovered successfully across 86 test files. (#pester-param-fix)


### Fixed
- Bootstrap script PowerShell syntax error with variable interpolation in strings - fixed `${repoPath}:`
- Bootstrap script path resolution - updated config files to specify correct `pwsh/runner.ps1` path
- Added comprehensive logging and debugging output to bootstrap script for easier troubleshooting

### Added
- Diagnostic Pester tests for bootstrap script path resolution and syntax validation
- Enhanced error messages in bootstrap script with detailed troubleshooting steps

### Breaking Changes
- Pester tests require updates due to breaking changes in script structure

### Technical Debt
- Pester test suite needs comprehensive review and fixes

## 2025-06-13 - Cross-Platform Deployment Wrapper

### One-Click Deployment System
- **Created `deploy.py`** - Cross-platform Python wrapper for easy deployment
- **Added `deploy.bat`** - Windows batch wrapper for double-click deployment
- **Added `deploy.sh`** - Unix/Linux shell wrapper for simple execution
- **Root-level deployment** - No need to navigate to subdirectories
- **Prerequisites checking** - Automatic platform and dependency verification

### Simplified User Experience
- **One-click deployment** from project root directory
- **Interactive configuration** with smart defaults
- **Headless mode** for CI/CD and automation
- **Custom configuration** support for advanced users
- **Cross-platform compatibility** (Windows, Linux, macOS)

### Deployment Modes
- **Quick mode**: `python deploy.py --quick` (30-second deployment)
- **Interactive mode**: `python deploy.py` (guided setup)
- **Headless mode**: `python deploy.py --quiet --non-interactive`
- **Check mode**: `python deploy.py --check` (verify prerequisites only)

### Documentation Overhaul
- **Completely rewritten README.md** with clear, concise instructions
- **30-second quick start** guide for immediate deployment
- **Use case examples** for different scenarios
- **Comprehensive troubleshooting** section
- **Platform-specific instructions** for all operating systems

### Technical Implementation
- **Lightweight Python wrapper** (no heavy dependencies)
- **Platform detection** and automatic path resolution
- **PowerShell integration** with proper error handling
- **Configuration management** with validation
- **Real-time progress** and comprehensive logging

## 2025-06-13 - Project Hygiene & Backup Consolidation

### � Additional Directory Cleanup
- **Duplicate Modules directory** resolved: `/pwsh/Modules/` (capital M) archived to preserve history
- **Modern modules structure** preserved: `/pwsh/modules/` (lowercase) remains active
- **Obsolete fixes directory** archived: Historical Pester fix scripts moved to `/archive/historical-fixes/`
- **Case-sensitive conflicts** eliminated for cross-platform compatibility
- **Archive organization** improved with timestamped legacy content

### � Backup Consolidation
- **Consolidated 49 scattered backup files** into organized date-based directory structure
- **Archived legacy LabRunner** from root directory to `/archive/legacy-modules/`
- **Organized backups** by date and source: `/backups/consolidated-backups/YYYY-MM-DD/`
- **Hidden backup directories** from VS Code file explorer to improve project focus
- **Updated .gitignore** to exclude backup directories from version control

### Infrastructure Improvements
- **Created backup consolidation script** (`/scripts/maintenance/consolidate-backups.ps1`)
- **Created VS Code hiding utility** (`/scripts/utilities/hide-backup-directories.ps1`)
- **Automated empty directory cleanup** during consolidation process
- **Enhanced project structure** with clear separation of active vs archived code

### Impact
- **Project root cleaned**: Removed duplicate LabRunner directory
- **File organization**: 49 backup files properly archived and organized
- **Developer experience**: Cleaner file explorer, focused on active development
- **Maintainability**: Repeatable scripts for future backup management

### Next Phase Ready
- ISO customization and local GitHub runner integration
- Unified configuration system development
- Advanced Tanium lab integration features

## 0.0.1 - 2025-06-12

### Added
- Initial changelog setup
- Bootstrap script functionality

### Fixed
- Fix bootstrap script URLs (#fix-bootstrap-url)
- Fixes the Windows lint job by checking the installed PSScriptAnalyzer version without using the unsupported `RequiredVersion` parameter (#lint-workflow-requiredversion)
- Bootstrap script path resolution - updated RunnerScriptName in config files

### Known Issues
- Pester tests failing due to structural changes

