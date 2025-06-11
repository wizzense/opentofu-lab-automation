Param([object]$Config)
Import-Module "$PSScriptRoot/../lab_utils/LabRunner/LabRunner.psd1"

Write-CustomLog "Starting $MyInvocation.MyCommand"
function Install-Python {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param([object]$Config)

    Invoke-LabStep -Config $Config -Body {
        Write-CustomLog "Running $($MyInvocation.MyCommand.Name)"
        if ($Config.InstallPython -eq $true) {
            if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
                $url = 'https://www.python.org/ftp/python/3.12.3/python-3.12.3-amd64.exe'
                $installer = Join-Path $env:TEMP 'python-installer.exe'
                Invoke-LabWebRequest -Uri $url -OutFile $installer -UseBasicParsing
                Start-Process -FilePath $installer -ArgumentList '/quiet InstallAllUsers=1 PrependPath=1' -Wait
                Remove-Item $installer -Force
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
