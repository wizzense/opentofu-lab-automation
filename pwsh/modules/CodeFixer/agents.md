# CodeFixer Agent Integration

## Self-Healing Workflow

CodeFixer integrates with PatchManager to provide automated fixes for common issues. The workflow includes:

1. **Detection**: Identify issues using PSScriptAnalyzer.
2. **Fixing**: Apply fixes using CodeFixer functions.
3. **Validation**: Ensure fixes are valid using Pester.

## Integration

- **PatchManager**: Calls CodeFixer functions for fixes.
- **PSScriptAnalyzer**: Detects issues.
- **Pester**: Validates fixes.

## Usage

Run fixes:
```powershell
Invoke-AutoFix -Path "/pwsh/modules/CodeFixer"
```
