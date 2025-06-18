<#
.SYNOPSIS
Sets up the extensible testing framework for the OpenTofu Lab Automation project

.DESCRIPTION
This script initializes the testing framework by:
- Installing required PowerShell modules
- Generating tests for existing scripts
- Setting up file watchers
- Validating the framework setup

.EXAMPLE
./Setup-TestingFramework.ps1

.EXAMPLE
./Setup-TestingFramework.ps1 -RegenerateAll -SetupWatcher
#>

param(
 switch$RegenerateAll,
 switch$SetupWatcher,
 switch$ValidateOnly,
 string$WatchDirectory = "pwsh"
)

$ErrorActionPreference = 'Stop'

Write-Host "Setting up OpenTofu Lab Automation Testing Framework" -ForegroundColor Cyan
Write-Host "=" * 60

# Load helper functions
$helpersPath = Join-Path $PSScriptRoot 'helpers'
if (Test-Path (Join-Path $helpersPath 'TestHelpers.ps1')) {
 . (Join-Path $helpersPath 'TestHelpers.ps1')
 Write-Host "PASS Loaded test helpers" -ForegroundColor Green
} else {
 Write-Warning "Test helpers not found, some features may not work"
}

function Install-RequiredModules {
 Write-Host "`nInstalling required PowerShell modules..." -ForegroundColor Yellow
 
    $modules = @(
        @{ Name = 'Pester'; Version = '5.7.1'; Scope = 'CurrentUser' }
        @{ Name = 'powershell-yaml'; Scope = 'CurrentUser' }
        @{ Name = 'PSScriptAnalyzer'; Scope = 'CurrentUser' }
    )
 
 foreach ($module in $modules) {
 try {
 $installed = Get-Module -ListAvailable -Name $module.Name
 if ($module.Version) {
 $installed = installed | Where-Object{ $_.Version -ge version$module.Version }
 }
 
 if ($installed) {
 Write-Host " $($module.Name) already installed" -ForegroundColor Green
 } else {
 Write-Host " Installing $($module.Name)..." -ForegroundColor Cyan
 $installParams = @{
 Name = $module.Name
 Force = $true
 Scope = $module.Scope
 }
 if ($module.Version) {
 $installParams.RequiredVersion = $module.Version
 }
 Install-Module @installParams
 Write-Host " $($module.Name) installed successfully" -ForegroundColor Green
 }
 } catch {
 Write-Error "Failed to install $($module.Name): $_"
 }
 }
}

function Test-FrameworkComponents {
 Write-Host "`nValidating framework components..." -ForegroundColor Yellow
 
 $components = @(
 @{ 
 Name = 'Test Generator'
 Path = Join-Path $helpersPath 'New-AutoTestGenerator.ps1'
 Description = 'Automatic test generation script'
 }
 @{ 
 Name = 'Extensible Test Runner'
 Path = Join-Path $helpersPath 'Invoke-ExtensibleTests.ps1'
 Description = 'Enhanced test execution framework'
 }
 @{ 
 Name = 'Test Helpers'
 Path = Join-Path $helpersPath 'TestHelpers.ps1'
 Description = 'Common test utilities and functions'
 }
 @{ 
 Name = 'GitHub Actions Workflow'
 Path = Join-Path $PSScriptRoot '..' '.github' 'workflows' 'auto-test-generation.yml'
 Description = 'Automated test generation CI/CD'
 }
 )
 
 $allValid = $true
 foreach ($component in $components) {
 if (Test-Path $component.Path) {
 Write-Host " $($component.Name): Found" -ForegroundColor Green
 
 # Validate PowerShell syntax for .ps1 files
 if ($component.Path -like "*.ps1") {
 try {
 $content = Get-Content $component.Path -Raw
 $ast = System.Management.Automation.Language.Parser::ParseInput($content, ref$null, ref$errors)
 if ($errors.Count -gt 0) {
 Write-Host " Syntax warnings: $($errors.Count)" -ForegroundColor Yellow
 } else {
 Write-Host " Syntax validated" -ForegroundColor Green
 }
 } catch {
 Write-Host " Syntax validation failed: $_" -ForegroundColor Red
 $allValid = $false
 }
 }
 } else {
 Write-Host " $($component.Name): Missing ($($component.Path))" -ForegroundColor Red
 Write-Host " $($component.Description)" -ForegroundColor Gray
 $allValid = $false
 }
 }
 
 return $allValid
}

