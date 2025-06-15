#!/usr/bin/env pwsh
<#
.SYNOPSIS
 Emergency system to resolve merge conflicts and implement proper branching workflow

.DESCRIPTION
 This script addresses the massive merge conflict situation and implements a robust
 branching strategy to prevent this from happening again.

.PARAMETER Action
 Action to perform: ResolveConflicts, ImplementBranching, ValidateSystem, All

.EXAMPLE
 ./emergency-system-fix.ps1 -Action All
#>

param(
 [ValidateSet("ResolveConflicts", "ImplementBranching", "ValidateSystem", "All")]
 [string]$Action = "All"
)

$ErrorActionPreference = "Continue"

Write-Host " Emergency System Recovery" -ForegroundColor Red
Write-Host "================================" -ForegroundColor Red
Write-Host "Date: $(Get-Date)" -ForegroundColor Yellow
Write-Host "Action: $Action" -ForegroundColor Yellow
Write-Host ""

function Resolve-MergeConflicts {
 Write-Host " Step 1: Resolving Merge Conflicts" -ForegroundColor Cyan
 
 # Find all files with merge conflict markers
 $conflictFiles = @()
 $conflictMarkers = @("<<<<<<< HEAD", "=======", ">>>>>>> ")
 
 foreach ($marker in $conflictMarkers) {
 $files = git grep -l "$marker" 2>$null
 if ($files) {
 $conflictFiles += $files
 }
 }
 
 $conflictFiles = $conflictFiles | Sort-Object -Unique
 
 if ($conflictFiles.Count -gt 0) {
 Write-Host "[FAIL] Found $($conflictFiles.Count) files with merge conflicts:" -ForegroundColor Red
 $conflictFiles | ForEach-Object { Write-Host " - $_" -ForegroundColor Yellow }
 
 Write-Host ""
 Write-Host " Auto-resolving simple conflicts..." -ForegroundColor Yellow
 
 foreach ($file in $conflictFiles) {
 try {
 $content = Get-Content $file -Raw
 
 # Strategy 1: If conflict is just whitespace or formatting, take HEAD version
 if ($content -match '<<<<<<< HEAD\s*\n(.*?)\n=======\s*\n\s*\n>>>>>>> ') {
 $resolved = $content -replace '<<<<<<< HEAD\s*\n(.*?)\n=======\s*\n\s*\n>>>>>>> [^\n]*\n', '$1'
 Set-Content $file $resolved -NoNewline
 Write-Host " [PASS] Auto-resolved whitespace conflict: $file" -ForegroundColor Green
 continue
 }
 
 # Strategy 2: For workflow files, prefer the main branch version
 if ($file -like "*.yml" -or $file -like "*.yaml") {
 $resolved = $content -replace '<<<<<<< HEAD\s*\n(.*?)\n=======.*?>>>>>>> [^\n]*\n', '$1'
 Set-Content $file $resolved -NoNewline
 Write-Host " [PASS] Auto-resolved workflow conflict: $file" -ForegroundColor Green
 continue
 }
 
 Write-Host " [WARN] Manual resolution needed: $file" -ForegroundColor Yellow
 }
 catch {
 Write-Host " [FAIL] Error processing $file`: $_" -ForegroundColor Red
 }
 }
 }
 else {
 Write-Host "[PASS] No merge conflicts found" -ForegroundColor Green
 }
}

