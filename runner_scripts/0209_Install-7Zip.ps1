Param([object]$Config)
Import-Module "$PSScriptRoot/../lab_utils/LabRunner/LabRunner.psd1"

Write-CustomLog "Starting $MyInvocation.MyCommand"
function Install-7Zip {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param([object]$Config)

    Invoke-LabStep -Config $Config -Body {
        Write-CustomLog "Running $($MyInvocation.MyCommand.Name)"
        if ($Config.Install7Zip -eq $true) {
            if (-not (Get-Command 7z -ErrorAction SilentlyContinue)) {
                $url = 'https://www.7-zip.org/a/7z2301-x64.exe'
                $installer = Join-Path $env:TEMP '7zip.exe'
                Invoke-LabWebRequest -Uri $url -OutFile $installer -UseBasicParsing
                Start-Process -FilePath $installer -ArgumentList '/S' -Wait
                Remove-Item $installer -Force
            } else {
                Write-CustomLog '7-Zip already installed.'
            }
        } else {
            Write-CustomLog 'Install7Zip flag is disabled. Skipping 7-Zip installation.'
        }
    }
    Write-CustomLog "Completed $($MyInvocation.MyCommand.Name)"
}
if ($MyInvocation.InvocationName -ne '.') { Install-7Zip @PSBoundParameters }
