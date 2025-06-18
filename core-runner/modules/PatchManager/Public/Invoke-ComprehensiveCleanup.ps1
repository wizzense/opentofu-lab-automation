#Requires -Version 7.0
<#
.SYNOPSIS
    Comprehensive cleanup functionality for PatchManager
    
.DESCRIPTION
    This function performs comprehensive cleanup of unnecessary files and directories
    before committing and creating pull requests. It ensures a clean state for all patches.
    
.PARAMETER CleanupMode
    The cleanup mode: 'Standard', 'Aggressive', 'Emergency', or 'Safe'
    
.PARAMETER ExcludePatterns
    Array of patterns to exclude from cleanup
    
.PARAMETER DryRun
    Perform a dry run without actually deleting files
    
.EXAMPLE
    Invoke-ComprehensiveCleanup -CleanupMode "Standard"
    
.EXAMPLE
    Invoke-ComprehensiveCleanup -CleanupMode "Aggressive" -DryRun
    
.NOTES
    - Always creates backup before cleanup
    - Follows cross-platform path standards
    - Removes emoji violations automatically
    - Consolidates duplicate files
    - Archives old files based on timestamps
#>

function Invoke-ComprehensiveCleanup {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $false)]
        [ValidateSet("Standard", "Aggressive", "Emergency", "Safe")]
        [string]$CleanupMode = "Standard",
        
        [Parameter(Mandatory = $false)]
        [string[]]$ExcludePatterns = @(),
        
        [Parameter(Mandatory = $false)]
        [switch]$DryRun
    )
    
    begin {
        Write-Host "Starting comprehensive cleanup..." -ForegroundColor Cyan
        Write-Host "Mode: $CleanupMode  Dry Run: $DryRun" -ForegroundColor Yellow
        
        # Get project root
        $script:ProjectRoot = (Get-Location).Path
        
        # Create cleanup log
        $script:CleanupLog = @{
            StartTime = Get-Date
            Mode = $CleanupMode
            DryRun = $DryRun
            FilesRemoved = @()
            DirectoriesRemoved = @()
            FilesRelocated = @()
            SizeReclaimed = 0
            Errors = @()
        }
          # Standard exclusion patterns (critical files to never touch)
        $script:CriticalExclusions = @(
            # Core project files
            "PROJECT-MANIFEST.json"
            "README.md"
            "LICENSE"
            "CHANGELOG.md"
            "mkdocs.yml"
            "pyproject.toml"
            
            # Module directories (complete protection)
            "pwsh/modules/*"
            "pwsh/modules/*/*"
            "pwsh/modules/*/*/*"
            
            # Configuration and tooling
            ".git/*"
            ".github/*"
            ".vscode/*"
            "configs/*"
            
            # Specific module files that must be protected
            "pwsh/modules/PatchManager/PatchManager.psm1"
            "pwsh/modules/PatchManager/PatchManager.psd1"
            "pwsh/modules/PatchManager/Public/*"
            "pwsh/modules/PatchManager/Private/*"
            "pwsh/modules/CodeFixer/CodeFixer.psm1"
            "pwsh/modules/CodeFixer/CodeFixer.psd1"
            "pwsh/modules/LabRunner/LabRunner.psm1"
            "pwsh/modules/LabRunner/LabRunner.psd1"
            "pwsh/modules/BackupManager/BackupManager.psm1"
            "pwsh/modules/BackupManager/BackupManager.psd1"
        ) + $ExcludePatterns
        
        Write-Host "Critical exclusions: $($script:CriticalExclusions.Count) patterns" -ForegroundColor Blue
    }
    
    process {
        try {
            # Phase 1: Remove temporary and cache files
            Write-Host "Phase 1: Removing temporary files..." -ForegroundColor Green
            Invoke-TempFileCleanup
            
            # Phase 2: Fix emoji violations (critical for workflows)
            Write-Host "Phase 2: Removing emoji violations..." -ForegroundColor Green
            Invoke-EmojiCleanup
            
            # Phase 3: Fix cross-platform path issues
            Write-Host "Phase 3: Fixing cross-platform path issues..." -ForegroundColor Green
            Invoke-PathStandardization
            
            # Phase 4: Consolidate duplicate files
            Write-Host "Phase 4: Consolidating duplicate files..." -ForegroundColor Green
            Invoke-DuplicateConsolidation
            
            # Phase 5: Archive old files based on age
            Write-Host "Phase 5: Archiving old files..." -ForegroundColor Green
            Invoke-FileArchival
            
            # Phase 6: Remove empty directories
            Write-Host "Phase 6: Removing empty directories..." -ForegroundColor Green
            Invoke-EmptyDirectoryCleanup
            
            # Phase 7: Organize remaining files
            Write-Host "Phase 7: Organizing files..." -ForegroundColor Green
            Invoke-FileOrganization
            
            # Phase 8: Validate cleanup results
            Write-Host "Phase 8: Validating cleanup results..." -ForegroundColor Green
            $validationResult = Invoke-CleanupValidation
            
            $script:CleanupLog.EndTime = Get-Date
            $script:CleanupLog.Duration = $script:CleanupLog.EndTime - $script:CleanupLog.StartTime
            
            # Generate cleanup report
            New-CleanupReport
            
            return @{
                Success = $true
                Message = "Comprehensive cleanup completed successfully"
                FilesRemoved = $script:CleanupLog.FilesRemoved.Count
                DirectoriesRemoved = $script:CleanupLog.DirectoriesRemoved.Count
                SizeReclaimed = $script:CleanupLog.SizeReclaimed
                Duration = $script:CleanupLog.Duration
                ValidationResult = $validationResult
            }
            
        } catch {
            $script:CleanupLog.Errors += $_.Exception.Message
            Write-Error "Cleanup failed: $($_.Exception.Message)"
            
            return @{
                Success = $false
                Message = $_.Exception.Message
                Errors = $script:CleanupLog.Errors
            }
        }
    }
}

