#Requires -Version 7.0

<#
.SYNOPSIS
    Starts the OpenTofu Lab Automation runner with the specified configuration.
    
.DESCRIPTION
    A wrapper around Invoke-CoreApplication that provides additional options
    for parallel execution and specialized runner configurations.
    
.PARAMETER ConfigPath
    Path to the configuration file (JSON format) containing application settings.
    
.PARAMETER Parallel
    Switch to enable parallel execution of scripts when possible.
    
.EXAMPLE
    Start-LabRunner -ConfigPath "./configs/default-config.json"
    
.EXAMPLE
    Start-LabRunner -ConfigPath "./configs/custom-config.json" -Parallel
#>
function Start-LabRunner {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ConfigPath,
        
        [Parameter()]
        [switch]$Parallel
    )
    
    process {
        try {
            if ($Parallel) {
                Write-CustomLog -Message "Parallel lab runner not implemented yet - using standard runner" -Level "WARN"
                Invoke-CoreApplication -ConfigPath $ConfigPath
            } else {
                if ($PSCmdlet.ShouldProcess($ConfigPath, "Start lab runner")) {
                    Invoke-CoreApplication -ConfigPath $ConfigPath
                }
            }
        } catch {
            Write-CustomLog -Message "Lab runner failed: $($_.Exception.Message)" -Level "ERROR"
            throw
        }
    }
}
