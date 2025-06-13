



# Test script for Format-ScriptName function
. ./tests/helpers/New-AutoTestGenerator.ps1

Write-Host "Testing Format-ScriptName function:" -ForegroundColor Yellow

$testCases = @(
    'install-node.ps1',
    'configure_dns.ps1', 
    'enable-winrm.ps1',
    'setup-environment.ps1',
    'get-system-info.ps1'
)

foreach ($testCase in $testCases) {
    try {
        $result = Format-ScriptName $testCase
        Write-Host "  $testCase -> $result" -ForegroundColor Green
    } catch {
        Write-Host "  ERROR with $testCase : $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Test with runner_scripts path
Write-Host ""
Write-Host "Testing with runner_scripts path:" -ForegroundColor Yellow
$runnerCase = 'pwsh/runner_scripts/install-docker.ps1'
try {
    $result = Format-ScriptName $runnerCase
    Write-Host "  $runnerCase -> $result" -ForegroundColor Green
} catch {
    Write-Host "  ERROR with $runnerCase : $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "Test completed" -ForegroundColor Cyan


