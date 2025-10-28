#!/usr/bin/env pwsh
#Requires -Version 7.0

<#
.SYNOPSIS
    Validates the custom agent team configuration.

.DESCRIPTION
    This script tests the agent team configuration to ensure:
    - All agents can be loaded from config.psd1
    - Gender balance is maintained (50/50)
    - All agents have required properties
    - Module assignments are valid
    - Project structure is documented

.EXAMPLE
    pwsh -File ./tests/Test-AgentConfiguration.ps1
#>

[CmdletBinding()]
param()

# Import required modules
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptPath

Write-Host "===== Agent Team Configuration Validation =====" -ForegroundColor Cyan
Write-Host ""

# Test 1: Load configuration
Write-Host "[Test 1] Loading agent configuration..." -ForegroundColor Yellow
try {
    $AgentConfigPath = Join-Path -Path $ProjectRoot -ChildPath '.github/agents/config.psd1'
    $AgentConfig = Import-PowerShellDataFile -Path $AgentConfigPath
    Write-Host "  ✓ Configuration loaded successfully" -ForegroundColor Green
} catch {
    Write-Host "  ✗ Failed to load configuration: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Test 2: Validate required fields
Write-Host "[Test 2] Validating required configuration fields..." -ForegroundColor Yellow
$RequiredFields = @('TeamName', 'TeamVersion', 'Project', 'CoreModules', 'Agents', 'Standards')
$MissingFields = $RequiredFields | Where-Object { -not $AgentConfig.ContainsKey($_) }
if ($MissingFields.Count -eq 0) {
    Write-Host "  ✓ All required fields present" -ForegroundColor Green
} else {
    Write-Host "  ✗ Missing required fields: $($MissingFields -join ', ')" -ForegroundColor Red
    exit 1
}

# Test 3: Validate agent count
Write-Host "[Test 3] Validating agent team size..." -ForegroundColor Yellow
$AgentCount = $AgentConfig.Agents.Count
if ($AgentCount -eq 8) {
    Write-Host "  ✓ Team has 8 agents as expected" -ForegroundColor Green
} else {
    Write-Host "  ✗ Expected 8 agents, found $AgentCount" -ForegroundColor Red
    exit 1
}

# Test 4: Validate gender balance
Write-Host "[Test 4] Validating gender balance (50/50)..." -ForegroundColor Yellow
$FemaleAgents = $AgentConfig.Agents | Where-Object { $_.Gender -eq 'Female' }
$MaleAgents = $AgentConfig.Agents | Where-Object { $_.Gender -eq 'Male' }
if ($FemaleAgents.Count -eq 4 -and $MaleAgents.Count -eq 4) {
    Write-Host "  ✓ Gender balance: 4 Female, 4 Male (50/50)" -ForegroundColor Green
} else {
    Write-Host "  ✗ Gender imbalance: $($FemaleAgents.Count) Female, $($MaleAgents.Count) Male" -ForegroundColor Red
    exit 1
}

# Test 5: Validate agent properties
Write-Host "[Test 5] Validating agent properties..." -ForegroundColor Yellow
$RequiredProps = @('Name', 'DisplayName', 'Gender', 'Role', 'Specialization', 'Active')
$AllPropsValid = $true
foreach ($Agent in $AgentConfig.Agents) {
    $MissingProps = $RequiredProps | Where-Object { -not $Agent.ContainsKey($_) }
    if ($MissingProps.Count -gt 0) {
        Write-Host "  ✗ Agent $($Agent.DisplayName) missing properties: $($MissingProps -join ', ')" -ForegroundColor Red
        $AllPropsValid = $false
    }
}
if ($AllPropsValid) {
    Write-Host "  ✓ All agents have required properties" -ForegroundColor Green
} else {
    exit 1
}

# Test 6: List agents
Write-Host "[Test 6] Agent roster:" -ForegroundColor Yellow
$AgentConfig.Agents | ForEach-Object {
    $StatusIcon = if ($_.Active) { "✓" } else { "✗" }
    Write-Host "  $StatusIcon $($_.DisplayName) ($($_.Role)) - $($_.Gender)" -ForegroundColor Gray
}

# Test 7: Validate core modules
Write-Host "[Test 7] Validating core modules..." -ForegroundColor Yellow
$ModuleCount = $AgentConfig.CoreModules.Count
if ($ModuleCount -eq 9) {
    Write-Host "  ✓ All 9 core modules documented" -ForegroundColor Green
} else {
    Write-Host "  ⚠ Expected 9 modules, found $ModuleCount" -ForegroundColor Yellow
}

# Test 8: Check agent markdown files exist
Write-Host "[Test 8] Checking agent documentation files..." -ForegroundColor Yellow
$AgentsDir = Join-Path -Path $ProjectRoot -ChildPath '.github/agents'
$MissingDocs = @()

# Manual mapping for agent names to file names
$AgentFileMapping = @{
    'InfrastructureOrchestrator' = 'infrastructure-orchestrator.md'
    'PowerShellArchitect' = 'powershell-architect.md'
    'TestingGuardian' = 'testing-guardian.md'
    'DevOpsEngineer' = 'devops-engineer.md'
    'SecurityAnalyst' = 'security-analyst.md'
    'DocumentationSpecialist' = 'documentation-specialist.md'
    'PerformanceOptimizer' = 'performance-optimizer.md'
    'LabEnvironmentManager' = 'lab-environment-manager.md'
}

foreach ($Agent in $AgentConfig.Agents) {
    $AgentFileName = $AgentFileMapping[$Agent.Name]
    $AgentFilePath = Join-Path -Path $AgentsDir -ChildPath $AgentFileName
    
    if (-not (Test-Path -Path $AgentFilePath)) {
        $MissingDocs += $AgentFileName
    }
}

if ($MissingDocs.Count -eq 0) {
    Write-Host "  ✓ All agent documentation files exist" -ForegroundColor Green
} else {
    Write-Host "  ✗ Missing documentation files: $($MissingDocs -join ', ')" -ForegroundColor Red
    exit 1
}

# Test 9: Validate project configuration can be loaded
Write-Host "[Test 9] Validating project configuration references..." -ForegroundColor Yellow
try {
    $CoreConfigPath = Join-Path -Path $ProjectRoot -ChildPath $AgentConfig.ConfigurationFiles.CoreRunnerConfig
    $ProjectConfig = Get-Content -Path $CoreConfigPath -Raw | ConvertFrom-Json
    Write-Host "  ✓ Project configuration loads successfully" -ForegroundColor Green
} catch {
    Write-Host "  ✗ Failed to load project configuration: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Test 10: Summary
Write-Host ""
Write-Host "===== Validation Summary =====" -ForegroundColor Cyan
Write-Host "Team: $($AgentConfig.TeamName)" -ForegroundColor White
Write-Host "Version: $($AgentConfig.TeamVersion)" -ForegroundColor White
Write-Host "Agents: $($AgentConfig.Agents.Count) (4 Female, 4 Male)" -ForegroundColor White
Write-Host "Modules: $($AgentConfig.CoreModules.Count)" -ForegroundColor White
Write-Host ""
Write-Host "✓ All validation tests passed!" -ForegroundColor Green
Write-Host ""

exit 0
