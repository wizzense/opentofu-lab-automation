---
description: Create new Git branch and prepare development environment with proper validation
mode: agent
tools: ["git", "filesystem", "powershell"]
---

# Create Feature Branch and Setup

Create a new Git feature branch following project standards, run pre-development validation, and set up the development environment properly.

## Branch Creation Workflow

### 1. Validate Current State
```powershell
# Before creating any branch, validate current project state
Write-Host "Validating current project state..." -ForegroundColor Cyan

# Import required modules
Import-Module "/pwsh/modules/LabRunner/" -Force
Import-Module "/pwsh/modules/CodeFixer/" -Force

# Check for uncommitted changes
$uncommittedChanges = git status --porcelain
if ($uncommittedChanges) {
    Write-Host "WARNING: Uncommitted changes detected:" -ForegroundColor Yellow
    git status --short
    $response = Read-Host "Do you want to commit or stash these changes? (c/s/abort)"
    
    switch ($response.ToLower()) {
        'c' { 
            git add -A
            $commitMessage = Read-Host "Enter commit message"
            git commit -m $commitMessage
        }
        's' { 
            git stash push -m "Auto-stash before branch creation $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
        }
        default { 
            Write-Host "ERROR: Branch creation aborted" -ForegroundColor Red
            return
        }
    }
}

# Run quick health check
Write-Host "Running pre-branch health check..." -ForegroundColor Yellow
$healthResult = ./scripts/maintenance/unified-maintenance.ps1 -Mode "Quick"
if ($healthResult.TotalErrors -gt 0) {
    Write-Host "Health check failed. Fix issues before creating branch." -ForegroundColor Red
    return
}
```

### 2. Create Feature Branch
```bash
# Ensure we're on the correct base branch
git checkout ${input:baseBranch|main}
git pull origin ${input:baseBranch|main}

# Create and switch to new feature branch
git checkout -b ${input:branchType}/${input:branchName}

# Examples of branch types:
# feature/enhance-codefixer-parallel-processing
# fix/module-import-path-issues  
# docs/update-api-documentation
# chore/cleanup-archive-files
# test/add-cross-platform-validation
```

### 3. Branch Setup Validation
```powershell
# Validate branch setup
Write-Host "Setting up new branch: ${input:branchType}/${input:branchName}" -ForegroundColor Green

# Verify branch was created
$currentBranch = git branch --show-current
if ($currentBranch -ne "${input:branchType}/${input:branchName}") {
    throw "Branch creation failed. Current branch: $currentBranch"
}

# Set up branch tracking
git push -u origin ${input:branchType}/${input:branchName}

# Create branch info file
$branchInfo = @{
    branchName = "${input:branchType}/${input:branchName}"
    baseBranch = "${input:baseBranch|main}"
    createdDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    creator = git config user.name
    purpose = "${input:branchPurpose}"
    estimatedCompletion = "${input:estimatedCompletion}"
    relatedIssues = @(${input:relatedIssues})
}

$branchInfo | ConvertTo-Json -Depth 3 | Set-Content "./.branch-info.json"
git add .branch-info.json
git commit -m "chore: initialize branch ${input:branchType}/${input:branchName}"
```

## Development Environment Setup

### 4. Environment Validation
```powershell
# Validate development environment
Write-Host " Setting up development environment..." -ForegroundColor Cyan

# 1. Verify PowerShell modules
$requiredModules = @("LabRunner", "CodeFixer")
foreach ($module in $requiredModules) {
    try {
        Import-Module "/pwsh/modules/$module/" -Force
        Write-Host " $module module loaded" -ForegroundColor Green
    } catch {
        Write-Host " Failed to load $module module: $_" -ForegroundColor Red
        throw "Module setup failed"
    }
}

# 2. Verify VS Code settings
if (Test-Path ".vscode/settings.json") {
    $settings = Get-Content ".vscode/settings.json" | ConvertFrom-Json
    if ($settings.'github.copilot.chat.codeGeneration.useInstructionFiles') {
        Write-Host " GitHub Copilot instructions enabled" -ForegroundColor Green
    } else {
        Write-Host " GitHub Copilot instructions not enabled" -ForegroundColor Yellow
    }
}

# 3. Verify Git hooks
$preCommitHook = ".git/hooks/pre-commit"
if (-not (Test-Path $preCommitHook)) {
    Write-Host " Pre-commit hook not found. Installing..." -ForegroundColor Yellow
    ./scripts/setup/Install-GitHooks.ps1
}

# 4. Create development workspace
$devWorkspace = "./.dev-workspace"
if (-not (Test-Path $devWorkspace)) {
    New-Item -ItemType Directory -Path $devWorkspace -Force
    
    # Create development scripts
    @"
# Development utility scripts for ${input:branchType}/${input:branchName}

# Quick validation
function Test-BranchChanges {
    Import-Module "/pwsh/modules/CodeFixer/" -Force
    `$changedFiles = git diff --name-only ${input:baseBranch|main}
    if (`$changedFiles) {
        Invoke-PowerShellLint -Files `$changedFiles -OutputFormat "CI"
    }
}

