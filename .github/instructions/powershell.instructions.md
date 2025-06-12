---
applyTo: "**/*.ps1,**/*.psm1"
---
# PowerShell Coding Standards

Apply the [general coding guidelines](./general-coding.instructions.md) to all code.

- Use `Write-CustomLog` for logging.
- Use `[CmdletBinding()]` for advanced functions.
- Always declare parameter types and use `Param()` blocks.
- Use `Should -Be`, `Should -Throw`, and `Should -Invoke` in Pester tests.
- Prefer `pscustomobject` for structured data.
- Use `Import-Module "$PSScriptRoot/../lab_utils/LabRunner/LabRunner.psd1"` in runner scripts.
