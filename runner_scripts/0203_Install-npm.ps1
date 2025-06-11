Param(
    [Parameter(Mandatory)]
    [pscustomobject]$Config
)

. "$PSScriptRoot/../runner_utility_scripts/ScriptTemplate.ps1"
function Install-NpmDependencies {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param([pscustomobject]$Config)


    Invoke-LabStep -Config $Config -Body {
        param($Config)

        Write-CustomLog 'Running 0203_Install-npm.ps1'
<#
.SYNOPSIS
    Installs npm dependencies for the frontend project.

.DESCRIPTION
    Runs `npm install` in the configured frontend directory.
    Can create the directory and a blank package.json when enabled.

.PARAMETER Config
    Hashed config object passed from runner.ps1

.EXAMPLE
    .\0203_Install-npm.ps1 -Config $Config
#>

        # Pull Node_Dependencies block
        $nodeDeps = if ($Config -is [hashtable]) { $Config['Node_Dependencies'] } else { $Config.Node_Dependencies }
        if (-not $nodeDeps) {
            Write-CustomLog 'Config missing Node_Dependencies; skipping npm install.'
            return
        }

        # Determine flags
        $installNpm = $true
        $createPath = $false

        foreach ($key in @('InstallNpm','CreateNpmPath')) {
            if ($nodeDeps -is [hashtable]) {
                if ($nodeDeps.ContainsKey($key)) {
                    switch ($key) {
                        'InstallNpm'    { $installNpm  = [bool]$nodeDeps[$key] }
                        'CreateNpmPath' { $createPath  = [bool]$nodeDeps[$key] }
                    }
                }
            } elseif ($nodeDeps.PSObject.Properties.Match($key).Count) {
                switch ($key) {
                    'InstallNpm'    { $installNpm  = [bool]$nodeDeps.$key }
                    'CreateNpmPath' { $createPath  = [bool]$nodeDeps.$key }
                }

            }
            if ($nodeDeps.PSObject.Properties.Match('CreateNpmPath').Count) {
                $createPath = [bool]$nodeDeps.CreateNpmPath
            }

        }

        if (-not $installNpm) {
            Write-CustomLog 'InstallNpm flag is disabled. Skipping project dependency installation.'
            return
        }

        # Determine frontend path
        $frontendPath = $null
        if ($nodeDeps -is [hashtable]) {
            if ($nodeDeps.ContainsKey('NpmPath')) { $frontendPath = $nodeDeps['NpmPath'] }
        } elseif ($nodeDeps.PSObject.Properties.Match('NpmPath').Count) {
            $frontendPath = $nodeDeps.NpmPath
        }
        if (-not $frontendPath) { $frontendPath = Join-Path $PSScriptRoot '..' 'frontend' }

        if ($nodeDeps.PSObject.Properties.Match('NpmPath').Count -and [string]::IsNullOrWhiteSpace($nodeDeps.NpmPath) -and -not $createPath) {
            throw 'Node_Dependencies.NpmPath is empty and CreateNpmPath is false.'
        }

        if (-not (Test-Path $frontendPath)) {
            if ($createPath) {
                Write-CustomLog "Creating missing frontend folder at: $frontendPath"
                if ($PSCmdlet.ShouldProcess($frontendPath,'Create NpmPath')) {
                    New-Item -ItemType Directory -Path $frontendPath -Force | Out-Null
                }
            } else {
                throw "Frontend folder not found at: $frontendPath"
            }
        }

        if (-not (Test-Path (Join-Path $frontendPath 'package.json'))) {
            if ($createPath) {
                '{}' | Set-Content -Path (Join-Path $frontendPath 'package.json')
            } else {
                Write-CustomLog "No package.json found in $frontendPath. Skipping npm install."
                return
            }
        }

        Push-Location $frontendPath
        try {
            Write-CustomLog "Running npm install in $frontendPath ..."
            if ($PSCmdlet.ShouldProcess($frontendPath,'Run npm install')) { npm install }
            Write-CustomLog 'npm install completed.'
        } catch {
            Write-Error "ERROR: npm install failed: $_"
            exit 1
        } finally {
            Pop-Location
        }
        Write-CustomLog '==== Frontend dependency installation complete ===='
    }
}

if ($MyInvocation.InvocationName -ne '.') { Install-NpmDependencies @PSBoundParameters }
