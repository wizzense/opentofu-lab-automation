# GitHub Actions Workflows

This directory contains the GitHub Actions workflows for the OpenTofu Lab Automation project, organized into a streamlined, more maintainable structure with descriptive names and emoji prefixes for better visibility.

## Core Workflows

| Workflow | Description |
|----------|-------------|
| [🚀 CI/CD Pipeline](./unified-ci.yml) | Main CI/CD pipeline for validation, linting, and testing |
| [🧪 Cross-Platform Testing](./unified-testing.yml) | Runs tests across Windows, Linux, and macOS |
| [🩺 System Health Monitor](./system-health-monitor.yml) | Monitors system health and creates alerts |
| [� Unified Utilities](./unified-utilities.yml) | Updates dashboard, path index, and documentation |

## Support Workflows

| Workflow | Description |
|----------|-------------|
| [�🔍 Workflow Validation](./validate-workflows.yml) | Validates the syntax of workflow files |
| [🧪 Automatic Test Generation](./auto-test-generation-consolidated.yml) | Automatically generates tests for PowerShell scripts |
| [📝 Update Changelog](./changelog.yml) | Updates the CHANGELOG.md file |
| [🚨 Automated Issue Creation](./issue-on-fail.yml) | Creates issues for workflow failures |

## Development Workflows

| Workflow | Description |
|----------|-------------|
| [🤖 Copilot Auto-Fix](./copilot-auto-fix.yml) | Generates AI-powered fix suggestions for open issues |
| [🔄 Auto-Merge PRs](./auto-merge.yml) | Automatically merges eligible pull requests |
| [📦 Package LabCTL Tool](./package-labctl.yml) | Builds and packages the LabCTL tool |

## Features

- **Emoji Prefixes**: All job and workflow names use emoji prefixes for better visibility in GitHub UI
- **Descriptive Job Names**: Each job has a clear, descriptive name with emoji prefix
- **Platform Matrices**: Cross-platform testing uses matrices instead of separate workflows
- **Consolidated Jobs**: Reduced total number of workflows by consolidating related functionality
- **Improved Error Handling**: Better error reporting across all workflows
- **GitHub Summary Integration**: All workflows report results in GitHub summaries

## Legacy Workflows (Consolidated)

The following workflows have been consolidated and can be safely archived:

- `pester-windows.yml`, `pester-linux.yml`, `pester-macos.yml` → Consolidated into `unified-testing.yml`
- `auto-test-generation.yml`, `auto-test-generation-setup.yml`, `auto-test-generation-execution.yml` → Consolidated into `auto-test-generation-consolidated.yml`
- `workflow-health-monitor.yml`, `comprehensive-health-monitor.yml` → Consolidated into `system-health-monitor.yml`
- `update-dashboard.yml`, `update-path-index.yml` → Consolidated into `unified-utilities.yml`

## Usage

- **For regular development**: The CI/CD pipeline runs automatically on PRs and pushes
- **For test generation**: The automatic test generation workflow runs when PowerShell files change
- **For system health**: The system health monitor runs daily and after key workflows complete
- **For documentation**: The unified utilities workflow updates dashboard and documentation

## Note on Archived Workflows

> Archiving completed on 2025-06-13 02:01:40

The legacy workflows mentioned above have been moved to [.github/archived_workflows](../archived_workflows/).
See the [archive README](../archived_workflows/README.md) for details.
