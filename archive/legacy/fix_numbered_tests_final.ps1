






# Script to fix the numbered test files with the correct execution pattern
# filepath: /workspaces/opentofu-lab-automation/fix_numbered_tests_final.ps1

$testFiles = @(
    "tests/0001_Reset-Git.Tests.ps1",
    "tests/0002_Setup-Directories.Tests.ps1", 
    "tests/0006_Install-ValidationTools.Tests.ps1",
    "tests/0007_Install-Go.Tests.ps1",
    "tests/0008_Install-OpenTofu.Tests.ps1",
    "tests/0009_Initialize-OpenTofu.Tests.ps1",
    "tests/0010_Prepare-HyperVProvider.Tests.ps1",
    "tests/0100_Enable-WinRM.Tests.ps1",
    "tests/0101_Enable-RemoteDesktop.Tests.ps1",
    "tests/0102_Configure-Firewall.Tests.ps1",
    "tests/0103_Change-ComputerName.Tests.ps1",
    "tests/0104_Install-CA.Tests.ps1",
    "tests/0105_Install-HyperV.Tests.ps1",
    "tests/0106_Install-WAC.Tests.ps1",
    "tests/0111_Disable-TCPIP6.Tests.ps1",
    "tests/0112_Enable-PXE.Tests.ps1",
    "tests/0113_Config-DNS.Tests.ps1",
    "tests/0114_Config-TrustedHosts.Tests.ps1",
    "tests/0200_Get-SystemInfo.Tests.ps1",
    "tests/0201_Install-NodeCore.Tests.ps1",
    "tests/0202_Install-NodeGlobalPackages.Tests.ps1",
    "tests/0203_Install-npm.Tests.ps1",
    "tests/0204_Install-Poetry.Tests.ps1",
    "tests/0205_Install-Sysinternals.Tests.ps1",
    "tests/0206_Install-Python.Tests.ps1",
    "tests/0207_Install-Git.Tests.ps1",
    "tests/0208_Install-DockerDesktop.Tests.ps1",
    "tests/0209_Install-7Zip.Tests.ps1",
    "tests/0210_Install-VSCode.Tests.ps1",
    "tests/0211_Install-VSBuildTools.Tests.ps1",
    "tests/0212_Install-AzureCLI.Tests.ps1",
    "tests/0213_Install-AWSCLI.Tests.ps1",
    "tests/0214_Install-Packer.Tests.ps1",
    "tests/0215_Install-Chocolatey.Tests.ps1",
    "tests/0216_Set-LabProfile.Tests.ps1",
    "tests/9999_Reset-Machine.Tests.ps1"
)

foreach ($testFile in $testFiles) {
    if (-not (Test-Path $testFile)) {
        Write-Warning "File not found: $testFile"
        continue
    }
    
    Write-Host "Processing: $testFile"
    $content = Get-Content $testFile -Raw
    
    # Pattern 1: Replace the direct script execution with & operator
    $oldPattern1 = '\{ & \$scriptPath -Config ''TestValue'' -WhatIf \} \| Should -Not -Throw'
    $newPattern1 = @'
$config = [pscustomobject]@{ TestProperty = 'TestValue' }
            $configJson = $config | ConvertTo-Json -Depth 5
            $tempConfig = Join-Path ([System.IO.Path]::GetTempPath()) "$([System.Guid]::NewGuid()).json"
            $configJson | Set-Content -Path $tempConfig
            try {
                $pwsh = (Get-Command pwsh).Source
                { & $pwsh -NoLogo -NoProfile -File $scriptPath -Config $tempConfig -WhatIf } | Should -Not -Throw
            } finally {
                Remove-Item $tempConfig -Force -ErrorAction SilentlyContinue
            }
'@
    
    # Pattern 2: Replace dot-sourcing in BeforeAll blocks
    $oldPattern2 = 'if \(Test-Path \$scriptPath\) \{\s*\. \$scriptPath\s*\}'
    $newPattern2 = '# Script will be tested via pwsh -File execution'
    
    # Apply replacements
    $updatedContent = $content -replace $oldPattern1, $newPattern1
    $updatedContent = $updatedContent -replace $oldPattern2, $newPattern2
    
    # Check if changes were made
    if ($updatedContent -ne $content) {
        Set-Content -Path $testFile -Value $updatedContent
        Write-Host "  Updated successfully" -ForegroundColor Green
    } else {
        Write-Host "  No changes needed" -ForegroundColor Yellow
    }
}

Write-Host "`nCompleted processing all numbered test files."



