# Non-interactive repository cleanup script

# Define the root directory for cleanup
$RootDirectory = "c:\Users\alexa\OneDrive\Documents\0. wizzense\opentofu-lab-automation"

# Directories to clean
$DirectoriesToClean = @(
    "$RootDirectory\assets",
    "$RootDirectory\backups",
    "$RootDirectory\build",
    "$RootDirectory\configs",
    "$RootDirectory\logs"
)

# Log file for cleanup
$LogFile = "$RootDirectory\cleanup-log.txt"

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
