# Test the actual function
$projectRoot = Split-Path $PSScriptRoot -Parent
while ($projectRoot -and -not (Test-Path (Join-Path $projectRoot "core-runner"))) {
    $projectRoot = Split-Path $projectRoot -Parent
}

Import-Module (Join-Path $projectRoot "core-runner/modules/Logging") -Force
Import-Module (Join-Path $projectRoot "core-runner/modules/PatchManager") -Force

$result = Test-PatchingRequirements -ProjectRoot $projectRoot

Write-Host "Result type: $($result.GetType().Name)"
Write-Host "ModulesAvailable: $($result.ModulesAvailable)"
Write-Host "ModulesAvailable type: $($result.ModulesAvailable.GetType().Name)"
Write-Host "ModulesAvailable count: $($result.ModulesAvailable.Count)"

Write-Host "ModulesMissing: $($result.ModulesMissing)"
Write-Host "ModulesMissing is null: $($null -eq $result.ModulesMissing)"
if ($result.ModulesMissing) {
    Write-Host "ModulesMissing type: $($result.ModulesMissing.GetType().Name)"
    Write-Host "ModulesMissing count: $($result.ModulesMissing.Count)"
} else {
    Write-Host "ModulesMissing is null or empty"
}

Write-Host "CommandsAvailable: $($result.CommandsAvailable)"
Write-Host "CommandsAvailable is null: $($null -eq $result.CommandsAvailable)"
if ($result.CommandsAvailable) {
    Write-Host "CommandsAvailable type: $($result.CommandsAvailable.GetType().Name)"
    Write-Host "CommandsAvailable count: $($result.CommandsAvailable.Count)"
} else {
    Write-Host "CommandsAvailable is null or empty"
}

Write-Host "CommandsMissing: $($result.CommandsMissing)"
Write-Host "CommandsMissing is null: $($null -eq $result.CommandsMissing)"
if ($result.CommandsMissing) {
    Write-Host "CommandsMissing type: $($result.CommandsMissing.GetType().Name)"
    Write-Host "CommandsMissing count: $($result.CommandsMissing.Count)"
} else {
    Write-Host "CommandsMissing is null or empty"
}
