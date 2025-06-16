# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Initial CHANGELOG.md file created
- PatchManager v2.0 with automated PR creation and branch cleanup
- Cross-platform environment variable support (PROJECT_ROOT, PWSH_MODULES_PATH)
- Anti-recursive branching protection in PatchManager
- Automated Copilot suggestion handling with background monitoring
- Comprehensive cleanup and maintenance automation

### Changed

- Integrated unified-maintenance functionality into PatchManager
- Improved error handling and logging across all modules
- Enhanced PR creation with detailed templates and checklists
- Updated all modules to use standardized cross-platform paths

### Fixed

- Double pipe (||) syntax errors in PowerShell scripts
- Path standardization issues across Windows/Linux/macOS
- PowerShell linting and validation errors
- Pre-commit hook batch validation logic

### Removed

- Legacy CodeFixer module (functionality moved to PatchManager)
- Deprecated ScriptManager module
- Unused legacy scripts and maintenance files

## [2.0.0] - 2025-01-14

### PatchManager Release

- PatchManager module with comprehensive patch management
- Automated GitHub issue tracking for all operations
- Branch cleanup automation after PR merge
- Cross-platform compatibility improvements

### Architecture Updates

- Major restructure of project architecture
- Moved from individual modules to integrated PatchManager
- Enhanced automation workflows

### Bug Fixes

- Multiple PowerShell syntax and linting issues
- Cross-platform path handling
- Workflow validation errors

## [1.0.0] - 2024-12-01

### Initial Release

- Initial project structure
- Basic PowerShell modules (CodeFixer, LabRunner, BackupManager)
- OpenTofu/Terraform infrastructure configurations
- GitHub Actions CI/CD workflows
- Cross-platform deployment scripts

---

**Note**: This changelog is automatically maintained by PatchManager. Each patch operation adds entries to the [Unreleased] section.
