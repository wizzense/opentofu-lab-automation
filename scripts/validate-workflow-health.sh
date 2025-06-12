#!/bin/bash
# Comprehensive workflow health validation

echo "Comprehensive Workflow Health Validation"
echo "========================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

errors=0
warnings=0

echo -e "${BLUE}Checking workflow file syntax...${NC}"
for file in .github/workflows/*.yml; do
    if python3 -c "import yaml; yaml.safe_load(open('$file'))" 2>/dev/null; then
        echo -e "  ${GREEN}OK $file - Valid YAML${NC}"
    else
        echo -e "  ${RED}ERROR $file - Invalid YAML${NC}"
        ((errors++))
    fi
done

echo -e "${BLUE}Checking required files and directories...${NC}"
required_files=(
    "tests/PesterConfiguration.psd1"
    "tests/helpers/Get-ScriptAst.ps1" 
    "pwsh/runner_scripts/0201_Install-NodeCore.ps1"
    "pwsh/lab_utils/LabRunner/LabRunner.psd1"
    "pwsh/PSScriptAnalyzerSettings.psd1"
)

for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        echo -e "  ${GREEN}OK $file exists${NC}"
    else
        echo -e "  ${RED}ERROR $file missing${NC}"
        ((errors++))
    fi
done

required_dirs=(
    "coverage"
    "tests/helpers"
    "pwsh/runner_scripts"
    "pwsh/lab_utils/LabRunner"
)

for dir in "${required_dirs[@]}"; do
    if [ -d "$dir" ]; then
        echo -e "  ${GREEN}OK $dir/ exists${NC}"
    else
        echo -e "  ${YELLOW}WARNING $dir/ missing - creating...${NC}"
        mkdir -p "$dir"
        ((warnings++))
    fi
done

echo -e "${BLUE}Checking for common workflow issues...${NC}"

# Check for escaped quotes in workflows  
if grep -r "\\\\\'" .github/workflows/ >/dev/null 2>&1; then
    echo -e "  ${RED}ERROR Found escaped quotes in workflows${NC}"
    ((errors++))
else
    echo -e "  ${GREEN}OK No escaped quote issues${NC}"
fi

# Check for invalid cache keys
if grep -r "\.github/actions/lint/requirements\.txt" .github/workflows/ >/dev/null 2>&1; then
    echo -e "  ${RED}ERROR Found invalid cache key references${NC}"
    ((errors++))
else
    echo -e "  ${GREEN}OK No invalid cache key references${NC}"
fi

echo ""
echo "Validation Summary"
echo "=================="
if [ $errors -eq 0 ]; then
    echo -e "${GREEN}All critical checks passed!${NC}"
    if [ $warnings -gt 0 ]; then
        echo -e "${YELLOW}WARNING: $warnings warnings found${NC}"
    fi
    exit 0
else
    echo -e "${RED}$errors critical errors found${NC}"
    if [ $warnings -gt 0 ]; then
        echo -e "${YELLOW}WARNING: $warnings warnings found${NC}"
    fi
    echo -e "${BLUE}Please fix the errors above and re-run validation${NC}"
    exit 1
fi
