---
mode: 'agent'
description: 'Generate a new PowerShell module with standard structure'
---
Generate a new PowerShell module in the `pwsh/lab_utils/` folder.

Requirements:
- Use `[CmdletBinding()]` and `Param()` for all exported functions.
- Add a comment block with `.SYNOPSIS`, `.DESCRIPTION`, and `.EXAMPLE`.
- Include Pester tests in `tests/` with at least one test per function.
- Add usage examples in the module docstring.
- Follow the [PowerShell Coding Standards](../instructions/powershell.instructions.md).
