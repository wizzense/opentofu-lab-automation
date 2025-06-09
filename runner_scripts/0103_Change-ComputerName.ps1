Param(
    [Parameter(Mandatory=$true)]
    [PSCustomObject]$Config
)
. "$PSScriptRoot\..\runner_utility_scripts\Logger.ps1"

if ($config.SetComputerName -eq $true) {

    try {
        $CurrentName = (Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction Stop).Name
    } catch {
        Write-CustomLog "Error retrieving current computer name: $_"
        exit 1
    }

    if ($null -ne $Config.ComputerName -and $Config.ComputerName -match "^\S+$") {
        if ($CurrentName -ne $Config.ComputerName) {
            Write-CustomLog "Changing Computer Name from $CurrentName to $($Config.ComputerName)..."
            try {
                Rename-Computer -NewName $Config.ComputerName -Force -ErrorAction Stop
                Write-CustomLog "Computer name changed successfully. A reboot is usually required."
                # Uncomment to reboot automatically
                # Restart-Computer -Force
            } catch {
                Write-CustomLog "Failed to change computer name: $_"
            }
        } else {
            Write-CustomLog "Computer name is already set to $($Config.ComputerName). Skipping rename."
        }
    } else {
    Write-CustomLog "No valid ComputerName specified in config. Skipping rename."
    }
} else {
    Write-CustomLog "SetComputerName flag is disabled. Skipping computer name change."
}
