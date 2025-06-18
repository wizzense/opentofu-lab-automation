# CoreApp PowerShell Module
# Consolidates lab utilities, runner scripts, and configuration files

#Requires -Version 7.0

$ErrorActionPreference = 'Stop'

# Create Public and Private directories if they don't exist
$publicFolder = Join-Path $PSScriptRoot 'Public'
$privateFolder = Join-Path $PSScriptRoot 'Private'

if (-not (Test-Path $publicFolder)) {
    New-Item -ItemType Directory -Path $publicFolder -Force | Out-Null
}

if (-not (Test-Path $privateFolder)) {
    New-Item -ItemType Directory -Path $privateFolder -Force | Out-Null
}

# Import public functions
$publicFunctions = @(
    Get-ChildItem -Path "$PSScriptRoot/Public" -Filter '*.ps1' -ErrorAction SilentlyContinue
)

# Import private functions if they exist
$privateFunctions = @(
    Get-ChildItem -Path "$PSScriptRoot/Private" -Filter '*.ps1' -ErrorAction SilentlyContinue
)

# Load all functions
$allFunctions = $privateFunctions + $publicFunctions

foreach ($function in $allFunctions) {
    try {
        . $function.FullName
        Write-Verbose "Imported function: $($function.BaseName)"
    } catch {
        Write-Error "Failed to import function $($function.FullName): $_"
    }
}

# Basic logging function if not already defined
if (-not (Get-Command Write-CustomLog -ErrorAction SilentlyContinue)) {
    function Write-CustomLog {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory = $true)]
            [string]$Message,
            
            [Parameter()]
            [ValidateSet('INFO', 'WARN', 'ERROR', 'SUCCESS', 'DEBUG')]
            [string]$Level = 'INFO',
            
            [Parameter()]
            [string]$Component = 'CoreApp'
        )
        
        $color = switch ($Level) {
            'ERROR' { 'Red' }
            'WARN' { 'Yellow' }
            'INFO' { 'Green' }
            'SUCCESS' { 'Cyan' }
            'DEBUG' { 'Gray' }
            default { 'White' }
        }
        
        Write-Host "[$Level] [$Component] $Message" -ForegroundColor $color
    }
    
    # Export the Write-CustomLog function
    Export-ModuleMember -Function Write-CustomLog
}

# Core functions if not defined in Public folder
if (-not (Get-Command Invoke-CoreApplication -ErrorAction SilentlyContinue)) {
    function Invoke-CoreApplication {
        [CmdletBinding(SupportsShouldProcess = $true)]
        param(
            [Parameter(Mandatory = $true)]
            [string]$ConfigPath,
            
            [Parameter()]
            [string[]]$Scripts,
            
            [Parameter()]
            [switch]$Auto,
            
            [Parameter()]
            [switch]$Force
        )
        
        process {
            Write-CustomLog -Message 'Starting core application execution' -Level 'INFO'
            
            try {
                # Load configuration
                if (-Not (Test-Path $ConfigPath)) {
                    throw "Configuration file not found at $ConfigPath"
                }
                
                $config = Get-Content $ConfigPath | ConvertFrom-Json
                Write-CustomLog -Message 'Loaded configuration' -Level 'INFO'
                  
                # Execute lab runner
                Write-CustomLog -Message 'Core application operation started' -Level 'INFO'
                
                # Run specified scripts or all scripts
                if ($Scripts) {
                    foreach ($script in $Scripts) {
                        $scriptPath = Join-Path $PSScriptRoot 'scripts' $script
                        if (Test-Path $scriptPath) {
                            Write-CustomLog -Message "Executing script: $script" -Level 'INFO'
                            if ($PSCmdlet.ShouldProcess($script, 'Execute script')) {
                                & $scriptPath -Config $config
                            }
                        } else {
                            Write-CustomLog -Message "Script not found: $script" -Level 'WARN'
                        }
                    }
                } else {
                    Write-CustomLog -Message 'No specific scripts specified - running core operations' -Level 'INFO'
                }
                
                Write-CustomLog -Message 'Core application operation completed successfully' -Level 'SUCCESS'
                return $true
                
            } catch {
                Write-CustomLog -Message "Core application operation failed: $($_.Exception.Message)" -Level 'ERROR'
                throw
            }
        }
    }
}

