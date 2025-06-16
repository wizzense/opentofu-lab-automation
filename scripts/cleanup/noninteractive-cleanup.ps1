# Non-interactive repository cleanup script
[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$RootDirectory = (Get-Location).Path
)

# Cross-platform path resolution
function Get-ProjectRoot {
    param([string]$StartPath = (Get-Location).Path)
    
    $current = $StartPath
    while ($current -and (Split-Path $current -Parent)) {
        if (Test-Path (Join-Path $current "PROJECT-MANIFEST.json")) {
            return $current
        }
        $current = Split-Path $current -Parent
    }
    return $StartPath
}

# Use cross-platform path resolution
$RootDirectory = Get-ProjectRoot

# Directories to clean (using cross-platform Join-Path)
$DirectoriesToClean = @(
    (Join-Path $RootDirectory "assets"),
    (Join-Path $RootDirectory "backups"), 
    (Join-Path $RootDirectory "build"),
    (Join-Path $RootDirectory "configs"),
    (Join-Path $RootDirectory "logs")
)

# Log file for cleanup (cross-platform)
$LogFile = Join-Path $RootDirectory "cleanup-log.txt"

# Initialize log
"Cleanup started at $(Get-Date)" | Out-File -FilePath $LogFile -Encoding UTF8

foreach ($Directory in $DirectoriesToClean) {
    Write-Host "Cleaning: $Directory" -ForegroundColor Cyan
    if (Test-Path $Directory) {
        try {
            Remove-Item -Path $Directory -Recurse -Force -ErrorAction Stop
            Write-Host "Successfully cleaned: $Directory" -ForegroundColor Green
            "Successfully cleaned: $Directory" | Out-File -FilePath $LogFile -Append -Encoding UTF8
        } catch {
            Write-Host "Error cleaning $Directory: ${_}" -ForegroundColor Red
            "Error cleaning $Directory: ${_}" | Out-File -FilePath $LogFile -Append -Encoding UTF8
        }
    } else {
        Write-Host "Directory not found: $Directory" -ForegroundColor Yellow
        "Directory not found: $Directory" | Out-File -FilePath $LogFile -Append -Encoding UTF8
    }
}

"Cleanup completed at $(Get-Date)" | Out-File -FilePath $LogFile -Append -Encoding UTF8
Write-Host "Cleanup log saved to $LogFile" -ForegroundColor Green
