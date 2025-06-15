[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet("Markdown", "JSON", "Host")]
    [string]$OutputFormat = "Markdown",
    
    [Parameter()]
    [string]$OutputPath = "./reports/infrastructure-health",
    
    [Parameter()]
    [switch]$AutoFix,
    
    [Parameter()]
    [switch]$CleanupBackups,
    
    [Parameter()]
    [switch]$IgnoreArchive
)

$ErrorActionPreference = 'Stop'

# Set project root and import modules
$script:ProjectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)

# Import required modules
try {
    # Import-Module "/workspaces/opentofu-lab-automation/pwsh/modules/CodeFixer/"" -Force -ErrorAction Stop
    Import-Module "/workspaces/opentofu-lab-automation/pwsh/modules/CodeFixer/"" -Force -ErrorAction Stop
    # Import-Module "/workspaces/opentofu-lab-automation/pwsh/modules/LabRunner/"" -Force -ErrorAction Stop
    Import-Module "/workspaces/opentofu-lab-automation/pwsh/modules/LabRunner/"" -Force -ErrorAction Stop
    # Import-Module "/workspaces/opentofu-lab-automation/pwsh/modules/PatchManager/"" -Force -ErrorAction SilentlyContinue
    Import-Module "/workspaces/opentofu-lab-automation/pwsh/modules/PatchManager/"" -Force -ErrorAction SilentlyContinue
} catch {
    Write-Error "Failed to import required modules: $_"
    exit 1
}

# Initialize report data structure
$report = @{
    GeneratedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Summary = @{
        TotalFiles = 0
        FilesWithErrors = 0
        TotalErrors = 0
        CriticalErrors = 0
        FixableErrors = 0
        AutoFixAttempted = $false
        AutoFixSuccess = 0
        AutoFixFailed = 0
    }
    Categories = @{
        Syntax = @()
        ImportPaths = @()
        ModuleLoading = @()
        Configuration = @()
        ProjectStructure = @()
        DeprecatedFeatures = @()
        Workflows = @()
    }
    RecommendedFixes = @()
    AutoFixResults = @()
}

function Test-PowerShellSyntax {
    param([string]$FilePath)
    
    # Skip archived files
    if ($IgnoreArchive -and $FilePath -match '\\(archive|backups|deprecated)\\') {
        return @{
            HasErrors = $false
            Errors = @()
        }
    }
    
    try {
        $errors = @()
        $tokens = $null
        $null = [System.Management.Automation.Language.Parser]::ParseFile(
            $FilePath, 
            [ref]$tokens, 
            [ref]$errors
        )
        return @{
            HasErrors = ($errors.Count -gt 0)
            Errors = $errors
        }
    } catch {
        return @{
            HasErrors = $true
            Errors = @($_)
        }
    }
}

function Test-ImportPaths {
    param([string]$FilePath)
    
    # Skip archived files
    if ($IgnoreArchive -and $FilePath -match '\\(archive|backups|deprecated)\\') {
        return @{
            HasIssues = $false
            Issues = @()
        }
    }
    
    $content = Get-Content $FilePath -Raw
    $issues = @()
    
    # Check for legacy import paths
    if ($content -match 'Import-Module\s+"(?!/)') {
        $issues += "Non-absolute import paths detected"
    }
    
    # Check for deprecated module locations
    if ($content -match 'Import-Module.*?pwsh/modules') {
        $issues += "Deprecated module location reference found"
    }
    
    return @{
        HasIssues = ($issues.Count -gt 0)
        Issues = $issues
    }
}

function Test-ModuleLoading {
    param([string]$FilePath)
    
    $issues = @()
    $content = Get-Content $FilePath -Raw
    
    # Extract module imports
    $moduleImports = [regex]::Matches($content, 'Import-Module\s+"([^"]+)"')
    
    foreach ($import in $moduleImports) {
        $modulePath = $import.Groups[1].Value
        if (-not (Test-Path $modulePath)) {
            $issues += "Module not found: $modulePath"
        }
    }
    
    return @{
        HasIssues = ($issues.Count -gt 0)
        Issues = $issues
    }
}

