# test-param-issue.ps1
# Test script to reproduce the parameter ordering issue

Param(
    [object]$Config,
    [switch]$TestSwitch
)





Write-Host "Script executed successfully"
Write-Host "Config type: $($Config.GetType().Name)"
Write-Host "Config value: $Config"

if ($Config -is [string] -and (Test-Path $Config)) {
    Write-Host "Config is a file path, loading JSON..."
    $Config = Get-Content -Raw -Path $Config | ConvertFrom-Json
    Write-Host "Loaded config: $($Config | ConvertTo-Json -Depth 2)"
}
Import-Module (Join-Path $PSScriptRoot "pwsh/modules/CodeFixer/CodeFixer.psd1") -Force