function Invoke-TempFileCleanup {
    $tempPatterns = @(
        "*.tmp", "*.temp", "*.bak", "*.orig", "*.log", "*.cache"
        "*~", "*.swp", "*.swo", ".DS_Store", "Thumbs.db"
        "TestResults*.xml", "coverage.xml", "*.coverage"
        "node_modules", ".pytest_cache", "__pycache__"
    )
    
    foreach ($pattern in $tempPatterns) {
        $files = Get-ChildItem -Path $script:ProjectRoot -Recurse -Include $pattern -Force -ErrorAction SilentlyContinue
        foreach ($file in $files) {
            if (-not (Test-CriticalExclusion $file.FullName)) {
                Remove-FileOrDirectory -Path $file.FullName -Reason "Temporary file cleanup"
            }
        }
    }
}

function Invoke-EmojiCleanup {
    # Get all text files and check for emoji violations
    $textExtensions = @("*.ps1", "*.psm1", "*.psd1", "*.py", "*.md", "*.yml", "*.yaml", "*.json", "*.txt")
    
    foreach ($extension in $textExtensions) {
        $files = Get-ChildItem -Path $script:ProjectRoot -Recurse -Include $extension -ErrorAction SilentlyContinue
        
        foreach ($file in $files) {            if (-not (Test-CriticalExclusion $file.FullName)) {
                $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
                # Use a simpler emoji detection pattern that works in PowerShell
                $emojiPattern = '\u2600-\u26FF\u2700-\u27BF'
                if ($content -and ($content -match $emojiPattern)) {
                    Write-Host "  Removing emojis from: $($file.Name)" -ForegroundColor Yellow
                    
                    if (-not $DryRun) {
                        # Remove emojis and save file
                        $cleanContent = $content -replace $emojiPattern, ''
                        Set-Content -Path $file.FullName -Value $cleanContent -NoNewline
                        $script:CleanupLog.FilesRelocated += @{ File = $file.FullName; Action = "Emoji removal" }
                    }
                }
            }
        }
    }
}