function Get-ConfigurationIssues {
    $issues = @()
    
    # Check PROJECT-MANIFEST.json
    if (Test-Path "$ProjectRoot/PROJECT-MANIFEST.json") {
        try {
            $null = Get-Content "$ProjectRoot/PROJECT-MANIFEST.json" | ConvertFrom-Json
        } catch {
            $issues += @{
                File = "PROJECT-MANIFEST.json"
                Issue = "Invalid JSON format"
                IsCritical = $true
            }
        }
    } else {
        $issues += @{
            File = "PROJECT-MANIFEST.json"
            Issue = "File missing"
            IsCritical = $true
        }
    }
    
    # Check .vscode/tasks.json
    if (Test-Path "$ProjectRoot/.vscode/tasks.json") {
        try {
            $null = Get-Content "$ProjectRoot/.vscode/tasks.json" | ConvertFrom-Json
        } catch {
            $issues += @{
                File = ".vscode/tasks.json"
                Issue = "Invalid JSON format"
                IsCritical = $false
            }
        }
    }
    
    return $issues
}

function Test-ProjectStructure {
    $requiredDirs = @(
        "$ProjectRoot/pwsh/modules/CodeFixer",
        "$ProjectRoot/pwsh/modules/LabRunner",
        "$ProjectRoot/scripts/maintenance",
        "$ProjectRoot/tests",
        "$ProjectRoot/configs"
    )
    
    $issues = @()
    
    foreach ($dir in $requiredDirs) {
        if (-not (Test-Path $dir)) {
            $issues += @{
                Path = $dir
                Issue = "Required directory missing"
                IsCritical = $true
            }
        }
    }
    
    return $issues
}

function Test-DeprecatedFeatures {
    param([string]$FilePath)
    
    $issues = @()
    $content = Get-Content $FilePath -Raw
    
    # Check for deprecated module paths
    if ($content -match 'pwsh/modules/CodeFixer(?!CodeFixer|LabRunner)') {
        $issues += "Referenced deprecated module path"
    }
    
    # Check for old script patterns
    if ($content -match '\.\\scripts\\(?:maintenance|validation)\\') {
        $issues += "Using legacy script paths"
    }
    
    # Check for deprecated parameters
    if ($content -match '-Fix\s+ImportPaths') {
        $issues += "Using deprecated -Fix ImportPaths parameter"
    }
    
    return @{
        HasIssues = ($issues.Count -gt 0)
        Issues = $issues
    }
}

function Invoke-AutoFix {
    param(
        [Parameter(Mandatory)]
        [string]$FilePath,
        [Parameter(Mandatory)]
        [hashtable]$Issues
    )
    
    $results = @()
    $content = Get-Content $FilePath -Raw
    $modified = $false
    
    # Fix import paths
    if ($Issues.ImportPaths) {
        $newContent = $content -replace 'Import-Module\s+"(?!/)([^"]+)"', '

Import-Module "/$1"'
        if ($newContent -ne $content) {
            $content = $newContent
            $modified = $true
            $results += "Fixed import paths"
        }
    }
    
    # Fix deprecated module references
    if ($Issues.DeprecatedFeatures) {
        $newContent = $content -replace 'pwsh/modules/CodeFixer(?!CodeFixer|LabRunner)', 'pwsh/modules/CodeFixer'
        if ($newContent -ne $content) {
            $content = $newContent
            $modified = $true
            $results += "Fixed deprecated module references"
        }
    }
    
    if ($modified) {
        try {
            Set-Content -Path $FilePath -Value $content -Force
            return @{
                Success = $true
                Changes = $results
            }
        } catch {
            return @{
                Success = $false
                Error = $_.Exception.Message
            }
        }
    }
    
    return @{
        Success = $true
        Changes = @("No changes needed")
    }
}

