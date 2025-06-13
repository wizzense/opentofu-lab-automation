Param([object]$Config)




Import-Module "$PSScriptRoot/../modules/LabRunner/LabRunner.psd1" -Force

Write-CustomLog "Starting $MyInvocation.MyCommand"
function Install-DockerDesktop {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param([object]$Config)

    



Invoke-LabStep -Config $Config -Body {
        Write-CustomLog "Running $($MyInvocation.MyCommand.Name)"
        if ($Config.InstallDockerDesktop -eq $true) {
            if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
                $url = 'https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe'
                Invoke-LabDownload -Uri $url -Prefix 'docker-desktop-installer' -Extension '.exe' -Action {
                    param($installer)
                    



Start-Process -FilePath $installer -ArgumentList 'install --quiet' -Wait
                }
            } else {
                Write-CustomLog 'Docker Desktop already installed.'
            }
        } else {
            Write-CustomLog 'InstallDockerDesktop flag is disabled. Skipping Docker Desktop installation.'
        }
    }
    Write-CustomLog "Completed $($MyInvocation.MyCommand.Name)"
}
if ($MyInvocation.InvocationName -ne '.') { Install-DockerDesktop @PSBoundParameters }
Write-CustomLog "Completed $($MyInvocation.MyCommand.Name)"


