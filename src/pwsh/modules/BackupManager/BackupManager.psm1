#Requires -Version 7.0

# BackupManager Module - Core module file
# Comprehensive backup management for OpenTofu Lab Automation

# Import the centralized Logging module
$loggingModulePath = Join-Path $env:PWSH_MODULES_PATH "Logging"
if (-not $env:PWSH_MODULES_PATH -or -not (Test-Path $loggingModulePath)) {
    $loggingModulePath = Join-Path (Split-Path $PSScriptRoot -Parent) "Logging"
}
if (Test-Path $loggingModulePath) {
    Import-Module $loggingModulePath -Force -Global
    Write-Verbose "Successfully imported centralized Logging module"
} else {
    Write-Warning "Could not find centralized Logging module at $loggingModulePath"
}

# Import LabRunner for additional utilities
$LabRunnerPath = Join-Path $PSScriptRoot '..' 'LabRunner'
if (Test-Path $LabRunnerPath) {
    Import-Module $LabRunnerPath -Force -ErrorAction SilentlyContinue
}

# Module-level variables
$script:BackupRootPath = "backups/consolidated-backups"
$script:ArchivePath = "archive"
$script:MaxBackupAge = 30 # days
$script:BackupExclusions = @(
    "*.tmp", "*.log", "*.cache", "*.lock",
    ".git/*", "node_modules/*", ".vscode/*",
    "backups/consolidated-backups/*",
    "coverage/*", "TestResults*"
)

# Import all public functions
$PublicFunctions = @(Get-ChildItem -Path "$PSScriptRoot\Public\*.ps1" -ErrorAction SilentlyContinue)
$PrivateFunctions = @(Get-ChildItem -Path "$PSScriptRoot\Private\*.ps1" -ErrorAction SilentlyContinue)

Write-Verbose "Found $($PublicFunctions.Count) public functions to import"

# Dot source the files
foreach ($Function in @($PublicFunctions + $PrivateFunctions)) {
    try {
        Write-Verbose "Importing function from $($Function.FullName)"
        . $Function.FullName
    } catch {
        Write-Error "Failed to import function $($Function.FullName): $_"
    }
}

# Export public functions
if ($PublicFunctions.Count -gt 0) {
    $FunctionNames = $PublicFunctions.BaseName
    Write-Verbose "Exporting functions: $($FunctionNames -join ', ')"
    Export-ModuleMember -Function $FunctionNames
} else {
    Write-Warning "No public functions found to export"
}

# Module cleanup
$MyInvocation.MyCommand.ScriptBlock.Module.OnRemove = {
    # Cleanup code here if needed
}
