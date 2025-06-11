Param([pscustomobject]$Config)
Import-Module "$PSScriptRoot/../lab_utils/LabRunner/LabRunner.psd1"

function Get-WacRegistryInstallation {
    param(
        [string]$RegistryPath
    )
    $items = Get-ChildItem $RegistryPath -ErrorAction SilentlyContinue
    foreach ($item in $items) {
        $itemProps = Get-ItemProperty $item.PSPath -ErrorAction SilentlyContinue
        # Only check if the DisplayName property exists
        if ($itemProps.PSObject.Properties['DisplayName'] -and $itemProps.DisplayName -like "*Windows Admin Center*") {
            return $itemProps
        }
    }
    return $null
}

Invoke-LabStep -Config $Config -Body {
    Write-CustomLog "Running $($MyInvocation.MyCommand.Name)"

if ($Config.InstallWAC -eq $true) {
    # Retrieve configuration for WAC from the config object
    $WacConfig = $Config.WAC
    if ($null -eq $WacConfig) {
        Write-CustomLog "No WAC configuration found. Skipping installation."
        return
    }

    $installPort = $WacConfig.InstallPort

    # Check both standard and Wow6432Node uninstall registry keys for WAC installation
    $wacInstalled = Get-WacRegistryInstallation -RegistryPath "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall"
    if (-not $wacInstalled) {
        $wacInstalled = Get-WacRegistryInstallation -RegistryPath "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
    }

    if ($wacInstalled) {
        Write-CustomLog "Windows Admin Center is already installed. Skipping installation."
        return
    }

    # Optionally, check if the desired installation port is already in use.
    $portInUse = Get-NetTCPConnection -LocalPort $installPort -ErrorAction SilentlyContinue
    if ($portInUse) {
        Write-CustomLog "Port $installPort is already in use. Assuming Windows Admin Center is running. Skipping installation."
        return
    }

    Write-CustomLog "Installing Windows Admin Center..."

    # Download the Windows Admin Center MSI
    $downloadUrl = "https://aka.ms/wacdownload"
    $installerPath = "$env:TEMP\WindowsAdminCenter.msi"

    $ProgressPreference = 'SilentlyContinue'

    Write-CustomLog "Downloading WAC from $downloadUrl"
    Invoke-WebRequest -Uri $downloadUrl -OutFile $installerPath -UseBasicParsing

    Write-CustomLog "Installing WAC silently on port $installPort"
    Start-Process msiexec.exe -Wait -ArgumentList "/i `"$installerPath`" /qn /L*v `"$env:TEMP\WacInstall.log`" SME_PORT=$installPort ACCEPT_EULA=1"

    Write-CustomLog "WAC installation complete."
} else {
    Write-CustomLog "InstallWAC flag is disabled. Skipping Windows Admin Center installation."
}
}
