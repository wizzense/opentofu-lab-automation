Import-Module "////pwsh/modules/CodeFixerLogging/" -Force

if (-not (Get-Command "Write-CustomLog" -ErrorAction SilentlyContinue)) {
    function Write-CustomLog {
        param([string]$Message, [string]$Level = "INFO")
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $color = switch ($Level) {
            "ERROR" { "Red" }
            "WARN" { "Yellow" }
            "INFO" { "Green" }
            default { "White" }
        }
        Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
    }
}
