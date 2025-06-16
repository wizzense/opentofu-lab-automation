# Deploy-CodeFixerModule.ps1
# Master script for deploying and integrating the CodeFixer module
CmdletBinding()
param(
    switch$Force,
    switch$SkipBackup,
    switch$SkipWorkflowUpdate,
    switch$SkipCleanup,
    switch$WhatIf
)








$ErrorActionPreference = 'Stop'

Write-Host "CodeFixer Module - Deployment and Integration" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

# Step 1: Validate that the CodeFixer module exists
$modulePath = Join-Path $PSScriptRoot ".." "pwsh" "modules" "CodeFixer" "CodeFixer.psd1"
if (-not (Test-Path $modulePath)) {
    Write-Host "ERROR: CodeFixer module not found at $modulePath" -ForegroundColor Red
    Write-Host "Please make sure you have created the module before running this script." -ForegroundColor Red
    exit 1
}

Write-Host " CodeFixer module found at $modulePath" -ForegroundColor Green

# Function to run a script with parameters
function Invoke-DeploymentScript {
    param(
        string$ScriptName,
        string$Description,
        hashtable$Parameters
    )

    






$scriptPath = Join-Path $PSScriptRoot $ScriptName
    
    if (-not (Test-Path $scriptPath)) {
        Write-Host "ERROR: Script $scriptPath not found" -ForegroundColor Red
        return $false
    }
    
    Write-Host "`n>> Running: $Description" -ForegroundColor Cyan
    
    try {
        if ($WhatIf) {
            Write-Host "What If: Would execute $ScriptName with parameters:" -ForegroundColor Yellow
            $Parameters.GetEnumerator()  ForEach-Object {
                Write-Host "  -$($_.Key) $($_.Value)" -ForegroundColor Yellow
            }
            return $true
        }
        
        & $scriptPath @Parameters
        
        if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) {
            Write-Host "Script $ScriptName failed with exit code $LASTEXITCODE" -ForegroundColor Red
            return $false
        }
        
        return $true
    }
    catch {
        Write-Host "ERROR running $ScriptName : $_" -ForegroundColor Red
        return $false
    }
}

# Step 2: Run the integration script
$integrationParams = @{
    Force = $Force
    SkipBackup = $SkipBackup
}

if (-not $SkipWorkflowUpdate) {
    $integrationParams.UpdateWorkflows = $true
}

$integrationSuccess = Invoke-DeploymentScript -ScriptName "Install-CodeFixerIntegration.ps1" -Description "Integrating CodeFixer module with runner scripts" -Parameters $integrationParams

if (-not $integrationSuccess) {
    Write-Host "Integration failed. Stopping deployment." -ForegroundColor Red
    exit 1
}

# Step 3: Update workflow files if not skipped
if (-not $SkipWorkflowUpdate) {
    $workflowParams = @{
        Force = $Force
        SkipBackup = $SkipBackup
    }
    
    $workflowSuccess = Invoke-DeploymentScript -ScriptName "Update-Workflows.ps1" -Description "Updating GitHub Actions workflows" -Parameters $workflowParams
    
    if (-not $workflowSuccess) {
        Write-Host "Workflow update failed. Continuing with other steps..." -ForegroundColor Yellow
    }
}
else {
    Write-Host "`n>> Skipping workflow update as requested" -ForegroundColor Yellow
}

# Step 4: Clean up deprecated files if not skipped
if (-not $SkipCleanup) {
    $cleanupParams = @{
        Force = $Force
        SkipBackup = $SkipBackup
        WhatIf = $WhatIf
    }
    
    $cleanupSuccess = Invoke-DeploymentScript -ScriptName "Cleanup-DeprecatedFiles.ps1" -Description "Cleaning up deprecated files" -Parameters $cleanupParams
    
    if (-not $cleanupSuccess) {
        Write-Host "Cleanup failed. Continuing with final steps..." -ForegroundColor Yellow
    }
}
else {
    Write-Host "`n>> Skipping cleanup as requested" -ForegroundColor Yellow
}

# Step 5: Run a test validation if not in WhatIf mode
if (-not $WhatIf) {
    Write-Host "`n>> Running a test validation to ensure everything is working properly" -ForegroundColor Cyan
    
    try {
        $validationScript = Join-Path $PSScriptRoot ".." "invoke-comprehensive-validation.ps1"
        if (Test-Path $validationScript) {
            Write-Host "Importing CodeFixer module for validation..." -ForegroundColor Gray
            Import-Module $modulePath -Force -ErrorAction Stop
            
            Write-Host "Running validation script..." -ForegroundColor Gray
            & $validationScript
            
            if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) {
                Write-Host "WARNING: Validation test returned exit code $LASTEXITCODE. There may be issues that need fixing." -ForegroundColor Yellow
            }
            else {
                Write-Host " Validation test completed successfully" -ForegroundColor Green
            }
        }
        else {
            Write-Host "Validation script not found at $validationScript. Skipping test validation." -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "WARNING: Validation test failed: $_" -ForegroundColor Yellow
        Write-Host "You may need to fix some issues manually." -ForegroundColor Yellow
    }
}

# Final summary
Write-Host "`n================================================" -ForegroundColor Cyan
Write-Host "CodeFixer Module Deployment Summary" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

if ($WhatIf) {
    Write-Host "This was a dry run (WhatIf mode). No actual changes were made." -ForegroundColor Yellow
    Write-Host "Run without -WhatIf parameter to apply the changes." -ForegroundColor Yellow
}
else {
    Write-Host " CodeFixer module has been deployed and integrated" -ForegroundColor Green
    Write-Host "`nThe following components have been deployed:" -ForegroundColor White
    Write-Host "- CodeFixer PowerShell module" -ForegroundColor White
    Write-Host "- Integration with runner scripts" -ForegroundColor White
    
    if (-not $SkipWorkflowUpdate) {
        Write-Host "- GitHub Actions workflow updates" -ForegroundColor White
    }
    
    if (-not $SkipCleanup) {
        Write-Host "- Cleanup of deprecated files" -ForegroundColor White
    }
    
    Write-Host "`nAvailable commands:" -ForegroundColor White
    Write-Host "- ./invoke-comprehensive-validation.ps1" -ForegroundColor White
    Write-Host "- ./auto-fix.ps1" -ForegroundColor White
    Write-Host "- ./comprehensive-lint.ps1" -ForegroundColor White
    Write-Host "- ./comprehensive-health-check.ps1" -ForegroundColor White
    
    Write-Host "`nDocumentation:" -ForegroundColor White
    Write-Host "- docs/TESTING.md" -ForegroundColor White
    Write-Host "- docs/CODEFIXER-GUIDE.md" -ForegroundColor White
}

Write-Host "`nThank you for using the CodeFixer module!" -ForegroundColor Cyan



