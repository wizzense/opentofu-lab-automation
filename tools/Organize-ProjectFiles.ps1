#!/usr/bin/env pwsh
# Smart file organization system with automatic tagging and sorting

param(
    [switch]$WhatIf,
    [switch]$Force,
    [string]$ConfigFile = "file-organization-rules.json"
)

$ErrorActionPreference = 'Stop'

# File organization rules with smart tagging
$organizationRules = @{
    # Documentation files
    "docs" = @{
        patterns = @("*.md", "CHANGELOG.*", "CONTRIBUTING.*", "LICENSE*", "README.*")
        exceptions = @("README.md")  # Keep main README in root
        description = "Documentation and markdown files"
    }
    
    # Archive/Historical
    "archive/legacy" = @{
        patterns = @("fix_*.ps1", "test-*.py", "test-*.ps1", "*-fixes.py")
        description = "Legacy fix scripts and historical files"
    }
    
    # Test Results/Reports  
    "reports" = @{
        patterns = @("TestResults_*.xml", "*-report.json", "workflow-*.json", "coverage/*")
        description = "Test results and generated reports"
    }
    
    # Configuration
    "configs/project" = @{
        patterns = @("*.toml", "mkdocs.yml", "path-index.yaml", "*.psd1")
        exceptions = @("tests/PesterConfiguration.psd1")
        description = "Project configuration files"
    }
    
    # Infrastructure as Code
    "infrastructure" = @{
        patterns = @("*.tf", "*.tfvars", "*.hcl")
        description = "Terraform and infrastructure files"
    }
    
    # Temporary/Unknown
    "temp" = @{
        patterns = @("a", "tmp_*", "temp_*", "*_temp.*")
        description = "Temporary files and unknowns"
    }
}

function Get-FileTag {
    param($FilePath, $FileName)
    
    # Smart tagging based on content and patterns
    $tags = @()
    
    # Pattern-based tagging
    switch -Regex ($FileName) {
        '^fix_.*\.ps1$' { $tags += @("legacy", "fix-script", "historical") }
        '^test-.*\.(py|ps1)$' { $tags += @("test", "legacy", "python", "powershell") }
        '.*[Rr]eport.*\.json$' { $tags += @("report", "json", "generated") }
        '.*[Rr]esults.*\.xml$' { $tags += @("test-results", "xml", "generated") }
        '\.(md|txt)$' { $tags += @("documentation", "text") }
        '\.(ps1|psm1|psd1)$' { $tags += @("powershell", "script") }
        '\.(py|pyc)$' { $tags += @("python", "script") }
        '\.(tf|tfvars|hcl)$' { $tags += @("terraform", "infrastructure") }
        '\.(yml|yaml)$' { $tags += @("yaml", "config") }
        '\.(json)$' { $tags += @("json", "config") }
    }
    
    # Content-based tagging (if we can read the file)
    if (Test-Path $FilePath -PathType Leaf) {
        try {
            $content = Get-Content $FilePath -TotalCount 10 -ErrorAction SilentlyContinue
            if ($content) {
                $firstLines = $content -join "`n"
                
                if ($firstLines -match "#!/usr/bin/env pwsh|#!/bin/bash") { $tags += "executable" }
                if ($firstLines -match "@{|@(") { $tags += "powershell-data" }
                if ($firstLines -match "import |from .* import") { $tags += "python-module" }
                if ($firstLines -match "# Test|Describe |It ") { $tags += "test-file" }
                if ($firstLines -match "# Fix|# Repair|# Patch") { $tags += "fix-script" }
                if ($firstLines -match "terraform|resource |provider ") { $tags += "terraform" }
            }
        } catch {
            # Ignore read errors
        }
    }
    
    return $tags
}

function Get-RecommendedLocation {
    param($FileName, $Tags, $CurrentPath)
    
    # Check organization rules
    foreach ($category in $organizationRules.Keys) {
        $rule = $organizationRules[$category]
        
        # Check if file matches patterns
        foreach ($pattern in $rule.patterns) {
            if ($FileName -like $pattern) {
                # Check exceptions
                if ($rule.exceptions -and $FileName -in $rule.exceptions) {
                    continue
                }
                return @{
                    Category = $category
                    Reason = "Matches pattern: $pattern"
                    Description = $rule.description
                }
            }
        }
    }
    
    # Tag-based recommendations
    if ($Tags -contains "legacy" -or $Tags -contains "fix-script") {
        return @{
            Category = "archive/legacy"
            Reason = "Tagged as legacy/fix script"
            Description = "Historical files and fix scripts"
        }
    }
    
    if ($Tags -contains "test-results" -or $Tags -contains "report") {
        return @{
            Category = "reports"
            Reason = "Tagged as test results or report"
            Description = "Generated reports and test outputs"
        }
    }
    
    if ($Tags -contains "terraform") {
        return @{
            Category = "infrastructure"
            Reason = "Tagged as Terraform/Infrastructure"
            Description = "Infrastructure as Code files"
        }
    }
    
    return $null
}

