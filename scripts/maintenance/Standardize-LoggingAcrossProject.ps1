# Standardize-LoggingAcrossProject.ps1
#
# This script helps standardize the logging implementation across all scripts
# in the OpenTofu Lab Automation project.
#
# It scans for non-standard logging implementations and replaces them with
# proper imports from the centralized logging module.

[CmdletBinding()]
param(
    [Parameter()]
    [switch]$DryRun,
    
    [Parameter()]
    [switch]$Force,
    
    [Parameter()]
    [switch]$BackupFiles,
    
    [Parameter()]
    [switch]$ShowDetails
)

# Import standardized logging
try {
    Import-Module "/pwsh/modules/Logging" -ErrorAction Stop
} catch {
    # Fallback if module not found
    function Write-CustomLog {
        param([string]$Message, [string]$Level = "INFO")
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $color = switch ($Level) {
            "INFO" { "Cyan" }
            "WARN" { "Yellow" }
            "ERROR" { "Red" }
            "DEBUG" { "Gray" }
            "SUCCESS" { "Green" }
            default { "White" }
        }
        Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
    }
}

# Set working directory to project root
if ($IsWindows -or $env:OS -eq "Windows_NT") {
    $ProjectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
} else {
    $ProjectRoot = "/workspaces/opentofu-lab-automation"
}
Set-Location $ProjectRoot

Write-CustomLog "Starting logging standardization process" "INFO"
Write-CustomLog "Project root: $ProjectRoot" "INFO"
Write-CustomLog "Dry run mode: $($DryRun.IsPresent)" "INFO"

# Create dictionary of patterns to search for and their replacements
$patterns = @{
    # Function definitions with various parameter styles
    'function Write-(Log|MaintenanceLog|CleanupLog|UtilityLog|InfoLog|DebugLog|ErrorLog)\s*\{\s*param\(' = 
        '# Import standardized logging
try {
    Import-Module "/pwsh/modules/Logging" -ErrorAction Stop
} catch {
    try {
        Import-Module "/pwsh/modules/LabRunner/" -ErrorAction Stop
    } catch {
        # Fallback implementation if module import fails
        function Write-CustomLog {'
    
    # Direct Write-Host calls with common patterns
    'Write-Host\s+\"\[\$\(Get-Date -Format [^\)]+\)\]\s+\[\w+\]' = 
        'Write-CustomLog'
        
    # Local fallback implementation of Write-CustomLog but without import
    'function Write-CustomLog\s*\{\s*param\([^\)]+\)\s*\$timestamp = Get-Date' = 
        'try {
    Import-Module "/pwsh/modules/Logging" -ErrorAction Stop
} catch {
    try {
        Import-Module "/pwsh/modules/LabRunner/" -ErrorAction Stop
    } catch {
        # Fallback implementation if module import fails
        function Write-CustomLog {'
}

# Function to check if a file already has proper imports
function Test-HasProperLoggingImports {
    param (
        [string]$Content
    )
    
    # Check for proper import patterns
    $hasImport = $Content -match 'Import-Module "/.*\/pwsh\/modules\/Logging"' -or 
                 $Content -match 'Import-Module "/.*\/pwsh\/modules\/LabRunner\/"'
    
    return $hasImport
}

# Function to create backup of files before modification
function Backup-File {
    param (
        [string]$FilePath
    )
    
    if ($BackupFiles) {
        $backupDir = Join-Path $ProjectRoot "backups/logging-standardization-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        if (-not (Test-Path $backupDir)) {
            New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
        }
        
        $relativePath = ($FilePath -replace [regex]::Escape($ProjectRoot), "").TrimStart('\/\\')
        $backupPath = Join-Path $backupDir $relativePath
        $backupFolder = Split-Path -Parent $backupPath
        
        if (-not (Test-Path $backupFolder)) {
            New-Item -ItemType Directory -Path $backupFolder -Force | Out-Null
        }
        
        Copy-Item -Path $FilePath -Destination $backupPath -Force
        Write-CustomLog "Created backup: $backupPath" "DEBUG"
    }
}

# Find all PowerShell files in the project
Write-CustomLog "Scanning for PowerShell files..." "INFO"
$files = Get-ChildItem -Path $ProjectRoot -Include "*.ps1", "*.psm1" -Recurse -File |
         Where-Object { $_.FullName -notmatch 'archive|backups|\.git' }

if (-not $files -or $files.Count -eq 0) {
    Write-CustomLog "No PowerShell files found!" "ERROR"
    exit 1
}

Write-CustomLog "Found $($files.Count) PowerShell files to analyze" "INFO"

$standardizedCount = 0
$alreadyStandardizedCount = 0
$skippedCount = 0
$errorCount = 0

foreach ($file in $files) {
    Write-CustomLog "Processing $($file.FullName)" "DEBUG"
    
    # Read file content
    try {
        $content = Get-Content -Path $file.FullName -Raw
    } catch {
        Write-CustomLog "Error reading file $($file.FullName): $_" "ERROR"
        $errorCount++
        continue
    }
    
    # Check if the file already has proper imports
    $hasProperImports = Test-HasProperLoggingImports -Content $content
    
    if ($hasProperImports -and -not $Force) {
        Write-CustomLog "File already has proper logging imports: $($file.Name)" "INFO"
        $alreadyStandardizedCount++
        continue
    }
    
    $needsStandardization = $false
    $modifiedContent = $content
    
    # Check each pattern
    foreach ($patternKey in $patterns.Keys) {
        if ($content -match $patternKey) {
            $needsStandardization = $true
            if (-not $DryRun) {
                $replacement = $patterns[$patternKey]
                $modifiedContent = $modifiedContent -replace $patternKey, $replacement
            }
        }
    }
    
    if ($needsStandardization) {
        if ($DryRun) {
            Write-CustomLog "Would standardize logging in: $($file.FullName)" "WARN"
        } else {
            # Backup the file before modifying
            Backup-File -FilePath $file.FullName
            
            # Write modified content
            try {
                Set-Content -Path $file.FullName -Value $modifiedContent
                Write-CustomLog "Standardized logging in: $($file.Name)" "SUCCESS"
                $standardizedCount++
            } catch {
                Write-CustomLog "Error writing to file $($file.FullName): $_" "ERROR"
                $errorCount++
            }
        }    } else {
        if ($ShowDetails) {
            Write-CustomLog "No need to standardize: $($file.Name)" "INFO"
        }
        $skippedCount++
    }
}

# Output summary statistics
Write-CustomLog "------ Logging Standardization Summary ------" "INFO"
Write-CustomLog "Files processed: $($files.Count)" "INFO"
Write-CustomLog "Files already standardized: $alreadyStandardizedCount" "INFO"
Write-CustomLog "Files newly standardized: $standardizedCount" "SUCCESS"
Write-CustomLog "Files skipped (no changes needed): $skippedCount" "INFO"
Write-CustomLog "Errors encountered: $errorCount" "$(if ($errorCount -gt 0) { 'ERROR' } else { 'INFO' })"
Write-CustomLog "-----------------------------------------" "INFO"

if ($DryRun) {
    Write-CustomLog "This was a DRY RUN. No files were actually modified." "WARN"
    Write-CustomLog "Run without -DryRun to apply changes." "WARN"
}

# Return if there were errors
if ($errorCount -gt 0) {
    exit 1
} else {
    exit 0
}

