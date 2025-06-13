<#
.SYNOPSIS
Detects and fixes PowerShell import/module issues throughout the project

.DESCRIPTION
This function scans PowerShell files to identify:
- Missing module imports
- Incorrect import paths
- Outdated LabRunner paths (lab_utils -> modules)
- Missing dependencies

.PARAMETER Path
Root path to scan for PowerShell files (default: current directory)

.PARAMETER AutoFix
Automatically apply fixes where possible

.PARAMETER OutputFormat
Output format: Text (console), JSON, or CI (for pipelines)

.EXAMPLE
Invoke-ImportAnalysis

.EXAMPLE
Invoke-ImportAnalysis -Path "/scripts" -AutoFix -OutputFormat JSON
#>
function Invoke-ImportAnalysis {
    [CmdletBinding()]
    param(
        [string]$Path = ".",
        [switch]$AutoFix,
        [ValidateSet('Text', 'JSON', 'CI')]
        [string]$OutputFormat = 'Text',
        [switch]$PassThru
    )
    
    $ErrorActionPreference = "Continue"
    
    Write-Host "🔍 Analyzing PowerShell imports and dependencies..." -ForegroundColor Cyan
    
    # Define known import patterns and their fixes
    $importPatterns = @{
        # LabRunner path migrations
        'pwsh[\\/]lab_utils[\\/]LabRunner' = 'pwsh/modules/LabRunner'
        'pwsh[\\/]lab_utils[\\/]Get-LabConfig\.ps1' = 'pwsh/modules/LabRunner/Get-LabConfig.ps1'
        'pwsh[\\/]lab_utils[\\/]Get-Platform\.ps1' = 'pwsh/modules/LabRunner/Get-Platform.ps1'
        'pwsh[\\/]lab_utils[\\/]Hypervisor\.psm1' = 'pwsh/modules/LabRunner/Hypervisor.psm1'
        
        # Common missing imports
        'Invoke-ScriptAnalyzer' = 'PSScriptAnalyzer'
        'Invoke-Pester' = 'Pester'
        'ConvertTo-Json|ConvertFrom-Json' = 'Microsoft.PowerShell.Utility'
    }
    
    # Find all PowerShell files
    $powerShellFiles = Get-ChildItem -Path $Path -Recurse -Include "*.ps1", "*.psm1", "*.psd1" -File
    
    if ($powerShellFiles.Count -eq 0) {
        Write-Host "No PowerShell files found in $Path" -ForegroundColor Yellow
        return
    }
    
    Write-Host "Found $($powerShellFiles.Count) PowerShell files to analyze" -ForegroundColor Green
    
    $allIssues = @()
    $fixedCount = 0
    
    foreach ($file in $powerShellFiles) {
        Write-Host "  📄 Analyzing: $($file.Name)" -ForegroundColor Gray
        
        try {
            $content = Get-Content -Path $file.FullName -Raw -ErrorAction SilentlyContinue
            if (-not $content) { continue }
            
            $originalContent = $content
            $fileIssues = @()
            
            # Check for outdated LabRunner paths
            if ($content -match "lab_utils") {
                $fileIssues += [PSCustomObject]@{
                    File = $file.FullName
                    Line = 0
                    Type = 'OutdatedPath'
                    Issue = 'Uses deprecated lab_utils path'
                    Suggestion = 'Update to pwsh/modules/LabRunner'
                    Severity = 'Warning'
                    AutoFixable = $true
                }
                
                if ($AutoFix) {
                    foreach ($pattern in $importPatterns.Keys) {
                        if ($pattern -like "*lab_utils*") {
                            $content = $content -replace $pattern, $importPatterns[$pattern]
                        }
                    }
                }
            }
            
            # Check for missing module imports
            $missingImports = @()
            
            # Check for PSScriptAnalyzer usage without import
            if ($content -match "Invoke-ScriptAnalyzer" -and $content -notmatch "Import-Module.*PSScriptAnalyzer") {
                $missingImports += "PSScriptAnalyzer"
                $fileIssues += [PSCustomObject]@{
                    File = $file.FullName
                    Line = 0
                    Type = 'MissingImport'
                    Issue = 'Uses Invoke-ScriptAnalyzer without importing PSScriptAnalyzer'
                    Suggestion = 'Add: Import-Module PSScriptAnalyzer -Force'
                    Severity = 'Error'
                    AutoFixable = $true
                }
            }
            
            # Check for Pester usage without import
            if ($content -match "Describe|It|BeforeAll|AfterAll|Should" -and $content -notmatch "Import-Module.*Pester") {
                $missingImports += "Pester"
                $fileIssues += [PSCustomObject]@{
                    File = $file.FullName
                    Line = 0
                    Type = 'MissingImport'
                    Issue = 'Uses Pester commands without importing Pester'
                    Suggestion = 'Add: '
                    Severity = 'Warning'
                    AutoFixable = $true
                }
            }
            
            # Check for LabRunner usage without import
            if ($content -match "InModuleScope.*LabRunner" -and $content -notmatch "Import-Module.*LabRunner") {
                $fileIssues += [PSCustomObject]@{
                    File = $file.FullName
                    Line = 0
                    Type = 'MissingImport'
                    Issue = 'Uses LabRunner InModuleScope without importing LabRunner'
                    Suggestion = 'Add: Import-Module LabRunner -Force'
                    Severity = 'Error'
                    AutoFixable = $true
                }
            }
            
            # Auto-fix missing imports
            if ($AutoFix -and $missingImports.Count -gt 0) {
                $importStatements = ""
                foreach ($module in $missingImports) {
                    switch ($module) {
                        "PSScriptAnalyzer" {
                            $importStatements += "`n# Auto-added import for PSScriptAnalyzer`nif (-not (Get-Module -ListAvailable PSScriptAnalyzer -ErrorAction SilentlyContinue)) { Install-Module PSScriptAnalyzer -Force -Scope CurrentUser }`nImport-Module PSScriptAnalyzer -Force`n"
                        }
                        "Pester" {
                            $importStatements += "`n`n`n"
                        }
                    }
                }
                
                # Add imports at the top of the file (after param block if exists)
                if ($content -match "param\s*\(") {
                    $content = $content -replace "(param\s*\([^)]*\)\s*)", "`$1$importStatements"
                } else {
                    $content = $importStatements + $content
                }
            }
            
            # Apply fixes if content changed
            if ($AutoFix -and $content -ne $originalContent) {
                try {
                    Set-Content -Path $file.FullName -Value $content -Encoding UTF8
                    $fixedCount++
                    Write-Host "    ✅ Auto-fixed import issues" -ForegroundColor Green
                } catch {
                    Write-Warning "Failed to apply fixes to $($file.FullName): $($_.Exception.Message)"
                }
            }
            
            $allIssues += $fileIssues
            
        } catch {
            Write-Warning "Failed to analyze $($file.FullName): $($_.Exception.Message)"
        }
    }
    
    # Output results
    switch ($OutputFormat) {
        'JSON' {
            $result = @{
                Issues = $allIssues
                Summary = @{
                    TotalFiles = $powerShellFiles.Count
                    FilesWithIssues = ($allIssues | Group-Object File).Count
                    TotalIssues = $allIssues.Count
                    FixedFiles = $fixedCount
                }
            }
            $result | ConvertTo-Json -Depth 3
        }
        'CI' {
            foreach ($issue in $allIssues) {
                $level = switch ($issue.Severity) {
                    'Error' { 'error' }
                    'Warning' { 'warning' }
                    default { 'notice' }
                }
                Write-Host "::$level file=$($issue.File),line=$($issue.Line)::[$($issue.Type)] $($issue.Issue)"
            }
        }
        default {
            if ($allIssues.Count -eq 0) {
                Write-Host "✅ No import issues found!" -ForegroundColor Green
            } else {
                Write-Host "`n📋 Import Analysis Results:" -ForegroundColor Cyan
                Write-Host "=============================" -ForegroundColor Cyan
                
                $groupedIssues = $allIssues | Group-Object File
                foreach ($group in $groupedIssues) {
                    Write-Host "`n📄 $($group.Name)" -ForegroundColor Yellow
                    Write-Host ("-" * 50) -ForegroundColor Gray
                    
                    foreach ($issue in $group.Group) {
                        $color = switch ($issue.Severity) {
                            'Error' { 'Red' }
                            'Warning' { 'Yellow' }
                            default { 'Cyan' }
                        }
                        Write-Host "  [$($issue.Type)] $($issue.Issue)" -ForegroundColor $color
                        Write-Host "    💡 Fix: $($issue.Suggestion)" -ForegroundColor Green
                    }
                }
                
                # Summary
                $errorCount = ($allIssues | Where-Object Severity -eq 'Error').Count
                $warningCount = ($allIssues | Where-Object Severity -eq 'Warning').Count
                
                Write-Host "`n📊 Summary:" -ForegroundColor Cyan
                Write-Host "==========" -ForegroundColor Cyan
                Write-Host "Files scanned: $($powerShellFiles.Count)" -ForegroundColor White
                Write-Host "Files with issues: $(($allIssues | Group-Object File).Count)" -ForegroundColor Yellow
                Write-Host "Import errors: $errorCount" -ForegroundColor $$(if (errorCount -gt 0) { 'Red' } else { 'Green' })
                Write-Host "Import warnings: $warningCount" -ForegroundColor $$(if (warningCount -gt 0) { 'Yellow' } else { 'Green' })
                
                if ($AutoFix) {
                    Write-Host "Files auto-fixed: $fixedCount" -ForegroundColor Green
                }
            }
        }
    }
    
    if ($PassThru) {
        return $allIssues
    }
}
