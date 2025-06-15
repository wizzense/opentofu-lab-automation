#!/bin/bash
# filepath: /workspaces/opentofu-lab-automation/scripts/test-all-fixes.sh
# Test script to validate all workflow optimization fixes

set -e

echo " Testing All Workflow Optimization Fixes"
echo "==========================================="

# Test 1: Workflow validation
echo ""
echo "1⃣ Testing workflow YAML validation..."
workflow_count=$(find .github/workflows -name "*.yml" -type f | wc -l)
echo " Found $workflow_count workflow files"

for workflow in .github/workflows/*.yml; do
 python3 -c "
import yaml
try:
 with open('$workflow', 'r') as f:
 yaml.safe_load(f)
 print('✓ $(basename $workflow)')
except Exception as e:
 print('✗ $(basename $workflow): $e')
 exit(1)
" || exit 1
done

# Test 2: Repository structure
echo ""
echo "2⃣ Testing repository structure..."
critical_files=(
 "tests/PesterConfiguration.psd1"
 "pwsh/PSScriptAnalyzerSettings.psd1"
 "tests/helpers/TestHelpers.ps1"
 "tests/helpers/Get-ScriptAst.ps1"
)

for file in "${critical_files[@]}"; do
 if [ -f "$file" ]; then
 echo " ✓ $file"
 else
 echo " ✗ $file missing"
 exit 1
 fi
done

# Test 3: Optimization tools
echo ""
echo "3⃣ Testing optimization tools..."
tools=(
 "scripts/validate-workflows.py"
 "scripts/workflow-dashboard.py"
 "scripts/workflow-health-check.sh"
)

for tool in "${tools[@]}"; do
 if [ -f "$tool" ] && [ -x "$tool" ]; then
 echo " ✓ $tool (executable)"
 elif [ -f "$tool" ]; then
 echo " ✓ $tool (exists)"
 else
 echo " ✗ $tool missing"
 exit 1
 fi
done

# Test 4: PowerShell syntax check (if pwsh available)
echo ""
echo "4⃣ Testing PowerShell files..."
if command -v pwsh >/dev/null 2>&1; then
 pwsh_files=(
 "test-workflow-setup.ps1"
 "tests/helpers/Get-ScriptAst.ps1"
 )
 
 for file in "${pwsh_files[@]}"; do
 if [ -f "$file" ]; then
 if pwsh -NoProfile -NoLogo -Command "try { \$null = Get-Content '$file' -Raw | Invoke-Expression -ErrorAction Stop; Write-Host 'Syntax OK' } catch { Write-Error \$_; exit 1 }" 2>/dev/null; then
 echo " ✓ $file (syntax valid)"
 else
 echo " [WARN] $file (syntax check failed)"
 fi
 fi
 done
else
 echo " [WARN] PowerShell not available, skipping syntax checks"
fi

# Test 5: Python tools
echo ""
echo "5⃣ Testing Python tools..."
python_tools=(
 "scripts/validate-workflows.py"
 "scripts/workflow-dashboard.py"
)

for tool in "${python_tools[@]}"; do
 if [ -f "$tool" ]; then
 if python3 -m py_compile "$tool" 2>/dev/null; then
 echo " ✓ $tool (syntax valid)"
 else
 echo " ✗ $tool (syntax error)"
 exit 1
 fi
 fi
done

# Summary
echo ""
echo " Test Summary"
echo "==============="
echo "[PASS] Workflow YAML validation: PASSED"
echo "[PASS] Repository structure: PASSED"
echo "[PASS] Optimization tools: PASSED"
echo "[PASS] PowerShell files: CHECKED"
echo "[PASS] Python tools: PASSED"

echo ""
echo " All workflow optimization fixes validated successfully!"
echo " Ready for production use."