function Initialize-TestGeneration {
 Write-Host "`nGenerating tests for existing scripts..." -ForegroundColor Yellow
 

    $scriptDirs = @(
        (Join-Path $PSScriptRoot '..' 'core-runner' 'core_app' 'scripts'),
        (Join-Path $PSScriptRoot '..' 'core-runner' 'lab_utils'),
        (Join-Path $PSScriptRoot '..' 'core-runner')
    )


 $totalScripts = 0
 $generatedTests = 0
 
 foreach ($dir in $scriptDirs) {
 if (Test-Path $dir) {
 Write-Host " � Processing directory: $dir" -ForegroundColor Cyan
 
 $scripts = Get-ChildItem $dir -Filter "*.ps1" -Recurse | Where-Object{ -not $_.Name.EndsWith('.Tests.ps1') -and $_.Name -ne 'Setup-TestingFramework.ps1' }
 
 $totalScripts += $scripts.Count
 Write-Host " Found $($scripts.Count) scripts" -ForegroundColor Gray
 
 foreach ($script in $scripts) {
 $testName = $script.Name -replace '\.ps1$', '.Tests.ps1'
 $testPath = Join-Path $PSScriptRoot $testName
 
 if (-not (Test-Path $testPath) -or $RegenerateAll) {
 try {
 Write-Host " Generating test for: $($script.Name)" -ForegroundColor Gray
 & (Join-Path $helpersPath 'New-AutoTestGenerator.ps1') -ScriptPath $script.FullName -Force:$RegenerateAll
 $generatedTests++
 Write-Host " PASS Generated: $testName" -ForegroundColor Green
 } catch {
 Write-Host " FAIL Failed to generate test for $($script.Name): $_" -ForegroundColor Red
 }
 } else {
 Write-Host " ⏭ Test exists: $testName" -ForegroundColor Gray
 }
 }
 }
 }
 
 Write-Host "`n Test Generation Summary:" -ForegroundColor Cyan
 Write-Host " Total Scripts: $totalScripts"
 Write-Host " Tests Generated: $generatedTests" -ForegroundColor Green
 Write-Host " Tests Skipped: $($totalScripts - $generatedTests)" -ForegroundColor Yellow
}

function Start-FileWatcher {
 Write-Host "`n� Setting up file watcher..." -ForegroundColor Yellow
 
 $watchPath = Join-Path $PSScriptRoot '..' $WatchDirectory
 if (-not (Test-Path $watchPath)) {
 Write-Error "Watch directory not found: $watchPath"
 return
 }
 
 Write-Host " � Watching: $watchPath" -ForegroundColor Cyan
 Write-Host " Starting background watcher process..." -ForegroundColor Cyan
 
 $watcherScript = Join-Path $helpersPath 'New-AutoTestGenerator.ps1'
 $job = Start-Job -ScriptBlock {
 param($WatcherScript, $WatchPath)
 & $WatcherScript -WatchMode -WatchDirectory $WatchPath -WatchIntervalSeconds 30
 } -ArgumentList $watcherScript, $watchPath
 
 Write-Host " PASS File watcher started (Job ID: $($job.Id))" -ForegroundColor Green
 Write-Host " Use 'Get-Job  Remove-Job' to stop the watcher" -ForegroundColor Gray
 
 return $job
} $pesterConfig.Run.PassThru = $true
 $pesterConfig.Output.Verbosity = 'None'
 $pesterConfig.Run.Path = @() # Empty path to test config only
 
 $result = Invoke-Pester -Configuration $pesterConfig
 Write-Host " PASS Pester integration working" -ForegroundColor Green
 
 return $true
 } catch {
 Write-Host " FAIL Framework execution test failed: $_" -ForegroundColor Red
 return $false
 }
}

