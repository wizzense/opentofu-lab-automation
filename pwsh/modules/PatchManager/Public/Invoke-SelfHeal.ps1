function Invoke-SelfHeal {
    <#
    .SYNOPSIS
    Enables PatchManager to heal itself using CodeFixer integration
    
    .DESCRIPTION
    Leverages the CodeFixer module to detect and fix issues in PatchManager itself,
    creating a self-improving system that learns from its own errors.
    
    .PARAMETER TargetModule
    Module to self-heal (defaults to PatchManager)
    
    .PARAMETER UpdateCodeFixer
    Whether to update CodeFixer with newly discovered patterns
    
    .EXAMPLE
    Invoke-SelfHeal -UpdateCodeFixer
    #>
    [CmdletBinding()]
    param(
        [string]$TargetModule = "PatchManager",
        
        [switch]$UpdateCodeFixer,
        
        [switch]$WhatIf
    )
    
    Write-Host "🔧 Starting self-healing process for $TargetModule module..." -ForegroundColor Cyan
    
    # Ensure logs are written to the logs directory
    $logDirectory = "./logs"
    if (-not (Test-Path $logDirectory)) {
        New-Item -ItemType Directory -Path $logDirectory -Force
    }

    # Write logs to the logs directory
    Write-CustomLog -Message "Self-healing operation started" -Level "INFO" -LogPath "$logDirectory/selfheal.log"

    # Write basic setup/install logs to temp folder
    $tempLogPath = [System.IO.Path]::GetTempPath() + "selfheal-temp.log"
    Write-CustomLog -Message "Basic setup/install logs" -Level "INFO" -LogPath $tempLogPath
    
    # Step 1: Import CodeFixer and PSScriptAnalyzer for analysis
    try {
        Import-Module "/workspaces/opentofu-lab-automation/pwsh/modules/CodeFixer/"" -Force -ErrorAction Stop
        Write-Host "✓ CodeFixer module loaded" -ForegroundColor Green
    } catch {
        Write-Error "Failed to load CodeFixer module: $($_.Exception.Message)"
        return $false
    }
    
    try {
        Import-Module PSScriptAnalyzer -Force -ErrorAction Stop
        Write-Host "✓ PSScriptAnalyzer module loaded" -ForegroundColor Green
    } catch {
        Write-Error "Failed to load PSScriptAnalyzer module: $($_.Exception.Message)"
        return $false
    }
    
    # Step 2: Analyze the target module
    $moduleRoot = Split-Path $PSScriptRoot -Parent
    if ($TargetModule -ne "PatchManager") {
        $moduleRoot = "$moduleRoot/../$TargetModule"
    }
    
    Write-Host "🔍 Analyzing module at: $moduleRoot" -ForegroundColor Yellow
      # Step 3: Run comprehensive analysis
    Write-Host "🔍 Running PSScriptAnalyzer and custom checks..." -ForegroundColor Yellow
    $lintResults = Invoke-ScriptAnalyzer -Path $moduleRoot -Severity Warning, Error -OutputFormat "Object" -PassThru
    
    if ($lintResults.ErrorCount -gt 0) {
        Write-Host "⚠️  Found $($lintResults.ErrorCount) PSScriptAnalyzer errors" -ForegroundColor Red
    }
    
    # Step 4: Check for automatic variable issues specifically
    $automaticVarIssues = @()
    Get-ChildItem -Path $moduleRoot -Filter "*.ps1" -Recurse | ForEach-Object {
        $issues = Test-AutomaticVariables -ScriptPath $_.FullName
        $automaticVarIssues += $issues
    }
    
    if ($automaticVarIssues.Count -gt 0) {
        Write-Host "🚨 Found $($automaticVarIssues.Count) automatic variable issues" -ForegroundColor Red
        
        # Step 5: Apply fixes
        $fixedFiles = @()
        $automaticVarIssues | Group-Object { Split-Path $_.ScriptPath -Leaf } | ForEach-Object {
            $scriptPath = ($automaticVarIssues | Where-Object { (Split-Path $_.ScriptPath -Leaf) -eq $_.Name })[0].ScriptPath
            if ($scriptPath -and (Test-Path $scriptPath)) {
                Write-Host "🔨 Fixing automatic variable issues in: $(Split-Path $scriptPath -Leaf)" -ForegroundColor Yellow
                
                $result = Repair-AutomaticVariables -ScriptPath $scriptPath -WhatIf:$WhatIf
                if ($result.ChangesMade -gt 0) {
                    $fixedFiles += $scriptPath
                }
            }
        }
        
        # Step 6: Update CodeFixer with new patterns if requested
        if ($UpdateCodeFixer -and $fixedFiles.Count -gt 0) {
            Write-Host "📚 Updating CodeFixer with newly discovered patterns..." -ForegroundColor Magenta
            Update-CodeFixerPatterns -FixedFiles $fixedFiles -IssueType "AutomaticVariables"
        }
        
        Write-Host "✅ Self-healing completed. Fixed $($fixedFiles.Count) files." -ForegroundColor Green
        
        # Validate fixes using Pester
        try {
            Invoke-Pester -Script "/tests/PatchManager.Tests.ps1" -Output Detailed -ErrorAction Stop
            Write-Host "✓ Pester validation completed successfully" -ForegroundColor Green
        } catch {
            Write-Error "Pester validation failed: $($_.Exception.Message)"
        }
        
        return @{
            Success = $true
            FixedFiles = $fixedFiles
            IssuesFound = $automaticVarIssues.Count
            Module = $TargetModule
        }
    } else {
        Write-Host "✅ No automatic variable issues found. Module is healthy!" -ForegroundColor Green
        return @{
            Success = $true
            FixedFiles = @()
            IssuesFound = 0
            Module = $TargetModule
        }
    }
}

function Update-CodeFixerPatterns {
    <#
    .SYNOPSIS
    Updates CodeFixer with newly discovered fix patterns
    
    .DESCRIPTION
    Analyzes successful fixes and creates new detection/repair patterns for CodeFixer
    #>
    [CmdletBinding()]
    param(
        [string[]]$FixedFiles,
        [string]$IssueType
    )
    
    Write-Host "📝 Learning from fixes to improve future detection..." -ForegroundColor Cyan
    
    # This would create a feedback loop where successful fixes become part of CodeFixer's knowledge base
    # For now, we'll log the patterns for manual review
    
    $patternLog = @{
        Timestamp = Get-Date
        IssueType = $IssueType
        FixedFiles = $FixedFiles
        Pattern = "Automatic variable assignment detection and repair"
        Recommendation = "Add Test-AutomaticVariables to standard CodeFixer analysis"
    }
    
    $logPath = "$PSScriptRoot/../../../CodeFixer/Logs/learned-patterns.json"
    $logDir = Split-Path $logPath -Parent
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }
    
    # Append to learning log
    $existingPatterns = @()
    if (Test-Path $logPath) {
        $existingPatterns = Get-Content $logPath | ConvertFrom-Json
    }
    
    $existingPatterns += $patternLog
    $existingPatterns | ConvertTo-Json -Depth 3 | Set-Content $logPath
    
    Write-Host "✓ Pattern logged for future CodeFixer enhancement" -ForegroundColor Green
}

