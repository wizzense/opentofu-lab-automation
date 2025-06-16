# Pre-commit hook for test validation
# This ensures no broken tests can be committed

# Run Pester tests with basic syntax validation
$config = New-PesterConfiguration
$config.Run.Path = ".\tests"
$config.Run.Exit = $true
$config.Output.Verbosity = "Detailed"

$result = Invoke-Pester -Configuration $config

if ($result.FailedCount -gt 0) {
    Write-Host "[FAIL] Test validation failed! Cannot commit." -ForegroundColor Red
    Write-Host "Please fix the failing tests before committing." -ForegroundColor Yellow
    exit 1
}

Write-Host "[PASS] All tests validated successfully!" -ForegroundColor Green
