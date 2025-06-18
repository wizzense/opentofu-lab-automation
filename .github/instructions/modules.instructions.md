---
applyTo: "**/*.ps1"
description: "Project module usage guidelines"
---
# Module Guidelines

Import project modules from `core-runner/modules` and use their exported commands instead of writing ad-hoc utilities. Key modules:

- `BackupManager` – clean up and consolidate backup files.
- `DevEnvironment` – set up local or remote development environments.
- `LabRunner` – run labs and orchestrate automation workflows.
- `Logging` – write logs with `Write-LogInfo`, `Write-LogError`, etc.
- `ParallelExecution` – execute tasks concurrently with runspaces.
- `PatchManager` – manage patch downloads and installation.
- `ScriptManager` – maintain reusable script templates.
- `TestingFramework` – run Pester tests consistently.
- `UnifiedMaintenance` – entry point for housekeeping tasks.
