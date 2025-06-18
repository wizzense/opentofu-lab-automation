#Requires -Version 7.0

[CmdletBinding()]
param(
    [Parameter()]
    [object]$Config,
    
    [Parameter()]
    [switch]$AsJson
)

Import-Module "$env:PROJECT_ROOT/core-runner/modules/LabRunner/" -Force
Write-CustomLog "Starting $($MyInvocation.MyCommand.Name)"

function Get-SystemInfo {
    [CmdletBinding()]
    param(
        [Parameter()]
        [switch]$AsJson,
        
        [Parameter()]
        [object]$Config
    )

    Invoke-LabStep -Config $Config -Body {
        Write-CustomLog "Running $($MyInvocation.MyCommand.Name)"
        $platform = Get-Platform
        Write-CustomLog "Detected platform: $platform"

        # Create base info object with cross-platform properties
        $info = [PSCustomObject]@{
            ComputerName = [System.Environment]::MachineName
            OSVersion    = [System.Environment]::OSVersion.VersionString
            Platform     = $platform
            IPAddresses  = @()
        }
        
        # Get IP addresses using cross-platform .NET method
        try {
            $info.IPAddresses = @(
                [System.Net.NetworkInformation.NetworkInterface]::GetAllNetworkInterfaces() | 
                    Where-Object { $_.OperationalStatus -eq 'Up' } | 
                    ForEach-Object { 
                        $_.GetIPProperties().UnicastAddresses 
                    } | 
                    Where-Object { 
                        $_.Address.AddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetwork 
                    } | 
                    ForEach-Object { 
                        $_.Address.ToString() 
                    }
            )
        } catch {
            Write-CustomLog "Error getting IP addresses: $($_)" -Level 'WARN'
        }

        # Add platform-specific information
        switch ($platform) {
            'Windows' {
                # Use cross-platform methods for Windows information
                if ($IsWindows -or $env:OS -eq 'Windows_NT') {
                    try {
                        # Get basic system info using .NET
                        $osInfo = [System.Environment]::OSVersion
                        $info | Add-Member -MemberType NoteProperty -Name 'OSName' -Value $osInfo.VersionString
                        $info | Add-Member -MemberType NoteProperty -Name 'ServicePack' -Value $osInfo.ServicePack
                        
                        # Use environment variables for additional information
                        $info | Add-Member -MemberType NoteProperty -Name 'ProcessorArchitecture' -Value $env:PROCESSOR_ARCHITECTURE
                        $info | Add-Member -MemberType NoteProperty -Name 'NumberOfProcessors' -Value $env:NUMBER_OF_PROCESSORS
                        
                        # Conditionally use PowerShell methods that work cross-platform
                        if (Get-Command Get-ComputerInfo -ErrorAction SilentlyContinue) {
                            $computerInfo = Get-ComputerInfo
                            $info | Add-Member -MemberType NoteProperty -Name 'WindowsSystemInfo' -Value $computerInfo
                        }
                    } catch {
                        Write-CustomLog "Error gathering Windows-specific information: $($_)" -Level 'WARN'
                    }
                }
            }
            'Linux' {
                # Get Linux-specific information
                try { 
                    $info.OSVersion = (uname -sr) 
                } catch { 
                    Write-CustomLog 'Error getting OS version' -Level 'WARN' 
                }
                
                # Get additional Linux information
                try {
                    $distroInfo = if (Test-Path /etc/os-release) {
                        Get-Content /etc/os-release | ConvertFrom-StringData
                    } else {
                        $null
                    }
                    
                    if ($distroInfo) {
                        $info | Add-Member -MemberType NoteProperty -Name 'Distribution' -Value $distroInfo.PRETTY_NAME
                    }
                } catch {
                    Write-CustomLog "Error getting Linux distribution information: $($_)" -Level 'WARN'
                }
            }
            'MacOS' {
                # Get macOS-specific information
                try { 
                    $info.OSVersion = (uname -sr)
                    
                    $swVers = if (Get-Command sw_vers -ErrorAction SilentlyContinue) {
                        @{
                            ProductName    = (sw_vers -productName)
                            ProductVersion = (sw_vers -productVersion)
                            BuildVersion   = (sw_vers -buildVersion)
                        }
                    } else {
                        $null
                    }
                    
                    if ($swVers) {
                        $info | Add-Member -MemberType NoteProperty -Name 'MacOSDetails' -Value $swVers
                    }
                } catch { 
                    Write-CustomLog "Error getting macOS version information: $($_)" -Level 'WARN'
                }
            }
            Default {
                Write-CustomLog "Unsupported platform: $platform" -Level 'WARN'
            }
        }

        # Get disk information - cross-platform method
        try {
            $info | Add-Member -MemberType NoteProperty -Name 'DiskInfo' -Value @(
                [System.IO.DriveInfo]::GetDrives() | 
                    Where-Object { $_.IsReady } | 
                    ForEach-Object {
                        [PSCustomObject]@{
                            Name        = $_.Name
                            VolumeLabel = $_.VolumeLabel
                            DriveType   = $_.DriveType
                            SizeGB      = [Math]::Round(($_.TotalSize / 1GB), 2)
                            FreeGB      = [Math]::Round(($_.AvailableFreeSpace / 1GB), 2)
                        }
                    }
                )
        } catch {
            Write-CustomLog "Error getting disk information: $($_)" -Level 'WARN'
        }

        if ($AsJson) {
            return $info | ConvertTo-Json -Depth 5
        } else {
            return $info
        }
    }
}

if ($MyInvocation.InvocationName -ne '.') {
    $result = Get-SystemInfo @PSBoundParameters
    Write-CustomLog "Completed $($MyInvocation.MyCommand.Name)"
    return $result
}

Write-CustomLog "Completed $($MyInvocation.MyCommand.Name)"
}
}
}

if ($MyInvocation.InvocationName -ne '.') {
    Get-SystemInfo @PSBoundParameters
    Write-CustomLog "Completed $($MyInvocation.MyCommand.Name)"
}
Write-CustomLog "Completed $($MyInvocation.MyCommand.Name)"
}
catch {
    Write-CustomLog "Error getting disk information: $($_)" -Level 'WARN'
}
}
Default {
    Write-CustomLog "Unsupported platform: $platform" -Level 'ERROR'
    throw "Unsupported platform: $platform"
}
}

if ($AsJson) {
    return $info | ConvertTo-Json -Depth 5
} else {
    return $info
}
}
}

if ($MyInvocation.InvocationName -ne '.') {
    Get-SystemInfo @PSBoundParameters
    Write-CustomLog "Completed $($MyInvocation.MyCommand.Name)"
}
Write-CustomLog "Completed $($MyInvocation.MyCommand.Name)"

