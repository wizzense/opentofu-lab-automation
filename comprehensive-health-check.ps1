[CmdletBinding()]
param(
    [switch]$CI,
    [switch]$Detailed,
    [ValidateSet('JSON','Text')]
    [string]$OutputFormat = 'Text'
)

$ErrorActionPreference = 'Stop'

$checks = @(
    @{ Name = 'Runner Script'; Path = 'pwsh/runner.ps1' }
    @{ Name = 'Python Project'; Path = 'py/pyproject.toml' }
    @{ Name = 'CI Workflow'; Path = '.github/workflows/ci.yml' }
)

$results = @()
$healthy = 0
$warning = 0
$critical = 0

foreach ($check in $checks) {
    if (Test-Path $check.Path) {
        $fileInfo = Get-Item $check.Path
        if ($fileInfo.LastWriteTime -lt (Get-Date).AddDays(-180)) {
            $warning++
            $results += [pscustomobject]@{ Check = $check.Name; Status = 'Warning'; Reason = 'Stale file' }
        } else {
            $healthy++
            $results += [pscustomobject]@{ Check = $check.Name; Status = 'Healthy' }
        }
    } else {
        $critical++
        $results += [pscustomobject]@{ Check = $check.Name; Status = 'Critical' }
    }
}

$overall = if ($critical -gt 0) {
    'Critical'
} elseif ($warning -gt 0) {
    'Warning'
} else {
    'Healthy'
}

$report = [pscustomobject]@{
    OverallStatus = $overall
    Summary = [pscustomobject]@{
        Healthy  = $healthy
        Warning  = $warning
        Critical = $critical
    }
    Details = $results
}

if ($OutputFormat -eq 'JSON') {
    $report | ConvertTo-Json -Depth 10
} else {
    $report | Format-Table -AutoSize
}
