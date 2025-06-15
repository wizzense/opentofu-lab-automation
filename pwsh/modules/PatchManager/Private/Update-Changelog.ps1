function Update-Changelog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$ProjectRoot = $script:ProjectRoot,
        
        [Parameter(Mandatory = $false)]
        [string]$ChangelogPath,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Changes,
        
        [Parameter(Mandatory = $false)]
        [string]$Version = "1.0.0",
        
        [Parameter(Mandatory = $false)]
        [switch]$WhatIf,
        
        [Parameter(Mandatory = $false)]
        [string]$LogFile
    )
    
    if (-not $ChangelogPath) {
        $ChangelogPath = Join-Path $ProjectRoot "CHANGELOG.md"
    }
    
    Write-PatchLog "Updating changelog at $ChangelogPath" "INFO" -LogFile $LogFile
    
    if (-not $Changes -or $Changes.Count -eq 0) {
        Write-PatchLog "No changes provided for changelog update" "WARNING" -LogFile $LogFile
        return $false
    }
    
    # Get current date for the changelog entry
    $dateStr = Get-Date -Format "yyyy-MM-dd"
    
    # Read existing changelog or create a new one
    if (Test-Path $ChangelogPath) {
        $content = Get-Content -Path $ChangelogPath -Raw
    } else {
        $content = @"
# Changelog

All notable changes to the OpenTofu Lab Automation project will be documented in this file.

"@
    }
    
    # Create new changelog section
    $newSection = @"
## [$Version] - $dateStr

"@
    
    if ($Changes.Added -and $Changes.Added.Count -gt 0) {
        $newSection += @"
### Added

$(foreach ($item in $Changes.Added) { "- $item`n" })

"@
    }
    
    if ($Changes.Fixed -and $Changes.Fixed.Count -gt 0) {
        $newSection += @"
### Fixed

$(foreach ($item in $Changes.Fixed) { "- $item`n" })

"@
    }
    
    if ($Changes.Changed -and $Changes.Changed.Count -gt 0) {
        $newSection += @"
### Changed

$(foreach ($item in $Changes.Changed) { "- $item`n" })

"@
    }
    
    if ($Changes.Removed -and $Changes.Removed.Count -gt 0) {
        $newSection += @"
### Removed

$(foreach ($item in $Changes.Removed) { "- $item`n" })

"@
    }
    
    # Insert new section after the header
    if ($content -match "# Changelog") {
        $updatedContent = $content -replace "(# Changelog.*?(?:\r?\n){2})", "`$1$newSection"
    } else {
        $updatedContent = @"
# Changelog

All notable changes to the OpenTofu Lab Automation project will be documented in this file.

$newSection
"@
    }
    
    # Save changelog
    if ($WhatIf) {
        Write-PatchLog "WhatIf: Would update changelog with new entry for $Version on $dateStr" "INFO" -LogFile $LogFile
    } else {
        Set-Content -Path $ChangelogPath -Value $updatedContent
        Write-PatchLog "Updated changelog with new entry for $Version on $dateStr" "SUCCESS" -LogFile $LogFile
    }
    
    return $true
}
