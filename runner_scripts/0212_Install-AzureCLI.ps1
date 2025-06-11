Param([object]$Config)
Import-Module "$PSScriptRoot/../lab_utils/LabRunner/LabRunner.psd1"

Write-CustomLog "Starting $MyInvocation.MyCommand"
function Install-AzureCLI {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param([object]$Config)

    Invoke-LabStep -Config $Config -Body {
        Write-CustomLog "Running $($MyInvocation.MyCommand.Name)"
        if ($Config.InstallAzureCLI -eq $true) {
            if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
                $url = 'https://aka.ms/installazurecliwindows'
                $msi = Join-Path $env:TEMP 'azure-cli.msi'
                Invoke-LabWebRequest -Uri $url -OutFile $msi -UseBasicParsing
                Start-Process msiexec.exe -ArgumentList "/i `"$msi`" /quiet /norestart" -Wait -NoNewWindow
                Remove-Item $msi -Force
            } else {
                Write-CustomLog 'Azure CLI already installed.'
            }
        } else {
            Write-CustomLog 'InstallAzureCLI flag is disabled. Skipping Azure CLI installation.'
        }
    }
    Write-CustomLog "Completed $($MyInvocation.MyCommand.Name)"
}
if ($MyInvocation.InvocationName -ne '.') { Install-AzureCLI @PSBoundParameters }
