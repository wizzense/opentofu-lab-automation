Param([object]$Config)







Import-Module "/C:\Users\alexa\OneDrive\Documents\0. wizzense\opentofu-lab-automation//pwsh/modules/LabRunner/" -Force -Force -Force -Force -Force -Force -ForceWrite-CustomLog "Starting $MyInvocation.MyCommand"
function Install-AzureCLI {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param([object]$Config)

    






Invoke-LabStep -Config $Config -Body {
        Write-CustomLog "Running $($MyInvocation.MyCommand.Name)"
        if ($Config.InstallAzureCLI -eq $true) {
            if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
                $url = 'https://aka.ms/installazurecliwindows'
                Invoke-LabDownload -Uri $url -Prefix 'azure-cli' -Extension '.msi' -Action {
                    param($msi)
                    






Start-Process msiexec.exe -ArgumentList "/i `"$msi`" /quiet /norestart" -Wait -NoNewWindow
                }
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
Write-CustomLog "Completed $($MyInvocation.MyCommand.Name)"