if (-not (Get-Command Start-LabRunner -ErrorAction SilentlyContinue)) {
    function Start-LabRunner {
        [CmdletBinding(SupportsShouldProcess = $true)]
        param(
            [Parameter(Mandatory = $true)]
            [string]$ConfigPath,
            
            [Parameter()]
            [switch]$Parallel
        )
        
        process {
            try {
                if ($Parallel) {
                    Write-CustomLog -Message 'Parallel lab runner not implemented yet - using standard runner' -Level 'WARN'
                    Invoke-CoreApplication -ConfigPath $ConfigPath
                } else {
                    if ($PSCmdlet.ShouldProcess($ConfigPath, 'Start lab runner')) {
                        Invoke-CoreApplication -ConfigPath $ConfigPath
                    }
                }
            } catch {
                Write-CustomLog -Message "Lab runner failed: $($_.Exception.Message)" -Level 'ERROR'
                throw
            }
        }
    }
}

if (-not (Get-Command Get-CoreConfiguration -ErrorAction SilentlyContinue)) {
    function Get-CoreConfiguration {
        [CmdletBinding()]
        param(
            [Parameter()]
            [string]$ConfigPath = (Join-Path $PSScriptRoot 'default-config.json')
        )
        
        process {
            try {
                if (Test-Path $ConfigPath) {
                    return Get-Content $ConfigPath | ConvertFrom-Json
                } else {
                    throw "Configuration file not found: $ConfigPath"
                }
            } catch {
                Write-CustomLog -Message "Failed to load configuration: $($_.Exception.Message)" -Level 'ERROR'
                throw
            }
        }
    }
}

if (-not (Get-Command Test-CoreApplicationHealth -ErrorAction SilentlyContinue)) {
    function Test-CoreApplicationHealth {
        [CmdletBinding()]
        param()
        
        process {
            try {
                Write-CustomLog -Message 'Running core application health check' -Level 'INFO'
                
                # Check configuration files
                $configPath = Join-Path $PSScriptRoot 'default-config.json'
                if (-not (Test-Path $configPath)) {
                    Write-CustomLog -Message 'Default configuration file missing' -Level 'ERROR'
                    return $false
                }
                
                # Check scripts directory
                $scriptsPath = Join-Path $PSScriptRoot 'scripts'
                if (-not (Test-Path $scriptsPath)) {
                    Write-CustomLog -Message 'Scripts directory missing' -Level 'ERROR'
                    return $false
                }
                
                Write-CustomLog -Message 'Core application health check passed' -Level 'INFO'
                return $true
                
            } catch {
                Write-CustomLog -Message "Health check failed: $($_.Exception.Message)" -Level 'ERROR'
                return $false
            }
        }
    }
}

if (-not (Get-Command Get-PlatformInfo -ErrorAction SilentlyContinue)) {
    function Get-PlatformInfo {
        [CmdletBinding()]
        param()
        
        process {
            if ($IsWindows -or ($PSVersionTable.PSVersion.Major -lt 6 -and -not (Get-Command uname -ErrorAction SilentlyContinue))) {
                return 'Windows'
            } elseif ($IsMacOS -or (uname) -eq 'Darwin') {
                return 'macOS'
            } elseif ($IsLinux -or (uname) -match 'Linux') {
                return 'Linux'
            } else {
                return 'Unknown'
            }
        }
    }
}

# Export all public functions
Export-ModuleMember -Function @(
    'Invoke-CoreApplication',
    'Start-LabRunner',
    'Get-CoreConfiguration',
    'Test-CoreApplicationHealth',
    'Write-CustomLog',
    'Get-PlatformInfo'
)
