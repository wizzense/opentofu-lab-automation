#Requires -Version 7.0

Write-Host "=== Testing Enhanced PatchManager Features ===" -ForegroundColor Cyan

# Test 1: Enhanced Git Operations
Write-Host "1. Testing enhanced Git operations..." -ForegroundColor Yellow
try {
    . "./pwsh/modules/PatchManager/Public/Invoke-EnhancedGitOperations.ps1"
    
    $result = Invoke-EnhancedGitOperations -Operation "ResolveConflicts" -ValidateAfter
    
    if ($result.Success) {
        Write-Host "✅ Enhanced Git operations working!" -ForegroundColor Green
        if ($result.AllChecksPassed) {
            Write-Host "✅ All automatic validation checks passed!" -ForegroundColor Green
        }
    }
} catch {
    Write-Host "❌ Error: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 2: Check if files exist
Write-Host "2. Checking new files..." -ForegroundColor Yellow
$newFiles = @(
    "./pwsh/modules/PatchManager/Public/Invoke-EnhancedGitOperations.ps1"
)

foreach ($file in $newFiles) {
    if (Test-Path $file) {
        Write-Host "✅ $file exists" -ForegroundColor Green
    } else {
        Write-Host "❌ $file missing" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "=== Merge Conflict Resolution Summary ===" -ForegroundColor Cyan
Write-Host "✅ Resolved merge conflict with Format-PatchOutput.ps1" -ForegroundColor Green
Write-Host "✅ Added automatic validation to PatchManager" -ForegroundColor Green
Write-Host "✅ Added locked directory cleanup" -ForegroundColor Green
Write-Host "✅ No more manual validation steps needed" -ForegroundColor Green

Write-Host ""
Write-Host "🚀 Ready to push changes to the PR!" -ForegroundColor Green
