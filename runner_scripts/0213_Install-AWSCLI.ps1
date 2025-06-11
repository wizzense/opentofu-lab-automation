Param([object]$Config)
Import-Module "$PSScriptRoot/../lab_utils/LabRunner/LabRunner.psd1"

Write-CustomLog "Starting $MyInvocation.MyCommand"
function Install-AWSCLI {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param([object]$Config)

    Invoke-LabStep -Config $Config -Body {
        Write-CustomLog "Running $($MyInvocation.MyCommand.Name)"
        if ($Config.InstallAWSCLI -eq $true) {
            if (-not (Get-Command aws -ErrorAction SilentlyContinue)) {
                $url = 'https://awscli.amazonaws.com/AWSCLIV2.msi'
                $msi = Join-Path $env:TEMP 'awscli.msi'
                Invoke-LabWebRequest -Uri $url -OutFile $msi -UseBasicParsing
                Start-Process msiexec.exe -ArgumentList "/i `"$msi`" /quiet /norestart" -Wait -NoNewWindow
                Remove-Item $msi -Force
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
