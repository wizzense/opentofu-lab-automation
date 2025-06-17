#Requires -Version 7.0

<#
.SYNOPSIS
    Removes emojis from project files and replaces them with professional language.

.DESCRIPTION
    This function scans project files for emojis and replaces them with appropriate
    professional language alternatives. Part of the DevEnvironment module for
    maintaining project standards and enforcing the no-emoji policy.

.PARAMETER Path
    The root path to scan for files. Defaults to current directory.

.PARAMETER FileTypes
    Array of file extensions to scan. Defaults to common code/documentation files.

.PARAMETER DryRun
    Show what would be changed without making actual changes.

.PARAMETER CreateBackup
    Create backup files before making changes.

.EXAMPLE
    Remove-ProjectEmojis -DryRun
    Shows what emoji replacements would be made without changing files.

.EXAMPLE
    Remove-ProjectEmojis -Path "." -CreateBackup
    Removes emojis from all supported files and creates backups.

.NOTES
    Part of the DevEnvironment module for maintaining project standards.
    Follows the project's strict no-emoji policy.
#>

function Remove-ProjectEmojis {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter()]
        [string]$Path = ".",
        
        [Parameter()]
        [string[]]$FileTypes = @("*.ps1", "*.md", "*.yml", "*.yaml", "*.json", "*.txt"),
        
        [Parameter()]
        [switch]$DryRun,
        
        [Parameter()]
        [switch]$CreateBackup
    )
    
    begin {
        Write-CustomLog "Starting emoji removal process..." -Level INFO
        
        # Comprehensive emoji pattern covering most Unicode emoji ranges
        $emojiPattern = [regex]'[\u{1F600}-\u{1F64F}]|[\u{1F300}-\u{1F5FF}]|[\u{1F680}-\u{1F6FF}]|[\u{1F1E0}-\u{1F1FF}]|[\u{2600}-\u{26FF}]|[\u{2700}-\u{27BF}]|[\u{1F900}-\u{1F9FF}]|[\u{1F018}-\u{1F0FF}]|[\u{1F100}-\u{1F64F}]'
        
        # Professional replacements for common emojis
        $emojiReplacements = @{
            'PASS' = 'PASS'
            'FAIL' = 'FAIL'
            'WARNING' = 'WARNING'
            'BLOCKED' = 'BLOCKED'
            'TIP' = 'TIP'
            'TOOL' = 'TOOL'
            'SEARCH' = 'SEARCH'
            'NOTE' = 'NOTE'
            'LIST' = 'LIST'
            'REPORT' = 'REPORT'
            'TARGET' = 'TARGET'
            'DEPLOY' = 'DEPLOY'
            'STAR' = 'STAR'
            'SYSTEM' = 'SYSTEM'
            'FEATURE' = 'FEATURE'
            'CRITICAL' = 'CRITICAL'
            'ENHANCED' = 'ENHANCED'
            'COMPLETED' = 'COMPLETED'
            'APPROVED' = 'APPROVED'
            'REJECTED' = 'REJECTED'
            'BUILD' = 'BUILD'
            'PACKAGE' = 'PACKAGE'
            'SECURE' = 'SECURE'
            'ORGANIZED' = 'ORGANIZED'
            'DEMO' = 'DEMO'
            'SYNC' = 'SYNC'
            'FAST' = 'FAST'
        }
        
        $filesScanned = 0
        $filesModified = 0
        $emojisReplaced = 0
    }
    
    process {
        try {
            # Get all files matching the specified types
            $allFiles = @()
            foreach ($fileType in $FileTypes) {
                $allFiles += Get-ChildItem -Path $Path -Filter $fileType -Recurse -File
            }
            
            Write-CustomLog "Scanning $($allFiles.Count) files for emojis..." -Level INFO
            
            foreach ($file in $allFiles) {
                $filesScanned++
                
                # Skip binary files and archives
                if ($file.Extension -in @('.exe', '.dll', '.zip', '.7z', '.tar', '.gz')) {
                    continue
                }
                
                try {
                    $content = Get-Content $file.FullName -Raw -Encoding UTF8
                    $fileModified = $false
                    
                    # Check for emojis using the pattern
                    if ($emojiPattern.IsMatch($content)) {
                        Write-CustomLog "Found emojis in: $($file.Name)" -Level WARN
                        
                        # Apply specific replacements first
                        foreach ($emoji in $emojiReplacements.Keys) {
                            if ($content.Contains($emoji)) {
                                $replacement = $emojiReplacements[$emoji]
                                $content = $content.Replace($emoji, $replacement)
                                $emojisReplaced++
                                $fileModified = $true
                                Write-CustomLog "  Replaced '$emoji' with '$replacement'" -Level INFO
                            }
                        }
                        
                        # Remove any remaining emojis with generic replacement
                        $remainingEmojis = $emojiPattern.Matches($content)
                        if ($remainingEmojis.Count -gt 0) {
                            foreach ($match in $remainingEmojis) {
                                $content = $content.Replace($match.Value, '[SYMBOL]')
                                $emojisReplaced++
                                $fileModified = $true
                                Write-CustomLog "  Replaced unknown emoji with '[SYMBOL]'" -Level INFO
                            }
                        }
                    }
                    
                    # Apply changes if any were made
                    if ($fileModified) {
                        $filesModified++
                        
                        if ($PSCmdlet.ShouldProcess($file.FullName, "Remove emojis")) {
                            if (-not $DryRun) {
                                # Create backup if requested
                                if ($CreateBackup) {
                                    $backupPath = "$($file.FullName).emoji-backup"
                                    Copy-Item $file.FullName $backupPath
                                    Write-CustomLog "  Created backup: $backupPath" -Level INFO
                                }
                                
                                # Write the cleaned content
                                Set-Content -Path $file.FullName -Value $content -Encoding UTF8
                                Write-CustomLog "  Updated file: $($file.Name)" -Level SUCCESS
                            } else {
                                Write-CustomLog "  [DRY RUN] Would update: $($file.Name)" -Level INFO
                            }
                        }
                    }
                }
                catch {
                    Write-CustomLog "Error processing file $($file.FullName): $($_.Exception.Message)" -Level ERROR
                }
            }
        }
        catch {
            Write-CustomLog "Error during emoji removal: $($_.Exception.Message)" -Level ERROR
            throw
        }
    }
    
    end {
        Write-CustomLog "=== Emoji Removal Summary ===" -Level INFO
        Write-CustomLog "Files scanned: $filesScanned" -Level INFO
        Write-CustomLog "Files modified: $filesModified" -Level SUCCESS
        Write-CustomLog "Emojis replaced: $emojisReplaced" -Level SUCCESS
        
        if ($DryRun) {
            Write-CustomLog "This was a dry run - no files were actually modified" -Level WARN
        }
        
        return @{
            FilesScanned = $filesScanned
            FilesModified = $filesModified
            EmojisReplaced = $emojisReplaced
            DryRun = $DryRun.IsPresent
        }
    }
}

# Execute if called directly
if ($MyInvocation.MyCommand.CommandType -eq 'Script') {
    Remove-ProjectEmojis -Path "c:\Users\alexa\OneDrive\Documents\0. wizzense\opentofu-lab-automation" -Verbose
}

