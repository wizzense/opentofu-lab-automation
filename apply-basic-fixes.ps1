# Simple pattern-based fixes for test files
$testFiles = @(
    "0104_Install-CA.Tests.ps1",
    "0105_Install-HyperV.Tests.ps1", 
    "0106_Install-WAC.Tests.ps1",
    "0114_Config-TrustedHosts.Tests.ps1",
    "0200_Get-SystemInfo.Tests.ps1",
    "0201_Install-NodeCore.Tests.ps1",
    "0205_Install-Sysinternals.Tests.ps1",
    "0206_Install-Python.Tests.ps1",
    "0207_Install-Git.Tests.ps1",
    "0208_Install-DockerDesktop.Tests.ps1",
    "0209_Install-7Zip.Tests.ps1",
    "0210_Install-VSCode.Tests.ps1",
    "0211_Install-VSBuildTools.Tests.ps1",
    "0212_Install-AzureCLI.Tests.ps1",
    "0213_Install-AWSCLI.Tests.ps1",
    "0214_Install-Packer.Tests.ps1",
    "0215_Install-Chocolatey.Tests.ps1",
    "9999_Reset-Machine.Tests.ps1"
)

foreach ($testFile in $testFiles) {
    $filePath = ".\tests\$testFile"
    if (Test-Path $filePath) {
        Write-Host "Processing: $testFile" -ForegroundColor Yellow
        
        $content = Get-Content -Path $filePath -Raw
        
        # Pattern 1: Fix empty pipe elements  
        $content = $content -replace '\s*\|\s*Should\s+-Not\s+-Throw\s*\n\s*\}\s*\n\s*_', '{ Test-Path $script:ScriptPath } | Should -Not -Throw' + "`n        }`n        `n        It 'should follow naming conventions' {`n            `$script:ScriptPath | Should -Match '^.*[0-9]{4}_"
        
        # Pattern 2: Fix broken regex patterns
        $content = $content -replace '_\[A-Z\]\[a-zA-Z0-9-\]\+\\\.ps1\$\|\^\[A-Z\]\[a-zA-Z0-9-\]\+\\\.ps1\$', '[A-Z][a-zA-Z0-9-]+\.ps1$|^[A-Z][a-zA-Z0-9-]+\.ps1$'''
        
        # Pattern 3: Fix unterminated Context strings
        $content = $content -replace "Context\s+'([^']+)'\s*\{\s*~~~", "Context '$1' {"
        
        # Write the changes
        Set-Content -Path $filePath -Value $content -Encoding UTF8
        Write-Host "   Applied basic fixes to: $testFile" -ForegroundColor Green
    }
}

Write-Host "Basic pattern fixes complete!" -ForegroundColor Green
