Param(object$Config)

Import-Module "/C:\Users\alexa\OneDrive\Documents\0. wizzense\opentofu-lab-automation\pwsh/modules/LabRunner/" -ForceWrite-CustomLog "Starting $MyInvocation.MyCommand"
function Install-VSBuildTools {
    CmdletBinding(SupportsShouldProcess = $true)
    param(object$Config)

Invoke-LabStep -Config $Config -Body {
        Write-CustomLog "Running $($MyInvocation.MyCommand.Name)"
        if ($Config.InstallVSBuildTools -eq $true) {
            if (-not (Get-Command vswhere -ErrorAction SilentlyContinue)) {
                $url = 'https://aka.ms/vs/17/release/vs_BuildTools.exe'
                Invoke-LabDownload -Uri $url -Prefix 'vs_buildtools' -Extension '.exe' -Action {
                    param($installer)

Start-Process -FilePath $installer -ArgumentList '--quiet --wait --norestart --nocache --installPath C:\BuildTools' -Wait
                }
            } else {
                Write-CustomLog 'VS Build Tools already installed.'
            }
        } else {
            Write-CustomLog 'InstallVSBuildTools flag is disabled. Skipping VS Build Tools installation.'
        }
    }
    Write-CustomLog "Completed $($MyInvocation.MyCommand.Name)"
}
if ($MyInvocation.InvocationName -ne '.') { Install-VSBuildTools @PSBoundParameters }
Write-CustomLog "Completed $($MyInvocation.MyCommand.Name)"

