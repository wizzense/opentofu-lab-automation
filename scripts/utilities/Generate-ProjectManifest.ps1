#Requires -Version 7.0
<#
.SYNOPSIS
    Automatically generates the PROJECT-MANIFEST.json based on project files.

.DESCRIPTION
    This script scans the project directory to identify modules, scripts, and tools.
    It maps dependencies and generates a visual representation of the dependency chart.

.PARAMETER OutputPath
    Path to save the generated manifest file.

.EXAMPLE
    ./Generate-ProjectManifest.ps1 -OutputPath "./PROJECT-MANIFEST.json"

.NOTES
    Requires PowerShell 7.0 or higher.
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$OutputPath
)

function Get-ProjectFiles {
    param(
        [string]$RootPath
    )

    Write-Host "Scanning project files in $RootPath..." -ForegroundColor Cyan

    $files = Get-ChildItem -Path $RootPath -Recurse -File -Include "*.ps1", "*.py", "*.json", "*.md", "*.yaml", "*.yml" -ErrorAction SilentlyContinue
    return $files
}

function Find-Dependencies {
    param(
        [array]$Files
    )

    Write-Host "Mapping dependencies..." -ForegroundColor Cyan

    $dependencies = @{}

    foreach ($file in $Files) {
        $content = Get-Content -Path $file.FullName -Raw -ErrorAction SilentlyContinue
        if ($content) {
            $dependencyMatches = $content | Select-String -Pattern "Import-Module|require|dependency" -AllMatches
            foreach ($match in $dependencyMatches) {
                $dependencies[$file.FullName] += $match.Matches.Value
            }
        }
    }

    return $dependencies
}

function Create-DependencyChart {
    param(
        [hashtable]$Dependencies
    )

    Write-Host "Generating dependency chart..." -ForegroundColor Cyan

    $chart = @()
    foreach ($key in $Dependencies.Keys) {
        foreach ($value in $Dependencies[$key]) {
            $chart += "`"$key`" -> `"$value`""
        }
    }

    return $chart
}

function Save-Manifest {
    param(
        [string]$Path,
        [hashtable]$Data
    )

    Write-Host "Saving manifest to $Path..." -ForegroundColor Cyan

    $json = $Data | ConvertTo-Json -Depth 10
    Set-Content -Path $Path -Value $json -Encoding UTF8
}

# Main script execution
$projectRoot = (Get-Location).Path
$files = Get-ProjectFiles -RootPath $projectRoot
$dependencies = Find-Dependencies -Files $files
$dependencyChart = Create-DependencyChart -Dependencies $dependencies

$manifest = @{
    project = @{
        description = "Automatically generated project manifest"
        version = "1.0.0"
        lastUpdated = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    }
    files = $files | ForEach-Object { $_.FullName }
    dependencies = $dependencies
    dependencyChart = $dependencyChart
}

Save-Manifest -Path $OutputPath -Data $manifest
Write-Host "Manifest generation complete." -ForegroundColor Green
