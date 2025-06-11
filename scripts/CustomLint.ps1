[CmdletBinding()]
param(
    [string]$Target = '.',
    [string]$SettingsPath = (Join-Path $PSScriptRoot '..' 'PSScriptAnalyzerSettings.psd1')
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path $SettingsPath)) {
    throw "Settings file not found: $SettingsPath"
}

$results = Get-ChildItem -Path $Target -Recurse -Include *.ps1,*.psm1,*.psd1 -File |
    Select-Object -ExpandProperty FullName |
    Invoke-ScriptAnalyzer -Severity Error,Warning -Settings $SettingsPath
$results | Format-Table

if ($results | Where-Object Severity -eq 'Error') {
    Write-Error 'ScriptAnalyzer errors detected'
    exit 1
}
