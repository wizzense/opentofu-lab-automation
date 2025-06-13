Param([object]$Config)







Import-Module "$PSScriptRoot/../modules/LabRunner/LabRunner.psd1" -Force

Write-CustomLog "Starting $MyInvocation.MyCommand"
function Install-Chocolatey {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param([object]$Config)

    






Invoke-LabStep -Config $Config -Body {
        Write-CustomLog "Running $($MyInvocation.MyCommand.Name)"
        if ($Config.InstallChocolatey -eq $true) {
            if (-not (Get-Command choco.exe -ErrorAction SilentlyContinue)) {
                $command = "Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))"
                Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command $command" -Wait
            } else {
                Write-CustomLog 'Chocolatey already installed.'
            }
        } else {
            Write-CustomLog 'InstallChocolatey flag is disabled. Skipping Chocolatey installation.'
        }
    }
    Write-CustomLog "Completed $($MyInvocation.MyCommand.Name)"
}
if ($MyInvocation.InvocationName -ne '.') { Install-Chocolatey @PSBoundParameters }
Write-CustomLog "Completed $($MyInvocation.MyCommand.Name)"



