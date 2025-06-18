# PatchManager Quick Operations

## Standard Git Workflow

```powershell
# Set environment (if not already set)
$env:PROJECT_ROOT = if ($env:PROJECT_ROOT) { $env:PROJECT_ROOT } else { (Get-Location).Path }

# Quick branch and commit
git checkout -b "feat/$(Get-Date -Format 'yyyyMMdd')-description"
git add .
git commit -m "feat(scope): description"
git push origin feat/$(Get-Date -Format 'yyyyMMdd')-description
```

## PatchManager Operations

```powershell
# Import modules
Import-Module "$env:PROJECT_ROOT/core-runner/modules/Logging" -Force -ErrorAction SilentlyContinue
Import-Module "$env:PROJECT_ROOT/core-runner/modules/PatchManager" -Force

# Use GitControlledPatch for complex operations
Invoke-GitControlledPatch -PatchDescription "feat(module): implement functionality" -CreatePullRequest

# Enhanced Git operations
Invoke-EnhancedGitOperations -Operation "MergeMain" -ValidateAfter
```

## Troubleshooting

```powershell
# Check module loading
if (-not (Get-Module PatchManager)) {
    Import-Module "$env:PROJECT_ROOT/core-runner/modules/Logging" -Force
    Import-Module "$env:PROJECT_ROOT/core-runner/modules/PatchManager" -Force
}

# Clear git locks
$lockedFiles = @(".git/index.lock", ".git/refs/heads.lock")
$lockedFiles | ForEach-Object { if (Test-Path $_) { Remove-Item $_ -Force } }
```
