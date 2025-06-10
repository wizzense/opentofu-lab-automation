Param(
    [pscustomobject]$Config,
    [switch]$AsJson
)

function Get-SystemInfo {
    [CmdletBinding()]
    param(
        [switch]$AsJson,
        [pscustomobject]$Config
    )

    . "$PSScriptRoot/../runner_utility_scripts/ScriptTemplate.ps1"
    Invoke-LabStep -Config $Config -Body {
        Write-CustomLog 'Running 0200_Get-SystemInfo.ps1'

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
