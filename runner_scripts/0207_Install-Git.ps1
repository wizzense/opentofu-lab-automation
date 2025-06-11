Param([object]$Config)
Import-Module "$PSScriptRoot/../lab_utils/LabRunner/LabRunner.psd1"

Write-CustomLog "Starting $MyInvocation.MyCommand"
function Install-Git {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param([object]$Config)

    Invoke-LabStep -Config $Config -Body {
        Write-CustomLog "Running $($MyInvocation.MyCommand.Name)"
        if ($Config.InstallGit -eq $true) {
            if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
                $url = 'https://github.com/git-for-windows/git/releases/download/v2.48.1.windows.1/Git-2.48.1-64-bit.exe'
                $installer = Join-Path $env:TEMP 'git-installer.exe'
                Invoke-LabWebRequest -Uri $url -OutFile $installer -UseBasicParsing
                Start-Process -FilePath $installer -ArgumentList '/SILENT' -Wait
                Remove-Item $installer -Force
            } else {
                Write-CustomLog 'Git already installed.'
            }
        } else {
            Write-CustomLog 'InstallGit flag is disabled. Skipping Git installation.'
        }
    }
    Write-CustomLog "Completed $($MyInvocation.MyCommand.Name)"
}
if ($MyInvocation.InvocationName -ne '.') { Install-Git @PSBoundParameters }
