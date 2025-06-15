function Invoke-UnifiedMaintenance {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false)]
        [ValidateSet("Quick", "Full", "Test", "Track", "Report", "All")]
        [string]$Mode = "Quick",
        
        [Parameter(Mandatory=$false)]
        [switch]$AutoFix,
        
        [Parameter(Mandatory=$false)]
        [switch]$UpdateChangelog,
        
        [Parameter(Mandatory=$false)]
        [switch]$SkipTests,

        [Parameter(Mandatory=$false)]
        [string]$ProjectRoot = $PWD
    )
    
    # Ensure we're using absolute paths
    $ProjectRoot = (Resolve-Path $ProjectRoot).Path
    
    Write-Host "Starting Unified Maintenance in $Mode mode..." -ForegroundColor Cyan
    
    # Track start time for performance metrics
    $startTime = Get-Date
    
    # Step 1: Set up logging and import utilities
    $logFile = Join-Path $ProjectRoot "logs/maintenance_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
    $null = New-Item -Path (Split-Path $logFile -Parent) -ItemType Directory -Force -ErrorAction SilentlyContinue
    
    function Write-MaintenanceLog {
        param (
            [string]$Message,
            [ValidateSet("INFO", "SUCCESS", "WARNING", "ERROR", "DEBUG")]
            [string]$Level = "INFO"
        )
        
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $formattedMessage = "[$timestamp] [$Level] $Message"
        
        # Color coding based on level
        switch ($Level) {
            "INFO"    { Write-Host $formattedMessage -ForegroundColor Gray }
            "SUCCESS" { Write-Host $formattedMessage -ForegroundColor Green }
            "WARNING" { Write-Host $formattedMessage -ForegroundColor Yellow }
            "ERROR"   { Write-Host $formattedMessage -ForegroundColor Red }
            "DEBUG"   { Write-Host $formattedMessage -ForegroundColor DarkGray }
        }
        
        # Also log to file
        Add-Content -Path $logFile -Value $formattedMessage
    }
    
    # Step 2: Read project manifest
    if (Test-Path "$ProjectRoot/PROJECT-MANIFEST.json") {
        try {
            $manifest = Get-Content "$ProjectRoot/PROJECT-MANIFEST.json" -Raw | ConvertFrom-Json
            Write-MaintenanceLog "Project manifest loaded successfully - $($manifest.project.name) v$($manifest.project.version)" "INFO"
        }
        catch {
            Write-MaintenanceLog "Failed to load project manifest: $_" "ERROR"
            $manifest = $null
        }
    }
    else {
        Write-MaintenanceLog "Project manifest not found" "ERROR"
    }
    
    # Step 3: Clean up archive/broken files
    if ($Mode -in @("Full", "All")) {
        Write-MaintenanceLog "Starting archive cleanup..." "INFO"
        Invoke-ArchiveCleanup -ProjectRoot $ProjectRoot
    }
    
    # Step 4: Run infrastructure health check
    Write-MaintenanceLog "Running infrastructure health check..." "INFO"
    $healthCheck = Invoke-HealthCheck -ProjectRoot $ProjectRoot -Mode $Mode -AutoFix:$AutoFix
    
    # Step 5: YAML validation
    Write-MaintenanceLog "Validating YAML files..." "INFO"
    $yamlResult = Invoke-YamlValidation -Path "$ProjectRoot/.github/workflows" -Mode $(if ($AutoFix) { "Fix" } else { "Check" })
    
    # Step 6: Import path fixes and other infrastructure fixes
    if ($AutoFix) {
        Write-MaintenanceLog "Applying infrastructure fixes..." "INFO"
        Invoke-InfrastructureFix -ProjectRoot $ProjectRoot -AutoFix
    }
    
    # Step 7: Test execution (if in Test or All mode and not skipped)
    if (($Mode -in @("Test", "All")) -and -not $SkipTests) {
        Write-MaintenanceLog "Running tests..." "INFO"
        $testResults = Invoke-TestsSuite -ProjectRoot $ProjectRoot
    }
    
    # Step 8: Recurring issue tracking 
    if ($Mode -in @("Track", "All")) {
        Write-MaintenanceLog "Checking recurring issues..." "INFO"
        $issues = Invoke-RecurringIssueCheck -ProjectRoot $ProjectRoot
    }
    
    # Step 9: Generate report
    if ($Mode -in @("Report", "All")) {
        Write-MaintenanceLog "Generating maintenance report..." "INFO"
        $report = Show-MaintenanceReport -ProjectRoot $ProjectRoot -HealthCheck $healthCheck -YamlResult $yamlResult -TestResults $testResults -Issues $issues
    }
    
    # Step 10: Update changelog if requested
    if ($UpdateChangelog) {
        Write-MaintenanceLog "Updating changelog..." "INFO"
        Update-Changelog -ProjectRoot $ProjectRoot -HealthCheck $healthCheck -YamlResult $yamlResult -Issues $issues
    }
    
    # Output summary and performance metrics
    $endTime = Get-Date
    $duration = ($endTime - $startTime).TotalSeconds
    
    Write-MaintenanceLog "Maintenance completed in $duration seconds" "SUCCESS"
    
    # Return results
    return [PSCustomObject]@{
        Mode = $Mode
        AutoFix = $AutoFix
        Duration = $duration
        HealthCheck = $healthCheck
        YamlValidation = $yamlResult
        TestResults = $testResults
        Issues = $issues
    }
}
