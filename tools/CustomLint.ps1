CmdletBinding()
param(
    string$Target = '.',
    string$SettingsPath = $null
)

# Simple PSScriptAnalyzer import
Import-Module PSScriptAnalyzer -Force

$ErrorActionPreference = 'Stop'

# Dynamically find the settings file if not provided
if (-not $SettingsPath) {
    $possiblePaths = @(
        (Join-Path $PSScriptRoot '..' '..' 'pwsh' 'PSScriptAnalyzerSettings.psd1'),
        (Join-Path $PSScriptRoot '..' 'pwsh' 'PSScriptAnalyzerSettings.psd1'),
        (Join-Path (Get-Location) 'pwsh' 'PSScriptAnalyzerSettings.psd1')
    )
    
    foreach ($path in $possiblePaths) {
        if (Test-Path $path) {
            $SettingsPath = $path
            break
        }
    }
}

if (-not $SettingsPath -or -not (Test-Path $SettingsPath)) {
    Write-Warning "Settings file not found, using default PSScriptAnalyzer rules"
    $SettingsPath = $null
}

# Load analyzer settings from the specified file
$include = $null
$exclude = $null

if ($SettingsPath) {
    $settings = Import-PowerShellDataFile -Path $SettingsPath
    $include = $settings.Rules.IncludeRules
    $exclude = $settings.Rules.ExcludeRules
}

# Discover all PowerShell files to analyze
$files = Get-ChildItem -Path $Target -Recurse -Include *.ps1,*.psm1,*.psd1 -File | Select-Object-ExpandProperty FullName

# Run Script Analyzer against the collected files
if ($include -and $exclude) {
    $results = $files  Invoke-ScriptAnalyzer -Severity Error,Warning -IncludeRule $include -ExcludeRule $exclude
} elseif ($include) {
    $results = $files  Invoke-ScriptAnalyzer -Severity Error,Warning -IncludeRule $include
} elseif ($exclude) {
    $results = $files  Invoke-ScriptAnalyzer -Severity Error,Warning -ExcludeRule $exclude
} else {
    $results = $files  Invoke-ScriptAnalyzer -Severity Error,Warning
}
# Use Write-Output so callers can capture or redirect the formatted results
$results  Format-Table  Out-String  Write-Output

$failed = $false
if (results | Where-ObjectSeverity -eq 'Error') {
    Write-Error 'ScriptAnalyzer errors detected' -ErrorAction Continue
    $failed = $true
}

# Enforce ParameterFilter on Invoke-WebRequest mocks
$mockIssues = @()
foreach ($file in $files) {
    $ast = System.Management.Automation.Language.Parser::ParseFile($file, ref$null, ref$null)
    $calls = $ast.FindAll({ param($n) 
        $n -is System.Management.Automation.Language.CommandAst -and $n.GetCommandName() -eq 'Mock' }, $true)
    foreach ($c in $calls) {
        $first = $c.CommandElements1
        if ($first -and $first.Extent.Text -match 'Invoke-WebRequest') {
            $hasFilter = $c.CommandElements | Where-Object{ $_ -is System.Management.Automation.Language.CommandParameterAst -and $_.ParameterName -eq 'ParameterFilter' }
            if (-not $hasFilter) {
                $mockIssues += "${file}:$($c.Extent.StartLineNumber) Mock Invoke-WebRequest missing -ParameterFilter"
            }
        }
    }
}
if ($mockIssues) {
    mockIssues | ForEach-Object{ Write-Warning $_ }
    Write-Error 'Mock lint errors detected' -ErrorAction Continue
    $failed = $true
}

if ($failed) {
    $global:LASTEXITCODE = 1
    return
}
$global:LASTEXITCODE = 0