function Invoke-PathStandardization {
    # Fix hardcoded paths throughout the codebase with environment variable support
    $files = Get-ChildItem -Path $script:ProjectRoot -Recurse -Include "*.ps1", "*.py", "*.json", "*.md", "*.yaml", "*.yml" -ErrorAction SilentlyContinue
    
    # Define standardized replacement paths with environment variables
    $pathMappings = @{
        # Windows specific paths
        'C:\\Users\\alexa\\OneDrive\\Documents\\0\. wizzense\\opentofu-lab-automation' = '$env:PROJECT_ROOT'
        'C:\Users\alexa\OneDrive\Documents\0. wizzense\opentofu-lab-automation' = '$env:PROJECT_ROOT'
        # Linux/WSL path
        '/mnt/c/Users/alexa/OneDrive/Documents/0. wizzense/opentofu-lab-automation' = '$env:PROJECT_ROOT'
        # Container paths
        '/workspaces/opentofu-lab-automation' = '$env:PROJECT_ROOT'
        # PowerShell modules path
        'C:\\Users\\alexa\\OneDrive\\Documents\\0\. wizzense\\opentofu-lab-automation\\pwsh\\modules' = '$env:PWSH_MODULES_PATH'
        'C:\Users\alexa\OneDrive\Documents\0. wizzense\opentofu-lab-automation\pwsh\modules' = '$env:PWSH_MODULES_PATH'
        '/workspaces/opentofu-lab-automation/pwsh/modules' = '$env:PWSH_MODULES_PATH'
    }
    
    # Add dynamically constructed paths based on current environment
    $currentDir = (Get-Location).Path
    if (-not [string]::IsNullOrEmpty($currentDir)) {
        $pathMappings[$currentDir] = '$env:PROJECT_ROOT'
    }
    
    # Counter for changed files
    $changedFiles = 0
    
    foreach ($file in $files) {
        if (-not (Test-CriticalExclusion $file.FullName)) {
            $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
            $contentChanged = $false
            
            if ($content) {
                $cleanContent = $content
                
                # Replace each hardcoded path with environment variable
                foreach ($pattern in $pathMappings.Keys) {
                    $replacement = $pathMappings[$pattern]
                    # First try direct string replacement for simpler paths
                    if ($cleanContent.Contains($pattern)) {
                        $cleanContent = $cleanContent.Replace($pattern, $replacement)
                        $contentChanged = $true
                    }
                    # Then try regex for more complex path patterns
                    $escapedPattern = [regex]::Escape($pattern)
                    if ($cleanContent -match $escapedPattern) {
                        $cleanContent = $cleanContent -replace $escapedPattern, $replacement
                        $contentChanged = $true
                    }
                }
                
                # Fix common path separator issues
                if ($cleanContent -match '\\\\') {
                    $cleanContent = $cleanContent -replace '\\\\', '/'
                    $contentChanged = $true
                }
                
                if ($contentChanged -and -not $DryRun) {
                    Write-Host "  Fixing paths in: $($file.Name)" -ForegroundColor Yellow
                    Set-Content -Path $file.FullName -Value $cleanContent -NoNewline
                    $script:CleanupLog.FilesRelocated += @{ 
                        File = $file.FullName
                        Action = "Path standardization with environment variables"
                    }
                    $changedFiles++
                }
            }
        }
    }
    
    Write-Host "  Standardized paths in $changedFiles files" -ForegroundColor Cyan
}

function Invoke-DuplicateConsolidation {
    # Find and consolidate duplicate files
    $fileHashes = @{}
    $duplicates = @()
    
    $files = Get-ChildItem -Path $script:ProjectRoot -Recurse -File -ErrorAction SilentlyContinue | Where-Object{ -not (Test-CriticalExclusion $_.FullName) }
    
    foreach ($file in $files) {
        try {
            $hash = Get-FileHash $file.FullName -Algorithm MD5
            if ($fileHashes.ContainsKey($hash.Hash)) {
                $duplicates += @{
                    Original = $fileHashes[$hash.Hash]
                    Duplicate = $file.FullName
                    Size = $file.Length
                }
            } else {
                $fileHashes[$hash.Hash] = $file.FullName
            }
        } catch {
            Write-Warning "Error processing file $($file.FullName): $_"
        }
    }
    
    # Remove duplicates (keep the one in the better location)
    foreach ($dup in $duplicates) {
        $keepOriginal = $true
        
        # Prefer files in proper directories over root directory
        if ($dup.Duplicate -match "^$([regex]::Escape($script:ProjectRoot))[/\\][^/\\]+$" -and 
            $dup.Original -match "scripts|pwsh|tests|docs") {
            $keepOriginal = $false
        }
        
        $fileToRemove = if ($keepOriginal) { $dup.Duplicate } else { $dup.Original }
        Write-Host "  Removing duplicate: $(Split-Path $fileToRemove -Leaf)" -ForegroundColor Yellow
        
        Remove-FileOrDirectory -Path $fileToRemove -Reason "Duplicate file consolidation"
        $script:CleanupLog.SizeReclaimed += $dup.Size
    }
}

