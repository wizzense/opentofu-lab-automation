






# Script to fix the remaining dot-sourcing pattern in numbered test files
# filepath: /workspaces/opentofu-lab-automation/fix_dot_sourcing.ps1

$testFiles = @(
    "tests/0001_Reset-Git.Tests.ps1",
    "tests/0002_Setup-Directories.Tests.ps1",
    "tests/0101_Enable-RemoteDesktop.Tests.ps1", 
    "tests/0102_Configure-Firewall.Tests.ps1",
    "tests/0111_Disable-TCPIP6.Tests.ps1",
    "tests/0112_Enable-PXE.Tests.ps1",
    "tests/0113_Config-DNS.Tests.ps1",
    "tests/0202_Install-NodeGlobalPackages.Tests.ps1"
)

foreach ($testFile in $testFiles) {
    if (-not (Test-Path $testFile)) {
        Write-Warning "File not found: $testFile"
        continue
    }
    
    Write-Host "Processing: $testFile"
    $content = Get-Content $testFile -Raw
    
    # Replace the dot-sourcing pattern in the syntax validation test
    $oldPattern = '\{ \. \$script:ScriptPath \} \| Should -Not -Throw'
    $newPattern = @'
$errors = $null
                [System.Management.Automation.Language.Parser]::ParseFile($script:ScriptPath, [ref]$null, [ref]$errors) | Out-Null
                ($$(if (errors) { $errors.Count } else { 0) | Should -Be 0 })
'@
    
    # Apply replacement
    $updatedContent = $content -replace $oldPattern, $newPattern
    
    # Check if changes were made
    if ($updatedContent -ne $content) {
        Set-Content -Path $testFile -Value $updatedContent
        Write-Host "  Updated dot-sourcing pattern successfully" -ForegroundColor Green
    } else {
        Write-Host "  No changes needed" -ForegroundColor Yellow
    }
}

Write-Host "`nCompleted processing all files with dot-sourcing issues."



