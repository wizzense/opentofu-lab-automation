Param (
    [Parameter(Mandatory)]
    [pscustomobject]$Config
)

function Install-NpmDependencies {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [pscustomobject]$Config
    )

    # Bring in common helpers / Write-CustomLog, Invoke-LabStep, etc.
    . "$PSScriptRoot/../runner_utility_scripts/ScriptTemplate.ps1"

    #---------------------------------------------------------------------
    # Invoke within the standard Lab-Step wrapper
    #---------------------------------------------------------------------
    Invoke-LabStep -Config $Config -Body {
        param ($Config)

        Write-CustomLog 'Running 0203_Install-npm.ps1'

        <#
        .SYNOPSIS
            Install frontend project dependencies using npm.

        .DESCRIPTION
            * Reads Node_Dependencies from $Config
            * Optionally creates the frontend path and a stub package.json
            * Executes `npm install` in that folder
        #>

        #--- Pull Node_Dependencies block --------------------------------
        $nodeDeps = if ($Config -is [hashtable]) { 
                        $Config['Node_Dependencies'] 
                    } else { 
                        $Config.Node_Dependencies 
                    }

        if (-not $nodeDeps) {
            Write-CustomLog "Config missing Node_Dependencies; skipping npm install."
            return
        }

        #-----------------------------------------------------------------
        # Determine flags
        #-----------------------------------------------------------------
        $installNpm = $true          # default
        $createPath = $false         # default

        foreach ($key in @('InstallNpm','CreateNpmPath')) {
            if ($nodeDeps -is [hashtable]) {
                if ($nodeDeps.ContainsKey($key)) {
                    Set-Variable -Name $key.ToLower() -Value ([bool]$nodeDeps[$key]) -Scope Local
                }
            } elseif ($nodeDeps.PSObject.Properties.Match($key).Count) {
                Set-Variable -Name $key.ToLower() -Value ([bool]$nodeDeps.$key) -Scope Local
            }
        }

        if (-not $insta
