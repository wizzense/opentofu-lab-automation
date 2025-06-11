Param([object]$Config)
Import-Module "$PSScriptRoot/../lab_utils/LabRunner/LabRunner.psd1"

Write-CustomLog "Starting $MyInvocation.MyCommand"
function Install-VSCode {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param([object]$Config)

    Invoke-LabStep -Config $Config -Body {
        Write-CustomLog "Running $($MyInvocation.MyCommand.Name)"
        if ($Config.InstallVSCode -eq $true) {
            if (-not (Get-Command code -ErrorAction SilentlyContinue)) {
                $url = 'https://update.code.visualstudio.com/latest/win32-x64-user/stable'
                $installer = Join-Path $env:TEMP 'vscode.exe'
                Invoke-LabWebRequest -Uri $url -OutFile $installer -UseBasicParsing
                Start-Process -FilePath $installer -ArgumentList '/verysilent /suppressmsgboxes /mergetasks=!runcode' -Wait
                Remove-Item $installer -Force
            } else {
                Write-CustomLog 'VS Code already installed.'
            }
        } else {
            Write-CustomLog 'InstallVSCode flag is disabled. Skipping VS Code installation.'
        }
    }
    Write-CustomLog "Completed $($MyInvocation.MyCommand.Name)"
}
if ($MyInvocation.InvocationName -ne '.') { Install-VSCode @PSBoundParameters }
