Param([object]$Config)







Import-Module "/pwsh/modules/LabRunner/"  -Force
Write-CustomLog "Starting $MyInvocation.MyCommand"
Invoke-LabStep -Config $Config -Body {
    Write-CustomLog "Running $($MyInvocation.MyCommand.Name)"

Write-CustomLog "Configuring Firewall rules..."

if ($null -ne $Config.FirewallPorts) {
    foreach ($port in $Config.FirewallPorts) {
        Write-CustomLog " - Opening TCP port $port"
        New-NetFirewallRule -DisplayName "Open Port $port" `
                            -Direction Inbound `
                            -Protocol TCP `
                            -LocalPort $port `
                            -Action Allow |
                            Out-Null
    }
} else {
    Write-CustomLog "No firewall ports specified."
}
    Write-CustomLog "Completed $($MyInvocation.MyCommand.Name)"
}
Write-CustomLog "Completed $($MyInvocation.MyCommand.Name)"















