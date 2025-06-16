#Requires -Version 7.0

<#
.SYNOPSIS
    Cross-Platform Path Standardization and Hardcoded Path Elimination
    
.DESCRIPTION
    Detects and fixes all hardcoded Windows paths, making the project truly cross-platform.
    Integrates emoji removal, Unicode regex fixes, and comprehensive project cleanup.
    
.PARAMETER TargetPath
    Root directory to scan for hardcoded paths (defaults to current directory)
    
.PARAMETER FixMode
    Standard: Fix common patterns
    Aggressive: Fix all detected patterns including complex ones
    Verify: Show what would be fixed without making changes
    
.PARAMETER BackupFiles
    Create backups before fixing files
    
.PARAMETER IncludeReports
    Also fix hardcoded paths in report files (usually not needed)
    
.EXAMPLE
    Invoke-CrossPlatformPathFixer -FixMode "Aggressive" -BackupFiles
    
.NOTES
    This function addresses the critical cross-platform compatibility issues
    by eliminating hardcoded Windows paths and standardizing all imports.
#>

function Invoke-CrossPlatformPathFixer {
    CmdletBinding()
    param(
        Parameter(Mandatory = $false)
        string$TargetPath = (Get-Location).Path,
        
        Parameter(Mandatory = $false)
        ValidateSet("Standard", "Aggressive", "Verify")
        string$FixMode = "Standard",
        
        Parameter(Mandatory = $false)
        switch$BackupFiles,
        
        Parameter(Mandatory = $false)
        switch$IncludeReports
    )
    
    begin {
        Write-Host "Starting Cross-Platform Path Standardization..." -ForegroundColor Cyan
        $fixedFiles = @()
        $errors = @()

        # Cross-platform path patterns to fix
        $pathPatterns = @{
            # Windows hardcoded paths
            'WindowsSpecific' = @(
                $Env:PROJECT_ROOT,  # Use environment variable for project root
                '/pwsh/modules',    # Use relative paths for modules
                '/workspaces/opentofu-lab-automation'  # Standardized workspace path
            )

            # Malformed import patterns
            'MalformedImports' = @(
                'Import-Module "$Env:PROJECT_ROOT/pwsh/modules/(^/+)/"',
                'Import-Module "$Env:PROJECT_ROOT/pwsh/modules/(^/+)/" -Force'
            )

            # Unicode regex patterns (emoji detection issues)
            'UnicodeRegex' = @(
                '\u{(0-9A-Fa-f{1,3})}',  # Invalid short Unicode
                '\\u{^}*}\'          # Invalid Unicode character classes
            )
        }

        # Replacement patterns
        $replacements = @{
            # Standard project root replacements
            'ProjectRoot' = $Env:PROJECT_ROOT
            'ModulePath' = '/pwsh/modules'

            # Fixed Unicode patterns for emoji detection (PowerShell 7+ compatible)
            'EmojiRegex' = '\uD83C-\uDBFF\uDC00-\uDFFF\u2600-\u27BF\uD83C\uDF00-\uDFFF\uD83D\uDC00-\uDE4F\uD83D\uDE80-\uDEFF'
        }
    }
    
    process {
        try {
            Write-Host "Scanning for hardcoded paths in: $TargetPath" -ForegroundColor Yellow
            
            # Get all PowerShell, JSON, and Markdown files
            $fileExtensions = @('*.ps1', '*.psm1', '*.psd1', '*.json', '*.md', '*.yml', '*.yaml')
              if (-not $IncludeReports) {
                # Exclude report directories from fixing
                $excludePaths = @('reports/*', 'logs/*', 'backups/*', 'archive/*', '*.backup*')
            } else {
                $excludePaths = @('backups/*', '*.backup*')
            }
            
            $allFiles = @()
            foreach ($ext in $fileExtensions) {
                $files = Get-ChildItem -Path $TargetPath -Recurse -Include $ext -File | Where-Object{ 
                             $exclude = $false
                             foreach ($excludePath in $excludePaths) {
                                 if ($_.FullName -like "*$excludePath*") {
                                     $exclude = $true
                                     break
                                 }
                             }
                             -not $exclude
                         }
                $allFiles += $files
            }
            
            Write-Host "Found $($allFiles.Count) files to analyze" -ForegroundColor Green
            
            foreach ($file in $allFiles) {
                try {
                    $content = Get-Content -Path $file.FullName -Raw -ErrorAction Stop
                    $originalContent = $content
                    $modified = $false
                    
                    if (string::IsNullOrEmpty($content)) {
                        continue
                    }
                    
                    Write-Verbose "Processing: $($file.FullName)"
                    
                    # Fix 1: Windows hardcoded paths
                    foreach ($pattern in $pathPatterns.WindowsSpecific) {
                        if ($content -match regex::Escape($pattern)) {
                            Write-Host "  Fixing hardcoded path in: $($file.Name)" -ForegroundColor Yellow
                            $content = $content -replace regex::Escape($pattern), $replacements.ProjectRoot
                            $modified = $true
                        }
                    }
                    
                    # Fix 2: Malformed Import-Module statements
                    # Fix the broken concatenated import statements
                    $content = $content -replace 'Import-Module "/C:\\Users\\alexa^"*" -ForceImport-Module "/C:\\Users\\alexa^"*" -Force\}', ''
                    $content = $content -replace 'Import-Module "/C:\\Users\\alexa^"*" -ForceImport-Module', 'Import-Module'
                    
                    # Fix standard malformed imports
                    $content = $content -replace '"/C:\\Users\\alexa\\OneDrive\\Documents\\0\. wizzense\\opentofu-lab-automation\\pwsh/modules/(^/+)/"', '"/pwsh/modules/$1/"'
                    $content = $content -replace '"/C:\\Users\\alexa\\OneDrive\\Documents\\0\. wizzense\\opentofu-lab-automation/pwsh/modules/(^/+)/"', '"/pwsh/modules/$1/"'
                    $content = $content -replace '/C:\\Users\\alexa\\OneDrive\\Documents\\0\. wizzense\\opentofu-lab-automation\\pwsh', '/pwsh'
                    
                    if ($content -ne $originalContent) {
                        $modified = $true
                    }
                    
                    # Fix 3: Unicode regex patterns (emoji issues)
                    if ($content -match '\\u\{0-9A-Fa-f{1,3}\}') {
                        Write-Host "  Fixing Unicode regex in: $($file.Name)" -ForegroundColor Yellow
                        # Replace invalid Unicode patterns with working PowerShell 7+ emoji regex
                        $content = $content -replace '\\\\u\{1F600\}-\\\u\{1F64F\}\\\\\\u\{1F300\}-\\\u\{1F5FF\}\\\\\\u\{1F680\}-\\\u\{1F6FF\}\\\\\\u\{1F1E0\}-\\\u\{1F1FF\}\\\\\\u\{2600\}-\\\u\{26FF\}\\\\\\u\{2700\}-\\\u\{27BF\}\', $replacements.EmojiRegex
                        $modified = $true
                    }
                    
                    # Fix 4: Fix broken test file BeforeAll blocks
                    if ($file.Extension -eq '.ps1' -and $file.Name -like '*.Tests.ps1') {
                        # Fix the malformed BeforeAll blocks in test files
                        $content = $content -replace 'BeforeAll \{\s*Import-Module^}*\}', @'
BeforeAll {
        Import-Module "/pwsh/modules/LabRunner/" -Force
        Import-Module "/pwsh/modules/CodeFixer/" -Force
    }
'@
                        if ($content -ne $originalContent) {
                            $modified = $true
                        }
                    }
                    
                    # Fix 5: Standardize all relative paths to use forward slashes
                    if ($FixMode -eq "Aggressive") {
                        # Convert Windows-style paths to Unix-style for cross-platform compatibility
                        $content = $content -replace '\\\\', '/'
                        $content = $content -replace '(^")\\\(^\\)', '$1/$2'  # Convert single backslashes
                        
                        if ($content -ne $originalContent) {
                            $modified = $true
                        }
                    }
                    
                    # Apply fixes if any were made
                    if ($modified) {
                        if ($FixMode -eq "Verify") {
                            Write-Host "  WOULD FIX: $($file.FullName)" -ForegroundColor Cyan
                        } else {
                            # Create backup if requested
                            if ($BackupFiles) {
                                $backupPath = "$($file.FullName).backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
                                Copy-Item -Path $file.FullName -Destination $backupPath -Force
                                Write-Verbose "  Created backup: $backupPath"
                            }
                            
                            # Write the fixed content
                            Set-Content -Path $file.FullName -Value $content -NoNewline -Force
                            $fixedFiles += $file.FullName
                            Write-Host "  FIXED: $($file.Name)" -ForegroundColor Green
                        }
                    }
                    
                } catch {
                    $errorMsg = "Error processing $($file.FullName): $($_.Exception.Message)"
                    $errors += $errorMsg
                    Write-Warning $errorMsg
                }
            }
            
        } catch {
            throw "Cross-platform path fixing failed: $($_.Exception.Message)"
        }
    }
    
    end {
        # Summary report
        Write-Host "`nCross-Platform Path Fixing Complete!" -ForegroundColor Green
        Write-Host "Fixed Files: $($fixedFiles.Count)" -ForegroundColor Cyan
        Write-Host "Errors: $($errors.Count)" -ForegroundColor $(if ($errors.Count -gt 0) { 'Red' } else { 'Green' })
        
        if ($fixedFiles.Count -gt 0) {
            Write-Host "`nFixed Files:" -ForegroundColor Yellow
            fixedFiles | ForEach-Object{ Write-Host "  $_" -ForegroundColor White }
        }
        
        if ($errors.Count -gt 0) {
            Write-Host "`nErrors:" -ForegroundColor Red
            errors | ForEach-Object{ Write-Host "  $_" -ForegroundColor White }
        }
        
        return @{
            FixedFiles = $fixedFiles
            Errors = $errors
            Success = $errors.Count -eq 0
        }
    }
}

# Export the function if this file is being imported as a module
if ($MyInvocation.InvocationName -ne '.') {
    Export-ModuleMember -Function Invoke-CrossPlatformPathFixer
}