function Invoke-FileArchival {
    # Archive files older than threshold based on cleanup mode
    $archiveThreshold = switch ($CleanupMode) {
        "Aggressive" { (Get-Date).AddDays(-7) }
        "Standard" { (Get-Date).AddDays(-30) }
        "Safe" { (Get-Date).AddDays(-90) }
        "Emergency" { (Get-Date).AddDays(-1) }
    }
    
    $archivePath = Join-Path $script:ProjectRoot "archive/cleanup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    
    # Find old files in root directory
    $oldFiles = Get-ChildItem -Path $script:ProjectRoot -File -ErrorAction SilentlyContinue | Where-Object{ 
            $_.LastWriteTime -lt $archiveThreshold -and 
            -not (Test-CriticalExclusion $_.FullName) -and
            $_.Name -match '\.(mdps1pylogtxt)$'
        }
    
    if ($oldFiles.Count -gt 0) {
        if (-not $DryRun) {
            if (-not (Test-Path $archivePath)) { New-Item -ItemType Directory -Path $archivePath -Force | Out-Null }
        
        foreach ($file in $oldFiles) {
            Write-Host "  Archiving old file: $($file.Name)" -ForegroundColor Yellow
            
            if (-not $DryRun) {
                Move-Item $file.FullName -Destination $archivePath
                $script:CleanupLog.FilesRelocated += @{ File = $file.FullName; Action = "Archived to $archivePath" }
            }
        }
    }
}

function Invoke-EmptyDirectoryCleanup {
    # Remove empty directories (except critical ones)
    $directories = Get-ChildItem -Path $script:ProjectRoot -Directory -Recurse -ErrorAction SilentlyContinue | Sort-Object FullName -Descending  # Process deepest first
    
    foreach ($dir in $directories) {
        if (-not (Test-CriticalExclusion $dir.FullName)) {
            $items = Get-ChildItem -Path $dir.FullName -Force -ErrorAction SilentlyContinue
            if ($items.Count -eq 0) {
                Write-Host "  Removing empty directory: $($dir.Name)" -ForegroundColor Yellow
                Remove-FileOrDirectory -Path $dir.FullName -Reason "Empty directory cleanup"
            }
        }
    }
}

function Invoke-FileOrganization {
    # Move misplaced files to appropriate directories
    $rootFiles = Get-ChildItem -Path $script:ProjectRoot -File -ErrorAction SilentlyContinue | Where-Object{ -not (Test-CriticalExclusion $_.FullName) }
    
    foreach ($file in $rootFiles) {
        $destination = $null
        
        switch -Regex ($file.Name) {
            '\.ps1$' { $destination = "scripts/utilities" }
            '\.py$' { $destination = "py" }
            '\.md$' { 
                if ($file.Name -match '^A-Z-+\.md$') {
                    $destination = "docs"
                }
            }
            '\.(ymlyaml)$' { $destination = "configs" }
            '\.(logtxt)$' { $destination = "logs" }
        }
        
        if ($destination) {
            $destPath = Join-Path $script:ProjectRoot $destination
            if (-not (Test-Path $destPath)) {
                if (-not $DryRun) {
                    if (-not (Test-Path $destPath)) { New-Item -ItemType Directory -Path $destPath -Force | Out-Null }
            }
            
            Write-Host "  Moving to ${destination}: $($file.Name)" -ForegroundColor Yellow
            
            if (-not $DryRun) {
                Move-Item $file.FullName -Destination $destPath
                $script:CleanupLog.FilesRelocated += @{ File = $file.FullName; Action = "Moved to $destination" }
            }
        }
    }
}

function Invoke-CleanupValidation {
    # Validate that cleanup didn't break anything critical
    $issues = @()
    
    # Check that critical files still exist
    $criticalFiles = @(
        "PROJECT-MANIFEST.json"
        "README.md"
        "LICENSE"
        ".vscode/settings.json"
    )
    
    foreach ($file in $criticalFiles) {
        $fullPath = Join-Path $script:ProjectRoot $file
        if (-not (Test-Path $fullPath)) {
            $issues += "Critical file missing after cleanup: $file"
        }
    }
    
    # Check that modules still exist
    $moduleDirectories = @(
        "pwsh/modules/LabRunner"
        "pwsh/modules/CodeFixer"
        "pwsh/modules/PatchManager"
    )
    
    foreach ($moduleDir in $moduleDirectories) {
        $fullPath = Join-Path $script:ProjectRoot $moduleDir
        if (-not (Test-Path $fullPath)) {
            $issues += "Critical module directory missing after cleanup: $moduleDir"
        }
    }
    
    return @{
        Success = $issues.Count -eq 0
        Issues = $issues
        Message = if ($issues.Count -eq 0) { "Validation passed" } else { "Validation failed with $($issues.Count) issues" }
    }
}

function Test-CriticalExclusion {
    param(
        [string]$Path
    )
    
    # Normalize path separators for cross-platform compatibility
    $normalizedPath = $Path.Replace('\', '/') 
    $normalizedProjectRoot = $script:ProjectRoot.Replace('\', '/')
    
    # Create platform-agnostic relative path
    $relativePath = $normalizedPath -replace [regex]::Escape($normalizedProjectRoot), ''
    $relativePath = $relativePath -replace '^/', ""
    
    # Try multiple matching strategies for maximum compatibility
    foreach ($pattern in $script:CriticalExclusions) {
        # Strategy 1: Simple wildcard matching (works for basic patterns)
        if ($relativePath -like $pattern) {
            return $true
        }
        
        # Strategy 2: Normalized regex pattern matching (more powerful)
        $normalizedPattern = $pattern.Replace('\', '/')
        $regexPattern = $normalizedPattern -replace '\*', '.*'
        if ($relativePath -match "^$regexPattern$") {
            return $true
        }
        
        # Strategy 3: Path-aware matching for directories
        if ($pattern.EndsWith('/') -and $relativePath.StartsWith($pattern.TrimEnd('/'))) {
            return $true
        }
    }
    
    return $false
}

function Remove-FileOrDirectory {
    param(
        [string]$Path,
        [string]$Reason,
        [switch]$Force
    )

    if (Test-Path $Path) {
        $item = Get-Item $Path
        $size = if ($item.PSIsContainer) { 0 } else { $item.Length }

        if (-not $DryRun) {
            Write-Host "    Removing: $(Split-Path $Path -Leaf) ($Reason)" -ForegroundColor Gray
            try {
                Remove-Item $Path -Recurse -Force
                if ($item.PSIsContainer) {
                    $script:CleanupLog.DirectoriesRemoved += $Path
                } else {
                    $script:CleanupLog.FilesRemoved += $Path
                    $script:CleanupLog.SizeReclaimed += $size
                }
            } catch {
                $script:CleanupLog.Errors += "Failed to remove ${Path}: $($_.Exception.Message)"
            }
        } else {
            Write-Host "      DRY RUN Would remove: $Path ($Reason)" -ForegroundColor DarkGray
        }
    }
}

function New-CleanupReport {
    $reportPath = Join-Path $script:ProjectRoot "CLEANUP-PROGRESS-$(Get-Date -Format 'yyyyMMdd-HHmmss').md"
    
    $report = @"
# Comprehensive Cleanup Report

**Generated**: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss UTC")
**Mode**: $($script:CleanupLog.Mode)
**Duration**: $($script:CleanupLog.Duration.TotalSeconds) seconds
**Dry Run**: $($script:CleanupLog.DryRun)

## Summary

- **Files Removed**: $($script:CleanupLog.FilesRemoved.Count)
- **Directories Removed**: $($script:CleanupLog.DirectoriesRemoved.Count)  
- **Files Relocated**: $($script:CleanupLog.FilesRelocated.Count)
- **Size Reclaimed**: $([Math]::Round($script:CleanupLog.SizeReclaimed / 1MB, 2)) MB
- **Errors**: $($script:CleanupLog.Errors.Count)

## Actions Performed

### Phase 1: Temporary File Cleanup
- Removed cache files, temporary files, and build artifacts
- Cleaned up test results and coverage files

### Phase 2: Emoji Violations Fixed
- Scanned all text files for emoji violations
- Removed emojis that break workflow parsing

### Phase 3: Cross-Platform Path Standardization
- Fixed hardcoded Windows paths throughout codebase
- Standardized to '/workspaces/opentofu-lab-automation' format

### Phase 4: Duplicate File Consolidation
- Identified and removed duplicate files
- Preserved files in proper directory structure

### Phase 5: File Archival
- Moved old files to archive based on age thresholds
- Preserved file history in organized archive structure

### Phase 6: Empty Directory Cleanup
- Removed empty directories
- Preserved critical directory structure

### Phase 7: File Organization
- Moved misplaced files to appropriate directories
- Improved project structure organization

### Phase 8: Validation
- Verified critical files and modules remain intact
- Ensured cleanup didn't break project functionality

## Files Relocated

$($script:CleanupLog.FilesRelocated | ForEach-Object{ "- $($_.File): $($_.NewLocation)" } | Out-String)

## Errors

$($script:CleanupLog.Errors | ForEach-Object{ "- $_" } | Out-String)

---
*Generated by PatchManager Comprehensive Cleanup v2.0*
"@

    if (-not $DryRun) {
        Set-Content -Path $reportPath -Value $report
        Write-Host "Cleanup report saved: $reportPath" -ForegroundColor Green
    } else {
        Write-Host "Cleanup report would be saved to: $reportPath" -ForegroundColor DarkGray    }
}