function Show-NextSteps {
 Write-Host "`n Next Steps:" -ForegroundColor Cyan
 Write-Host "=" * 40
 
 Write-Host "`n1. Run tests locally:" -ForegroundColor Yellow
 Write-Host " ./tests/helpers/Invoke-ExtensibleTests.ps1" -ForegroundColor Gray
 
 Write-Host "`n2. Generate test for new script:" -ForegroundColor Yellow
 Write-Host " ./tests/helpers/New-AutoTestGenerator.ps1 -ScriptPath 'path/to/script.ps1'" -ForegroundColor Gray
 
 Write-Host "`n3. Start file watcher:" -ForegroundColor Yellow
 Write-Host " ./tests/helpers/New-AutoTestGenerator.ps1 -WatchMode" -ForegroundColor Gray
 
 Write-Host "`n4. View framework documentation:" -ForegroundColor Yellow
 Write-Host " docs/testing-framework.md" -ForegroundColor Gray
 
 Write-Host "`n5. GitHub Actions will automatically:" -ForegroundColor Yellow
 Write-Host " - Generate tests for new/modified scripts" -ForegroundColor Gray
 Write-Host " - Fix naming conventions" -ForegroundColor Gray
 Write-Host " - Run tests across platforms" -ForegroundColor Gray
 
 Write-Host "`n Documentation: docs/testing-framework.md" -ForegroundColor Cyan
 Write-Host "� Issues: Report to the project repository" -ForegroundColor Cyan
}

# Main execution
try {
 if ($ValidateOnly) {
 Write-Host " Validation mode - checking framework components only" -ForegroundColor Yellow
 $isValid = Test-FrameworkComponents
 if ($isValid) {
 Write-Host "`nPASS Framework validation passed!" -ForegroundColor Green
 } else {
 Write-Host "`nFAIL Framework validation failed!" -ForegroundColor Red
 exit 1
 }
 exit 0
 }
 
 # Step 1: Install required modules
 Install-RequiredModules
 
 # Step 2: Validate framework components
 Write-Host "`n Validating framework components..." -ForegroundColor Yellow
 $isValid = Test-FrameworkComponents
 if (-not $isValid) {
 Write-Error "Framework validation failed. Please check missing components."
 }
 
 # Step 3: Generate tests for existing scripts
 if (-not $ValidateOnly) {
 Initialize-TestGeneration
 }
 
 # Step 4: Test framework execution
 Write-Host "`n Testing framework execution..." -ForegroundColor Yellow
 $executionWorks = Test-FrameworkExecution
 if (-not $executionWorks) {
 Write-Warning "Framework execution test failed, but setup will continue"
 }
 
 # Step 5: Setup file watcher if requested
 if ($SetupWatcher) {
 $watcherJob = Start-FileWatcher
 }
 
 # Success message
 Write-Host "`n Testing framework setup completed successfully!" -ForegroundColor Green
 Write-Host "=" * 60
 
 # Show next steps
 Show-NextSteps
 
 if ($SetupWatcher -and $watcherJob) {
 Write-Host "`n⏰ File watcher is running in background (Job ID: $($watcherJob.Id))" -ForegroundColor Yellow
 Write-Host " Press Ctrl+C to stop this script, watcher will continue running" -ForegroundColor Gray
 
 # Keep script running to monitor watcher
 Write-Host "`n� Monitoring file watcher (press Ctrl+C to exit)..." -ForegroundColor Cyan
 try {
 while ($true) {
 Start-Sleep 10
 $job = Get-Job -Id $watcherJob.Id -ErrorAction SilentlyContinue
 if (-not $job -or $job.State -eq 'Failed') {
 Write-Host "WARN File watcher stopped unexpectedly" -ForegroundColor Yellow
 break
 }
 }
 } catch {
 Write-Host "`n� Monitoring stopped" -ForegroundColor Yellow
 }
 }
 
} catch {
 Write-Host "`nFAIL Setup failed: $_" -ForegroundColor Red
 Write-Host "Check the error above and try again" -ForegroundColor Gray
 exit 1
}





