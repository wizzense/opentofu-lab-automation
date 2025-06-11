Param([object]$Config)
Import-Module "$PSScriptRoot/../lab_utils/LabRunner/LabRunner.psd1"

Write-CustomLog "Starting $MyInvocation.MyCommand"
function Install-VSBuildTools {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param([object]$Config)

    Invoke-LabStep -Config $Config -Body {
        Write-CustomLog "Running $($MyInvocation.MyCommand.Name)"
        if ($Config.InstallVSBuildTools -eq $true) {
            if (-not (Get-Command vswhere -ErrorAction SilentlyContinue)) {
                $url = 'https://aka.ms/vs/17/release/vs_BuildTools.exe'
                $installer = Join-Path $env:TEMP 'vs_buildtools.exe'
                Invoke-LabWebRequest -Uri $url -OutFile $installer -UseBasicParsing
                Start-Process -FilePath $installer -ArgumentList '--quiet --wait --norestart --nocache --installPath C:\BuildTools' -Wait
                Remove-Item $installer -Force
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
