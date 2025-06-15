Param([object]$Config)







Import-Module "/pwsh/modules/LabRunner/"  -Force
Write-CustomLog "Starting $MyInvocation.MyCommand"
Invoke-LabStep -Config $Config -Body {
    Write-CustomLog "Running $($MyInvocation.MyCommand.Name)"

    if (-not $Config.InstallSysinternals) {
        Write-CustomLog "InstallSysinternals flag is disabled. Skipping installation."
        return
    }

    $destDir = if ($Config.SysinternalsPath) { $Config.SysinternalsPath    } else { 'C:\\Sysinternals'    }
    if (-not (Test-Path $destDir)) {
        New-Item -ItemType Directory -Path $destDir -Force | Out-Null
    }

    $zipUrl  = 'https://download.sysinternals.com/files/SysinternalsSuite.zip'
    Invoke-LabDownload -Uri $zipUrl -Prefix 'SysinternalsSuite' -Extension '.zip' -Action {
        param($zipPath)
        






Write-CustomLog "Extracting to $destDir"
        Expand-Archive -Path $zipPath -DestinationPath $destDir -Force
    }

    $psInfo = Join-Path $destDir 'PsInfo.exe'
    if (Test-Path $psInfo) {
        Write-CustomLog 'Verifying PsInfo.exe'
        & $psInfo | Out-Null
    }

    Write-CustomLog "Completed $($MyInvocation.MyCommand.Name)"
}
Write-CustomLog "Completed $($MyInvocation.MyCommand.Name)"















