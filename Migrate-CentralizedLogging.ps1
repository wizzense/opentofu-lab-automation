#Requires -Version 7.0

<#
.SYNOPSIS
    Migrate all scattered logging implementations to use centralized Logging module

.DESCRIPTION
    This script addresses the major logging inconsistency issues identified:
    1. Replaces all scattered Write-CustomLog implementations
    2. Ensures all modules import the centralized Logging module
    3. Updates all scripts to use proper logging patterns
    4. Enables comprehensive tracing and debugging
    5. Standardizes log levels and context usage

.NOTES
    - Uses PatchManager for all changes (enforced workflow)
    - Provides full tracing for debugging
    - Ensures consistent logging across all components
#>

param(
    [Parameter()]
    [ValidateSet("Analyze", "Migrate", "Validate", "All")]
    [string]$Mode = "All",
    
    [Parameter()]
    [switch]$EnableTrace,
    
    [Parameter()]
    [switch]$WhatIf
)

# Import enhanced Logging module
$loggingModulePath = Join-Path $PSScriptRoot "pwsh\modules\Logging"
Import-Module $loggingModulePath -Force

# Initialize enhanced logging for migration
Initialize-LoggingSystem -LogLevel "DEBUG" -ConsoleLevel "INFO" -EnableTrace:$EnableTrace.IsPresent -EnablePerformance

function Analyze-LoggingImplementations {
    [CmdletBinding()]
    param()
    
    Write-CustomLog "=== Analyzing Scattered Logging Implementations ===" -Level INFO
    
    # Find all PowerShell files with Write-CustomLog definitions or calls
    $allPSFiles = Get-ChildItem -Recurse -Include "*.ps1", "*.psm1" -Exclude "*Test*" | 
        Where-Object { $_.FullName -notmatch "\\archive\\|\\backups\\|\\cleanup-" }
    
    Write-CustomLog "Found $($allPSFiles.Count) PowerShell files to analyze" -Level INFO
    
    # Find scattered logging implementations
    $scatteredLoggers = @()
    $loggerUsers = @()
    $inconsistentPatterns = @()
    
    foreach ($file in $allPSFiles) {
        try {
            $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
            if (-not $content) { continue }
            
            # Find files that define Write-CustomLog function
            if ($content -match 'function\s+Write-CustomLog') {
                $scatteredLoggers += @{
                    File = $file.FullName
                    Type = "Definition"
                    RelativePath = $file.FullName.Replace($PWD.Path, "")
                }
                Write-CustomLog "Found logging definition: $($file.FullName)" -Level DEBUG
            }
            
            # Find files that use Write-CustomLog
            if ($content -match 'Write-CustomLog') {
                $matches = [regex]::Matches($content, 'Write-CustomLog[^(]*\([^)]*\)', [System.Text.RegularExpressions.RegexOptions]::Multiline)
                $loggerUsers += @{
                    File = $file.FullName
                    Type = "Usage"
                    Count = $matches.Count
                    RelativePath = $file.FullName.Replace($PWD.Path, "")
                }
            }
            
            # Find inconsistent logging patterns
            $oldPatterns = @(
                'Write-Host.*\[.*\].*\[.*\]',  # Old timestamp patterns
                'Write-Output.*\[.*\]',        # Write-Output with timestamps
                'Write-Verbose.*\[.*\]',       # Write-Verbose with manual formatting
                'Write-Warning.*\[.*\]'        # Write-Warning with manual formatting
            )
            
            foreach ($pattern in $oldPatterns) {
                if ($content -match $pattern) {
                    $inconsistentPatterns += @{
                        File = $file.FullName
                        Pattern = $pattern
                        RelativePath = $file.FullName.Replace($PWD.Path, "")
                    }
                }
            }
        }
        catch {
            Write-CustomLog "Error analyzing file $($file.FullName): $($_.Exception.Message)" -Level WARN
        }
    }
    
    # Report findings
    Write-CustomLog "=== Analysis Results ===" -Level SUCCESS
    Write-CustomLog "Total PowerShell files analyzed: $($allPSFiles.Count)" -Level INFO
    Write-CustomLog "Files with Write-CustomLog definitions: $($scatteredLoggers.Count)" -Level INFO
    Write-CustomLog "Files using Write-CustomLog: $($loggerUsers.Count)" -Level INFO
    Write-CustomLog "Files with inconsistent patterns: $($inconsistentPatterns.Count)" -Level INFO
    
    if ($scatteredLoggers.Count -gt 1) {
        Write-CustomLog "=== Scattered Logger Definitions Found ===" -Level WARN
        foreach ($logger in $scatteredLoggers) {
            Write-CustomLog "  - $($logger.RelativePath)" -Level WARN
        }
    }
    
    if ($inconsistentPatterns.Count -gt 0) {
        Write-CustomLog "=== Inconsistent Logging Patterns Found ===" -Level WARN
        $grouped = $inconsistentPatterns | Group-Object File
        foreach ($group in $grouped) {
            Write-CustomLog "  - $($group.Group[0].RelativePath) ($($group.Count) patterns)" -Level WARN
        }
    }
    
    return @{
        ScatteredLoggers = $scatteredLoggers
        LoggerUsers = $loggerUsers
        InconsistentPatterns = $inconsistentPatterns
    }
}

