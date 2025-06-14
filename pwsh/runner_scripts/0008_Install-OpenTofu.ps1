Param([object]$Config)








Import-Module "C:\Users\alexa\OneDrive\Documents\0. wizzense\opentofu-lab-automation/pwsh/modules/LabRunner/" -Force -Force -Force -Force -Force -Force -Force# Param([pscustomobject]$Config)







# Import-Module "C:\Users\alexa\OneDrive\Documents\0. wizzense\opentofu-lab-automation/pwsh/modules/LabRunner/" -Force -Force -Force -Force -Force -Force -Force-Force.psd1')

Write-CustomLog "Starting $MyInvocation.MyCommand"

function Install-OpenTofu {
    [CmdletBinding()]
    param([object]$Config)

    






Invoke-LabStep -Config $Config -Body {
        Write-CustomLog "Running $($MyInvocation.MyCommand.Name)"

        if ($Config.InstallOpenTofu -eq $true) {
            $Cosign = Join-Path $Config.CosignPath "cosign-windows-amd64.exe"
            $openTofuVersion = if ($Config.OpenTofuVersion) { $Config.OpenTofuVersion    } else { 'latest'    }
            Invoke-OpenTofuInstaller -CosignPath $Cosign -OpenTofuVersion $openTofuVersion        } else {
            Write-CustomLog "InstallOpenTofu flag is disabled. Skipping OpenTofu installation."
        }
    }
}

if ($MyInvocation.InvocationName -ne '.') { Install-OpenTofu @PSBoundParameters }
Write-CustomLog "Completed $($MyInvocation.MyCommand.Name)"

















