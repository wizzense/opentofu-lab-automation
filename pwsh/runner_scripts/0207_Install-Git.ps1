Param([object]$Config)







Import-Module "C:\Users\alexa\OneDrive\Documents\0. wizzense\opentofu-lab-automation/pwsh/modules/LabRunner/" -Force -Force -Force -Force -Force -Force -ForceWrite-CustomLog "Starting $MyInvocation.MyCommand"
function Install-Git {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param([object]$Config)

    






Invoke-LabStep -Config $Config -Body {
        Write-CustomLog "Running $($MyInvocation.MyCommand.Name)"
        if ($Config.InstallGit -eq $true) {
            if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
                $url = 'https://github.com/git-for-windows/git/releases/download/v2.48.1.windows.1/Git-2.48.1-64-bit.exe'
                Invoke-LabDownload -Uri $url -Prefix 'git-installer' -Extension '.exe' -Action {
                    param($installer)
                    






Start-Process -FilePath $installer -ArgumentList '/SILENT' -Wait
                }
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
Write-CustomLog "Completed $($MyInvocation.MyCommand.Name)"