# Run tests for changed modules
function Test-ChangedModules {
    `$changedFiles = git diff --name-only ${input:baseBranch|main}
    `$affectedModules = Get-AffectedModules -Files `$changedFiles
    if (`$affectedModules) {
        Invoke-Pester -Path "./tests/" -Tag `$affectedModules
    }
}

# Quick commit with validation
function Invoke-QuickCommit {
    param([string]`$Message)
    
    # Pre-commit validation
    if (Test-BranchChanges) {
        git add -A
        git commit -m `$Message
        Write-Host " Commit successful" -ForegroundColor Green
    } else {
        Write-Host " Commit aborted due to validation failures" -ForegroundColor Red
    }
}
"@ | Set-Content "$devWorkspace/dev-utils.ps1"
}
```

### 5. Pre-Development Checks
```powershell
# Run comprehensive pre-development validation
Write-Host " Running pre-development validation..." -ForegroundColor Yellow

# 1. Code quality baseline
$baselineResult = Invoke-PowerShellLint -Path "." -PassThru -OutputFormat "JSON"
$baselineResult | ConvertTo-Json | Set-Content "./.dev-workspace/baseline-lint.json"

# 2. Test baseline
try {
    $baselineTests = Invoke-Pester -Path "./tests/" -PassThru -Output None
    $testBaseline = @{
        passed = $baselineTests.PassedCount
        failed = $baselineTests.FailedCount
        total = $baselineTests.TotalCount
        timestamp = Get-Date
    }
    $testBaseline | ConvertTo-Json | Set-Content "./.dev-workspace/baseline-tests.json"
} catch {
    Write-Host " Baseline tests could not be established: $_" -ForegroundColor Yellow
}

# 3. Performance baseline
try {
    $performanceBaseline = ./scripts/performance/Invoke-PerformanceBenchmarks.ps1 -Quick
    $performanceBaseline | ConvertTo-Json | Set-Content "./.dev-workspace/baseline-performance.json"
} catch {
    Write-Host " Performance baseline could not be established" -ForegroundColor Yellow
}

# 4. Documentation check
$docFiles = Get-ChildItem -Path "./docs/" -Filter "*.md" -Recurse
$docBaseline = @{
    fileCount = $docFiles.Count
    totalSize = ($docFiles | Measure-Object -Property Length -Sum).Sum
    lastUpdated = ($docFiles | Sort-Object LastWriteTime -Descending | Select-Object -First 1).LastWriteTime
}
$docBaseline | ConvertTo-Json | Set-Content "./.dev-workspace/baseline-docs.json"
```

## Continuous Integration Setup

### 6. CI/CD Integration
```powershell
# Set up branch-specific CI configuration
Write-Host " Setting up CI/CD integration..." -ForegroundColor Cyan

# Create branch-specific workflow (if needed)
$branchWorkflow = @"
name: "Feature Branch Validation - ${input:branchType}/${input:branchName}"

on:
  push:
    branches: [ ${input:branchType}/${input:branchName} ]
  pull_request:
    branches: [ ${input:baseBranch|main} ]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4.1.1
      - name: "Setup PowerShell"
        uses: actions/setup-powershell@v1
        with:
          pwsh: true
      - name: "Run Validation"
        shell: pwsh
        run: |
          Import-Module "/pwsh/modules/LabRunner/" -Force
          Import-Module "/pwsh/modules/CodeFixer/" -Force
          Invoke-ComprehensiveValidation -OutputFormat "CI"
"@

# Only create if this is a long-term feature branch
if ("${input:branchType}" -eq "feature" -and "${input:longTerm}" -eq "true") {
    $branchWorkflow | Set-Content "./.github/workflows/branch-${input:branchName}.yml"
    git add "./.github/workflows/branch-${input:branchName}.yml"
    git commit -m "ci: add branch-specific workflow"
}
```

### 7. Development Guidelines
```powershell
# Create development guidelines for this branch
$guidelines = @"
# Development Guidelines for ${input:branchType}/${input:branchName}

## Purpose
${input:branchPurpose}

## Development Checklist
- [ ] All changes follow OpenTofu Lab Automation standards
- [ ] PowerShell scripts use proper module imports (/pwsh/modules/)
- [ ] Error handling includes Write-CustomLog usage
- [ ] Cross-platform compatibility maintained
- [ ] Tests updated for new functionality
- [ ] Documentation updated as needed

## Before Each Commit
```powershell
# Run development validation
. ./.dev-workspace/dev-utils.ps1
Test-BranchChanges

# Run affected tests
Test-ChangedModules

# Quick health check
./scripts/maintenance/unified-maintenance.ps1 -Mode Quick
```

## Before Creating PR
```powershell
# Comprehensive validation
Invoke-ComprehensiveValidation -Path "." -OutputFormat "Detailed"

# Security check
./scripts/security/Invoke-SecurityValidation.ps1

# Performance validation
./scripts/performance/Invoke-PerformanceBenchmarks.ps1 -Compare ./.dev-workspace/baseline-performance.json

# Update project manifest
Update-ProjectManifest -IncrementalUpdate
```

## Related Issues
${input:relatedIssues}

## Estimated Completion
${input:estimatedCompletion}
"@

$guidelines | Set-Content "./.dev-workspace/DEVELOPMENT-GUIDELINES.md"
```

### 8. Final Setup Validation
```powershell
# Final validation of branch setup
Write-Host " Validating complete branch setup..." -ForegroundColor Green

$setupValidation = @{
    branchCreated = (git branch --show-current) -eq "${input:branchType}/${input:branchName}"
    branchTracked = (git remote show origin | Select-String "${input:branchType}/${input:branchName}") -ne $null
    modulesLoaded = (Get-Module LabRunner) -and (Get-Module CodeFixer)
    devWorkspaceCreated = Test-Path "./.dev-workspace"
    branchInfoCreated = Test-Path "./.branch-info.json"
    guidelinesCreated = Test-Path "./.dev-workspace/DEVELOPMENT-GUIDELINES.md"
}

$setupValidation | ConvertTo-Json | Set-Content "./.dev-workspace/setup-validation.json"

$failedChecks = $setupValidation.GetEnumerator() | Where-Object { -not $_.Value }
if ($failedChecks) {
    Write-Host " Setup validation failed:" -ForegroundColor Red
    $failedChecks | ForEach-Object { Write-Host "  - $($_.Key)" -ForegroundColor Red }
} else {
    Write-Host " Branch setup completed successfully!" -ForegroundColor Green
    Write-Host " Development guidelines: ./.dev-workspace/DEVELOPMENT-GUIDELINES.md" -ForegroundColor Cyan
    Write-Host " Development utilities: ./.dev-workspace/dev-utils.ps1" -ForegroundColor Cyan
}

# Log branch creation
Write-CustomLog "Created feature branch: ${input:branchType}/${input:branchName}" "INFO"
```

## Input Variables

- `${input:branchType}`: Type of branch (feature, fix, docs, chore, test)
- `${input:branchName}`: Descriptive name for the branch
- `${input:branchPurpose}`: Detailed description of branch purpose
- `${input:baseBranch}`: Base branch to branch from (usually main or develop)
- `${input:estimatedCompletion}`: Estimated completion date
- `${input:relatedIssues}`: Related issue numbers or URLs
- `${input:longTerm}`: Whether this is a long-term feature branch

## Reference Instructions

This prompt references:
- [Git Collaboration](../instructions/git-collaboration.instructions.md)
- [Maintenance Standards](../instructions/maintenance-standards.instructions.md)
- [PowerShell Standards](../instructions/powershell-standards.instructions.md)

Please specify:
1. Branch type and descriptive name
2. Purpose and scope of changes
3. Estimated timeline
4. Any related issues or requirements
5. Whether this will be a long-term feature branch
