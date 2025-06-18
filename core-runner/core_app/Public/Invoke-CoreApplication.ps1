#Requires -Version 7.0

<#
.SYNOPSIS
    Main entry point for the OpenTofu Lab Automation Core Application.
    
.DESCRIPTION
    Processes the given configuration file and executes the requested scripts.
    Provides a standardized way to run scripts from the Core Application.
    
.PARAMETER ConfigPath
    Path to the configuration file (JSON format) containing application settings.
    
.PARAMETER Scripts
    Optional array of script names to execute. If not provided, runs based on configuration.
    
.PARAMETER Auto
    Switch to run in automatic mode without user interaction.
    
.PARAMETER Force
    Switch to force execution even if validation checks fail.
    
.EXAMPLE
    Invoke-CoreApplication -ConfigPath "./configs/default-config.json"
    
.EXAMPLE
    Invoke-CoreApplication -ConfigPath "./configs/custom-config.json" -Scripts "0008_Install-OpenTofu.ps1"
#>
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
                    $scriptPath = Join-Path $PSScriptRoot '../scripts' $script
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
                
                # Get all numbered scripts in order
                $scriptsPath = Join-Path $PSScriptRoot '../scripts'
                if (Test-Path $scriptsPath) {
                    $scriptFiles = Get-ChildItem -Path $scriptsPath -Filter '[0-9]*.ps1' | Sort-Object Name
                    
                    foreach ($scriptFile in $scriptFiles) {
                        if ($Auto -or $Force -or $PSCmdlet.ShouldProcess($scriptFile.Name, 'Execute script')) {
                            Write-CustomLog -Message "Executing script: $($scriptFile.Name)" -Level 'INFO'
                            & $scriptFile.FullName -Config $config
                        }
                    }
                }
            }
            
            Write-CustomLog -Message 'Core application operation completed successfully' -Level 'SUCCESS'
            return $true
            
        } catch {
            Write-CustomLog -Message "Core application operation failed: $($_.Exception.Message)" -Level 'ERROR'
            throw
        }
    }
}