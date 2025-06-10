function Write-CustomLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [string]$Message,
        [Parameter(Position=1)]
        [string]$LogFile = $null
    )

    if (-not $PSBoundParameters.ContainsKey('LogFile')) {
        $candidate = $null
        if (Get-Variable -Name LogFilePath -Scope Script -ErrorAction SilentlyContinue) {
            $candidate = Get-Variable -Name LogFilePath -Scope Script -ValueOnly
        } elseif (Get-Variable -Name LogFilePath -Scope Global -ErrorAction SilentlyContinue) {
            $candidate = Get-Variable -Name LogFilePath -Scope Global -ValueOnly
        }

        if (-not [string]::IsNullOrWhiteSpace($candidate)) {
            $LogFile = $candidate
        } else {
            $logDir = $env:LAB_LOG_DIR
            if (-not $logDir) {
                if ($IsWindows) { $logDir = 'C:\\temp' } else { $logDir = [System.IO.Path]::GetTempPath() }
            }
            $LogFile = Join-Path $logDir 'lab.log'
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