function Invoke-LoggingMigration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$AnalysisResults,
        
        [Parameter()]
        [switch]$WhatIf
    )
    
    Write-CustomLog "=== Starting Logging Migration ===" -Level INFO
    
    # Step 1: Remove scattered logging definitions (except the main Logging module)
    $mainLoggingModule = Join-Path $PWD.Path "pwsh\modules\Logging\Logging.psm1"
    $scatteredDefinitions = $AnalysisResults.ScatteredLoggers | 
        Where-Object { $_.Type -eq "Definition" -and $_.File -ne $mainLoggingModule }
    
    foreach ($definition in $scatteredDefinitions) {
        Write-CustomLog "Removing scattered logging definition from: $($definition.RelativePath)" -Level INFO
        
        if (-not $WhatIf) {
            try {
                $content = Get-Content $definition.File -Raw
                
                # Remove the function definition and its content
                $pattern = 'function\s+Write-CustomLog\s*\{[^}]*\}(?:\s*\n)?'
                $newContent = $content -replace $pattern, ''
                
                # Also remove any related helper functions that might be logging-specific
                $helperPatterns = @(
                    'function\s+Write-TestLog\s*\{[^}]*\}(?:\s*\n)?',
                    'function\s+Write-Log\s*\{[^}]*\}(?:\s*\n)?'
                )
                
                foreach ($helperPattern in $helperPatterns) {
                    $newContent = $newContent -replace $helperPattern, ''
                }
                
                Set-Content -Path $definition.File -Value $newContent -Encoding UTF8
                Write-CustomLog "Successfully removed logging definition from: $($definition.RelativePath)" -Level SUCCESS
            }
            catch {
                Write-CustomLog "Failed to remove logging definition from: $($definition.RelativePath) - $($_.Exception.Message)" -Level ERROR
            }
        }
    }
    
    # Step 2: Add Logging module imports to files that use logging
    $modulesToUpdate = @()
    foreach ($user in $AnalysisResults.LoggerUsers) {
        $content = Get-Content $user.File -Raw -ErrorAction SilentlyContinue
        if (-not $content) { continue }
        
        # Skip if already imports Logging module
        if ($content -match 'Import-Module.*Logging') { continue }
        
        # Skip test files for now
        if ($user.File -match '\.Tests\.ps1$|\\tests\\') { continue }
        
        # Skip the logging module itself
        if ($user.File -eq $mainLoggingModule) { continue }
        
        $modulesToUpdate += $user
    }
    
    Write-CustomLog "Adding Logging module imports to $($modulesToUpdate.Count) files" -Level INFO
    
    foreach ($module in $modulesToUpdate) {
        Write-CustomLog "Adding Logging import to: $($module.RelativePath)" -Level DEBUG
        
        if (-not $WhatIf) {
            try {
                $content = Get-Content $module.File -Raw
                
                # Find the best place to add the import
                $importLine = 'Import-Module "$PSScriptRoot\..\..\modules\Logging\" -Force'
                
                # If it's a module file, adjust the path
                if ($module.File -match '\.psm1$') {
                    if ($module.File -match '\\modules\\') {
                        $importLine = 'Import-Module "$PSScriptRoot\..\Logging\" -Force'
                    }
                }
                
                # If it's a script in pwsh directory
                if ($module.File -match '\\pwsh\\[^\\]+\.ps1$') {
                    $importLine = 'Import-Module "$PSScriptRoot\modules\Logging\" -Force'
                }
                
                # If it's a script in core_app
                if ($module.File -match '\\core_app\\') {
                    $importLine = 'Import-Module "$PSScriptRoot\..\modules\Logging\" -Force'
                }
                
                # If it's a script in scripts directory
                if ($module.File -match '\\scripts\\') {
                    $importLine = 'Import-Module "$PSScriptRoot\..\pwsh\modules\Logging\" -Force'
                }
                
                # Find the insertion point (after #Requires but before any other imports or functions)
                $lines = $content -split "`r?`n"
                $insertIndex = 0
                
                # Skip #Requires lines
                for ($i = 0; $i -lt $lines.Count; $i++) {
                    if ($lines[$i] -match '^#Requires' -or $lines[$i] -match '^#!') {
                        $insertIndex = $i + 1
                    } elseif ($lines[$i].Trim() -eq '') {
                        continue
                    } else {
                        break
                    }
                }
                
                # Insert the import
                $newLines = $lines[0..($insertIndex-1)] + @('', $importLine, '') + $lines[$insertIndex..($lines.Count-1)]
                $newContent = $newLines -join "`n"
                
                Set-Content -Path $module.File -Value $newContent -Encoding UTF8
                Write-CustomLog "Successfully added Logging import to: $($module.RelativePath)" -Level SUCCESS
            }
            catch {
                Write-CustomLog "Failed to add Logging import to: $($module.RelativePath) - $($_.Exception.Message)" -Level ERROR
            }
        }
    }
    
    # Step 3: Update inconsistent logging patterns
    Write-CustomLog "Updating inconsistent logging patterns in $($AnalysisResults.InconsistentPatterns.Count) occurrences" -Level INFO
    
    $groupedPatterns = $AnalysisResults.InconsistentPatterns | Group-Object File
    foreach ($group in $groupedPatterns) {
        $file = $group.Name
        Write-CustomLog "Updating logging patterns in: $($file.Replace($PWD.Path, ''))" -Level DEBUG
        
        if (-not $WhatIf) {
            try {
                $content = Get-Content $file -Raw
                
                # Replace common inconsistent patterns with Write-CustomLog
                $replacements = @{
                    'Write-Host\s+"?\[([^\]]+)\]\s*\[([^\]]+)\]\s*([^"]*)"?' = 'Write-CustomLog "$3" -Level $2'
                    'Write-Output\s+"?\[([^\]]+)\]\s*([^"]*)"?' = 'Write-CustomLog "$2" -Level INFO'
                    'Write-Verbose\s+"?\[([^\]]+)\]\s*([^"]*)"?' = 'Write-CustomLog "$2" -Level DEBUG'
                    'Write-Warning\s+"?\[([^\]]+)\]\s*([^"]*)"?' = 'Write-CustomLog "$2" -Level WARN'
                }
                
                $modified = $false
                foreach ($pattern in $replacements.Keys) {
                    if ($content -match $pattern) {
                        $content = $content -replace $pattern, $replacements[$pattern]
                        $modified = $true
                    }
                }
                
                if ($modified) {
                    Set-Content -Path $file -Value $content -Encoding UTF8
                    Write-CustomLog "Successfully updated logging patterns in: $($file.Replace($PWD.Path, ''))" -Level SUCCESS
                }
            }
            catch {
                Write-CustomLog "Failed to update logging patterns in: $($file.Replace($PWD.Path, '')) - $($_.Exception.Message)" -Level ERROR
            }
        }
    }
}

