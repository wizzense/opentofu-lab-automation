Param(
    [pscustomobject]$Config,
    [switch]$AsJson
)

. "$PSScriptRoot/../runner_utility_scripts/ScriptTemplate.ps1"
function Get-SystemInfo {
    [CmdletBinding()]
    param(
        [switch]$AsJson,
        [pscustomobject]$Config
    )

    . "$PSScriptRoot/../runner_utility_scripts/ScriptTemplate.ps1"
    Invoke-LabStep -Config $Config -Body {
        if (-not (Get-Command Get-Platform -ErrorAction SilentlyContinue)) {
            . "$PSScriptRoot/../lab_utils/Get-Platform.ps1"
        }
        Write-CustomLog 'Running 0200_Get-SystemInfo.ps1'
        $platform = Get-Platform
        Write-CustomLog "Detected platform: $platform"

        switch ($platform) {
            'Windows' {
                $computer = Get-CimInstance -ClassName Win32_ComputerSystem
                $os       = Get-CimInstance -ClassName Win32_OperatingSystem
                $net      = Get-NetIPConfiguration
                $hotfix   = Get-HotFix | Sort-Object InstalledOn -Descending | Select-Object -First 1
                $features = Get-WindowsFeature | Where-Object { $_.Installed } | Select-Object -ExpandProperty Name
                $disks    = Get-Disk | ForEach-Object {
                    $disk = $_
                    $parts = Get-Partition -DiskNumber $disk.Number | ForEach-Object {
                        $vol = $_ | Get-Volume -ErrorAction SilentlyContinue
                        [pscustomobject]@{
                            Partition   = $_.PartitionNumber
                            DriveLetter = $vol.DriveLetter
                            SizeGB      = [math]::Round(($vol.Size/1GB),2)
                            MediaType   = $disk.MediaType
                        }
                    }
                    $parts
                }

                $info = [pscustomobject]@{
                    ComputerName   = $computer.Name
                    IPAddresses    = $net.IPv4Address.IPAddress
                    DefaultGateway = ($net.IPv4DefaultGateway | Select-Object -ExpandProperty NextHop)
                    OSVersion      = $os.Version
                    DiskInfo       = $disks
                    RolesFeatures  = $features
                    LatestHotfix   = $hotfix.HotFixID
                }
            }
            'Linux' {
                $computer = (hostname)
                $addresses = [System.Net.NetworkInformation.NetworkInterface]::GetAllNetworkInterfaces() |
                    Where-Object { $_.OperationalStatus -eq 'Up' } |
                    ForEach-Object { $_.GetIPProperties().UnicastAddresses } |
                    Where-Object { $_.Address.AddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetwork } |
                    ForEach-Object { $_.Address.ToString() } | Sort-Object -Unique
                $gateway = [System.Net.NetworkInformation.NetworkInterface]::GetAllNetworkInterfaces() |
                    ForEach-Object { $_.GetIPProperties().GatewayAddresses } |
                    Where-Object { $_.Address.AddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetwork } |
                    Select-Object -First 1 -ExpandProperty Address |
                    ForEach-Object { $_.ToString() }
                $osVersion = (uname -sr)
                $disks = [System.IO.DriveInfo]::GetDrives() |
                    Where-Object { $_.IsReady } |
                    ForEach-Object {
                        [pscustomobject]@{
                            Partition   = $_.Name
                            DriveLetter = $_.Name
                            SizeGB      = [math]::Round(($_.TotalSize/1GB),2)
                            MediaType   = $_.DriveType
                        }
                    }
                $info = [pscustomobject]@{
                    ComputerName   = $computer
                    IPAddresses    = $addresses
                    DefaultGateway = $gateway
                    OSVersion      = $osVersion
                    DiskInfo       = $disks
                }
            }
            'MacOS' {
                $computer = (hostname)
                $addresses = [System.Net.NetworkInformation.NetworkInterface]::GetAllNetworkInterfaces() |
                    Where-Object { $_.OperationalStatus -eq 'Up' } |
                    ForEach-Object { $_.GetIPProperties().UnicastAddresses } |
                    Where-Object { $_.Address.AddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetwork } |
                    ForEach-Object { $_.Address.ToString() } | Sort-Object -Unique
                $gateway = [System.Net.NetworkInformation.NetworkInterface]::GetAllNetworkInterfaces() |
                    ForEach-Object { $_.GetIPProperties().GatewayAddresses } |
                    Where-Object { $_.Address.AddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetwork } |
                    Select-Object -First 1 -ExpandProperty Address |
                    ForEach-Object { $_.ToString() }
                $osVersion = (uname -sr)
                $disks = [System.IO.DriveInfo]::GetDrives() |
                    Where-Object { $_.IsReady } |
                    ForEach-Object {
                        [pscustomobject]@{
                            Partition   = $_.Name
                            DriveLetter = $_.Name
                            SizeGB      = [math]::Round(($_.TotalSize/1GB),2)
                            MediaType   = $_.DriveType
                        }
                    }
                $info = [pscustomobject]@{
                    ComputerName   = $computer
                    IPAddresses    = $addresses
                    DefaultGateway = $gateway
                    OSVersion      = $osVersion
                    DiskInfo       = $disks
                }
            }
            Default {
                Write-CustomLog "Unsupported platform: $platform" -Level 'ERROR'
                exit 1
            }
        }

        if ($AsJson) {
            $info | ConvertTo-Json -Depth 5
        } else {
            $info
        }
    }
}

if ($MyInvocation.InvocationName -ne '.') {
    Get-SystemInfo @PSBoundParameters
}
