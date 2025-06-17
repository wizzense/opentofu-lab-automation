---
mode: 'edit'
description: 'Fix PowerShell script errors using PatchManager workflow'
---

Fix PowerShell script errors in the OpenTofu Lab Automation project using the mandatory PatchManager workflow.

Apply the [PatchManager enforcement](../.vscode/instructions/patchmanager-enforcement.instructions.md) and [PowerShell standards](../.vscode/instructions/powershell-standards.instructions.md).

Process for fixing errors:
1. **Identify Issues**: Analyze the code for syntax errors, PSScriptAnalyzer violations, and compatibility issues
2. **Plan Fixes**: Determine the minimal changes needed to resolve issues
3. **Apply PatchManager**: Wrap ALL file changes in `Invoke-GitControlledPatch`
4. **Validate**: Include proper testing to ensure fixes don't break functionality

Common fixes to apply:
* Add `#Requires -Version 7.0` for cross-platform compatibility
* Fix path separators to use forward slashes
* Replace Windows-specific cmdlets with cross-platform alternatives
* Add proper error handling with try-catch blocks
* Implement `Write-CustomLog` for consistent logging
* Add parameter validation attributes
* Fix module import paths to use absolute paths
* Ensure `[CmdletBinding(SupportsShouldProcess)]` usage

Required PatchManager workflow:
```powershell
Invoke-GitControlledPatch -PatchDescription "Fix: PowerShell script errors" -PatchOperation {
    # File fixing logic here
} -AutoCommitUncommitted -TestCommands @(
    "Invoke-Pester tests/",
    "Invoke-ScriptAnalyzer path/to/fixed/script.ps1"
)
```

**CRITICAL**: Never edit files directly. All changes must use the PatchManager workflow.
