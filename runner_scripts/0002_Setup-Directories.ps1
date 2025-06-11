Param([pscustomobject]$Config)
Import-Module "$PSScriptRoot/../runner_utility_scripts/LabRunner.psd1"
Invoke-LabStep -Config $Config -Body {
    Write-CustomLog 'Running 0002_Setup-Directories.ps1'

    $dirs = @()
    if ($Config.Directories -and $Config.Directories.HyperVPath) {
        $dirs += $Config.Directories.HyperVPath
    }
    if ($Config.Directories -and $Config.Directories.IsoSharePath) {
        $dirs += $Config.Directories.IsoSharePath
    }

    if (-not $dirs) {
        Write-CustomLog 'No directories specified for creation.'
        return
    }

    Write-CustomLog ("Preparing directories: {0}" -f ($dirs -join ', '))

    foreach ($dir in $dirs) {
        Write-CustomLog "Ensuring directory '$dir' exists..."
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
            Write-CustomLog "Created directory '$dir'"
        } else {
            Write-CustomLog "Directory '$dir' already exists; skipping."
        }
    }
}
