# CoreApp PowerShell Module
# Consolidates lab utilities, runner scripts, and configuration files

$ErrorActionPreference = "Stop"

# Import required modules
Import-Module "/pwsh/modules/LabRunner/" -Force
Import-Module "/pwsh/modules/CodeFixer/" -Force

# Export module functions
function Invoke-CoreApplication {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ConfigPath,
        
        [Parameter()]
        [string[]]$Scripts,
        
        [Parameter()]
        [switch]$Auto,
        
        [Parameter()]
        [switch]$Force
    )
    
    process {
        Write-CustomLog "Starting core application execution" "INFO"
        
        try {
            # Load configuration
            if (-Not (Test-Path $ConfigPath)) {
                throw "Configuration file not found at $ConfigPath"
            }
            
            $config = Get-Content $ConfigPath | ConvertFrom-Json
            Write-CustomLog "Loaded configuration: $($config.ApplicationName)" "INFO"
            
            # Execute lab runner
            Invoke-LabStep -Config $config -Body {
                Write-CustomLog "Core application operation started" "INFO"
                
                # Run specified scripts or all scripts
                if ($Scripts) {
                    foreach ($script in $Scripts) {
                        $scriptPath = Join-Path $PSScriptRoot "scripts" $script
                        if (Test-Path $scriptPath) {
                            Write-CustomLog "Executing script: $script" "INFO"
                            & $scriptPath
                        } else {
                            Write-CustomLog "Script not found: $script" "WARN"
                        }
                    }
                } else {
                    Write-CustomLog "No specific scripts specified - running core operations" "INFO"
                }
                
                Write-CustomLog "Core application operation completed successfully" "INFO"
            }
            
        } catch {
            Write-CustomLog "Core application operation failed: $($_.Exception.Message)" "ERROR"
            throw
        }
    }
}

function Start-LabRunner {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ConfigPath,
        
        [Parameter()]
        [switch]$Parallel
    )
    
    process {
        try {
            if ($Parallel) {
                Invoke-ParallelLabRunner -ConfigPath $ConfigPath
            } else {
                Invoke-CoreApplication -ConfigPath $ConfigPath
            }
        } catch {
            Write-CustomLog "Lab runner failed: $($_.Exception.Message)" "ERROR"
            throw
        }
    }
}

function Get-CoreConfiguration {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$ConfigPath = (Join-Path $PSScriptRoot "default-config.json")
    )
    
    process {
        try {
            if (Test-Path $ConfigPath) {
                return Get-Content $ConfigPath | ConvertFrom-Json
            } else {
                throw "Configuration file not found: $ConfigPath"
            }
        } catch {
            Write-CustomLog "Failed to load configuration: $($_.Exception.Message)" "ERROR"
            throw
        }
    }
}

function Test-CoreApplicationHealth {
    [CmdletBinding()]
    param()
    
    process {
        try {
            Write-CustomLog "Running core application health check" "INFO"
            
            # Check required modules
            $requiredModules = @('LabRunner', 'CodeFixer')
            foreach ($module in $requiredModules) {
                if (-not (Get-Module $module)) {
                    Write-CustomLog "Required module not loaded: $module" "ERROR"
                    return $false
                }
            }
            
            # Check configuration files
            $configPath = Join-Path $PSScriptRoot "default-config.json"
            if (-not (Test-Path $configPath)) {
                Write-CustomLog "Default configuration file missing" "ERROR"
                return $false
            }
            
            # Check scripts directory
            $scriptsPath = Join-Path $PSScriptRoot "scripts"
            if (-not (Test-Path $scriptsPath)) {
                Write-CustomLog "Scripts directory missing" "ERROR"
                return $false
            }
            
            Write-CustomLog "Core application health check passed" "INFO"
            return $true
            
        } catch {
            Write-CustomLog "Health check failed: $($_.Exception.Message)" "ERROR"
            return $false
        }
    }
}

# Export functions
Export-ModuleMember -Function 'Invoke-CoreApplication', 'Start-LabRunner', 'Get-CoreConfiguration', 'Test-CoreApplicationHealth'
