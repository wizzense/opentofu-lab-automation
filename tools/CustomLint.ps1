[CmdletBinding()]
param(
    [string]$Target = '.',
    [string]$SettingsPath = (Join-Path $PSScriptRoot '..' '..' 'pwsh' 'PSScriptAnalyzerSettings.psd1')
)

# Simple PSScriptAnalyzer import
Import-Module PSScriptAnalyzer -Force

$ErrorActionPreference = 'Stop'


if (-not (Test-Path $SettingsPath)) {
    throw "Settings file not found: $SettingsPath"
}

# Load analyzer settings from the specified file
$settings = Import-PowerShellDataFile -Path $SettingsPath
$include = $settings.Rules.IncludeRules
$exclude = $settings.Rules.ExcludeRules

# Discover all PowerShell files to analyze
$files = Get-ChildItem -Path $Target -Recurse -Include *.ps1,*.psm1,*.psd1 -File |
    Select-Object -ExpandProperty FullName

# Run Script Analyzer against the collected files
$results = $files | Invoke-ScriptAnalyzer -Severity Error,Warning -IncludeRule $include -ExcludeRule $exclude
# Use Write-Output so callers can capture or redirect the formatted results
$results | Format-Table | Out-String | Write-Output

$failed = $false
if ($results | Where-Object Severity -eq 'Error') {
    Write-Error 'ScriptAnalyzer errors detected' -ErrorAction Continue
    $failed = $true
}

# Enforce ParameterFilter on Invoke-WebRequest mocks
$mockIssues = @()
foreach ($file in $files) {
    $ast = [System.Management.Automation.Language.Parser]::ParseFile($file, [ref]$null, [ref]$null)
    $calls = $ast.FindAll({ param($n) 
        $n -is [System.Management.Automation.Language.CommandAst] -and $n.GetCommandName() -eq 'Mock' }, $true)
    foreach ($c in $calls) {
        $first = $c.CommandElements[1]
        if ($first -and $first.Extent.Text -match 'Invoke-WebRequest') {
            $hasFilter = $c.CommandElements | Where-Object { $_ -is [System.Management.Automation.Language.CommandParameterAst] -and $_.ParameterName -eq 'ParameterFilter' }
            if (-not $hasFilter) {
                $mockIssues += "${file}:$($c.Extent.StartLineNumber) Mock Invoke-WebRequest missing -ParameterFilter"
            }
        }
    }
}
if ($mockIssues) {
    $mockIssues | ForEach-Object { Write-Warning $_ }
    Write-Error 'Mock lint errors detected' -ErrorAction Continue
    $failed = $true
}

if ($failed) {
    $global:LASTEXITCODE = 1
    return
}
$global:LASTEXITCODE = 0


