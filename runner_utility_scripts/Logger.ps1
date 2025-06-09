function Write-CustomLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [string]$Message,
        [Parameter(Position=1)]
        [string]$LogFile = $null
    )

    if (-not $PSBoundParameters.ContainsKey('LogFile')) {
        try {
            $LogFile = Get-Variable -Name LogFilePath -Scope Global -ValueOnly -ErrorAction Stop
        } catch {
            $LogFile = $null
        }
    }
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $formatted = "[$timestamp] $Message"
    Write-Host $formatted
    if ($LogFile) {
        try {
            $formatted | Out-File -FilePath $LogFile -Encoding utf8 -Append
        } catch {
            Write-Host "[ERROR] Failed to write to log file ${LogFile}: $_"
        }
    }
}
