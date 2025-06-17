#Requires -Version 7.0
<#
.SYNOPSIS
    Cleanup operations module for PatchManager
    
.DESCRIPTION
    Provides comprehensive cleanup functions for PatchManager including:
    - Temporary file removal
    - Emoji cleanup
    - Backup consolidation
    - Unused file removal
    
.NOTES
    - Integrated with Git operations
    - Provides consolidated backups
    - Cross-platform compatible cleanup operations
    - Configurable cleanup modes: Standard, Aggressive, Emergency, Safe
#>

function RunComprehensiveCleanup {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("Standard", "Aggressive", "Emergency", "Safe")]
        [string]$CleanupMode,
        
        [Parameter(Mandatory = $false)]
        [string[]]$ExcludePatterns = @(),
        
        [Parameter(Mandatory = $false)]
        [switch]$DryRun = $false
    )

    Write-Host "Running comprehensive cleanup in mode: $CleanupMode" -ForegroundColor Cyan
    
    try {
        # Get age threshold based on mode
        $ageThresholdDays = switch ($CleanupMode) {
            "Safe" { 90 }
            "Standard" { 30 }
            "Aggressive" { 7 }
            "Emergency" { 1 }
        }
        
        Write-Host "Using age threshold: $ageThresholdDays days" -ForegroundColor Yellow
        
        # Call the main cleanup function
        $result = Invoke-ComprehensiveCleanup -CleanupMode $CleanupMode -ExcludePatterns $ExcludePatterns -DryRun:$DryRun
        
        return $result
    }
    catch {
        Write-Error "Cleanup failed: $_"
        return @{
            Success = $false
            Message = "Cleanup failed: $_"
            FilesRemoved = 0
            SizeReclaimed = 0
        }
    }
}

function Invoke-TempFileCleanup {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [int]$AgeThresholdDays = 7,
        
        [Parameter(Mandatory = $false)]
        [switch]$DryRun = $false
    )
    
    $tempPatterns = @("*.tmp", "*.bak", "*.log", "*.cache")
    $totalRemoved = 0
    $totalSizeReclaimed = 0
    
    foreach ($pattern in $tempPatterns) {
        $files = Get-ChildItem -Path . -Recurse -File -Filter $pattern -ErrorAction SilentlyContinue |
                 Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-$AgeThresholdDays) }
        
        foreach ($file in $files) {
            if (-not $DryRun) {
                $fileSize = $file.Length
                Remove-Item -Path $file.FullName -Force -ErrorAction SilentlyContinue
                if (-not (Test-Path $file.FullName)) {
                    $totalRemoved++
                    $totalSizeReclaimed += $fileSize
                    Write-Verbose "Removed temp file: $($file.FullName) ($($fileSize) bytes)"
                }
            } else {
                Write-Verbose "[DRY RUN] Would remove: $($file.FullName) ($($file.Length) bytes)"
                $totalRemoved++
                $totalSizeReclaimed += $file.Length
            }
        }
    }
    
    return @{
        FilesRemoved = $totalRemoved
        SizeReclaimed = $totalSizeReclaimed
    }
}

function Invoke-EmojiCleanup {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string[]]$FileExtensions = @("*.ps1", "*.md", "*.yaml", "*.yml", "*.json"),
        
        [Parameter(Mandatory = $false)]
        [switch]$DryRun = $false
    )
    
    # Unicode emoji pattern (very basic)
    $emojiPattern = '[\u1F300-\u1F6FF\u2600-\u26FF\u2700-\u27BF]'
    $totalFixed = 0
    
    foreach ($extension in $FileExtensions) {
        $files = Get-ChildItem -Path . -Recurse -File -Filter $extension -ErrorAction SilentlyContinue
        
        foreach ($file in $files) {
            $content = Get-Content -Path $file.FullName -Raw -ErrorAction SilentlyContinue
            if ($content -match $emojiPattern) {
                $newContent = $content -replace $emojiPattern, ''
                
                if (-not $DryRun) {
                    $newContent | Set-Content -Path $file.FullName -NoNewline -ErrorAction SilentlyContinue
                    Write-Verbose "Removed emojis from: $($file.FullName)"
                } else {
                    Write-Verbose "[DRY RUN] Would remove emojis from: $($file.FullName)"
                }
                
                $totalFixed++
            }
        }
    }
    
    return $totalFixed
}

# Export public functions
Export-ModuleMember -Function RunComprehensiveCleanup, Invoke-TempFileCleanup, Invoke-EmojiCleanup
