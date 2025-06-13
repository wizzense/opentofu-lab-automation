# /workspaces/opentofu-lab-automation/scripts/utilities/hide-backup-directories.ps1

<#
.SYNOPSIS
    Hides backup and archive directories from main project views

.DESCRIPTION
    Creates .vscode/settings.json entries to hide backup directories from the file explorer
    and search results in VS Code, improving project navigation and focus.

.PARAMETER Unhide
    Remove hiding rules to show backup directories again

.EXAMPLE
    ./scripts/utilities/hide-backup-directories.ps1
    ./scripts/utilities/hide-backup-directories.ps1 -Unhide
#>

[CmdletBinding()]
param(
    [switch]$Unhide
)





$ErrorActionPreference = "Stop"
$vscodePath = "/workspaces/opentofu-lab-automation/.vscode"
$settingsPath = "$vscodePath/settings.json"

function Get-BackupHidingRules {
    return @{
        "files.exclude" = @{
            "**/backups/**" = $true
            "**/archive/**" = $true
            "**/*.backup*" = $true
            "**/cleanup-backup-*/**" = $true
        }
        "search.exclude" = @{
            "**/backups/**" = $true
            "**/archive/**" = $true
            "**/*.backup*" = $true
            "**/cleanup-backup-*/**" = $true
        }
        "files.watcherExclude" = @{
            "**/backups/**" = $true
            "**/archive/**" = $true
            "**/*.backup*" = $true
            "**/cleanup-backup-*/**" = $true
        }
    }
}

function Update-VSCodeSettings {
    param($HidingRules, $Remove = $false)
    
    



# Ensure .vscode directory exists
    if (-not (Test-Path $vscodePath)) {
        New-Item -Path $vscodePath -ItemType Directory -Force | Out-Null
        Write-Host "Created .vscode directory"
    }
    
    # Load existing settings or create new
    $settings = @{}
    if (Test-Path $settingsPath) {
        try {
            $content = Get-Content $settingsPath -Raw | ConvertFrom-Json -AsHashtable
            $settings = $content
        }
        catch {
            Write-Warning "Could not parse existing settings.json, creating new"
            $settings = @{}
        }
    }
    
    if ($Remove) {
        # Remove hiding rules
        foreach ($category in $HidingRules.Keys) {
            if ($settings.ContainsKey($category)) {
                foreach ($pattern in $HidingRules[$category].Keys) {
                    if ($settings[$category].ContainsKey($pattern)) {
                        $settings[$category].Remove($pattern)
                    }
                }
                # Remove category if empty
                if ($settings[$category].Count -eq 0) {
                    $settings.Remove($category)
                }
            }
        }
        Write-Host "Removed backup hiding rules from VS Code settings"
    } else {
        # Add hiding rules
        foreach ($category in $HidingRules.Keys) {
            if (-not $settings.ContainsKey($category)) {
                $settings[$category] = @{}
            }
            foreach ($pattern in $HidingRules[$category].Keys) {
                $settings[$category][$pattern] = $HidingRules[$category][$pattern]
            }
        }
        Write-Host "Added backup hiding rules to VS Code settings"
    }
    
    # Save updated settings
    $settings | ConvertTo-Json -Depth 10 | Set-Content $settingsPath -Encoding UTF8
    Write-Host "Updated: $settingsPath"
}

function Show-CurrentState {
    if (Test-Path $settingsPath) {
        Write-Host "`nCurrent VS Code settings:" -ForegroundColor Green
        $content = Get-Content $settingsPath -Raw
        Write-Host $content
    } else {
        Write-Host "`nNo VS Code settings file found" -ForegroundColor Yellow
    }
}

# Main execution
try {
    Write-Host "Updating VS Code settings to $$(if (Unhide) { 'show' } else { 'hide' }) backup directories..." -ForegroundColor Cyan
    
    $hidingRules = Get-BackupHidingRules
    Update-VSCodeSettings -HidingRules $hidingRules -Remove:$Unhide
    
    Show-CurrentState
    
    Write-Host "`n✅ Successfully $$(if (Unhide) { 'unhid' } else { 'hid' }) backup directories" -ForegroundColor Green
    Write-Host "💡 Restart VS Code or reload window to see changes" -ForegroundColor Yellow
    
} catch {
    Write-Error "Failed to update VS Code settings: $_"
    exit 1
}


