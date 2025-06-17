#!/usr/bin/env pwsh
# Ensure environment variables are set for admin-friendly module discovery
if (-not $env:PWSH_MODULES_PATH) {
    $env:PWSH_MODULES_PATH = Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) "src/pwsh/modules"
}
<#
.SYNOPSIS
    Comprehensive emoji removal script for scientific, professional output.

.DESCRIPTION
    Removes all emojis and emoji-like content from PowerShell and Python files,
    replacing them with professional alternatives for scientific documentation.

.PARAMETER Path
    Path to scan for files (default: current directory)

.PARAMETER Recurse
    Recursively scan subdirectories

.PARAMETER WhatIf
    Show what would be changed without making changes

.PARAMETER BackupOriginal
    Create .bak files before making changes

.EXAMPLE
    .\Remove-Emojis.ps1 -Recurse
    Remove all emojis from current directory and subdirectories

.EXAMPLE
    .\Remove-Emojis.ps1 -Path "src/" -WhatIf
    Preview changes that would be made in src directory
#>

param(
    [string]$Path = $PSScriptRoot,
    
    [switch]$Recurse = $true,
    
    [switch]$WhatIf,
    
    [switch]$BackupOriginal
)

# Import existing logging
$loggingModule = Join-Path $env:PWSH_MODULES_PATH "LabRunner/Logger.ps1"
if (Test-Path $loggingModule) {
    . $loggingModule
} else {
    function Write-CustomLog { param($Message, $Level = 'INFO') Write-Host "[$Level] $Message" }
}

Write-CustomLog "Starting comprehensive emoji removal for scientific output" -Level INFO
Write-CustomLog "Target path: $Path" -Level INFO
Write-CustomLog "Recursive: $Recurse" -Level INFO
Write-CustomLog "What-if mode: $WhatIf" -Level INFO

# Professional replacements for common emojis and emoji-like content
$emojiReplacements = @{
    # Success/Failure indicators
    'PASS' = 'PASS'
    'FAIL' = 'FAIL'
    'WARNING' = 'WARNING'
    '[SYMBOL]' = 'ERROR'
    '[SYMBOL]' = 'SUCCESS'
    '[SYMBOL]' = 'WARNING'
    '[SYMBOL]' = 'INFO'
    
    # Process indicators
    'DEPLOY' = 'EXECUTING'
    '⏳' = 'PROCESSING'
    '[SYMBOL]' = 'COMPLETED'
    'COMPLETED' = 'SUCCESS'
    '[SYMBOL]' = 'FAILED'
    'TOOL' = 'CONFIGURING'
    '[SYMBOL]️' = 'SETTINGS'
    'LIST' = 'CHECKLIST'
    'REPORT' = 'ANALYSIS'
    '[SYMBOL]' = 'PYTHON'
    'SYSTEM' = 'SYSTEM'
    '[SYMBOL]' = 'DIRECTORY'
    '[SYMBOL]' = 'FILE'
    'SEARCH' = 'SEARCHING'
    '[SYMBOL]' = 'LINKED'
    'NOTE' = 'NOTES'
    'TIP' = 'TIP'
    'STAR' = 'IMPORTANT'
    'TARGET' = 'TARGET'
    'SYNC' = 'REFRESH'
    '⬇️' = 'DOWNLOAD'
    '⬆️' = 'UPLOAD'
    '▶️' = 'START'
    '⏸️' = 'PAUSE'
    '⏹️' = 'STOP'
    '[SYMBOL]' = 'FINISH'
    
    # Text-based emoji patterns
    ':white_check_mark:' = 'PASS'
    ':x:' = 'FAIL'
    ':warning:' = 'WARNING'
    ':rocket:' = 'EXECUTING'
    ':sparkles:' = 'COMPLETED'
    ':tada:' = 'SUCCESS'
    ':boom:' = 'FAILED'
    ':wrench:' = 'CONFIGURING'
    ':gear:' = 'SETTINGS'
    ':clipboard:' = 'CHECKLIST'
    ':bar_chart:' = 'ANALYSIS'
    ':snake:' = 'PYTHON'
    ':computer:' = 'SYSTEM'
    ':file_folder:' = 'DIRECTORY'
    ':page_facing_up:' = 'FILE'
    ':mag:' = 'SEARCHING'
    ':link:' = 'LINKED'
    ':memo:' = 'NOTES'
    ':bulb:' = 'TIP'
    ':star:' = 'IMPORTANT'
    ':dart:' = 'TARGET'
      # Emoticons and other emoji-like content
    ':-\)' = ''
    ':\)' = ''
    ':-\(' = ''
    ':\(' = ''
    ':D' = ''
    ';-\)' = ''
    ';\)' = ''    ':-P' = ''
    ':o' = ''
    ':O' = ''
    ':-o' = ''
    ':-O' = ''
    
    # Common emoji expressions in comments
    'YAY!' = 'SUCCESS'
    'BOOM!' = 'EXECUTED'
    'TADA!' = 'COMPLETED'
    'WOO!' = 'SUCCESS'
    'WOOHOO!' = 'SUCCESS'
}