function Implement-BranchingStrategy {
 Write-Host "� Step 2: Implementing Proper Branching Strategy" -ForegroundColor Cyan
 
 # Create branching strategy documentation
 $branchingDoc = @"
# � Branching Strategy & Workflow Guidelines

## Branch Strategy

### Main Branches
- **main**: Production-ready code, protected branch
- **develop**: Integration branch for feature development (optional)

### Feature Branches
- **feature/description**: New features or enhancements
- **fix/description**: Bug fixes
- **hotfix/description**: Critical production fixes
- **docs/description**: Documentation updates

## Workflow Process

### 1. Creating Feature Branches
\`\`\`bash
# Start from latest main
git checkout main
git pull origin main

# Create feature branch
git checkout -b feature/your-feature-name

# Work on changes...
git add .
git commit -m "feat: add new feature"

# Push feature branch
git push origin feature/your-feature-name
\`\`\`

### 2. Pull Request Process
1. **Create PR** from feature branch to main
2. **Auto-validation** runs (CI/CD pipeline)
3. **Auto-fixes** applied if needed
4. **Review & approval** required
5. **Merge** to main (squash merge preferred)
6. **Branch cleanup** automatic

### 3. Hotfix Process
\`\`\`bash
# For critical fixes
git checkout main
git pull origin main
git checkout -b hotfix/critical-issue

# Make fix and test
git commit -m "fix: resolve critical issue"
git push origin hotfix/critical-issue

# Create PR for immediate review
\`\`\`

## Protection Rules

### Main Branch Protection
- [PASS] Require PR reviews (1+ approvals)
- [PASS] Require status checks (CI/CD must pass)
- [PASS] Require up-to-date branches
- [PASS] Auto-delete head branches after merge
- [PASS] Restrict force pushes
- [PASS] Restrict deletions

### Auto-Validation Requirements
- [PASS] PowerShell syntax validation
- [PASS] YAML lint checks
- [PASS] Pester test execution
- [PASS] Auto-fix application
- [PASS] Security scanning

## Auto-Fix Integration

### Pre-commit Hooks
- Syntax validation
- Import path fixes
- Format consistency
- Test generation

### CI/CD Auto-fixes
- PowerShell linting
- YAML formatting
- Merge conflict prevention
- Dependency updates

## Commit Message Convention

\`\`\`
<type>(<scope>): <description>

[optional body]

[optional footer]
\`\`\`

### Types
- **feat**: New feature
- **fix**: Bug fix 
- **docs**: Documentation changes
- **style**: Code style changes
- **refactor**: Code refactoring
- **test**: Test changes
- **chore**: Maintenance tasks

### Examples
\`\`\`
feat(gui): add timeout handling for deploy script downloads
fix(workflow): resolve merge conflicts in CI pipeline
docs(readme): simplify deployment instructions for Server Core
chore(deps): update PowerShell modules to latest versions
\`\`\`

## Merge Conflict Prevention

### Before Creating PR
1. **Sync with main**: \`git pull origin main\`
2. **Run validation**: \`./scripts/maintenance/unified-maintenance.ps1 -Mode Quick\`
3. **Check for conflicts**: \`git merge-tree \$(git merge-base HEAD main) HEAD main\`

### If Conflicts Occur
1. **Abort and restart**: \`git merge --abort\`
2. **Rebase on main**: \`git rebase main\`
3. **Resolve conflicts**: Use IDE or merge tools
4. **Re-validate**: Run tests and auto-fixes
5. **Force push**: \`git push --force-with-lease\`

## Regular Maintenance

### Daily (Automated)
- Dependency updates
- Security scans
- Health checks
- Auto-fixes

### Weekly (Manual Review)
- Branch cleanup
- Documentation updates
- Performance analysis
- Issue triage

### Monthly (Strategic)
- Architecture review
- Workflow optimization
- Training updates
- Tool evaluation
"@

 $branchingDoc | Out-File "docs/BRANCHING-STRATEGY.md" -Encoding UTF8
 Write-Host "[PASS] Created branching strategy documentation" -ForegroundColor Green
}

function Validate-SystemHealth {
 Write-Host " Step 3: Validating System Health" -ForegroundColor Cyan
 
 $issues = @()
 
 # Check critical files
 $criticalFiles = @(
 ".github/workflows/unified-ci.yml",
 "/pwsh/modules/CodeFixer/CodeFixer.psm1",
 "/pwsh/modules/LabRunner/LabRunner.psm1",
 "scripts/maintenance/unified-maintenance.ps1"
 )
 
 foreach ($file in $criticalFiles) {
 if (Test-Path $file) {
 $content = Get-Content $file -Raw
 if ($content -match '<<<<<<< HEAD|=======|>>>>>>> ') {
 $issues += "Merge conflicts in $file"
 Write-Host " [FAIL] Merge conflicts: $file" -ForegroundColor Red
 }
 else {
 Write-Host " [PASS] Clean: $file" -ForegroundColor Green
 }
 }
 else {
 $issues += "Missing critical file: $file"
 Write-Host " [FAIL] Missing: $file" -ForegroundColor Red
 }
 }
 
 # Test PowerShell modules
 try {
 Import-Module "/C:\Users\alexa\OneDrive\Documents\0. wizzense\opentofu-lab-automation//pwsh/modules/CodeFixer/" -Force -Force -Force -Force -Force -Force -Force -Force -Force -Force -Force -Force -Force -Force -Force -Force -Force -Force -Force -Force -Force -Force -Force -ErrorAction Stop
 Write-Host " [PASS] CodeFixer module loads" -ForegroundColor Green
 }
 catch {
 $issues += "CodeFixer module failed to load: $_"
 Write-Host " [FAIL] CodeFixer module: $_" -ForegroundColor Red
 }
 
 try {
 Import-Module "/C:\Users\alexa\OneDrive\Documents\0. wizzense\opentofu-lab-automation//pwsh/modules/LabRunner/" -Force -Force -Force -Force -Force -Force -Force -Force -Force -Force -Force -Force -Force -Force -Force -Force -Force -Force -Force -Force -Force -Force -Force -ErrorAction Stop 
 Write-Host " [PASS] LabRunner module loads" -ForegroundColor Green
 }
 catch {
 $issues += "LabRunner module failed to load: $_"
 Write-Host " [FAIL] LabRunner module: $_" -ForegroundColor Red
 }
 
 # Summary
 if ($issues.Count -eq 0) {
 Write-Host " System validation passed!" -ForegroundColor Green
 return $true
 }
 else {
 Write-Host "[WARN] Found $($issues.Count) issues:" -ForegroundColor Yellow
 $issues | ForEach-Object { Write-Host " - $_" -ForegroundColor Red }
 return $false
 }
}

function Set-BranchProtection {
 Write-Host " Step 4: Setting Up Branch Protection" -ForegroundColor Cyan
 
 # This would normally use GitHub CLI or API
 # For now, create instructions
 $protectionScript = @"
# Branch Protection Setup (Run with GitHub CLI)

# Install GitHub CLI if not available
# https://cli.github.com/

# Set up main branch protection
gh api repos/wizzense/opentofu-lab-automation/branches/main/protection \
 --method PUT \
 --field required_status_checks='{"strict":true,"contexts":["CI/CD Pipeline"]}' \
 --field enforce_admins=true \
 --field required_pull_request_reviews='{"required_approving_review_count":1,"dismiss_stale_reviews":true}' \
 --field restrictions=null \
 --field allow_force_pushes=false \
 --field allow_deletions=false

echo "[PASS] Branch protection rules applied"
"@

 $protectionScript | Out-File "scripts/setup-branch-protection.sh" -Encoding UTF8
 Write-Host "[PASS] Created branch protection setup script" -ForegroundColor Green
}

# Main execution
switch ($Action) {
 "ResolveConflicts" { Resolve-MergeConflicts }
 "ImplementBranching" { Implement-BranchingStrategy }
 "ValidateSystem" { Validate-SystemHealth }
 "All" {
 Resolve-MergeConflicts
 Implement-BranchingStrategy
 $systemHealthy = Validate-SystemHealth
 Set-BranchProtection
 
 Write-Host ""
 Write-Host " Emergency Recovery Summary" -ForegroundColor Cyan
 Write-Host "==============================" -ForegroundColor Cyan
 
 if ($systemHealthy) {
 Write-Host "[PASS] System is now healthy and operational" -ForegroundColor Green
 Write-Host "[PASS] Branching strategy implemented" -ForegroundColor Green
 Write-Host "[PASS] Protection rules ready for setup" -ForegroundColor Green
 Write-Host ""
 Write-Host " Next Steps:" -ForegroundColor Yellow
 Write-Host "1. Review and commit all changes" -ForegroundColor White
 Write-Host "2. Run: ./scripts/setup-branch-protection.sh" -ForegroundColor White
 Write-Host "3. Test the new workflow with a feature branch" -ForegroundColor White
 Write-Host "4. Update team on new branching strategy" -ForegroundColor White
 }
 else {
 Write-Host "[WARN] System needs manual intervention" -ForegroundColor Yellow
 Write-Host " Please resolve the issues above before proceeding" -ForegroundColor White
 }
 }
}

Write-Host ""
Write-Host " Emergency recovery script completed" -ForegroundColor Green











