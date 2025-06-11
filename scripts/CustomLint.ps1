[CmdletBinding()]
param(
    [string]$Target = '.',
    [string]$SettingsPath = (Join-Path $PSScriptRoot '..' 'PSScriptAnalyzerSettings.psd1')
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path $SettingsPath)) {
    throw "Settings file not found: $SettingsPath"
}

$files = Get-ChildItem -Path $Target -Recurse -Include *.ps1,*.psm1,*.psd1 -File |
    Select-Object -ExpandProperty FullName

$results = $files | Invoke-ScriptAnalyzer -Severity Error,Warning -Settings $SettingsPath
# Use Write-Output so callers can capture or redirect the formatted results
$results | Format-Table | Out-String | Write-Output

if ($results | Where-Object Severity -eq 'Error') {
    Write-Error 'ScriptAnalyzer errors detected'
    exit 1
}
