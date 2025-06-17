#Requires -Version 7.0

<#
.SYNOPSIS
    Centralized module import manager with proper error handling and fallbacks

.DESCRIPTION
    Provides robust module importing with:
    - Automatic fallback functions when modules aren't available
    - Proper error handling and logging
    - Environment variable support
    - Cross-platform path handling
    - Anti-recursive import protection

.NOTES
    Use this module to ensure consistent imports across all scripts
#>

# Global variables for import tracking
$script:ImportedModules = @{}
$script:FallbackFunctions = @{}

function Import-ModuleWithFallback {
    <#
    .SYNOPSIS
        Import a module with proper error handling and fallback functions
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ModuleName,
        
        [Parameter()]
        [string]$ModulePath,
        
        [Parameter()]
        [hashtable]$FallbackFunctions = @{},
        
        [Parameter()]
        [switch]$Force,
        
        [Parameter()]
        [switch]$Silent
    )
    
    $importResult = @{
        Success = $false
        ModuleName = $ModuleName
        ModulePath = $ModulePath
        FallbacksCreated = @()
        ErrorMessage = $null
    }
    
    try {
        # Check if already imported and not forcing
        if ($script:ImportedModules.ContainsKey($ModuleName) -and -not $Force) {
            if (-not $Silent) {
                Write-Host "Module $ModuleName already imported" -ForegroundColor Gray
            }
            $importResult.Success = $true
            return $importResult
        }
        
        # Determine module path
        $resolvedPath = if ($ModulePath) {
            $ModulePath
        } elseif ($env:PWSH_MODULES_PATH) {
            Join-Path $env:PWSH_MODULES_PATH $ModuleName
        } elseif ($env:PROJECT_ROOT) {
            Join-Path $env:PROJECT_ROOT "pwsh/modules/$ModuleName"
        } else {
            # Try relative path from script location
            $scriptRoot = if ($PSScriptRoot) { Split-Path $PSScriptRoot -Parent } else { Get-Location }
            Join-Path $scriptRoot "pwsh/modules/$ModuleName"
        }
        
        # Try to import the module
        if (Test-Path $resolvedPath) {
            Import-Module $resolvedPath -Force:$Force -ErrorAction Stop
            $script:ImportedModules[$ModuleName] = $resolvedPath
            $importResult.Success = $true
            $importResult.ModulePath = $resolvedPath
            
            if (-not $Silent) {
                Write-Host "✓ Imported module: $ModuleName" -ForegroundColor Green
            }
        } else {
            throw "Module path not found: $resolvedPath"
        }
        
    } catch {
        $importResult.ErrorMessage = $_.Exception.Message
        
        if (-not $Silent) {
            Write-Host "⚠ Failed to import $ModuleName : $($_.Exception.Message)" -ForegroundColor Yellow
        }
        
        # Create fallback functions
        foreach ($funcName in $FallbackFunctions.Keys) {
            $fallbackScript = $FallbackFunctions[$funcName]
            
            if (-not (Get-Command $funcName -ErrorAction SilentlyContinue)) {
                try {
                    # Create the fallback function in global scope
                    $functionDef = "function global:$funcName { $fallbackScript }"
                    Invoke-Expression $functionDef
                    
                    $importResult.FallbacksCreated += $funcName
                    $script:FallbackFunctions[$funcName] = $fallbackScript
                    
                    if (-not $Silent) {
                        Write-Host "  → Created fallback function: $funcName" -ForegroundColor Cyan
                    }
                } catch {
                    if (-not $Silent) {
                        Write-Host "  ✗ Failed to create fallback for $funcName : $_" -ForegroundColor Red
                    }
                }
            }
        }
    }
    
    return $importResult
}

function Import-LoggingModule {
    <#
    .SYNOPSIS
        Import the Logging module with Write-CustomLog fallback
    #>
    [CmdletBinding()]
    param([switch]$Silent)
    
    $fallbacks = @{
        'Write-CustomLog' = @'
            param(
                [Parameter(Mandatory)]
                [string]$Message,
                
                [Parameter()]
                [ValidateSet("INFO", "WARN", "ERROR", "SUCCESS", "DEBUG")]
                [string]$Level = "INFO"
            )
            
            $colors = @{
                "INFO" = "White"
                "WARN" = "Yellow" 
                "ERROR" = "Red"
                "SUCCESS" = "Green"
                "DEBUG" = "Gray"
            }
            
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            $logMessage = "[$timestamp] [$Level] $Message"
            
            Write-Host $logMessage -ForegroundColor $colors[$Level]
'@
    }
    
    return Import-ModuleWithFallback -ModuleName "Logging" -FallbackFunctions $fallbacks -Silent:$Silent
}

function Import-PatchManagerModule {
    <#
    .SYNOPSIS
        Import the PatchManager module with essential fallbacks
    #>
    [CmdletBinding()]
    param([switch]$Silent)
    
    $fallbacks = @{
        'Write-PatchLog' = @'
            param([string]$Message, [string]$Level = "INFO")
            if (Get-Command Write-CustomLog -ErrorAction SilentlyContinue) {
                Write-CustomLog -Message $Message -Level $Level
            } else {
                Write-Host "[$Level] $Message" -ForegroundColor $(if ($Level -eq "ERROR") { "Red" } elseif ($Level -eq "WARN") { "Yellow" } else { "White" })
            }
'@
    }
    
    return Import-ModuleWithFallback -ModuleName "PatchManager" -FallbackFunctions $fallbacks -Silent:$Silent
}

function Import-AllCoreModules {
    <#
    .SYNOPSIS
        Import all core modules needed for the project
    #>
    [CmdletBinding()]
    param([switch]$Silent)
    
    $results = @{}
    
    # Import Logging first (other modules depend on it)
    $results.Logging = Import-LoggingModule -Silent:$Silent
    
    # Import PatchManager
    $results.PatchManager = Import-PatchManagerModule -Silent:$Silent
    
    # Import other core modules
    $coreModules = @("DevEnvironment", "GitHubIssueTracking", "LabRunner")
    
    foreach ($module in $coreModules) {
        $results[$module] = Import-ModuleWithFallback -ModuleName $module -Silent:$Silent
    }
    
    return $results
}

function Get-ImportStatus {
    <#
    .SYNOPSIS
        Get the current import status of all modules
    #>
    return @{
        ImportedModules = $script:ImportedModules.Clone()
        FallbackFunctions = $script:FallbackFunctions.Clone()
        AvailableCommands = Get-Command | Where-Object { $_.Source -in $script:ImportedModules.Keys } | Select-Object Name, Source
    }
}

# Export functions
Export-ModuleMember -Function Import-ModuleWithFallback, Import-LoggingModule, Import-PatchManagerModule, Import-AllCoreModules, Get-ImportStatus
