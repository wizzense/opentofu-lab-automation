# Test Generator for OpenTofu Lab Automation
# Generates standardized, robust test files that won't break the testing system

Param(
    [Parameter(Mandatory=$true)]
    [string]$ScriptName,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("Installer", "Configuration", "SystemInfo", "Setup", "Cleanup", "Validation", "Security")]
    [string]$ScriptType = "Installer",
    
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = ".\tests\",
    
    [Parameter(Mandatory=$false)]
    [switch]$OverwriteExisting,
    
    [Parameter(Mandatory=$false)]
    [switch]$Validate
)

function New-StandardTest {
    param(
        [string]$ScriptName,
        [string]$ScriptType,
        [string]$OutputPath,
        [bool]$OverwriteExisting
    )
    
    Write-Host "Generating test for: $ScriptName" -ForegroundColor Cyan
    
    # Load template
    $templatePath = Join-Path $PSScriptRoot "helpers" "StandardTestTemplate.ps1"
    if (-not (Test-Path $templatePath)) {
        throw "Template not found at: $templatePath"
    }
    
    $template = Get-Content $templatePath -Raw
    
    # Determine tag and context based on script type
    $tagMappings = @{
        "Installer" = @{ Tag = "Installer"; Context = "Installation" }
        "Configuration" = @{ Tag = "Configuration"; Context = "Configuration" }
        "SystemInfo" = @{ Tag = "SystemInfo"; Context = "System Information" }
        "Setup" = @{ Tag = "Setup"; Context = "Setup" }
        "Cleanup" = @{ Tag = "Cleanup"; Context = "Cleanup" }
        "Validation" = @{ Tag = "Validation"; Context = "Validation" }
        "Security" = @{ Tag = "Security"; Context = "Security" }
    }
    
    $mapping = $tagMappings[$ScriptType]
    if (-not $mapping) {
        $mapping = @{ Tag = "Unknown"; Context = "General" }
    }
    
    # Replace template tokens
    $testContent = $template
    $testContent = $testContent -replace '\{SCRIPT_NAME\}', $ScriptName
    $testContent = $testContent -replace '\{TAG\}', $mapping.Tag
    $testContent = $testContent -replace '\{CONTEXT_NAME\}', $mapping.Context
    
    # Generate test filename
    $testFileName = "$ScriptName.Tests.ps1"
    $testFilePath = Join-Path $OutputPath $testFileName
    
    # Check if file exists
    if ((Test-Path $testFilePath) -and -not $OverwriteExisting) {
        Write-Warning "Test file already exists: $testFilePath"
        Write-Warning "Use -OverwriteExisting to replace it"
        return $false
    }
    
    # Ensure output directory exists
    if (-not (Test-Path $OutputPath)) {
        New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
    }
    
    # Write test file
    try {
        $testContent | Set-Content -Path $testFilePath -Encoding UTF8
        Write-Host "[PASS] Generated test file: $testFilePath" -ForegroundColor Green
        
        # Validate the generated test
        if ($Validate) {
            Write-Host "Validating generated test..." -ForegroundColor Yellow
            $validation = Test-GeneratedTest -Path $testFilePath
            if ($validation.IsValid) {
                Write-Host "[PASS] Test validation passed" -ForegroundColor Green
            } else {
                Write-Error "[FAIL] Test validation failed: $($validation.Errors -join '; ')"
                return $false
            }
        }
        
        return $true
    } catch {
        Write-Error "Failed to generate test file: $($_.Exception.Message)"
        return $false
    }
}

function Test-GeneratedTest {
    param([string]$Path)
    
    $errors = @()
    $isValid = $true
    
    try {
        # Test 1: PowerShell syntax validation
        $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $Path -Raw), [ref]$null)
          # Test 2: Try to run Pester discovery (without execution)
        $null = Invoke-Pester -Path $Path -DryRun -ErrorAction Stop
        
        # Test 3: Check for required elements
        $content = Get-Content $Path -Raw
        
        if ($content -notmatch 'Describe\s+.*Tests') {
            $errors += "Missing Describe block"
            $isValid = $false
        }
        
        if ($content -notmatch 'Context\s+.*Validation') {
            $errors += "Missing validation Context"
            $isValid = $false
        }
        
        if ($content -notmatch 'It\s+.*should') {
            $errors += "Missing It blocks"
            $isValid = $false
        }
        
    } catch {
        $errors += "Syntax or structure error: $($_.Exception.Message)"
        $isValid = $false
    }
    
    return @{
        IsValid = $isValid
        Errors = $errors
    }
}

