# Test workflow components locally
param(
    [string]$Platform = "linux",
    [switch]$DryRun
)

Write-Host "🧪 Testing workflow components for $Platform..." -ForegroundColor Yellow

# Ensure coverage directory exists
if (-not (Test-Path coverage)) {
    New-Item -ItemType Directory -Path coverage | Out-Null
    Write-Host "✅ Created coverage directory" -ForegroundColor Green
}

# Test Pester configuration loading
try {
    $cfg = New-PesterConfiguration -Hashtable (Import-PowerShellDataFile 'tests/PesterConfiguration.psd1')
    Write-Host "✅ Pester configuration loaded successfully" -ForegroundColor Green
} catch {
    Write-Error "❌ Failed to load Pester configuration: $_"
    exit 1
}

# Test helper scripts
try {
    . ./tests/helpers/Get-ScriptAst.ps1
    if (-not (Get-Command Get-ScriptAst -ErrorAction SilentlyContinue)) {
        throw "Get-ScriptAst helper not loaded"
    }
    Write-Host "✅ Test helpers loaded successfully" -ForegroundColor Green
} catch {
    Write-Error "❌ Failed to load test helpers: $_"
    exit 1
}

# Test NodeCore script loading
try {
    . ./pwsh/runner_scripts/0201_Install-NodeCore.ps1
    Write-Host "✅ NodeCore script loaded successfully" -ForegroundColor Green
} catch {
    Write-Error "❌ Failed to load NodeCore script: $_"
    exit 1
}

if ($DryRun) {
    Write-Host "🏃 Running quick Pester test..." -ForegroundColor Yellow
    try {
        $cfg.Run.PassThru = $true
        $cfg.Output.Verbosity = 'Minimal'
        # Test just one file to verify execution
        $cfg.Run.Path = 'tests/0001_Reset-Git.Tests.ps1'
        $result = Invoke-Pester -Configuration $cfg
        Write-Host "✅ Pester test completed successfully" -ForegroundColor Green
        Write-Host "📊 Passed: $($result.PassedCount), Failed: $($result.FailedCount), Total: $($result.TotalCount)" -ForegroundColor Cyan
        if ($result.FailedCount -gt 0) {
            Write-Warning "Some tests failed - check individual test output"
        }
    } catch {
        Write-Error "❌ Pester test failed: $_"
        exit 1
    }
} else {
    Write-Host "✅ All workflow components validated successfully!" -ForegroundColor Green
    Write-Host "💡 Run with -DryRun to test Pester execution" -ForegroundColor Cyan
}
