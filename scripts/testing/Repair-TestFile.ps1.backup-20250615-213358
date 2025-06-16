Param(
    [Parameter(Mandatory=$true)]
    [string]$FilePath
)

$ErrorActionPreference = "Stop"
Import-Module "/C:\Users\alexa\OneDrive\Documents\0. wizzense\opentofu-lab-automation//pwsh/modules/CodeFixer/" -Force -Force -Force -Force -Force -Force -Force

function Test-PesterStructure {
    param([string]$Content)
    
    $hasDescribe = $Content -match '^\s*Describe\s+.+'
    $hasDot = $Content -match '^\s*\.\s+\$PSScriptRoot[^''"]+'
    $hasBeforeAll = $Content -match '^\s*BeforeAll\s*\{'
    
    return @{
        HasDescribe = $hasDescribe
        HasDot = $hasDot
        HasBeforeAll = $hasBeforeAll
    }
}

function Add-TestHeader {
    param([string]$Content)
    
    $header = @"
. (Join-Path `$PSScriptRoot 'helpers' 'TestHelpers.ps1')

"@
    return $header + $Content
}

function Add-PesterStructure {
    param([string]$Content)
    
    $scriptName = [System.IO.Path]::GetFileNameWithoutExtension($FilePath)
    return @"
Describe '$scriptName' {
    BeforeAll {
        # Setup test environment
        Import-Module "/C:\Users\alexa\OneDrive\Documents\0. wizzense\opentofu-lab-automation//pwsh/modules/LabRunner/" -Force -Force -Force -Force -Force -Force -Force
        Import-Module "/C:\Users\alexa\OneDrive\Documents\0. wizzense\opentofu-lab-automation//pwsh/modules/CodeFixer/" -Force -Force -Force -Force -Force -Force -Force
        
        `$script:TestConfig = [pscustomobject]@{
            TestProperty = "TestValue"
        }
    }
    
    Context 'Basic Validation' {
$Content
    }
    
    AfterAll {
        # Cleanup
    }
}
"@
}

# Read and analyze the test file
$content = Get-Content -Path $FilePath -Raw
$structure = Test-PesterStructure -Content $content

# Fix the file structure
$newContent = $content

if (-not $structure.HasDot) {
    $newContent = Add-TestHeader -Content $newContent
}

if (-not $structure.HasDescribe) {
    $newContent = Add-PesterStructure -Content $newContent
}

# Save the fixed content
Set-Content -Path $FilePath -Value $newContent

# Run PowerShell Script Analyzer
$analyzerSettings = Join-Path (Split-Path $FilePath -Parent) ".pssa-test-rules.psd1"
$results = Invoke-ScriptAnalyzer -Path $FilePath -Settings $analyzerSettings

if ($results) {
    Write-Host "Script Analyzer found $($results.Count) issues in $FilePath" -ForegroundColor Yellow
    $results | ForEach-Object {
        Write-Host "[$($_.Severity)] Line $($_.Line): $($_.Message)" -ForegroundColor Yellow
    }
}

# Test if the file can be imported by Pester
try {
    $null = Invoke-Pester -Path $FilePath -PassThru
    Write-Host "✅ Test file structure validated successfully" -ForegroundColor Green
} catch {
    Write-Host "❌ Test file validation failed: $($_.Exception.Message)" -ForegroundColor Red
    throw
}