function Show-OrganizationPlan {
    Write-Host "🗂️  File Organization Analysis" -ForegroundColor Yellow
    Write-Host "==============================" -ForegroundColor Yellow
    
    $rootFiles = Get-ChildItem -Path . -File | Where-Object { -not $_.Name.StartsWith('.') }
    $organizationPlan = @()
    
    foreach ($file in $rootFiles) {
        $tags = Get-FileTag $file.FullName $file.Name
        $recommendation = Get-RecommendedLocation $file.Name $tags $file.FullName
        
        $organizationPlan += [PSCustomObject]@{
            FileName = $file.Name
            CurrentLocation = "ROOT"
            RecommendedLocation = if ($recommendation) { $recommendation.Category } else { "ROOT (keep)" }
            Tags = $tags -join ", "
            Reason = if ($recommendation) { $recommendation.Reason } else { "No move needed" }
            Description = if ($recommendation) { $recommendation.Description } else { "Appropriate in root" }
        }
    }
    
    # Group by recommended location
    $grouped = $organizationPlan | Group-Object RecommendedLocation
    
    foreach ($group in $grouped) {
        $location = $group.Name
        $files = $group.Group
        
        if ($location -eq "ROOT (keep)") {
            Write-Host "`n📂 $location" -ForegroundColor Green
        } else {
            Write-Host "`n📂 $location" -ForegroundColor Cyan
        }
        
        foreach ($file in $files) {
            $color = if ($location -eq "ROOT (keep)") { "Gray" } else { "White" }
            Write-Host "   📄 $($file.FileName)" -ForegroundColor $color
            if ($file.Tags) {
                Write-Host "      🏷️  Tags: $($file.Tags)" -ForegroundColor DarkGray
            }
            if ($file.Reason -ne "No move needed") {
                Write-Host "      📝 $($file.Reason)" -ForegroundColor DarkGray
            }
        }
    }
    
    # Summary
    $toMove = $organizationPlan | Where-Object { $_.RecommendedLocation -ne "ROOT (keep)" }
    $toKeep = $organizationPlan | Where-Object { $_.RecommendedLocation -eq "ROOT (keep)" }
    
    Write-Host "`n📊 Summary:" -ForegroundColor Yellow
    Write-Host "   📁 Files to organize: $($toMove.Count)" -ForegroundColor Cyan
    Write-Host "   📁 Files to keep in root: $($toKeep.Count)" -ForegroundColor Green
    
    return $organizationPlan
}

function Invoke-FileOrganization {
    param($OrganizationPlan)
    
    if (-not $Force -and -not $WhatIf) {
        $confirm = Read-Host "`nProceed with file organization? (y/N)"
        if ($confirm -ne 'y' -and $confirm -ne 'Y') {
            Write-Host "Organization cancelled." -ForegroundColor Yellow
            return
        }
    }
    
    $toMove = $OrganizationPlan | Where-Object { $_.RecommendedLocation -ne "ROOT (keep)" }
    
    foreach ($item in $toMove) {
        $source = $item.FileName
        $targetDir = $item.RecommendedLocation
        $target = Join-Path $targetDir $item.FileName
        
        if ($WhatIf) {
            Write-Host "WHATIF: Would move '$source' to '$target'" -ForegroundColor Yellow
        } else {
            try {
                # Create target directory if it doesn't exist
                if (-not (Test-Path $targetDir)) {
                    New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
                    Write-Host "✅ Created directory: $targetDir" -ForegroundColor Green
                }
                
                # Move the file
                Move-Item -Path $source -Destination $target -Force
                Write-Host "✅ Moved: $source → $target" -ForegroundColor Green
                
            } catch {
                Write-Host "❌ Failed to move $source : $_" -ForegroundColor Red
            }
        }
    }
    
    if (-not $WhatIf) {
        Write-Host "`n🎉 File organization completed!" -ForegroundColor Green
        Write-Host "📁 $($toMove.Count) files have been organized into appropriate directories." -ForegroundColor Cyan
    }
}

# Create file organization rules config
function Export-OrganizationRules {
    $config = @{
        metadata = @{
            created = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            description = "OpenTofu Lab Automation file organization rules"
        }
        rules = $organizationRules
    }
    
    $config | ConvertTo-Json -Depth 5 | Set-Content $ConfigFile
    Write-Host "📋 Organization rules exported to: $ConfigFile" -ForegroundColor Green
}

# Main execution
try {
    Write-Host "🗂️  OpenTofu Lab Automation - Smart File Organization" -ForegroundColor Cyan
    Write-Host "====================================================" -ForegroundColor Cyan
    
    # Show organization plan
    $plan = Show-OrganizationPlan
    
    if (-not $WhatIf) {
        # Execute organization
        Invoke-FileOrganization $plan
        
        # Export rules for future reference
        Export-OrganizationRules
    } else {
        Write-Host "`n💡 Use -Force to skip confirmation, remove -WhatIf to execute" -ForegroundColor Yellow
    }
    
} catch {
    Write-Error "Organization failed: $_"
}
