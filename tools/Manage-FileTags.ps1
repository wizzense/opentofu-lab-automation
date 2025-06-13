#!/usr/bin/env pwsh
# Smart file tagging system for automatic organization

param(
    [string]$FilePath,
    [switch]$ListTags,
    [switch]$UpdateIndex,
    [string[]]$AddTags,
    [string[]]$RemoveTags
)





$tagIndexPath = "file-tags-index.json"

function Initialize-TagIndex {
    if (-not (Test-Path $tagIndexPath)) {
        $initialIndex = @{
            metadata = @{
                created = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                version = "1.0"
                description = "File tagging index for project organization"
            }
            tags = @{}
            files = @{}
            rules = @{
                auto_tags = @{
                    "*.ps1" = @("powershell", "script")
                    "*.py" = @("python", "script") 
                    "*.md" = @("documentation", "markdown")
                    "*.json" = @("json", "config")
                    "*.yml" = @("yaml", "config")
                    "*Test*.ps1" = @("test", "powershell")
                    "*fix_*.ps1" = @("legacy", "fix-script")
                    "*report*.json" = @("report", "generated")
                }
                organization_rules = @{
                    "legacy" = "archive/legacy"
                    "test-results" = "reports"
                    "report" = "reports"
                    "documentation" = "docs"
                    "terraform" = "infrastructure"
                }
            }
        }
        
        $initialIndex | ConvertTo-Json -Depth 5 | Set-Content $tagIndexPath
        Write-Host "📋 Initialized tag index: $tagIndexPath" -ForegroundColor Green
        return $initialIndex
    } else {
        return Get-Content $tagIndexPath | ConvertFrom-Json
    }
}

function Get-AutoTags {
    param($FileName, $Content = $null)
    
    



$autoTags = @()
    
    # Pattern-based auto-tagging
    $patterns = @{
        "^fix_.*\.ps1$" = @("legacy", "fix-script")
        "^test-.*\.(py|ps1)$" = @("test", "legacy")
        ".*[Tt]est.*\.ps1$" = @("test", "powershell")
        ".*[Rr]eport.*\.json$" = @("report", "generated")
        ".*[Rr]esults.*\.xml$" = @("test-results", "generated")
        "\.(ps1|psm1|psd1)$" = @("powershell", "script")
        "\.(py|pyc)$" = @("python", "script")
        "\.(md|txt)$" = @("documentation")
        "\.(tf|tfvars)$" = @("terraform", "infrastructure")
        "\.(yml|yaml)$" = @("yaml", "config")
        "\.(json)$" = @("json", "config")
    }
    
    foreach ($pattern in $patterns.Keys) {
        if ($FileName -match $pattern) {
            $autoTags += $patterns[$pattern]
        }
    }
    
    # Content-based tagging
    if ($Content) {
        if ($Content -match "#!/usr/bin/env pwsh|#!/bin/bash") { $autoTags += "executable" }
        if ($Content -match "Describe |It ") { $autoTags += "pester-test" }
        if ($Content -match "terraform|resource |provider ") { $autoTags += "terraform" }
        if ($Content -match "function|param\(") { $autoTags += "function-definition" }
    }
    
    return $autoTags | Sort-Object -Unique
}

function Set-FileTags {
    param($FilePath, $Tags)
    
    



$index = Initialize-TagIndex
    $relativePath = Resolve-Path $FilePath -Relative
    
    # Update file entry
    $index.files.$relativePath = @{
        tags = $Tags
        last_updated = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        auto_detected = $false
    }
    
    # Update tag index
    foreach ($tag in $Tags) {
        if (-not $index.tags.$tag) {
            $index.tags.$tag = @()
        }
        if ($relativePath -notin $index.tags.$tag) {
            $index.tags.$tag += $relativePath
        }
    }
    
    # Save updated index
    $index | ConvertTo-Json -Depth 5 | Set-Content $tagIndexPath
    Write-Host "🏷️  Tagged '$FilePath' with: $($Tags -join ', ')" -ForegroundColor Green
}

function Get-FileTags {
    param($FilePath)
    
    



$index = Initialize-TagIndex
    $relativePath = Resolve-Path $FilePath -Relative -ErrorAction SilentlyContinue
    
    if ($relativePath -and $index.files.$relativePath) {
        return $index.files.$relativePath.tags
    }
    
    return @()
}

function Get-FilesByTag {
    param($Tag)
    
    



$index = Initialize-TagIndex
    
    if ($index.tags.$Tag) {
        return $index.tags.$Tag
    }
    
    return @()
}

