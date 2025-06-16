Param([object]$Config)







Import-Module "/C:\Users\alexa\OneDrive\Documents\0. wizzense\opentofu-lab-automation\pwsh/modules/LabRunner/" -ForceWrite-CustomLog "Starting $MyInvocation.MyCommand"
function Install-AWSCLI {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param([object]$Config)

    






Invoke-LabStep -Config $Config -Body {
        Write-CustomLog "Running $($MyInvocation.MyCommand.Name)"
        if ($Config.InstallAWSCLI -eq $true) {
            if (-not (Get-Command aws -ErrorAction SilentlyContinue)) {
                $url = 'https://awscli.amazonaws.com/AWSCLIV2.msi'
                Invoke-LabDownload -Uri $url -Prefix 'awscli' -Extension '.msi' -Action {
                    param($msi)
                    






Start-Process msiexec.exe -ArgumentList "/i `"$msi`" /quiet /norestart" -Wait -NoNewWindow
                }
            } else {
                Write-CustomLog 'AWS CLI already installed.'
            }
        } else {
            Write-CustomLog 'InstallAWSCLI flag is disabled. Skipping AWS CLI installation.'
        }
    }
    Write-CustomLog "Completed $($MyInvocation.MyCommand.Name)"
}
if ($MyInvocation.InvocationName -ne '.') { Install-AWSCLI @PSBoundParameters }
Write-CustomLog "Completed $($MyInvocation.MyCommand.Name)"
















