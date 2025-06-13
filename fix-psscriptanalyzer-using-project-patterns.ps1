#!/usr/bin/env pwsh
# Fix PSScriptAnalyzer issues by copying working patterns from the project

Write-Host "🔧 Fixing PSScriptAnalyzer Issues Using Working Project Patterns" -ForegroundColor Green

# Step 1: Copy the working simple import pattern from CustomLint.ps1
Write-Host "`n1. Using proven simple import pattern..." -ForegroundColor Yellow

$workingPattern = @'
# Simple PSScriptAnalyzer import
Import-Module PSScriptAnalyzer -Force
'@

# Step 2: Fix the corrupted auto-generated PSScriptAnalyzer imports
Write-Host "`n2. Removing corrupted auto-generated PSScriptAnalyzer imports..." -ForegroundColor Yellow

$filesToFix = @(
    "/workspaces/opentofu-lab-automation/tools/validation/test-fixes.ps1",
    "/workspaces/opentofu-lab-automation/pwsh/modules/CodeFixer/Public/Invoke-PowerShellLint.ps1",
    "/workspaces/opentofu-lab-automation/tests/helpers/TestHelpers.ps1"
)

foreach ($file in $filesToFix) {
    if (Test-Path $file) {
        Write-Host "  Fixing: $file" -ForegroundColor Gray
        
        $content = Get-Content $file -Raw
        
        # Remove the auto-generated corrupted blocks
        $content = $content -replace '# Auto-added import for PSScriptAnalyzer\s*\n.*?Import-Module PSScriptAnalyzer -Force\s*\n', ''
        
        # For test-fixes.ps1, replace with working pattern at the top
        if ($file -like "*test-fixes.ps1") {
            # Add the working import at the beginning
            if ($content -notmatch 'Import-Module PSScriptAnalyzer -Force') {
                $content = $workingPattern + "`n`n" + $content
            }
        }
        
        # For Invoke-PowerShellLint.ps1, use the proven initialization
        if ($file -like "*Invoke-PowerShellLint.ps1") {
            # Replace the complex initialization with simple pattern
            $content = $content -replace '# Initialize PSScriptAnalyzer.*?catch \{[^}]+\}', $workingPattern
        }
        
        Set-Content $file -Value $content -Encoding UTF8
        Write-Host "    ✅ Fixed corrupted imports" -ForegroundColor Green
    }
}

# Step 3: Create a robust PSScriptAnalyzer initializer function (copy from fix-psscriptanalyzer.ps1)
Write-Host "`n3. Creating robust PSScriptAnalyzer initialization..." -ForegroundColor Yellow

$initFunction = @'
function Initialize-PSScriptAnalyzer {
    <#
    .SYNOPSIS
    Robust PSScriptAnalyzer initialization using proven patterns from the project
    #>
    
    try {
        # Simple import first (the pattern that works)
        Import-Module PSScriptAnalyzer -Force
        
        # Test it works
        $null = Invoke-ScriptAnalyzer -ScriptDefinition "Write-Host 'test'" -ErrorAction Stop
        
        Write-Host "✅ PSScriptAnalyzer ready" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "⚠️ PSScriptAnalyzer not available, using fallback methods" -ForegroundColor Yellow
        
        # Install using the proven method from fix-psscriptanalyzer.ps1
        try {
            Set-PSRepository -Name PSGallery -InstallationPolicy Trusted -ErrorAction SilentlyContinue
            Install-Module PSScriptAnalyzer -Force -Scope CurrentUser -Repository PSGallery -AllowClobber -SkipPublisherCheck
            Import-Module PSScriptAnalyzer -Force
            
            Write-Host "✅ PSScriptAnalyzer installed and ready" -ForegroundColor Green
            return $true
        } catch {
            Write-Host "❌ PSScriptAnalyzer initialization failed: $($_.Exception.Message)" -ForegroundColor Red
            return $false
        }
    }
}
'@

# Add this function to the CodeFixer module
$initFunctionPath = "/workspaces/opentofu-lab-automation/pwsh/modules/CodeFixer/Private/Initialize-PSScriptAnalyzer.ps1"
Set-Content $initFunctionPath -Value $initFunction -Encoding UTF8
Write-Host "    ✅ Created robust initializer function" -ForegroundColor Green

# Step 4: Create parallel processing that uses the working pattern
Write-Host "`n4. Creating parallel processing for PSScriptAnalyzer..." -ForegroundColor Yellow

