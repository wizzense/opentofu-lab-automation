Param(
    [Parameter(Mandatory=$true)]
    [PSCustomObject]$Config
)
. "$PSScriptRoot\..\runner_utility_scripts\Logger.ps1"

Write-Log "Configuring Firewall rules..."

if ($null -ne $Config.FirewallPorts) {
    foreach ($port in $Config.FirewallPorts) {
        Write-Log " - Opening TCP port $port"
        New-NetFirewallRule -DisplayName "Open Port $port" `
                            -Direction Inbound `
                            -Protocol TCP `
                            -LocalPort $port `
                            -Action Allow |
                            Out-Null
    }
} else {
    Write-Log "No firewall ports specified."
}