# Unicode emoji ranges to remove
$unicodeEmojiPatterns = @(
    # Emoticons
    '[\u{1F600}-\u{1F64F}]',
    # Miscellaneous Symbols and Pictographs  
    '[\u{1F300}-\u{1F5FF}]',
    # Transport and Map Symbols
    '[\u{1F680}-\u{1F6FF}]',
    # Miscellaneous Symbols
    '[\u{2600}-\u{26FF}]',
    # Dingbats
    '[\u{2700}-\u{27BF}]',
    # Supplemental Symbols and Pictographs
    '[\u{1F900}-\u{1F9FF}]',
    # Symbols and Pictographs Extended-A
    '[\u{1FA70}-\u{1FAFF}]'
)

# Get target files
$fileExtensions = @('*.ps1', '*.psm1', '*.psd1', '*.py', '*.md', '*.txt', '*.json')
$excludePatterns = @('\.git', '\.venv', '__pycache__', 'node_modules', '\.pytest_cache', '\.coverage')

$getChildItemParams = @{
    Path = $Path
    Include = $fileExtensions
}

if ($Recurse) {
    $getChildItemParams.Recurse = $true
}

$allFiles = Get-ChildItem @getChildItemParams | Where-Object {
    $file = $_
    $shouldExclude = $false
    foreach ($pattern in $excludePatterns) {
        if ($file.FullName -match $pattern) {
            $shouldExclude = $true
            break
        }
    }
    -not $shouldExclude
}

Write-CustomLog "Found $($allFiles.Count) files to process" -Level INFO

$statistics = @{
    FilesProcessed = 0
    FilesModified = 0
    EmojisRemoved = 0
    EmojiTypesFound = @{}
}

