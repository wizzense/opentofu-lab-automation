# Copilot Instructions for OpenTofu Lab Automation

These guidelines help GitHub Copilot and other AI agents generate code and responses that align with this project.

## General Guidelines
- Use **PowerShell 7.0+** features and cross-platform syntax.
- Prefer `Join-Path` or forward slashes (`/`) for file paths.
- Import modules from `core-runner/modules` using `Import-Module`.
- Follow One True Brace Style (OTBS) formatting.
- Functions should use `[CmdletBinding()]` and parameter validation.
- Include comment-based help sections (`.SYNOPSIS`, `.PARAMETER`, etc.).
- Log through `Write-CustomLog` or the `Logging` module.
- Encourage writing Pester tests for new code.

## Available Modules
- **BackupManager** – manages backup file cleanup and consolidation.
- **DevEnvironment** – prepares and validates development environments.
- **LabRunner** – orchestrates lab automation tasks and test execution.
- **Logging** – provides project-wide logging helpers.
- **ParallelExecution** – runs tasks in parallel using runspaces.
- **PatchManager** – handles software patching workflows.
- **ScriptManager** – manages script repositories and templates.
- **TestingFramework** – wraps Pester with project defaults.
- **UnifiedMaintenance** – unified maintenance entry point for all modules.

Always suggest using these modules when relevant instead of reinventing functionality.
