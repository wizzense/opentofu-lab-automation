Param(
    [object]$Config
)








Import-Module "/C:\Users\alexa\OneDrive\Documents\0. wizzense\opentofu-lab-automation//pwsh/modules/LabRunner/" -Force -Force -Force -Force -Force -Force -ForceWrite-CustomLog "Starting $MyInvocation.MyCommand"

function Set-LabProfile {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param([object]$Config)

    






Invoke-LabStep -Config $Config -Body {
        param($Config)
        






Write-CustomLog "Running $($MyInvocation.MyCommand.Name)"
        if ($Config.SetupLabProfile -eq $true) {
            $profilePath = $PROFILE.CurrentUserAllHosts
            $profileDir  = Split-Path $profilePath
            if (-not (Test-Path $profileDir)) {
                New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
            }
            $repoRoot = Resolve-Path -Path (Join-Path $PSScriptRoot '..')
            $content = @"
# OpenTofu Lab Automation profile
`$env:PATH = \"$repoRoot;`$env:PATH\"
`$env:PSModulePath = \"$repoRoot\pwsh\modules;`$env:PSModulePath\"
"@
            Set-Content -Path $profilePath -Value $content -Encoding utf8
            Write-CustomLog "Profile written to $profilePath"
        } else {
            Write-CustomLog 'SetupLabProfile flag is disabled. Skipping profile creation.'
        }
    }
    Write-CustomLog "Completed $($MyInvocation.MyCommand.Name)"
}

if ($MyInvocation.InvocationName -ne '.') { Set-LabProfile @PSBoundParameters }
Write-CustomLog "Completed $($MyInvocation.MyCommand.Name)"
















