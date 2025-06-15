function Invoke-HealthCheck {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false)]
        [string]$ProjectRoot = $PWD,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet("Quick", "Full", "Deep")]
        [string]$Mode = "Quick",
        
        [Parameter(Mandatory=$false)]
        [switch]$AutoFix
    )
    
    # Normalize project root to absolute path
    $ProjectRoot = (Resolve-Path $ProjectRoot).Path
    
    # Function for centralized logging
    function Write-HealthLog {
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
    }
    
    Write-HealthLog "Starting health check in $Mode mode for $ProjectRoot..." "INFO"
    
    # Track results
    $results = @{
        ChecksPerformed = 0
        IssuesFound = 0
        FixesApplied = 0
        ImportPaths = 0
        TestSyntax = 0
        ModuleStructure = 0
        Errors = 0
        Details = @()
    }
    
    # Check 1: Project Manifest
    $results.ChecksPerformed++
    if (Test-Path "$ProjectRoot/PROJECT-MANIFEST.json") {
        try {
            $manifest = Get-Content "$ProjectRoot/PROJECT-MANIFEST.json" -Raw | ConvertFrom-Json
            Write-HealthLog "Project manifest loaded successfully" "SUCCESS"
        }
        catch {
            Write-HealthLog "Failed to load project manifest: $_" "ERROR"
            $results.IssuesFound++
            $results.Details += @{
                Check = "Project Manifest"
                Status = "Error"
                Details = "Could not parse PROJECT-MANIFEST.json: $($_.Exception.Message)"
                CanAutoFix = $false
            }
        }
    }
    else {
        Write-HealthLog "Project manifest not found" "ERROR"
        $results.IssuesFound++
        $results.Details += @{
            Check = "Project Manifest"
            Status = "Error"
            Details = "PROJECT-MANIFEST.json not found"
            CanAutoFix = $false
        }
    }
    
    # Check 2: Module Structure
    $results.ChecksPerformed++
    $modulesPath = Join-Path $ProjectRoot "pwsh/modules"
    if (Test-Path $modulesPath) {
        $modules = Get-ChildItem -Path $modulesPath -Directory -ErrorAction SilentlyContinue
        
        if ($modules.Count -eq 0) {
            Write-HealthLog "No modules found in $modulesPath" "WARNING"
            $results.IssuesFound++
            $results.Details += @{
                Check = "Module Structure"
                Status = "Warning"
                Details = "No modules found in pwsh/modules directory"
                CanAutoFix = $false
            }
        }
        else {
            $moduleIssues = @()
            
            foreach ($module in $modules) {
                $missingItems = @()
                
                if (-not (Test-Path (Join-Path $module.FullName "Public"))) {
                    $missingItems += "Public directory"
                }
                
                if (-not (Test-Path (Join-Path $module.FullName "Private"))) {
                    $missingItems += "Private directory"
                }
                
                $moduleFile = Join-Path $module.FullName "$($module.Name).psm1"
                if (-not (Test-Path $moduleFile)) {
                    $missingItems += "$($module.Name).psm1"
                }
                
                $manifestFile = Join-Path $module.FullName "$($module.Name).psd1"
                if (-not (Test-Path $manifestFile)) {
                    $missingItems += "$($module.Name).psd1"
                }
                
                if ($missingItems.Count -gt 0) {
                    $moduleIssues += @{
                        Module = $module.Name
                        MissingItems = $missingItems
                    }
                    
                    if ($AutoFix) {
                        Write-HealthLog "Attempting to fix module structure for $($module.Name)..." "INFO"
                        
                        foreach ($item in $missingItems) {
                            if ($item -in @("Public directory", "Private directory")) {
                                $dirName = $item -replace " directory", ""
                                $dirPath = Join-Path $module.FullName $dirName
                                try {
                                    $null = New-Item -Path $dirPath -ItemType Directory -Force -ErrorAction Stop
                                    Write-HealthLog "Created $dirName directory for module $($module.Name)" "SUCCESS"
                                    $results.ModuleStructure++
                                    $results.FixesApplied++
                                }
                                catch {
                                    Write-HealthLog "Failed to create directory $dirName for module $($module.Name): $($_.Exception.Message)" "ERROR"
                                    $results.Errors++
                                }
                            }
                            else {
                                # Create basic module files
                                $fileName = $item
                                $filePath = Join-Path $module.FullName $fileName
                                
                                try {
                                    if ($fileName -match "\.psm1$") {
                                        # Module file
                                        $moduleContent = @"
# $($module.Name) Module
# Part of OpenTofu Lab Automation

# Get public and private function definition files
`$Public = @(Get-ChildItem -Path `$PSScriptRoot\Public\*.ps1 -ErrorAction SilentlyContinue)
`$Private = @(Get-ChildItem -Path `$PSScriptRoot\Private\*.ps1 -ErrorAction SilentlyContinue)

# Dot source the files
foreach (`$import in @(`$Public + `$Private)) {
    try {
        . `$import.FullName
    } catch {
        Write-Error -Message "Failed to import function `$(`$import.FullName): `$_"
    }
}

# Export Public functions
Export-ModuleMember -Function `$Public.BaseName
"@
                                        Set-Content -Path $filePath -Value $moduleContent -NoNewline
                                    }
                                    elseif ($fileName -match "\.psd1$") {
                                        # Module manifest
                                        $manifestContent = @"
@{
    RootModule = '$($module.Name).psm1'
    ModuleVersion = '0.1.0'
    GUID = '$([Guid]::NewGuid().ToString())'
    Author = 'OpenTofu Lab Automation Team'
    CompanyName = 'OpenTofu'
    Copyright = '(c) $(Get-Date -Format "yyyy") OpenTofu. All rights reserved.'
    Description = '$($module.Name) module for OpenTofu Lab Automation'
    PowerShellVersion = '5.1'
    FunctionsToExport = @()*
    CmdletsToExport = @()
    VariablesToExport = '*'
    AliasesToExport = @()
    PrivateData = @{
        PSData = @{
            Tags = @('OpenTofu', 'Lab', 'Automation')
            ProjectUri = 'https://github.com/yourusername/opentofu-lab-automation'
        }
    }
}
"@
                                        Set-Content -Path $filePath -Value $manifestContent -NoNewline
                                    }
                                    
                                    Write-HealthLog "Created $fileName for module $($module.Name)" "SUCCESS"
                                    $results.ModuleStructure++
                                    $results.FixesApplied++
                                }
                                catch {
                                    Write-HealthLog "Failed to create $fileName for module $($module.Name): $($_.Exception.Message)" "ERROR"
                                    $results.Errors++
                                }
                            }
                        }
                    }
                }
            }
            
            if ($moduleIssues.Count -gt 0) {
                Write-HealthLog "Found $($moduleIssues.Count) modules with structure issues" "WARNING"
                $results.IssuesFound += $moduleIssues.Count
                
                foreach ($issue in $moduleIssues) {
                    $results.Details += @{
                        Check = "Module Structure"
                        Module = $issue.Module
                        Status = "Warning"
                        Details = "Missing items: $($issue.MissingItems -join ', ')"
                        CanAutoFix = $true
                    }
                }
            }
            else {
                Write-HealthLog "All modules have correct structure" "SUCCESS"
            }
        }
    }
    else {
        Write-HealthLog "Modules path not found: $modulesPath" "ERROR"
        $results.IssuesFound++
        $results.Details += @{
            Check = "Module Structure"
            Status = "Error"
            Details = "Modules path not found: $modulesPath"
            CanAutoFix = $true
        }
        
        if ($AutoFix) {
            try {
                $null = New-Item -Path $modulesPath -ItemType Directory -Force -ErrorAction Stop
                Write-HealthLog "Created modules directory" "SUCCESS"
                $results.ModuleStructure++
                $results.FixesApplied++
            }
            catch {
                Write-HealthLog "Failed to create modules directory: $($_.Exception.Message)" "ERROR"
                $results.Errors++
            }
        }
    }
    
    # Check 3: Import Paths (if Full or Deep mode)
    if ($Mode -in @("Full", "Deep")) {
        $results.ChecksPerformed++
        Write-HealthLog "Checking import paths..." "INFO"
        
        # Define expected module paths
        $expectedPaths = @{
            "CodeFixer" = "/pwsh/modules/CodeFixer/"
            "LabRunner" = "/pwsh/modules/LabRunner/"
            "BackupManager" = "/pwsh/modules/BackupManager/"
            "PatchManager" = "/pwsh/modules/PatchManager/"
        }
        
        # Use manifest if available
        if ($manifest -and $manifest.core -and $manifest.core.modules) {
            $expectedPaths = @{}
            $manifest.core.modules.PSObject.Properties | ForEach-Object {
                $moduleName = $_.Name
                $modulePath = $_.Value.path
                $expectedPaths[$moduleName] = $modulePath
            }
        }
        
        # Find all PS1 files that might have import statements
        $ps1Files = Get-ChildItem -Path $ProjectRoot -Filter "*.ps1" -Recurse -ErrorAction SilentlyContinue | 
            Where-Object { $_.FullName -notlike "*/archive/*" -and $_.FullName -notlike "*/backups/*" }
        
        $importIssues = @()
        
        foreach ($file in $ps1Files) {
            $content = Get-Content -Path $file.FullName -Raw
            
            # Check for module imports
            foreach ($moduleName in $expectedPaths.Keys) {
                $correctPath = $expectedPaths[$moduleName]
                
                # Patterns to find incorrect imports
                $patterns = @(
                    "Import-Module .*?[/\\]$moduleName",
                    "Import-Module .*?[/\\]$moduleName[/\\]",
                    "Import-Module ['""].*?[/\\]$moduleName['""]",
                    "Import-Module ['""].*?[/\\]$moduleName[/\\]['""]"
                )
                
                $hasIncorrectImport = $false
                foreach ($pattern in $patterns) {
                    if ($content -match $pattern -and $content -notmatch "Import-Module .*?$correctPath") {
                        $hasIncorrectImport = $true
                        break
                    }
                }
                
                if ($hasIncorrectImport) {
                    $importIssues += @{
                        File = $file.Name
                        Module = $moduleName
                        ExpectedPath = $correctPath
                    }
                    
                    if ($AutoFix) {
                        try {
                            Write-HealthLog "Fixing import path for $moduleName in $($file.Name)..." "INFO"
                            
                            foreach ($pattern in $patterns) {
                                if ($content -match $pattern -and $content -notmatch "Import-Module .*?$correctPath") {
                                    $content = $content -replace $pattern, "Import-Module `"/workspaces/opentofu-lab-automation$correctPath`""
                                }
                            }
                            
                            Set-Content -Path $file.FullName -Value $content -NoNewline
                            Write-HealthLog "Fixed import path for $moduleName in $($file.Name)" "SUCCESS"
                            $results.ImportPaths++
                            $results.FixesApplied++
                        }
                        catch {
                            Write-HealthLog "Failed to fix import path in $($file.Name): $($_.Exception.Message)" "ERROR"
                            $results.Errors++
                        }
                    }
                }
            }
        }
        
        if ($importIssues.Count -gt 0) {
            Write-HealthLog "Found $($importIssues.Count) files with incorrect import paths" "WARNING"
            $results.IssuesFound += $importIssues.Count
            
            foreach ($issue in ($importIssues | Select-Object -First 5)) {
                $results.Details += @{
                    Check = "Import Paths"
                    File = $issue.File
                    Status = "Warning"
                    Details = "Incorrect import path for module $($issue.Module)"
                    CanAutoFix = $true
                }
            }
            
            if ($importIssues.Count -gt 5) {
                $results.Details += @{
                    Check = "Import Paths"
                    Status = "Info"
                    Details = "And $($importIssues.Count - 5) more files with import issues"
                    CanAutoFix = $true
                }
            }
        }
        else {
            Write-HealthLog "All import paths are correct" "SUCCESS"
        }
    }
    
    # Check 4: Test Syntax (if Full or Deep mode)
    if ($Mode -in @("Full", "Deep")) {
        $results.ChecksPerformed++
        Write-HealthLog "Checking test file syntax..." "INFO"
        
        $testFiles = Get-ChildItem -Path "$ProjectRoot/tests" -Filter "*.ps1" -Recurse -ErrorAction SilentlyContinue
        $syntaxIssues = @()
        
        foreach ($file in $testFiles) {
            try {
                $parseErrors = $null
                $null = [System.Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$null, [ref]$parseErrors)
                
                if ($parseErrors -and $parseErrors.Count -gt 0) {
                    $syntaxIssues += @{
                        File = $file.Name
                        ErrorCount = $parseErrors.Count
                        FirstError = $parseErrors[0].ErrorId
                    }
                    
                    if ($AutoFix) {
                        try {
                            Write-HealthLog "Attempting to fix syntax in $($file.Name)..." "INFO"
                            # This is a simplified version of the fix logic
                            # For real implementation, we would call the more comprehensive Invoke-InfrastructureFix function
                            
                            # Read the file content
                            $content = Get-Content -Path $file.FullName -Raw
                            $fixed = $false
                            
                            # Common test file issues to fix
                            
                            # Fix 1: Missing closing braces
                            if ($parseErrors -match "missing closing brace") {
                                # Count opening and closing braces
                                $openBraces = ($content -split "{").Count - 1
                                $closeBraces = ($content -split "}").Count - 1
                                
                                if ($openBraces -gt $closeBraces) {
                                    # Add missing closing braces
                                    $missingBraces = $openBraces - $closeBraces
                                    $content = $content.TrimEnd() + "`r`n" + ("}") * $missingBraces
                                    $fixed = $true
                                    Write-HealthLog "Added $missingBraces closing braces to $($file.Name)" "SUCCESS"
                                }
                            }
                            
                            if ($fixed) {
                                Set-Content -Path $file.FullName -Value $content -NoNewline
                                $results.TestSyntax++
                                $results.FixesApplied++
                            }
                        }
                        catch {
                            Write-HealthLog "Failed to fix syntax in $($file.Name): $($_.Exception.Message)" "ERROR"
                            $results.Errors++
                        }
                    }
                }
            }
            catch {
                Write-HealthLog "Error analyzing $($file.Name): $($_.Exception.Message)" "ERROR"
                $results.Errors++
            }
        }
        
        if ($syntaxIssues.Count -gt 0) {
            Write-HealthLog "Found $($syntaxIssues.Count) test files with syntax issues" "WARNING"
            $results.IssuesFound += $syntaxIssues.Count
            
            foreach ($issue in ($syntaxIssues | Select-Object -First 5)) {
                $results.Details += @{
                    Check = "Test Syntax"
                    File = $issue.File
                    Status = "Warning"
                    Details = "$($issue.ErrorCount) errors, first error: $($issue.FirstError)"
                    CanAutoFix = $true
                }
            }
            
            if ($syntaxIssues.Count -gt 5) {
                $results.Details += @{
                    Check = "Test Syntax"
                    Status = "Info"
                    Details = "And $($syntaxIssues.Count - 5) more files with syntax issues"
                    CanAutoFix = $true
                }
            }
        }
        else {
            Write-HealthLog "All test files have valid syntax" "SUCCESS"
        }
    }
    
    # Check 5: Archive file buildup (if Deep mode)
    if ($Mode -eq "Deep") {
        $results.ChecksPerformed++
        Write-HealthLog "Checking archive directory..." "INFO"
        
        $archiveDirs = @(
            "$ProjectRoot/archive/broken-syntax-files",
            "$ProjectRoot/archive/broken-syntax-files-*",
            "$ProjectRoot/archive/broken-workflows-*",
            "$ProjectRoot/archive/cleanup-*",
            "$ProjectRoot/archive/duplicate-labrunner-*",
            "$ProjectRoot/archive/excess-installers-*",
            "$ProjectRoot/archive/excess-readme-files-*",
            "$ProjectRoot/archive/root-fix-scripts-*",
            "$ProjectRoot/archive/summary-files-*"
        )
        
        $matchingDirs = @()
        foreach ($pattern in $archiveDirs) {
            $dirs = Get-Item -Path $pattern -ErrorAction SilentlyContinue
            if ($dirs) {
                $matchingDirs += $dirs
            }
        }
        
        if ($matchingDirs.Count -gt 0) {
            Write-HealthLog "Found $($matchingDirs.Count) archive directories that should be cleaned up" "WARNING"
            $results.IssuesFound++
            
            $results.Details += @{
                Check = "Archive Cleanup"
                Status = "Warning"
                Details = "Found $($matchingDirs.Count) archive directories that should be cleaned up"
                CanAutoFix = $true
            }
            
            if ($AutoFix) {
                Write-HealthLog "Cleaning up archive directories with Invoke-ArchiveCleanup..." "INFO"
                try {
                    # We would call the Invoke-ArchiveCleanup function here
                    # For now, just log it
                    Write-HealthLog "Would clean up $($matchingDirs.Count) archive directories" "INFO"
                }
                catch {
                    Write-HealthLog "Failed to clean up archive directories: $($_.Exception.Message)" "ERROR"
                    $results.Errors++
                }
            }
        }
        else {
            Write-HealthLog "No archive directories need cleanup" "SUCCESS"
        }
    }
    
    # Final summary
    Write-HealthLog "Health check completed: $($results.ChecksPerformed) checks performed" "INFO"
    Write-HealthLog "Issues found: $($results.IssuesFound)" "INFO"
    Write-HealthLog "Fixes applied: $($results.FixesApplied)" "INFO"
    Write-HealthLog "Errors encountered: $($results.Errors)" "INFO"
    
    if ($results.IssuesFound -eq 0) {
        Write-HealthLog "System health: GOOD" "SUCCESS"
    }
    elseif ($results.IssuesFound -le 3) {
        Write-HealthLog "System health: FAIR - Minor issues found" "WARNING"
    }
    else {
        Write-HealthLog "System health: POOR - Multiple issues found" "ERROR"
    }
    
    return [PSCustomObject]$results
}