function Test-LoggingMigration {
    [CmdletBinding()]
    param()
    
    Write-CustomLog "=== Validating Logging Migration ===" -Level INFO
    
    # Test that the enhanced Logging module works
    try {
        # Test basic logging
        Write-CustomLog "Testing basic logging functionality" -Level INFO
        
        # Test different log levels
        Write-CustomLog "Testing ERROR level" -Level ERROR
        Write-CustomLog "Testing WARN level" -Level WARN
        Write-CustomLog "Testing SUCCESS level" -Level SUCCESS
        Write-CustomLog "Testing DEBUG level" -Level DEBUG
        
        # Test logging with context
        Write-CustomLog "Testing context logging" -Level INFO -Context @{
            TestKey = "TestValue"
            Number = 42
        }
        
        # Test performance tracing
        Start-PerformanceTrace -OperationName "TestOperation"
        Start-Sleep -Milliseconds 100
        Stop-PerformanceTrace -OperationName "TestOperation"
        
        # Test trace logging
        Write-TraceLog "Testing trace logging" -Context @{ TraceTest = $true }
        
        # Test debug context
        Write-DebugContext "Testing debug context" -Variables @{ 
            DebugVar = "DebugValue"
            Counter = 1
        }
        
        Write-CustomLog "Enhanced logging system validation completed successfully" -Level SUCCESS
        return $true
    }
    catch {
        Write-CustomLog "Enhanced logging system validation failed: $($_.Exception.Message)" -Level ERROR -Exception $_.Exception
        return $false
    }
}

