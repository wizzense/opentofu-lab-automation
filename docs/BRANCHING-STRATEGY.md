# 🌳 Branching Strategy & Workflow Guidelines

## 🎯 Branch Strategy

### Main Branches
- **main**: Production-ready code, protected branch
- **develop**: Integration branch for feature development (optional)

### Feature Branches
- **feature/description**: New features or enhancements
- **fix/description**: Bug fixes
- **hotfix/description**: Critical production fixes
- **docs/description**: Documentation updates

## 🔄 Workflow Process

### 1. Creating Feature Branches
\\\ash
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
\\\

### 2. Pull Request Process
1. **Create PR** from feature branch to main
2. **Auto-validation** runs (CI/CD pipeline)
3. **Auto-fixes** applied if needed
4. **Review & approval** required
5. **Merge** to main (squash merge preferred)
6. **Branch cleanup** automatic

### 3. Hotfix Process
\\\ash
# For critical fixes
git checkout main
git pull origin main
git checkout -b hotfix/critical-issue

# Make fix and test
git commit -m "fix: resolve critical issue"
git push origin hotfix/critical-issue

# Create PR for immediate review
\\\

## 🛡️ Protection Rules

### Main Branch Protection
- ✅ Require PR reviews (1+ approvals)
- ✅ Require status checks (CI/CD must pass)
- ✅ Require up-to-date branches
- ✅ Auto-delete head branches after merge
- ✅ Restrict force pushes
- ✅ Restrict deletions

### Auto-Validation Requirements
- ✅ PowerShell syntax validation
- ✅ YAML lint checks
- ✅ Pester test execution
- ✅ Auto-fix application
- ✅ Security scanning

## 🔧 Auto-Fix Integration

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

## 📋 Commit Message Convention

\\\
<type>(<scope>): <description>

[optional body]

[optional footer]
\\\

### Types
- **feat**: New feature
- **fix**: Bug fix  
- **docs**: Documentation changes
- **style**: Code style changes
- **refactor**: Code refactoring
- **test**: Test changes
- **chore**: Maintenance tasks

### Examples
\\\
feat(gui): add timeout handling for deploy script downloads
fix(workflow): resolve merge conflicts in CI pipeline
docs(readme): simplify deployment instructions for Server Core
chore(deps): update PowerShell modules to latest versions
\\\

## 🚨 Merge Conflict Prevention

### Before Creating PR
1. **Sync with main**: \git pull origin main\
2. **Run validation**: \./scripts/maintenance/unified-maintenance.ps1 -Mode Quick\
3. **Check for conflicts**: \git merge-tree \6d69547812305ebc39c4faa4466b5112f0dce25d HEAD main\

### If Conflicts Occur
1. **Abort and restart**: \git merge --abort\
2. **Rebase on main**: \git rebase main\
3. **Resolve conflicts**: Use IDE or merge tools
4. **Re-validate**: Run tests and auto-fixes
5. **Force push**: \git push --force-with-lease\

## 🔄 Regular Maintenance

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
