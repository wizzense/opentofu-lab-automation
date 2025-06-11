function Write-CustomLog {
    param(
        [string]$Message,
        [ValidateSet('INFO','WARN','ERROR')] [string]$Level = 'INFO'
    )
    $levelIdx = @{ INFO = 1; WARN = 0; ERROR = 0 }[$Level]

    if (-not (Get-Variable -Name LogFilePath -Scope Script -ErrorAction SilentlyContinue)) {
        $logDir = $env:LAB_LOG_DIR
        if (-not $logDir) { $logDir = if ($IsWindows) { 'C:\\temp' } else { [System.IO.Path]::GetTempPath() } }
        $script:LogFilePath = Join-Path $logDir 'lab.log'
    }

    if (-not (Get-Variable -Name ConsoleLevel -Scope Script -ErrorAction SilentlyContinue)) {
        if ($env:LAB_CONSOLE_LEVEL) {
            $script:ConsoleLevel = [int]$env:LAB_CONSOLE_LEVEL
        } else {
            $script:ConsoleLevel = 1
        }
    }

    $ts  = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $fmt = "[$ts] [$Level] $Message"
    $fmt | Out-File -FilePath $script:LogFilePath -Encoding utf8 -Append

    if ($levelIdx -le $script:ConsoleLevel) {
        $color = @{ INFO='Gray'; WARN='Yellow'; ERROR='Red' }[$Level]
        Write-Host $fmt -ForegroundColor $color
    }
}
