






# Script to fix the execution pattern in remaining numbered test files
# filepath: /workspaces/opentofu-lab-automation/fix_remaining_numbered_tests.ps1

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
    $filePath = $testFile
    if (-not (Test-Path $filePath)) {
        Write-Warning "File not found: $filePath"
        continue
    }
    
    Write-Host "Processing: $testFile"
    $content = Get-Content $filePath -Raw
    
    # Check if the file already has the new pattern
    if ($content -match '\$pwsh = \(Get-Command pwsh\)\.Source' -and 
        $content -match '& \$pwsh -NoLogo -NoProfile -File') {
        Write-Host "  Already updated - skipping"
        continue
    }
    
    # Find and replace the execution patterns
    $oldPattern1 = '(\s+)(\{ & \$script:ScriptPath -Config \$config \} \| Should -Not -Throw)'
    $oldPattern2 = '(\s+)(\{ & \$script:ScriptPath -Config \$config -WhatIf \} \| Should -Not -Throw)'
    
    $newReplacement1 = @'
$1$config = [pscustomobject]@{}
$1$configJson = $config | ConvertTo-Json -Depth 5
$1$tempConfig = Join-Path ([System.IO.Path]::GetTempPath()) "$([System.Guid]::NewGuid()).json"
$1$configJson | Set-Content -Path $tempConfig
$1try {
$1    $pwsh = (Get-Command pwsh).Source
$1    { & $pwsh -NoLogo -NoProfile -File $script:ScriptPath -Config $tempConfig } | Should -Not -Throw
$1} finally {
$1    Remove-Item $tempConfig -Force -ErrorAction SilentlyContinue
$1}
'@
    
    $newReplacement2 = @'
$1$config = [pscustomobject]@{}
$1$configJson = $config | ConvertTo-Json -Depth 5
$1$tempConfig = Join-Path ([System.IO.Path]::GetTempPath()) "$([System.Guid]::NewGuid()).json"
$1$configJson | Set-Content -Path $tempConfig
$1try {
$1    $pwsh = (Get-Command pwsh).Source
$1    { & $pwsh -NoLogo -NoProfile -File $script:ScriptPath -Config $tempConfig -WhatIf } | Should -Not -Throw
$1} finally {
$1    Remove-Item $tempConfig -Force -ErrorAction SilentlyContinue
$1}
'@
    
    $updatedContent = $content
    
    # Replace the basic execution pattern
    $updatedContent = $updatedContent -replace $oldPattern1, $newReplacement1
    
    # Replace the whatif execution pattern  
    $updatedContent = $updatedContent -replace $oldPattern2, $newReplacement2
    
    # Remove InModuleScope if present
    $updatedContent = $updatedContent -replace 'InModuleScope LabRunner \{\s*\n', ''
    $updatedContent = $updatedContent -replace '\s*\} # End InModuleScope', ''
    
    # Check if changes were made
    if ($updatedContent -ne $content) {
        Set-Content -Path $filePath -Value $updatedContent
        Write-Host "  Updated successfully" -ForegroundColor Green
    } else {
        Write-Host "  No changes needed" -ForegroundColor Yellow
    }
}

Write-Host "`nCompleted processing all numbered test files."



