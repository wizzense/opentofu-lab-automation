#Requires -Version 7.0

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
if ($Public.Count -gt 0) {
    $functionNames = $Public.BaseName
    Export-ModuleMember -Function $functionNames
    Write-Verbose "Exported functions: $($functionNames -join ', ')"
} else {
    Write-Warning "No public functions found to export in $PSScriptRoot\Public\"
}
