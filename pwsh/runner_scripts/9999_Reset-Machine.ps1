Param([object]$Config)







Import-Module "/C:\Users\alexa\OneDrive\Documents\0. wizzense\opentofu-lab-automation//pwsh/modules/LabRunner/" -Force -Force -Force -Force -Force -Force -ForceWrite-CustomLog "Starting $MyInvocation.MyCommand"
Invoke-LabStep -Config $Config -Body {
    Write-CustomLog "Running $($MyInvocation.MyCommand.Name)"
    $platform = Get-Platform
    Write-CustomLog "Detected platform: $platform"
    if ($platform -eq 'Windows') {
        $Config.AllowRemoteDesktop = $true
        if (-not $Config.FirewallPorts) { $Config.FirewallPorts = @() }
        if ($Config.FirewallPorts -notcontains 3389) { $Config.FirewallPorts += 3389 }

        & "$PSScriptRoot/0101_Enable-RemoteDesktop.ps1" -Config $Config
        & "$PSScriptRoot/0102_Configure-Firewall.ps1" -Config $Config

        $sysprep = 'C:\\Windows\\System32\\Sysprep\\Sysprep.exe'
        if (Test-Path $sysprep) {
            Write-CustomLog "Invoking sysprep at $sysprep"
            Start-Process $sysprep -ArgumentList '/generalize /oobe /shutdown /quiet' -Wait
        } else {
            Write-CustomLog 'Sysprep not found; unable to reset.' -Level 'ERROR'
            exit 1
        }
    } elseif ($platform -in @('Linux','MacOS')) {
        Write-CustomLog 'Initiating system reboot...'
        Restart-Computer
    } else {
        Write-CustomLog 'Unknown platform; cannot reset.'
        exit 1
    }
    Write-CustomLog "Completed $($MyInvocation.MyCommand.Name)"
}
Write-CustomLog "Completed $($MyInvocation.MyCommand.Name)"















