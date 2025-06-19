# PatchManager Demo - Quick Start Examples

# Example 1: Basic Demo
Write-Host "🚀 Running Basic PatchManager Demo..." -ForegroundColor Green
.\demo-patchmanager.ps1 -DemoMode Basic -DryRun

Write-Host "`n" + "="*50 -ForegroundColor Cyan

# Example 2: Interactive Advanced Demo
Write-Host "🔧 Running Advanced Demo (Interactive)..." -ForegroundColor Green
.\demo-patchmanager.ps1 -DemoMode Advanced -Interactive -DryRun

Write-Host "`n" + "="*50 -ForegroundColor Cyan

# Example 3: Full Demo Suite
Write-Host "🎯 Running Complete Demo Suite..." -ForegroundColor Green
.\demo-patchmanager.ps1 -DemoMode All -DryRun

Write-Host "`n✅ Demo examples completed!" -ForegroundColor Green
