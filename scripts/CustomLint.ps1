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
        Where-Object { $_.FullName -ne (Resolve-Path $SettingsPath).Path }
    $results = $files |
        Select-Object -ExpandProperty FullName |
        Invoke-ScriptAnalyzer -Severity Error,Warning -Settings $SettingsPath
    $results | Format-Table
# Use Write-Output so callers can capture or redirect the formatted results
$results | Format-Table | Out-String | Write-Output

$failed = $false
if ($results | Where-Object Severity -eq 'Error') {
    Write-Error 'ScriptAnalyzer errors detected'
    $failed = $true
}

# Enforce ParameterFilter on Invoke-WebRequest mocks
$mockIssues = @()
foreach ($file in $files) {
    $ast = [System.Management.Automation.Language.Parser]::ParseFile($file, [ref]$null, [ref]$null)
    $calls = $ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.CommandAst] -and $n.GetCommandName() -eq 'Mock' }, $true)
    foreach ($c in $calls) {
        $first = $c.CommandElements[1]
        if ($first -and $first.Extent.Text -match 'Invoke-WebRequest') {
            $hasFilter = $c.CommandElements | Where-Object { $_ -is [System.Management.Automation.Language.CommandParameterAst] -and $_.ParameterName -eq 'ParameterFilter' }
            if (-not $hasFilter) {
                $mockIssues += "$file:$($c.Extent.StartLineNumber) Mock Invoke-WebRequest missing -ParameterFilter"
            }
        }
    }
}
if ($mockIssues) {
    $mockIssues | ForEach-Object { Write-Warning $_ }
    Write-Error 'Mock lint errors detected'
    $failed = $true
}

if ($failed) { exit 1 }
