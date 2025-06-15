# PatchManager Agent Integration

## Self-Healing Workflow

PatchManager leverages CodeFixer and PSScriptAnalyzer for automated linting and fixing. The workflow includes:

1. **Linting**: Detect issues using PSScriptAnalyzer.
2. **Fixing**: Apply fixes using CodeFixer functions (e.g., `Invoke-TestSyntaxFix`, `Invoke-TernarySyntaxFix`).
3. **Validation**: Run Pester tests to ensure fixes are valid.

## Integration

- **CodeFixer**: Provides functions for syntax fixes.
- **PSScriptAnalyzer**: Detects linting issues.
- **Pester**: Validates fixes through tests.

## Usage

Run the self-healing process:
```powershell
Invoke-SelfHeal -Path "/pwsh/modules/PatchManager"
```
