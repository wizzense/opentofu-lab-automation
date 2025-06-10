Param([pscustomobject]$Config)
. "$PSScriptRoot/../runner_utility_scripts/ScriptTemplate.ps1"
Invoke-LabStep -Config $Config -Body {
    Write-CustomLog 'Running 0102_Configure-Firewall.ps1'

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
}
