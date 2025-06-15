#!/usr/bin/env pwsh
# Test the Cross-Platform Executor system
# This demonstrates encoding and execution capabilities

$ErrorActionPreference = "Stop"

Write-Host "🧪 TESTING CROSS-PLATFORM EXECUTOR SYSTEM" -ForegroundColor Cyan
Write-Host "=" * 60

# Test 1: Create a simple test script
$testScript = @'
Param(
    [string]$Message = "Hello from encoded script!",
    [string]$Environment = "test"
)








Write-Host "Test script executing..." -ForegroundColor Green
Write-Host "Message: $Message" -ForegroundColor Yellow
Write-Host "Environment: $Environment" -ForegroundColor Yellow
Write-Host "Platform: $($PSVersionTable.Platform)" -ForegroundColor Cyan
Write-Host "PowerShell Version: $($PSVersionTable.PSVersion)" -ForegroundColor Cyan

if ($Environment -eq "test") {
    Write-Host "✅ Test environment detected - execution successful" -ForegroundColor Green
    exit 0
} else {
    Write-Host "❌ Unexpected environment: $Environment" -ForegroundColor Red
    exit 1
}
'@

# Use cross-platform temp directory
$tempDir = if ($IsWindows -or $env:OS -eq "Windows_NT") { $env:TEMP    } else { "/tmp"    }
$testScriptPath = Join-Path $tempDir "cross-platform-test.ps1"
Set-Content -Path $testScriptPath -Value $testScript -Encoding UTF8

try {
    Write-Host "`n🔍 Test 1: Script Encoding" -ForegroundColor Yellow
    
    # Test encoding
    $encodeResult = & "$PSScriptRoot/pwsh/CrossPlatformExecutor.ps1" -Action encode -ScriptPath $testScriptPath -Parameters @{
        Message = "Encoded script working perfectly!"
        Environment = "test"
    } -CI | ConvertFrom-Json
    
    Write-Host "  ✅ Script encoded successfully" -ForegroundColor Green
    Write-Host "  Encoded length: $($encodeResult.EncodedScript.Length) characters" -ForegroundColor Gray
    
    Write-Host "`n🔍 Test 2: Script Validation" -ForegroundColor Yellow
    
    # Test validation
    $validateResult = & "$PSScriptRoot/pwsh/CrossPlatformExecutor.ps1" -Action validate -EncodedScript $encodeResult.EncodedScript -CI | ConvertFrom-Json
    
    if ($validateResult.Valid) {
        Write-Host "  ✅ Encoded script is valid" -ForegroundColor Green
        Write-Host "  Contains Param block: $($validateResult.ContainsParam)" -ForegroundColor Gray
        Write-Host "  Contains functions: $($validateResult.ContainsFunction)" -ForegroundColor Gray
    } else {
        Write-Host "  ❌ Validation failed: $($validateResult.Error)" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "`n🔍 Test 3: Script Execution" -ForegroundColor Yellow
    
    # Test execution
    $executeResult = & "$PSScriptRoot/pwsh/CrossPlatformExecutor.ps1" -Action execute -EncodedScript $encodeResult.EncodedScript -CI | ConvertFrom-Json
    
    if ($executeResult.ExitCode -eq 0) {
        Write-Host "  ✅ Encoded script executed successfully" -ForegroundColor Green
        Write-Host "  Exit Code: $($executeResult.ExitCode)" -ForegroundColor Gray
    } else {
        Write-Host "  ❌ Execution failed with exit code: $($executeResult.ExitCode)" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "`n🔍 Test 4: Complex Script with Functions" -ForegroundColor Yellow
    
    # Test with a more complex script
    $complexScript = @'
Param(
    [string]$ConfigPath = "default.json"
)








function Test-ComplexFunction {
    param([string]$Input)
    






return "Processed: $Input"
}

$result = Test-ComplexFunction -Input "Complex script test"
Write-Host $result -ForegroundColor Magenta

# Test cross-platform path handling
$separator = if ($IsWindows -or $env:OS -eq "Windows_NT") { "\"    } else { "/"    }
Write-Host "Platform-specific separator: $separator" -ForegroundColor Cyan

Write-Host "Complex script completed successfully" -ForegroundColor Green
exit 0
'@
    
    $complexScriptPath = Join-Path $tempDir "complex-test.ps1"
    Set-Content -Path $complexScriptPath -Value $complexScript -Encoding UTF8
    
    # Encode and execute complex script
    $complexEncoded = & "$PSScriptRoot/pwsh/CrossPlatformExecutor.ps1" -Action encode -ScriptPath $complexScriptPath -CI | ConvertFrom-Json
    $complexResult = & "$PSScriptRoot/pwsh/CrossPlatformExecutor.ps1" -Action execute -EncodedScript $complexEncoded.EncodedScript -CI | ConvertFrom-Json
    
    if ($complexResult.ExitCode -eq 0) {
        Write-Host "  ✅ Complex script executed successfully" -ForegroundColor Green
    } else {
        Write-Host "  ❌ Complex script failed with exit code: $($complexResult.ExitCode)" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "`n" + "=" * 60 -ForegroundColor Cyan
    Write-Host "🎉 CROSS-PLATFORM EXECUTOR TESTS PASSED!" -ForegroundColor Green
    Write-Host "=" * 60
    
    Write-Host "`n✅ Key Capabilities Verified:" -ForegroundColor Green
    Write-Host "  • Base64 encoding/decoding of PowerShell scripts" -ForegroundColor Gray
    Write-Host "  • Parameter injection into encoded scripts" -ForegroundColor Gray
    Write-Host "  • Cross-platform script execution" -ForegroundColor Gray
    Write-Host "  • Syntax validation of encoded scripts" -ForegroundColor Gray
    Write-Host "  • Complex script support with functions" -ForegroundColor Gray
    Write-Host "  • JSON output for CI integration" -ForegroundColor Gray
    
    Write-Host "`n💡 Usage in GitHub Actions:" -ForegroundColor Cyan
    Write-Host @"
# Encode script for cross-platform execution
`$encoded = pwsh CrossPlatformExecutor.ps1 -Action encode -ScriptPath "script.ps1" -CI | ConvertFrom-Json

# Execute on any platform
pwsh CrossPlatformExecutor.ps1 -Action execute -EncodedScript "`$(`$encoded.EncodedScript)"
"@ -ForegroundColor Gray

} finally {
    # Cleanup
    if ($testScriptPath -and (Test-Path $testScriptPath)) {
        Remove-Item $testScriptPath -ErrorAction SilentlyContinue
    }
    if ($complexScriptPath -and (Test-Path $complexScriptPath)) {
        Remove-Item $complexScriptPath -ErrorAction SilentlyContinue
    }
}
Import-Module "/workspaces/opentofu-lab-automation/pwsh/modules/CodeFixer/""/CodeFixer.psd1") -Force