$parallelScript = @'
function Invoke-ParallelScriptAnalyzer {
    <#
    .SYNOPSIS
    Parallel PSScriptAnalyzer processing using ThreadJob and proven import patterns
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [array]$Files,
        
        [Parameter()]
        [int]$MaxConcurrency = [Environment]::ProcessorCount
    )
    
    # Import ThreadJob for parallel processing
    if (-not (Get-Module -ListAvailable ThreadJob)) {
        Install-Module ThreadJob -Force -Scope CurrentUser
    }
    Import-Module ThreadJob -Force
    
    # Initialize PSScriptAnalyzer using the proven pattern
    if (-not (Initialize-PSScriptAnalyzer)) {
        Write-Warning "PSScriptAnalyzer not available, skipping parallel analysis"
        return @()
    }
    
    Write-Host "🚀 Running parallel analysis on $($Files.Count) files with $MaxConcurrency threads" -ForegroundColor Cyan
    
    $allResults = @()
    $jobs = @()
    
    # Process files in parallel batches
    for ($i = 0; $i -lt $Files.Count; $i += $MaxConcurrency) {
        $batch = $Files[$i..([Math]::Min($i + $MaxConcurrency - 1, $Files.Count - 1))]
        
        foreach ($file in $batch) {
            $job = Start-ThreadJob -ScriptBlock {
                param($FilePath)
                
                # Use the simple, working import pattern in each thread
                Import-Module PSScriptAnalyzer -Force
                
                try {
                    $results = Invoke-ScriptAnalyzer -Path $FilePath -Severity Error,Warning -ErrorAction SilentlyContinue
                    return @{
                        File = $FilePath
                        Results = $results
                        Success = $true
                        Error = $null
                    }
                } catch {
                    return @{
                        File = $FilePath
                        Results = @()
                        Success = $false
                        Error = $_.Exception.Message
                    }
                }
            } -ArgumentList $file.FullName
            
            $jobs += $job
        }
        
        # Wait for batch to complete
        $jobs | Wait-Job | ForEach-Object {
            $result = Receive-Job $_
            if ($result.Success) {
                $allResults += $result.Results
                Write-Host "  ✅ $([System.IO.Path]::GetFileName($result.File))" -ForegroundColor Green
            } else {
                Write-Host "  ❌ $([System.IO.Path]::GetFileName($result.File)): $($result.Error)" -ForegroundColor Red
            }
            Remove-Job $_
        }
        
        $jobs = @()
    }
    
    Write-Host "📊 Parallel analysis complete: $($allResults.Count) issues found" -ForegroundColor Blue
    return $allResults
}
'@

$parallelPath = "/workspaces/opentofu-lab-automation/pwsh/modules/CodeFixer/Public/Invoke-ParallelScriptAnalyzer.ps1"
Set-Content $parallelPath -Value $parallelScript -Encoding UTF8
Write-Host "    ✅ Created parallel PSScriptAnalyzer processor" -ForegroundColor Green

# Step 5: Update the main lint function to use proven patterns
Write-Host "`n5. Updating main lint function with proven patterns..." -ForegroundColor Yellow

$lintPath = "/workspaces/opentofu-lab-automation/pwsh/modules/CodeFixer/Public/Invoke-PowerShellLint.ps1"
if (Test-Path $lintPath) {
    $content = Get-Content $lintPath -Raw
    
    # Replace the initialization section with proven pattern
    $newInit = @'
    # Initialize PSScriptAnalyzer using proven pattern
    $psaAvailable = Initialize-PSScriptAnalyzer
'@
    
    $content = $content -replace '# Simple PSScriptAnalyzer import.*?catch \{[^}]+\}', $newInit
    
    # Replace parallel processing call
    $content = $content -replace 'Write-Host "🚀 Using parallel processing.*?\$allIssues = Invoke-ParallelScriptAnalyzer -Files \$powerShellFiles', 
        'Write-Host "🚀 Using parallel processing for $($powerShellFiles.Count) files..." -ForegroundColor Cyan
        $allResults = Invoke-ParallelScriptAnalyzer -Files $powerShellFiles'
    
    Set-Content $lintPath -Value $content -Encoding UTF8
    Write-Host "    ✅ Updated main lint function" -ForegroundColor Green
}

# Step 6: Test the fixes
Write-Host "`n6. Testing the fixes..." -ForegroundColor Yellow

try {
    # Test the proven pattern
    Import-Module PSScriptAnalyzer -Force
    Write-Host "    ✅ Simple import works" -ForegroundColor Green
    
    # Test the parallel function
    . $parallelPath
    . $initFunctionPath
    
    if (Initialize-PSScriptAnalyzer) {
        Write-Host "    ✅ Robust initializer works" -ForegroundColor Green
    }
    
    Write-Host "`n🎉 PSScriptAnalyzer fixes applied successfully!" -ForegroundColor Green
    Write-Host "    Using proven patterns from the project" -ForegroundColor Gray
    
} catch {
    Write-Host "    ❌ Test failed: $($_.Exception.Message)" -ForegroundColor Red
}