foreach ($file in $allFiles) {
    Write-CustomLog "Processing: $($file.FullName.Replace($PSScriptRoot, '').TrimStart('\', '/'))" -Level INFO
    
    try {
        $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8
        $originalContent = $content
        $fileModified = $false
        
        # Apply text-based emoji replacements
        foreach ($emoji in $emojiReplacements.Keys) {
            if ($content -match [regex]::Escape($emoji)) {
                $replacement = $emojiReplacements[$emoji]
                $oldContent = $content
                $content = $content -replace [regex]::Escape($emoji), $replacement
                
                if ($content -ne $oldContent) {
                    $fileModified = $true
                    $matchCount = ([regex]::Matches($oldContent, [regex]::Escape($emoji))).Count
                    $statistics.EmojisRemoved += $matchCount
                    
                    if (-not $statistics.EmojiTypesFound.ContainsKey($emoji)) {
                        $statistics.EmojiTypesFound[$emoji] = 0
                    }
                    $statistics.EmojiTypesFound[$emoji] += $matchCount
                    
                    Write-CustomLog "  Replaced $matchCount instances of '$emoji' with '$replacement'" -Level INFO
                }
            }
        }
        
        # Remove Unicode emojis
        foreach ($pattern in $unicodeEmojiPatterns) {
            $matches = [regex]::Matches($content, $pattern)
            if ($matches.Count -gt 0) {
                $content = $content -replace $pattern, ''
                $fileModified = $true
                $statistics.EmojisRemoved += $matches.Count
                
                foreach ($match in $matches) {
                    $emojiChar = $match.Value
                    if (-not $statistics.EmojiTypesFound.ContainsKey($emojiChar)) {
                        $statistics.EmojiTypesFound[$emojiChar] = 0
                    }
                    $statistics.EmojiTypesFound[$emojiChar]++
                }
                
                Write-CustomLog "  Removed $($matches.Count) Unicode emoji characters" -Level INFO
            }
        }
        
        # Clean up extra whitespace that might be left behind
        if ($fileModified) {
            # Remove multiple consecutive spaces (but preserve indentation)
            $content = $content -replace '(?<!^)  +', ' '
            # Remove trailing spaces
            $content = $content -replace ' +$', ''
            # Remove multiple consecutive empty lines
            $content = $content -replace '\n\n\n+', "`n`n"
        }
        
        # Save changes if modifications were made
        if ($fileModified) {
            $statistics.FilesModified++
            
            if ($WhatIf) {
                Write-CustomLog "  [WHAT-IF] Would modify file: $($file.FullName)" -Level INFO
            } else {
                # Create backup if requested
                if ($BackupOriginal) {
                    $backupPath = "$($file.FullName).bak"
                    Copy-Item -Path $file.FullName -Destination $backupPath -Force
                    Write-CustomLog "  Created backup: $backupPath" -Level INFO
                }
                
                # Write modified content
                $content | Out-File -FilePath $file.FullName -Encoding UTF8 -NoNewline
                Write-CustomLog "  Modified file successfully" -Level INFO
            }
        }
        
        $statistics.FilesProcessed++
        
    } catch {
        Write-CustomLog "  Error processing file: $_" -Level ERROR
    }
}

# Generate summary report
Write-CustomLog "Emoji removal completed" -Level INFO
Write-CustomLog "Files processed: $($statistics.FilesProcessed)" -Level INFO
Write-CustomLog "Files modified: $($statistics.FilesModified)" -Level INFO
Write-CustomLog "Total emojis removed: $($statistics.EmojisRemoved)" -Level INFO

if ($statistics.EmojiTypesFound.Count -gt 0) {
    Write-CustomLog "Emoji types found and processed:" -Level INFO
    $sortedEmojis = $statistics.EmojiTypesFound.GetEnumerator() | Sort-Object Value -Descending
    foreach ($emojiType in $sortedEmojis) {
        $emoji = $emojiType.Key
        $count = $emojiType.Value
        $replacement = if ($emojiReplacements.ContainsKey($emoji)) { " -> $($emojiReplacements[$emoji])" } else { " [removed]" }
        Write-CustomLog "  '$emoji': $count occurrences$replacement" -Level INFO
    }
}

if ($WhatIf) {
    Write-CustomLog "What-if mode completed. No files were actually modified." -Level INFO
} else {
    Write-CustomLog "All files have been processed and emojis removed for professional, scientific output." -Level INFO
}

# Create summary report file
$reportPath = Join-Path $PSScriptRoot "emoji-removal-report.txt"
$reportContent = @"
Emoji Removal Report
Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

Summary:
- Files Processed: $($statistics.FilesProcessed)
- Files Modified: $($statistics.FilesModified)
- Total Emojis Removed: $($statistics.EmojisRemoved)
- What-if Mode: $WhatIf

Emoji Types Processed:
$($sortedEmojis | ForEach-Object { "  '$($_.Key)': $($_.Value) occurrences" } | Out-String)

Processing completed successfully.
All output is now professional and scientific without emoji content.
"@

$reportContent | Out-File -FilePath $reportPath -Encoding UTF8
Write-CustomLog "Detailed report saved to: $reportPath" -Level INFO