function New-MarkdownReport {
    param($ReportData)
    
    $md = @"
# Infrastructure Health Report
Generated: $($ReportData.GeneratedAt)

## Summary
- Total Files Analyzed: $($ReportData.Summary.TotalFiles)
- Files With Errors: $($ReportData.Summary.FilesWithErrors)
- Total Errors: $($ReportData.Summary.TotalErrors)
- Critical Errors: $($ReportData.Summary.CriticalErrors)
- Fixable Errors: $($ReportData.Summary.FixableErrors)

## Issues by Category

### Syntax Issues
$(
    foreach ($issue in $ReportData.Categories.Syntax) {
        "- **$($issue.File)**:`n  - $($issue.Error)`n"
    }
)

### Import Path Issues
$(
    foreach ($issue in $ReportData.Categories.ImportPaths) {
        "- **$($issue.File)**:`n  - $($issue.Issue)`n"
    }
)

### Module Loading Issues
$(
    foreach ($issue in $ReportData.Categories.ModuleLoading) {
        "- **$($issue.File)**:`n  - $($issue.Issue)`n"
    }
)

### Configuration Issues
$(
    foreach ($issue in $ReportData.Categories.Configuration) {
        "- **$($issue.File)**: $($issue.Issue) $(if ($issue.IsCritical) {"⚠️ CRITICAL"})`n"
    }
)

### Project Structure Issues
$(
    foreach ($issue in $ReportData.Categories.ProjectStructure) {
        "- **$($issue.Path)**: $($issue.Issue) $(if ($issue.IsCritical) {"⚠️ CRITICAL"})`n"
    }
)

### Deprecated Features Issues
$(
    foreach ($issue in $ReportData.Categories.DeprecatedFeatures) {
        "- **$($issue.File)**:`n  - $($issue.Issue)`n"
    }
)

### Workflow Issues
$(
    foreach ($issue in $ReportData.Categories.Workflows) {
        "- **$($issue.File)**:`n  - $($issue.Issue)`n"
    }
)

## Recommended Fixes
$(
    foreach ($fix in $ReportData.RecommendedFixes) {
        "### $($fix.Category)`n$($fix.Description)`n\`\`\`powershell`n$($fix.Command)`n\`\`\``n"
    }
)

$(if ($ReportData.AutoFixResults.Count -gt 0) {
"## Auto-Fix Results
$(
    foreach ($result in $ReportData.AutoFixResults) {
        "- **$($result.File)**: $($result.Result)`n"
    }
)"
})

"@
    
    return $md
}

