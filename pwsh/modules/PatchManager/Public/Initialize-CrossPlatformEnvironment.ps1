#Requires -Version 7.0
<#
.SYNOPSIS
    Initialize cross-platform environment variables for the project
    
.DESCRIPTION
    Sets up essential environment variables for cross-platform compatibility
    and standardizes path handling across Windows, Linux, and macOS
    
.OUTPUTS
    PSCustomObject with Success status and environment details
    
.EXAMPLE
    $envResult = Initialize-CrossPlatformEnvironment
    if ($envResult.Success) {
        Write-Host "Environment initialized: $($envResult.Platform)"
    }
    
.NOTES
    Called automatically by PatchManager functions to ensure consistent
    cross-platform behavior and path handling
#>

function Initialize-CrossPlatformEnvironment {
    [CmdletBinding()]
    param()
    
    try {
        Write-Verbose "Initializing cross-platform environment..."
        
        # Detect platform
        $platform = "Unknown"
        if ($IsWindows -or $env:OS -eq "Windows_NT") {
            $platform = "Windows"
        } elseif ($IsLinux) {
            $platform = "Linux"
        } elseif ($IsMacOS) {
            $platform = "macOS"
        }
        
        # Set PROJECT_ROOT if not already set
        if (-not $env:PROJECT_ROOT) {
            # Try to detect project root by looking for key files
            $currentPath = Get-Location
            $searchPath = $currentPath
            
            while ($searchPath.Path -ne $searchPath.Parent.Path) {
                if (Test-Path (Join-Path $searchPath "PROJECT-MANIFEST.json")) {
                    $env:PROJECT_ROOT = $searchPath.Path
                    break
                } elseif (Test-Path (Join-Path $searchPath ".git")) {
                    $env:PROJECT_ROOT = $searchPath.Path
                    break
                }
                $searchPath = $searchPath.Parent
            }
            
            # Fallback to current directory if not found
            if (-not $env:PROJECT_ROOT) {
                $env:PROJECT_ROOT = $currentPath.Path
            }
        }
        
        # Set PWSH_MODULES_PATH
        if (-not $env:PWSH_MODULES_PATH) {
            $env:PWSH_MODULES_PATH = Join-Path $env:PROJECT_ROOT "pwsh\modules"
        }
        
        # Set PLATFORM
        $env:PLATFORM = $platform
        
        # Set path separator for cross-platform compatibility
        $env:PATH_SEPARATOR = if ($platform -eq "Windows") { ";" } else { ":" }
        
        # Create standard directories if they don't exist
        $standardDirs = @(
            (Join-Path $env:PROJECT_ROOT "logs"),
            (Join-Path $env:PROJECT_ROOT "backups"),
            (Join-Path $env:PROJECT_ROOT "reports")
        )
        
        foreach ($dir in $standardDirs) {
            if (-not (Test-Path $dir)) {
                New-Item -ItemType Directory -Path $dir -Force | Out-Null
                Write-Verbose "Created directory: $dir"
            }
        }
        
        Write-Verbose "Cross-platform environment initialized successfully"
        Write-Verbose "Platform: $platform"
        Write-Verbose "Project Root: $env:PROJECT_ROOT"
        Write-Verbose "Modules Path: $env:PWSH_MODULES_PATH"
        
        return @{
            Success = $true
            Platform = $platform
            ProjectRoot = $env:PROJECT_ROOT
            ModulesPath = $env:PWSH_MODULES_PATH
            Message = "Cross-platform environment initialized successfully"
        }
        
    } catch {
        Write-Error "Failed to initialize cross-platform environment: $($_.Exception.Message)"
        return @{
            Success = $false
            Platform = "Unknown"
            Error = $_.Exception.Message
            Message = "Failed to initialize cross-platform environment"
        }
    }
}
