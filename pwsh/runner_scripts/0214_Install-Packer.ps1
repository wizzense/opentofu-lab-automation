Param([object]$Config)
Import-Module "$PSScriptRoot/../lab_utils/LabRunner/LabRunner.psd1" -Force

Write-CustomLog "Starting $MyInvocation.MyCommand"
function Install-Packer {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param([object]$Config)

    Invoke-LabStep -Config $Config -Body {
        Write-CustomLog "Running $($MyInvocation.MyCommand.Name)"
        if ($Config.InstallPacker -eq $true) {
            if (-not (Get-Command packer -ErrorAction SilentlyContinue)) {
                $url = 'https://releases.hashicorp.com/packer/1.10.2/packer_1.10.2_windows_amd64.zip'
                $dest = Join-Path $env:ProgramFiles 'Packer'
                Invoke-LabDownload -Uri $url -Prefix 'packer' -Extension '.zip' -Action {
                    param($zip)
                    if (-not (Test-Path $dest)) { New-Item -ItemType Directory -Path $dest -Force | Out-Null }
                    Expand-Archive -Path $zip -DestinationPath $dest -Force
                }
            } else {
                Write-CustomLog 'Packer already installed.'
            }
        } else {
            Write-CustomLog 'InstallPacker flag is disabled. Skipping Packer installation.'
        }
    }
    Write-CustomLog "Completed $($MyInvocation.MyCommand.Name)"
}
if ($MyInvocation.InvocationName -ne '.') { Install-Packer @PSBoundParameters }
Write-CustomLog "Completed $($MyInvocation.MyCommand.Name)"