# Create output directory if it doesn't exist
if (-not (Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
}

# Paths to exclude from analysis
$script:ExcludePaths = @(
    '\\archive\\',
    '\\backups\\',
    '\\deprecated\\',
    '-backup-\d{8}-\d{6}\\',
    'broken-.*-backup-\d{8}-\d{6}\\'
)

function Remove-OldBackups {
    param(
        [int]$DaysToKeep = 7
    )
    
    Write-Host "Cleaning up old backup files..." -ForegroundColor Yellow
    $cutoffDate = (Get-Date).AddDays(-$DaysToKeep)
    
    # Find backup directories older than cutoff
    $oldBackups = Get-ChildItem -Path "$ProjectRoot" -Recurse -Directory |
        Where-Object { 
            $_.Name -match '(backup|broken).*\d{8}-\d{6}' -and
            $_.CreationTime -lt $cutoffDate 
        }
    
    foreach ($backup in $oldBackups) {
        try {
            Remove-Item -Path $backup.FullName -Recurse -Force
            Write-Host "Removed old backup: $($backup.Name)" -ForegroundColor Gray
        } catch {
            Write-Warning "Failed to remove backup $($backup.Name): $_"
        }
    }
}

# Get all PowerShell files excluding archives/backups
$psFiles = Get-ChildItem -Path $ProjectRoot -Recurse -Filter "*.ps1" | 
    Where-Object { 
        $file = $_.FullName
        -not ($script:ExcludePaths | Where-Object { $file -match $_ })
    } |
    Select-Object -ExpandProperty FullName

# Update report data
$report.Summary.TotalFiles = $psFiles.Count

# Analyze each file
foreach ($file in $psFiles) {
    # Test syntax
    $syntaxResult = Test-PowerShellSyntax -FilePath $file
    if ($syntaxResult.HasErrors) {
        $report.Summary.FilesWithErrors++
        $report.Summary.TotalErrors += $syntaxResult.Errors.Count
        
        foreach ($error in $syntaxResult.Errors) {
            $report.Categories.Syntax += @{
                File = $file
                Error = $error.Message
                Line = $error.Extent.StartLineNumber
            }
        }
    }
    
    # Test import paths
    $importResult = Test-ImportPaths -FilePath $file
    if ($importResult.HasIssues) {
        foreach ($issue in $importResult.Issues) {
            $report.Categories.ImportPaths += @{
                File = $file
                Issue = $issue
            }
        }
    }
    
    # Test module loading
    $moduleResult = Test-ModuleLoading -FilePath $file
    if ($moduleResult.HasIssues) {
        foreach ($issue in $moduleResult.Issues) {
            $report.Categories.ModuleLoading += @{
                File = $file
                Issue = $issue
            }
        }
    }
}

# Test configuration
$report.Categories.Configuration = Get-ConfigurationIssues

# Test project structure
$report.Categories.ProjectStructure = Test-ProjectStructure

# Analyze deprecated features
foreach ($file in $psFiles) {
    $deprecatedResult = Test-DeprecatedFeatures -FilePath $file
    if ($deprecatedResult.HasIssues) {
        foreach ($issue in $deprecatedResult.Issues) {
            $report.Categories.DeprecatedFeatures += @{
                File = $file
                Issue = $issue
            }
            $report.Summary.FixableErrors++
        }
    }
}

# Generate recommended fixes
if ($report.Categories.ImportPaths.Count -gt 0) {
    $report.RecommendedFixes += @{
        Category = "Import Path Fixes"
        Description = "Fix non-absolute and deprecated module import paths"
        Command = "./scripts/maintenance/fix-infrastructure-issues.ps1 -Fix ImportPaths -AutoFix"
    }
}

if ($report.Categories.Syntax.Count -gt 0) {
    $report.RecommendedFixes += @{
        Category = "Syntax Fixes"
        Description = "Fix PowerShell syntax errors"
        Command = "Invoke-PowerShellLint -Path . -AutoFix"
    }
}

# Calculate critical errors
$report.Summary.CriticalErrors = (
    $report.Categories.Configuration | 
    Where-Object { $_.IsCritical } | 
    Measure-Object
).Count + (
    $report.Categories.ProjectStructure | 
    Where-Object { $_.IsCritical } | 
    Measure-Object
).Count

# Calculate fixable errors
$report.Summary.FixableErrors = $report.Categories.ImportPaths.Count + $report.Categories.Syntax.Count

# Auto-fix if requested
if ($AutoFix) {
    $report.Summary.AutoFixAttempted = $true
    Write-Host "Applying automatic fixes..." -ForegroundColor Yellow
    
    foreach ($file in $psFiles) {
        $issues = @{
            ImportPaths = ($report.Categories.ImportPaths | Where-Object { $_.File -eq $file })
            DeprecatedFeatures = ($report.Categories.DeprecatedFeatures | Where-Object { $_.File -eq $file })
        }
        
        if ($issues.ImportPaths -or $issues.DeprecatedFeatures) {
            $fixResult = Invoke-AutoFix -FilePath $file -Issues $issues
            
            if ($fixResult.Success) {
                $report.Summary.AutoFixSuccess++
                $report.AutoFixResults += @{
                    File = $file
                    Result = "Fixed: $($fixResult.Changes -join ', ')"
                }
            } else {
                $report.Summary.AutoFixFailed++
                $report.AutoFixResults += @{
                    File = $file
                    Result = "Failed: $($fixResult.Error)"
                }
            }
        }
    }
}

# Generate output
$outputFile = Join-Path $OutputPath "infrastructure-health-report.md"

switch ($OutputFormat) {
    "Markdown" {
        $markdown = New-MarkdownReport -ReportData $report
        Set-Content -Path $outputFile -Value $markdown
        Write-Host "Report generated at: $outputFile" -ForegroundColor Green
    }
    "JSON" {
        $jsonFile = Join-Path $OutputPath "infrastructure-health-report.json"
        $report | ConvertTo-Json -Depth 10 | Set-Content $jsonFile
        Write-Host "JSON report generated at: $jsonFile" -ForegroundColor Green
    }
    "Host" {
        Write-Host "Infrastructure Health Report" -ForegroundColor Cyan
        Write-Host "Generated: $($report.GeneratedAt)" -ForegroundColor Cyan
        Write-Host "`nSummary:" -ForegroundColor Yellow
        Write-Host "- Total Files: $($report.Summary.TotalFiles)"
        Write-Host "- Files With Errors: $($report.Summary.FilesWithErrors)"
        Write-Host "- Total Errors: $($report.Summary.TotalErrors)"
        Write-Host "- Critical Errors: $($report.Summary.CriticalErrors)"
        Write-Host "- Fixable Errors: $($report.Summary.FixableErrors)"
        
        if ($report.Categories.Syntax.Count -gt 0) {
            Write-Host "`nSyntax Issues:" -ForegroundColor Red
            $report.Categories.Syntax | ForEach-Object {
                Write-Host "- $($_.File): $($_.Error)"
            }
        }
        
        if ($report.Categories.ImportPaths.Count -gt 0) {
            Write-Host "`nImport Path Issues:" -ForegroundColor Yellow
            $report.Categories.ImportPaths | ForEach-Object {
                Write-Host "- $($_.File): $($_.Issue)"
            }
        }
        
        if ($report.Categories.DeprecatedFeatures.Count -gt 0) {
            Write-Host "`nDeprecated Features Issues:" -ForegroundColor Magenta
            $report.Categories.DeprecatedFeatures | ForEach-Object {
                Write-Host "- $($_.File): $($_.Issue)"
            }
        }
        
        if ($report.Categories.Workflows.Count -gt 0) {
            Write-Host "`nWorkflow Issues:" -ForegroundColor Cyan
            $report.Categories.Workflows | ForEach-Object {
                Write-Host "- $($_.File): $($_.Issue)"
            }
        }
    }
}

function Test-WorkflowHealth {
    param(
        [string]$WorkflowPath = ".github/workflows",
        [switch]$AutoFix
    )
    
    # First try using the PatchManager module for comprehensive validation
    $patchManagerResults = Test-WorkflowsUsingPatchManager -WorkflowPath $WorkflowPath -AutoFix:$AutoFix
    
    if ($null -ne $patchManagerResults) {
        # PatchManager module was used successfully
        return $patchManagerResults.Issues
    }
    
    # Fall back to basic validation
    $issues = @()
    
    # Check workflow files exist
    $workflowFiles = Get-ChildItem -Path $WorkflowPath -Filter "*.yml" -ErrorAction SilentlyContinue
    
    if ($workflowFiles.Count -eq 0) {
        $issues += @{
            Category = "Missing Workflows"
            Issue = "No workflow files found in $WorkflowPath"
            IsCritical = $true
        }
        return $issues
    }
    
    foreach ($file in $workflowFiles) {
        try {
            # YAML syntax validation
            $content = Get-Content $file.FullName -Raw
            $null = ConvertFrom-Yaml $content
            
            # Check for required sections
            $yaml = ConvertFrom-Yaml $content
            if (-not $yaml.name) {
                $issues += @{
                    File = $file.Name
                    Category = "Workflow Structure"
                    Issue = "Missing workflow name"
                    IsCritical = $false
                }
            }
            
            if (-not $yaml.on) {
                $issues += @{
                    File = $file.Name
                    Category = "Workflow Structure"
                    Issue = "Missing trigger configuration"
                    IsCritical = $true
                }
            }
            
            if (-not $yaml.jobs) {
                $issues += @{
                    File = $file.Name
                    Category = "Workflow Structure"
                    Issue = "Missing jobs configuration"
                    IsCritical = $true
                }
            }
            
            # Check for common issues
            if ($content -match "uses:\s+actions/checkout@v1") {
                $issues += @{
                    File = $file.Name
                    Category = "Outdated Actions"
                    Issue = "Using outdated checkout action (v1)"
                    IsCritical = $false
                }
            }
            
        } catch {
            $issues += @{
                File = $file.Name
                Category = "YAML Syntax"
                Issue = $_.Exception.Message
                IsCritical = $true
            }
        }
    }
    
    return $issues
}

function Test-WorkflowsUsingPatchManager {
    param(
        [string]$WorkflowPath = "$script:ProjectRoot/.github/workflows",
        [switch]$AutoFix
    )
    
    $issues = @()
    
    # Try to use PatchManager's Invoke-YamlValidation if available
    if (Get-Command "Invoke-YamlValidation" -ErrorAction SilentlyContinue) {
        try {
            Write-Host "Using PatchManager for advanced YAML validation..." -ForegroundColor Cyan
            
            $mode = if ($AutoFix) { "Fix" } else { "Check" }
            $yamlResults = Invoke-YamlValidation -Path $WorkflowPath -Mode $mode -ProjectRoot $script:ProjectRoot
            
            # Process the results
            foreach ($error in $yamlResults.Errors) {
                $issues += @{
                    File = $error.File
                    Category = "YAML Syntax"
                    Issue = $error.Message
                    IsCritical = $true
                    Line = $error.Line
                    Column = $error.Column
                }
            }
            
            foreach ($warning in $yamlResults.Warnings) {
                $issues += @{
                    File = $warning.File
                    Category = "YAML Structure"
                    Issue = $warning.Message
                    IsCritical = $false
                    Line = $warning.Line
                    Column = $warning.Column
                }
            }
            
            return @{
                Issues = $issues
                TotalFiles = $yamlResults.TotalFiles
                ValidFiles = $yamlResults.ValidFiles
                InvalidFiles = $yamlResults.InvalidFiles
                FixedFiles = $yamlResults.FixedFiles
            }
        }
        catch {
            Write-Host "PatchManager YAML validation failed: $($_.Exception.Message)" -ForegroundColor Yellow
            Write-Host "Falling back to basic validation..." -ForegroundColor Yellow
            return $null  # Fall back to basic validation
        }
    }
    
    return $null  # Fall back to basic validation
}

# Update the checking workflow when analyzing infrastructure
$workflowIssues = Test-WorkflowHealth -AutoFix:$AutoFix
if ($workflowIssues.Count -gt 0) {
    $report.Categories.Workflows = $workflowIssues
    
    # Add workflow-related fixes
    $report.RecommendedFixes += @{
        Category = "GitHub Actions"
        Description = "Workflow issues detected"
        Command = "./scripts/maintenance/unified-maintenance.ps1 -Mode 'All' -AutoFix"
    }
}

# Advanced workflow analysis using PatchManager
if (Get-Command "Invoke-YamlValidation" -ErrorAction SilentlyContinue) {
    $patchManagerResults = Test-WorkflowsUsingPatchManager -WorkflowPath "$script:ProjectRoot/.github/workflows" -AutoFix:$AutoFix
    
    if ($null -ne $patchManagerResults) {
        $report.Summary.FilesWithErrors += $patchManagerResults.Issues.Count
        $report.Summary.TotalErrors += $patchManagerResults.Issues.Count
        $report.Categories.Workflows += $patchManagerResults.Issues
        
        if ($AutoFix) {
            $report.Summary.AutoFixSuccess += ($patchManagerResults.FixedFiles)
            $report.Summary.AutoFixFailed += ($patchManagerResults.InvalidFiles)
        }
    }
}




