# Corrected script to fix the execution pattern in numbered test files
# filepath: /workspaces/opentofu-lab-automation/fix_numbered_tests_corrected.ps1

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

# Function to restore files from git
function Restore-TestFile {
    param(string$FilePath)
    






Write-Host "Restoring $FilePath from git..."
    git checkout HEAD -- $FilePath
}

# Function to fix the test file execution pattern
function Fix-TestFile {
    param(string$FilePath)
    
    






$content = Get-Content $FilePath -Raw
    
    # Define the working pattern to look for and replace
    $basicExecutionPattern = @'
It 'should execute without errors with valid config' {
                \$config = \pscustomobject\@\{\}
                \{ & \$script:ScriptPath -Config \$config \} \ Should -Not -Throw
            \}
'@
    
    $whatifExecutionPattern = @'
It 'should handle whatif parameter' {
                \$config = \pscustomobject\@\{\}
                \{ & \$script:ScriptPath -Config \$config -WhatIf \} \ Should -Not -Throw
            \}
'@
    
    # The corrected patterns to replace them with
    $newBasicPattern = @'
It 'should execute without errors with valid config' {
                $config = pscustomobject@{}
                $configJson = config | ConvertTo-Json -Depth 5
                $tempConfig = Join-Path (System.IO.Path::GetTempPath()) "$(System.Guid::NewGuid()).json"
                configJson | Set-Content -Path $tempConfig
                try {
                    $pwsh = (Get-Command pwsh).Source
                    { & $pwsh -NoLogo -NoProfile -File $script:ScriptPath -Config $tempConfig }  Should -Not -Throw
                } finally {
                    Remove-Item $tempConfig -Force -ErrorAction SilentlyContinue
                }
            }
'@
    
    $newWhatifPattern = @'
It 'should handle whatif parameter' {
                $config = pscustomobject@{}
                $configJson = config | ConvertTo-Json -Depth 5
                $tempConfig = Join-Path (System.IO.Path::GetTempPath()) "$(System.Guid::NewGuid()).json"
                configJson | Set-Content -Path $tempConfig
                try {
                    $pwsh = (Get-Command pwsh).Source
                    { & $pwsh -NoLogo -NoProfile -File $script:ScriptPath -Config $tempConfig -WhatIf }  Should -Not -Throw
                } finally {
                    Remove-Item $tempConfig -Force -ErrorAction SilentlyContinue
                }
            }
'@
    
    # Apply replacements using regex
    $updatedContent = $content -replace $basicExecutionPattern, $newBasicPattern
    $updatedContent = $updatedContent -replace $whatifExecutionPattern, $newWhatifPattern
    
    # Remove any InModuleScope wrappers if present
    $updatedContent = $updatedContent -replace 'InModuleScope LabRunner \{\s*\n', ''
    $updatedContent = $updatedContent -replace '\s*\} # End InModuleScope', ''
    
    # Check if changes were made
    if ($updatedContent -ne $content) {
        Set-Content -Path $FilePath -Value $updatedContent
        Write-Host "  Updated successfully" -ForegroundColor Green
    } else {
        Write-Host "  No changes made" -ForegroundColor Yellow
    }
}

foreach ($testFile in $testFiles) {
    $filePath = $testFile
    if (-not (Test-Path $filePath)) {
        Write-Warning "File not found: $filePath"
        continue
    }
    
    Write-Host "Processing: $testFile"
    
    # First, restore the file from git to undo any bad changes
    Restore-TestFile $filePath
    
    # Now apply the correct fix
    Fix-TestFile $filePath
}

Write-Host "`nCompleted processing all numbered test files."