function Update-AutoTags {
    Write-Host "🔄 Updating automatic tags for all files..." -ForegroundColor Yellow
    
    $index = Initialize-TagIndex
    $updated = 0
    
    # Scan all files in project
    $allFiles = Get-ChildItem -Recurse -File | Where-Object { 
        $_.FullName -notlike "*\.git*" -and
        $_.FullName -notlike "*node_modules*" -and
        $_.Name -ne "file-tags-index.json"
    }
    
    foreach ($file in $allFiles) {
        $relativePath = Resolve-Path $file.FullName -Relative
        
        # Get automatic tags
        $content = if ($file.Length -lt 10KB) { 
            try { Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue } 
            catch { $null }
        } else { $null }
        
        $autoTags = Get-AutoTags $file.Name $content
        
        if ($autoTags.Count -gt 0) {
            # Check if file already has tags
            $existingTags = if ($index.files.$relativePath) { $index.files.$relativePath.tags    } else { @()    }
            
            # Merge auto tags with existing manual tags
            $allTags = ($existingTags + $autoTags) | Sort-Object -Unique
            
            # Update only if changed
            $comparison = Compare-Object $existingTags $allTags -ErrorAction SilentlyContinue
            if ($comparison -or ($existingTags.Count -ne $allTags.Count)) {
                Set-FileTags $file.FullName $allTags
                $updated++
            }
        }
    }
    
    Write-Host "✅ Updated tags for $updated files" -ForegroundColor Green
}

function Show-TagSummary {
    $index = Initialize-TagIndex
    
    Write-Host "🏷️  File Tagging Summary" -ForegroundColor Yellow
    Write-Host "======================" -ForegroundColor Yellow
    
    # Show tag distribution
    Write-Host "`n📊 Tag Distribution:" -ForegroundColor Cyan
    $tagCounts = @{}
    foreach ($tag in $index.tags.Keys) {
        $tagCounts[$tag] = $index.tags.$tag.Count
    }
    
    $tagCounts.GetEnumerator() | Sort-Object Value -Descending | ForEach-Object {
        $bar = "█" * [Math]::Min($_.Value, 20)
        Write-Host "   $($_.Key.PadRight(15)) │$bar │ $($_.Value) files" -ForegroundColor White
    }
    
    # Show organization suggestions
    Write-Host "`n📂 Organization Suggestions:" -ForegroundColor Cyan
    $orgRules = $index.rules.organization_rules
    foreach ($tag in $orgRules.Keys) {
        $files = Get-FilesByTag $tag
        if ($files.Count -gt 0) {
            Write-Host "   $tag → $($orgRules.$tag) ($($files.Count) files)" -ForegroundColor Yellow
        }
    }
    
    # Show untagged files
    $allFiles = Get-ChildItem -File | Where-Object { $_.Name -ne "file-tags-index.json" }
    $untagged = $allFiles | Where-Object { 
        $relativePath = Resolve-Path $_.FullName -Relative
        -not $index.files.$relativePath
    }
    
    if ($untagged.Count -gt 0) {
        Write-Host "`n⚠️  Untagged Files ($($untagged.Count)):" -ForegroundColor Yellow
        $untagged | ForEach-Object { Write-Host "   📄 $($_.Name)" -ForegroundColor Gray }
    }
}

# Main execution
if ($ListTags) {
    Show-TagSummary
} elseif ($UpdateIndex) {
    Update-AutoTags
} elseif ($FilePath) {
    if ($AddTags) {
        $existingTags = Get-FileTags $FilePath
        $newTags = ($existingTags + $AddTags) | Sort-Object -Unique
        Set-FileTags $FilePath $newTags
    } elseif ($RemoveTags) {
        $existingTags = Get-FileTags $FilePath
        $newTags = $existingTags | Where-Object { $_ -notin $RemoveTags }
        Set-FileTags $FilePath $newTags
    } else {
        $tags = Get-FileTags $FilePath
        if ($tags.Count -gt 0) {
            Write-Host "🏷️  Tags for '$FilePath': $($tags -join ', ')" -ForegroundColor Green
        } else {
            Write-Host "📄 No tags found for '$FilePath'" -ForegroundColor Gray
            
            # Suggest auto tags
            $content = if ((Get-Item $FilePath).Length -lt 10KB) { 
                Get-Content $FilePath -Raw -ErrorAction SilentlyContinue 
            } else { $null }
            $autoTags = Get-AutoTags (Split-Path $FilePath -Leaf) $content
            
            if ($autoTags.Count -gt 0) {
                Write-Host "💡 Suggested tags: $($autoTags -join ', ')" -ForegroundColor Yellow
            }
        }
    }
} else {
    Write-Host "🏷️  Smart File Tagging System" -ForegroundColor Cyan
    Write-Host "=============================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Usage:" -ForegroundColor Yellow
    Write-Host "  Tag a file:     $($MyInvocation.MyCommand.Name) -FilePath 'file.ps1' -AddTags 'script','utility'"
    Write-Host "  Remove tags:    $($MyInvocation.MyCommand.Name) -FilePath 'file.ps1' -RemoveTags 'legacy'"
    Write-Host "  Show file tags: $($MyInvocation.MyCommand.Name) -FilePath 'file.ps1'"
    Write-Host "  List all tags:  $($MyInvocation.MyCommand.Name) -ListTags"
    Write-Host "  Update index:   $($MyInvocation.MyCommand.Name) -UpdateIndex"
}