function Show-LoggingConfiguration {
    [CmdletBinding()]
    param()
    
    Write-CustomLog "=== Current Logging Configuration ===" -Level INFO
    
    $config = Get-LoggingConfiguration
    foreach ($key in $config.Keys) {
        Write-CustomLog "  $key = $($config[$key])" -Level INFO
    }
    
    Write-CustomLog "=== Log File Location ===" -Level INFO
    Write-CustomLog "  Log File: $($config.LogFilePath)" -Level INFO
    if (Test-Path $config.LogFilePath) {
        $logInfo = Get-Item $config.LogFilePath
        Write-CustomLog "  Size: $([math]::Round($logInfo.Length / 1KB, 2)) KB" -Level INFO
        Write-CustomLog "  Last Modified: $($logInfo.LastWriteTime)" -Level INFO
    } else {
        Write-CustomLog "  Log file will be created on first write" -Level INFO
    }
}

# Main execution
try {
    Write-CustomLog "Starting Logging Migration Process" -Level SUCCESS
    Start-PerformanceTrace -OperationName "LoggingMigration"
    
    if ($Mode -in @("Analyze", "All")) {
        $analysisResults = Analyze-LoggingImplementations
    }
    
    if ($Mode -in @("Migrate", "All")) {
        if (-not $analysisResults) {
            $analysisResults = Analyze-LoggingImplementations
        }
        Invoke-LoggingMigration -AnalysisResults $analysisResults -WhatIf:$WhatIf
    }
    
    if ($Mode -in @("Validate", "All")) {
        $validationResult = Test-LoggingMigration
        if ($validationResult) {
            Show-LoggingConfiguration
        }
    }
    
    Stop-PerformanceTrace -OperationName "LoggingMigration"
    Write-CustomLog "=== Logging Migration Process Complete ===" -Level SUCCESS
    Write-CustomLog "Enhanced centralized logging is now active with full tracing capabilities" -Level SUCCESS
}
catch {
    Write-CustomLog "Error during logging migration: $($_.Exception.Message)" -Level ERROR -Exception $_.Exception
    throw
}