function Repair-ExistingTests {
    param(
        [string]$TestsPath = ".\tests\",
        [switch]$WhatIf
    )
    
    Write-Host "Repairing existing test files using standard template..." -ForegroundColor Cyan
    
    $testFiles = Get-ChildItem -Path $TestsPath -Filter "*.Tests.ps1" | Where-Object { $_.Name -match '^[0-9]{4}_.*\.Tests\.ps1$' }
    
    foreach ($testFile in $testFiles) {
        $scriptName = $testFile.BaseName -replace '\.Tests$', ''
        
        Write-Host "Processing: $($testFile.Name)" -ForegroundColor Yellow
        
        # Determine script type based on name patterns
        $scriptType = switch -Regex ($scriptName) {
            '^[0-9]{4}_Install-' { "Installer" }
            '^[0-9]{4}_Config-' { "Configuration" }
            '^[0-9]{4}_Get-' { "SystemInfo" }
            '^[0-9]{4}_Setup-' { "Setup" }
            '^[0-9]{4}_Reset-' { "Cleanup" }
            '^[0-9]{4}_Enable-' { "Configuration" }
            default { "Installer" }
        }
        
        if ($WhatIf) {
            Write-Host "  Would repair: $scriptName as $scriptType" -ForegroundColor Gray
        } else {
            # Backup original if it exists
            if (Test-Path $testFile.FullName) {
                $backupPath = "$($testFile.FullName).backup.$(Get-Date -Format 'yyyyMMdd-HHmmss')"
                Copy-Item $testFile.FullName $backupPath
                Write-Host "  📁 Backed up original to: $backupPath" -ForegroundColor Gray
            }
            
            # Generate new test
            $success = New-StandardTest -ScriptName $scriptName -ScriptType $scriptType -OutputPath $TestsPath -OverwriteExisting $true
            
            if ($success) {
                Write-Host "  [PASS] Repaired: $($testFile.Name)" -ForegroundColor Green
            } else {
                Write-Host "  [FAIL] Failed to repair: $($testFile.Name)" -ForegroundColor Red
            }
        }
    }
}

# Main execution
if ($ScriptName) {
    $success = New-StandardTest -ScriptName $ScriptName -ScriptType $ScriptType -OutputPath $OutputPath -OverwriteExisting $OverwriteExisting
    
    if ($success) {
        Write-Host "[PASS] Test generation completed successfully!" -ForegroundColor Green
        Write-Host "Run the following to test your new test file:" -ForegroundColor Cyan
        Write-Host "Invoke-Pester -Path `"$OutputPath$ScriptName.Tests.ps1`" -PassThru" -ForegroundColor Gray
    } else {
        Write-Error "[FAIL] Test generation failed!"
        exit 1
    }
} else {
    Write-Host "Test Generator for OpenTofu Lab Automation" -ForegroundColor Cyan
    Write-Host "Usage examples:" -ForegroundColor Yellow
    Write-Host "  .\New-StandardTest.ps1 -ScriptName '0205_Install-Sysinternals' -ScriptType 'Installer'" -ForegroundColor Gray
    Write-Host "  .\New-StandardTest.ps1 -ScriptName '0300_Config-Network' -ScriptType 'Configuration'" -ForegroundColor Gray
    Write-Host "  .\New-StandardTest.ps1 -ScriptName 'MyScript' -Validate" -ForegroundColor Gray
    Write-Host ""
    Write-Host "To repair all existing tests:" -ForegroundColor Yellow
    Write-Host "  Repair-ExistingTests -WhatIf" -ForegroundColor Gray
    Write-Host "  Repair-ExistingTests" -ForegroundColor Gray
}
