#!/bin/bash
# filepath: /workspaces/opentofu-lab-automation/scripts/workflow-health-check.sh
# Quick workflow health check script

set -e

echo "🏥 GitHub Actions Workflow Health Check"
echo "======================================"

# Check if we're in a git repository
if [ ! -d ".github/workflows" ]; then
    echo "❌ Not in a GitHub repository with workflows"
    exit 1
fi

# Count workflows
WORKFLOW_COUNT=$(find .github/workflows -name "*.yml" -type f | wc -l)
echo "📊 Found $WORKFLOW_COUNT workflow files"

# Check for common issues
echo ""
echo "🔍 Checking for common issues..."

# Check for very long workflows
LONG_WORKFLOWS=$(find .github/workflows -name "*.yml" -exec wc -l {} + | awk '$1 > 200 {print $2 " (" $1 " lines)"}' | grep -v total || true)
if [ -n "$LONG_WORKFLOWS" ]; then
    echo "⚠️  Long workflows found:"
    echo "$LONG_WORKFLOWS" | sed 's/^/   /'
else
    echo "✅ No excessively long workflows"
fi

# Check for workflows without caching
WORKFLOWS_WITHOUT_CACHE=$(grep -L "cache@" .github/workflows/*.yml | wc -l)
CACHE_PERCENTAGE=$((100 - (WORKFLOWS_WITHOUT_CACHE * 100 / WORKFLOW_COUNT)))
echo "📦 Cache usage: $CACHE_PERCENTAGE% of workflows use caching"

# Check for workflows without artifacts
WORKFLOWS_WITHOUT_ARTIFACTS=$(grep -L "upload-artifact@" .github/workflows/*.yml | wc -l)
ARTIFACTS_PERCENTAGE=$((100 - (WORKFLOWS_WITHOUT_ARTIFACTS * 100 / WORKFLOW_COUNT)))
echo "📁 Artifact usage: $ARTIFACTS_PERCENTAGE% of workflows upload artifacts"

# Check for recent workflow runs (if gh cli is available)
echo ""
echo "🏃 Recent workflow activity..."
if command -v gh >/dev/null 2>&1; then
    RECENT_FAILURES=$(gh run list --limit 10 --json conclusion | jq -r '.[] | select(.conclusion == "failure") | .conclusion' | wc -l || echo "0")
    echo "❌ Recent failures: $RECENT_FAILURES out of last 10 runs"
    
    if [ "$RECENT_FAILURES" -gt 5 ]; then
        echo "⚠️  High failure rate detected!"
        gh run list --limit 5 --json workflowName,conclusion,status --template '{{range .}}{{.workflowName}}: {{.conclusion}}{{"\n"}}{{end}}'
    fi
else
    echo "ℹ️  GitHub CLI not available - skipping run history"
fi

# Check critical files
echo ""
echo "📋 Checking critical files..."

CRITICAL_FILES=(
    "tests/PesterConfiguration.psd1"
    "pwsh/PSScriptAnalyzerSettings.psd1"
    "tests/helpers/TestHelpers.ps1"
    "tests/helpers/Get-ScriptAst.ps1"
)

for file in "${CRITICAL_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file exists"
    else
        echo "❌ $file missing"
    fi
done

# Overall health score
echo ""
echo "🎯 Overall Health Score"
echo "====================="

HEALTH_SCORE=0

# Scoring criteria
[ "$CACHE_PERCENTAGE" -gt 50 ] && HEALTH_SCORE=$((HEALTH_SCORE + 25))
[ "$ARTIFACTS_PERCENTAGE" -gt 50 ] && HEALTH_SCORE=$((HEALTH_SCORE + 25))
[ "$WORKFLOW_COUNT" -lt 20 ] && HEALTH_SCORE=$((HEALTH_SCORE + 25)) # Not too many workflows
[ -z "$LONG_WORKFLOWS" ] && HEALTH_SCORE=$((HEALTH_SCORE + 25))

if [ "$HEALTH_SCORE" -ge 75 ]; then
    echo "🟢 Health Score: $HEALTH_SCORE/100 - Excellent"
elif [ "$HEALTH_SCORE" -ge 50 ]; then
    echo "🟡 Health Score: $HEALTH_SCORE/100 - Good"
elif [ "$HEALTH_SCORE" -ge 25 ]; then
    echo "🟠 Health Score: $HEALTH_SCORE/100 - Needs Improvement"
else
    echo "🔴 Health Score: $HEALTH_SCORE/100 - Poor"
fi

echo ""
echo "💡 Run 'python3 scripts/workflow-dashboard.py' for detailed analysis"
echo "🔧 Run 'python3 scripts/validate-workflows.py' for comprehensive validation"
