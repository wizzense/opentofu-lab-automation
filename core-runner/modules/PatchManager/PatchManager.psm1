#Requires -Version 7.0

# Import the centralized Logging module using multiple fallback paths
$loggingImported = $false
$loggingPaths = @(
    'Logging',  # Try module name first (if in PSModulePath)
    (Join-Path (Split-Path $PSScriptRoot -Parent) "Logging"),  # Relative to modules directory
    (Join-Path $env:PWSH_MODULES_PATH "Logging"),  # Environment path
    (Join-Path $env:PROJECT_ROOT "core-runner/modules/Logging")  # Full project path
)

foreach ($loggingPath in $loggingPaths) {
    if ($loggingImported) { break }
    
    try {
        if ($loggingPath -eq 'Logging') {
            Import-Module 'Logging' -Force -Global -ErrorAction Stop
        } elseif (Test-Path $loggingPath) {
            Import-Module $loggingPath -Force -Global -ErrorAction Stop
        } else {
            continue
        }
        Write-Verbose "Successfully imported Logging module from: $loggingPath"
        $loggingImported = $true
    } catch {
        Write-Verbose "Failed to import Logging from $loggingPath : $_"
    }
}

if (-not $loggingImported) {
    Write-Warning "Could not import Logging module from any of the attempted paths"
}

# Import all public functions
$Public = @(Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -ErrorAction SilentlyContinue)

# Import all private functions  
$Private = @(Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -ErrorAction SilentlyContinue)

Write-Verbose "Found $($Public.Count) public functions and $($Private.Count) private functions"

# Dot source the files
foreach ($import in @($Public + $Private)) {
    try {
        . $import.FullName
        Write-Verbose "Successfully imported: $($import.Name)"
    } catch {
        Write-Error -Message "Failed to import function $($import.FullName): $_"
        throw
    }
}

# Initialize cross-platform environment
try {
    # Initialize cross-platform environment when module is loaded
    $envResult = Initialize-CrossPlatformEnvironment
    if ($envResult.Success) {
        Write-Verbose "Cross-platform environment initialized successfully: $($envResult.Platform)"
        Write-Verbose "PROJECT_ROOT: $env:PROJECT_ROOT"
        Write-Verbose "PWSH_MODULES_PATH: $env:PWSH_MODULES_PATH"
    } else {
        Write-Warning "Failed to initialize cross-platform environment: $($envResult.Error)"
    }
} catch {
    Write-Warning "Error initializing cross-platform environment: $_"
}

# Export only the public functions (private functions are available internally but not exported)
# Export all functions defined in the module manifest
Export-ModuleMember -Function @(
    'Invoke-GitControlledPatch',
    'Invoke-EnhancedPatchManager', 
    'Invoke-GitHubIssueIntegration',
    'Invoke-GitHubIssueResolution',
    'Invoke-QuickRollback',
    'Invoke-PatchRollback',
    'Invoke-PatchValidation',
    'Invoke-ComprehensiveIssueTracking',
    'Invoke-ErrorHandler',
    'Invoke-MonitoredExecution',
    'Set-PatchManagerAliases',
    'Test-PatchingRequirements',
    'Get-IntelligentBranchStrategy',
    'Test-BranchProtection',
    'Get-SanitizedBranchName',
    'New-PatchBranch',
    'Invoke-PatchOperation',
    'New-PatchCommit',
    'New-PatchPullRequest',
    'Build-ComprehensivePRBody',
    'Get-GitChangeStatistics',
    'Get-GitCommitInfo',
    'Invoke-EnhancedGitOperations'
)

Write-Verbose "Module loading complete. Exported all public functions."
