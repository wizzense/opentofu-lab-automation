






#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Archive legacy GitHub Actions workflows
.DESCRIPTION
    This script archives legacy GitHub Actions workflows that have been consolidated
    into newer, more maintainable workflows. It moves them to the .github/archived_workflows
    directory and creates a README explaining which workflows were archived.
#>

# Ensure we're running from the repository root
$repoRoot = $PSScriptRoot
if (!(Test-Path -Path "$repoRoot/.github/workflows")) {
    $repoRoot = (Get-Location).Path
    if (!(Test-Path -Path "$repoRoot/.github/workflows")) {
        Write-Error "This script must be run from the repository root or scripts directory"
        exit 1
    }
}

# Create archive directory if it doesn't exist
$archiveDir = "$repoRoot/.github/archived_workflows"
if (!(Test-Path -Path $archiveDir)) {
    New-Item -Path $archiveDir -ItemType Directory | Out-Null
    Write-Host "📁 Created archive directory: $archiveDir"
}

# Create README file for the archive directory
$readmePath = "$archiveDir/README.md"
@"
# Archived Workflows

These workflows have been consolidated into newer, more maintainable workflows.
They are kept here for reference purposes only.

See the main [workflows README](./../workflows/README.md) for details on the current workflow structure.

## Archived Workflows

| Original Workflow | Consolidated Into |
|------------------|-------------------|
"@ | Out-File -FilePath $readmePath -Encoding utf8

# List of legacy workflows to archive
$legacyWorkflows = @(
    @{ File = "pester-windows.yml"; ConsolidatedInto = "unified-testing.yml" },
    @{ File = "pester-linux.yml"; ConsolidatedInto = "unified-testing.yml" },
    @{ File = "pester-macos.yml"; ConsolidatedInto = "unified-testing.yml" },
    @{ File = "auto-test-generation.yml"; ConsolidatedInto = "auto-test-generation-consolidated.yml" },
    @{ File = "auto-test-generation-setup.yml"; ConsolidatedInto = "auto-test-generation-consolidated.yml" },
    @{ File = "auto-test-generation-execution.yml"; ConsolidatedInto = "auto-test-generation-consolidated.yml" },
    @{ File = "auto-test-generation-reporting.yml"; ConsolidatedInto = "auto-test-generation-consolidated.yml" },
    @{ File = "workflow-health-monitor.yml"; ConsolidatedInto = "system-health-monitor.yml" },
    @{ File = "comprehensive-health-monitor.yml"; ConsolidatedInto = "system-health-monitor.yml" },
    @{ File = "update-dashboard.yml"; ConsolidatedInto = "unified-utilities.yml" },
    @{ File = "update-path-index.yml"; ConsolidatedInto = "unified-utilities.yml" },
    @{ File = "update-pester-failures-doc.yml"; ConsolidatedInto = "unified-utilities.yml" },
    @{ File = "workflow-lint.yml"; ConsolidatedInto = "unified-ci.yml" },
    @{ File = "pytest.yml"; ConsolidatedInto = "unified-testing.yml" },
    @{ File = "setup-environment.yml"; ConsolidatedInto = "unified-ci.yml" }
)

# Archive each workflow and update the README
foreach ($workflow in $legacyWorkflows) {
    $sourcePath = "$repoRoot/.github/workflows/$($workflow.File)"
    $destPath = "$archiveDir/$($workflow.File)"

    if (Test-Path -Path $sourcePath) {
        try {
            Move-Item -Path $sourcePath -Destination $destPath -Force
            Write-Host "✅ Archived: $($workflow.File) → $($workflow.ConsolidatedInto)"
            
            # Add entry to README
            "| $($workflow.File) | $($workflow.ConsolidatedInto) |" | Out-File -FilePath $readmePath -Append -Encoding utf8
        }
        catch {
            Write-Error "❌ Failed to archive $($workflow.File): $_"
        }
    }
    else {
        Write-Warning "⚠️ Workflow not found: $($workflow.File)"
    }
}

# Update the main workflows README to indicate which workflows were archived
$mainReadmePath = "$repoRoot/.github/workflows/README.md"
if (Test-Path -Path $mainReadmePath) {
    $readmeContent = Get-Content -Path $mainReadmePath -Raw
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    # Add a note about archived workflows if not already present
    if ($readmeContent -notmatch "Archived on") {
        $readmeContent += @"

## Note on Archived Workflows

> Archiving completed on $timestamp

The legacy workflows mentioned above have been moved to [.github/archived_workflows](../archived_workflows/).
See the [archive README](../archived_workflows/README.md) for details.
"@
        $readmeContent | Out-File -FilePath $mainReadmePath -Encoding utf8
        Write-Host "✅ Updated main workflows README with archive information"
    }
}

Write-Host "`n🎉 Archiving complete! Legacy workflows have been moved to $archiveDir"
Write-Host "📄 See $readmePath for details on which workflows were archived"



