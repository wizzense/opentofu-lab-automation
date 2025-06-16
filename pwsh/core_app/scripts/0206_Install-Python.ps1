Param(object$Config)







Import-Module "/C:\Users\alexa\OneDrive\Documents\0. wizzense\opentofu-lab-automation\pwsh/modules/LabRunner/" -ForceWrite-CustomLog "Starting $MyInvocation.MyCommand"
function Install-Python {
    CmdletBinding(SupportsShouldProcess = $true)
    param(object$Config)

    






Invoke-LabStep -Config $Config -Body {
        Write-CustomLog "Running $($MyInvocation.MyCommand.Name)"
        if ($Config.InstallPython -eq $true) {
            if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
                $url = 'https://www.python.org/ftp/python/3.12.3/python-3.12.3-amd64.exe'
                Invoke-LabDownload -Uri $url -Prefix 'python-installer' -Extension '.exe' -Action {
                    param($installer)
                    






Start-Process -FilePath $installer -ArgumentList '/quiet InstallAllUsers=1 PrependPath=1' -Wait
                    # Refresh PATH for the current session so subsequent scripts can find python
                    $userPath = Environment::GetEnvironmentVariable('PATH', 'User')
                    $machinePath = Environment::GetEnvironmentVariable('PATH', 'Machine')
                    $env:PATH = (($userPath, $machinePath) -join ';')
                    Write-CustomLog 'PATH refreshed with new Python location.'
                }
            } else {
                Write-CustomLog 'Python already installed.'
            }
        } else {
            Write-CustomLog 'InstallPython flag is disabled. Skipping Python installation.'
        }
    }
    Write-CustomLog "Completed $($MyInvocation.MyCommand.Name)"
}
if ($MyInvocation.InvocationName -ne '.') { Install-Python @PSBoundParameters }
Write-CustomLog "Completed $($MyInvocation.MyCommand.Name)"
















