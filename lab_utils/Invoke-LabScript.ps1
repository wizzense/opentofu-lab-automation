function Invoke-LabScript {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [object]$Config,
        [Parameter(Mandatory=$true)]
        [scriptblock]$ScriptBlock
    )

    if (-not $Config) {
        throw 'Config object cannot be null'
    }
    if (-not (Get-Command Write-CustomLog -ErrorAction SilentlyContinue)) {
        . "$PSScriptRoot\..\runner_utility_scripts\Logger.ps1"
    }

    $prev = $ErrorActionPreference
    $ErrorActionPreference = 'Stop'
    try {
        Invoke-Command -ScriptBlock $ScriptBlock -NoNewScope
    } finally {
        $ErrorActionPreference = $prev
    }
}
