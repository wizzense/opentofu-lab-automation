# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]
# Labctl 0.0.0 (2025-06-12)

No significant changes.


# Labctl 0.0.0 (2025-06-12)

No significant changes.


# Labctl 0.0.0 (2025-06-12)

No significant changes.


### Fixed
- Bootstrap script PowerShell syntax error with variable interpolation in strings - fixed `$repoPath:` to `${repoPath}:`
- Bootstrap script path resolution - updated config files to specify correct `pwsh/runner.ps1` path
- Added comprehensive logging and debugging output to bootstrap script for easier troubleshooting

### Added
- Diagnostic Pester tests for bootstrap script path resolution and syntax validation
- Enhanced error messages in bootstrap script with detailed troubleshooting steps

### Breaking Changes
- Pester tests require updates due to breaking changes in script structure

### Technical Debt
- Multiple duplicate changelog entries need cleanup
- Pester test suite needs comprehensive review and fixes

## [0.0.1] - 2025-06-12

### Added
- Initial changelog setup
- Bootstrap script functionality

### Fixed
- Fix bootstrap script URLs (#fix-bootstrap-url)
- Fixes the Windows lint job by checking the installed PSScriptAnalyzer version without using the unsupported `RequiredVersion` parameter (#lint-workflow-requiredversion)
- Bootstrap script path resolution - updated RunnerScriptName in config files

### Known Issues
- Pester tests failing due to structural changes
