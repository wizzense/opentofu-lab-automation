function Invoke-RecurringIssueCheck {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false)]
        [string]$ProjectRoot = $PWD,
        
        [Parameter(Mandatory=$false)]
        [switch]$CreateGitHubIssue,
        
        [Parameter(Mandatory=$false)]
        [switch]$UpdateIssueFile
    )
    
    # Normalize project root to absolute path
    $ProjectRoot = (Resolve-Path $ProjectRoot).Path
    
    # Function for centralized logging
    function Write-IssueLog {
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
    
    Write-IssueLog "Starting recurring issue check for $ProjectRoot..." "INFO"
    
    # Define the issues file path
    $issuesFilePath = Join-Path $ProjectRoot "PROJECT-ISSUES.json"
    
    # Load or create issues file
    if (Test-Path $issuesFilePath) {
        try {
            $issuesData = Get-Content $issuesFilePath -Raw | ConvertFrom-Json
            Write-IssueLog "Loaded existing issues tracking file" "SUCCESS"
        }
        catch {
            Write-IssueLog "Error loading issues file: $_" "ERROR"
            $issuesData = @{
                lastUpdated = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
                issues = @()
            }
        }
    }
    else {
        Write-IssueLog "No issues file found, creating new tracking" "INFO"
        $issuesData = @{
            lastUpdated = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
            issues = @()
        }
    }
    
    # Define checks for recurring issues
    $checks = @(
        @{
            Name = "YAML Validation Issues"
            Type = "WorkflowValidation"
            Check = {
                $yamlFiles = Get-ChildItem -Path "$ProjectRoot/.github/workflows" -Filter "*.yml","*.yaml" -Recurse -ErrorAction SilentlyContinue
                $issues = @()
                
                foreach ($file in $yamlFiles) {
                    try {
                        # Try simple YAML parsing
                        $content = Get-Content -Path $file.FullName -Raw -ErrorAction Stop
                        $null = ConvertFrom-Yaml $content -ErrorAction Stop
                    }
                    catch {
                        $issues += @{
                            File = $file.Name
                            Error = $_.Exception.Message
                        }
                    }
                }
                
                return @{
                    Found = $issues.Count -gt 0
                    Details = if ($issues.Count -gt 0) { $issues } else { $null }
                    Count = $issues.Count
                }
            }
            Severity = "High"
            AutoFixCommand = "./scripts/validation/Invoke-YamlValidation.ps1 -Mode Fix"
        },
        @{
            Name = "Broken Import Paths"
            Type = "ImportPaths"
            Check = {
                $ps1Files = Get-ChildItem -Path $ProjectRoot -Filter "*.ps1" -Recurse -ErrorAction SilentlyContinue | 
                    Where-Object { $_.FullName -notlike "*/archive/*" -and $_.FullName -notlike "*/backups/*" }
                
                $issues = @()
                $importRegex = "Import-Module\s+['""]?(.*?(CodeFixer|LabRunner|BackupManager|PatchManager)['""]?)"
                
                foreach ($file in $ps1Files) {
                    $content = Get-Content -Path $file.FullName -Raw
                    
                    if ($content -match $importRegex) {
                        $import = $Matches[1]
                        
                        # Check if it's using the correct path format
                        if ($import -notmatch "/workspaces/opentofu-lab-automation/pwsh/modules/" -and 
                            $import -notmatch "/pwsh/modules/") {
                            $issues += @{
                                File = $file.Name
                                ImportPath = $import
                            }
                        }
                    }
                }
                
                return @{
                    Found = $issues.Count -gt 0
                    Details = if ($issues.Count -gt 0) { $issues } else { $null }
                    Count = $issues.Count
                }
            }
            Severity = "Medium"
            AutoFixCommand = "./scripts/maintenance/fix-infrastructure-issues.ps1 -Fix ImportPaths -AutoFix"
        },
        @{
            Name = "Test File Syntax Errors"
            Type = "TestSyntax"
            Check = {
                $testFiles = Get-ChildItem -Path "$ProjectRoot/tests" -Filter "*.ps1" -Recurse -ErrorAction SilentlyContinue
                $issues = @()
                
                foreach ($file in $testFiles) {
                    try {
                        $parseErrors = $null
                        $null = [System.Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$null, [ref]$parseErrors)
                        
                        if ($parseErrors -and $parseErrors.Count -gt 0) {
                            $issues += @{
                                File = $file.Name
                                ErrorCount = $parseErrors.Count
                                FirstError = $parseErrors[0].ErrorId
                            }
                        }
                    }
                    catch {
                        $issues += @{
                            File = $file.Name
                            Error = $_.Exception.Message
                        }
                    }
                }
                
                return @{
                    Found = $issues.Count -gt 0
                    Details = if ($issues.Count -gt 0) { $issues } else { $null }
                    Count = $issues.Count
                }
            }
            Severity = "High"
            AutoFixCommand = "./scripts/maintenance/fix-infrastructure-issues.ps1 -Fix TestSyntax -AutoFix"
        },
        @{
            Name = "Archive File Buildup"
            Type = "ArchiveCleanup"
            Check = {
                $archiveDirs = @(
                    "$ProjectRoot/archive/broken-syntax-files",
                    "$ProjectRoot/archive/broken-syntax-files-*",
                    "$ProjectRoot/archive/broken-workflows-*",
                    "$ProjectRoot/archive/cleanup-*",
                    "$ProjectRoot/archive/duplicate-labrunner-*",
                    "$ProjectRoot/archive/excess-installers-*"
                )
                
                $matchingDirs = @()
                foreach ($pattern in $archiveDirs) {
                    $dirs = Get-Item -Path $pattern -ErrorAction SilentlyContinue
                    if ($dirs) {
                        $matchingDirs += $dirs
                    }
                }
                
                return @{
                    Found = $matchingDirs.Count -gt 0
                    Details = if ($matchingDirs.Count -gt 0) { 
                        $matchingDirs | ForEach-Object { 
                            @{ Directory = $_.Name; ItemCount = (Get-ChildItem $_.FullName -Recurse).Count }
                        }
                    } else { $null }
                    Count = $matchingDirs.Count
                }
            }
            Severity = "Low"
            AutoFixCommand = "./scripts/maintenance/unified-maintenance.ps1 -Mode Quick -AutoFix"
        }
    )
    
    # Run all checks
    $allIssues = @()
    $totalIssues = 0
    
    foreach ($check in $checks) {
        Write-IssueLog "Running check: $($check.Name)..." "INFO"
        try {
            $result = & $check.Check
            
            if ($result.Found) {
                $totalIssues += $result.Count
                Write-IssueLog "Found $($result.Count) $($check.Name) issues (Severity: $($check.Severity))" "WARNING"
                
                # Add or update issue in tracking
                $existingIssue = $issuesData.issues | Where-Object { $_.Type -eq $check.Type }
                
                if ($existingIssue) {
                    Write-IssueLog "Updating existing issue tracking for $($check.Name)" "INFO"
                    $existingIssue.LastDetected = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
                    $existingIssue.Count = $result.Count
                    $existingIssue.Details = $result.Details
                    $existingIssue.RecurrenceCount++
                }
                else {
                    Write-IssueLog "Adding new issue tracking for $($check.Name)" "INFO"
                    $newIssue = @{
                        Type = $check.Type
                        Name = $check.Name
                        Severity = $check.Severity
                        FirstDetected = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
                        LastDetected = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
                        Count = $result.Count
                        Details = $result.Details
                        AutoFixCommand = $check.AutoFixCommand
                        RecurrenceCount = 1
                        GitHubIssue = $null
                    }
                    
                    $issuesData.issues += $newIssue
                }
                
                $allIssues += @{
                    Type = $check.Type
                    Name = $check.Name
                    Severity = $check.Severity
                    Count = $result.Count
                    Details = $result.Details
                    AutoFixCommand = $check.AutoFixCommand
                }
            }
            else {
                Write-IssueLog "No issues found for $($check.Name)" "SUCCESS"
                
                # If it was a previously tracked issue, update to show it's resolved
                $existingIssue = $issuesData.issues | Where-Object { $_.Type -eq $check.Type }
                if ($existingIssue) {
                    $existingIssue.Status = "Resolved"
                    $existingIssue.ResolvedDate = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
                }
            }
        }
        catch {
            Write-IssueLog "Error running check $($check.Name): $_" "ERROR"
        }
    }
    
    # Update last updated timestamp
    $issuesData.lastUpdated = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    
    # Save updated issues file if requested
    if ($UpdateIssueFile) {
        try {
            $issuesData | ConvertTo-Json -Depth 5 | Set-Content -Path $issuesFilePath -NoNewline
            Write-IssueLog "Updated issues tracking file saved" "SUCCESS"
        }
        catch {
            Write-IssueLog "Failed to save issues tracking file: $_" "ERROR"
        }
    }
    
    # Create GitHub issues if requested
    if ($CreateGitHubIssue -and $allIssues.Count -gt 0) {
        $criticalIssues = $allIssues | Where-Object { $_.Severity -eq "High" }
        
        if ($criticalIssues.Count -gt 0) {
            try {
                Write-IssueLog "Creating GitHub issues for critical issues..." "INFO"
                # This would call a function to create GitHub issues
                # For now we'll just log it
                Write-IssueLog "Would create $($criticalIssues.Count) GitHub issues" "INFO"
            }
            catch {
                Write-IssueLog "Failed to create GitHub issues: $_" "ERROR"
            }
        }
    }
    
    # Summary
    Write-IssueLog "Recurring issue check complete: found $totalIssues issues across $($allIssues.Count) categories" "INFO"
    
    return $allIssues
}
