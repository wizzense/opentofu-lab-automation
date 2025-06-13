#!/usr/bin/env pwsh
# Fix PSScriptAnalyzer installation issues in Linux/Codespaces environments

Write-Host "🔧 Fixing PSScriptAnalyzer Installation Issues" -ForegroundColor Green

# Strategy 1: Clean existing installation
Write-Host "1. Cleaning existing PSScriptAnalyzer installation..." -ForegroundColor Yellow
try {
    $modules = Get-Module PSScriptAnalyzer -ListAvailable -ErrorAction SilentlyContinue
    foreach ($module in $modules) {
        Write-Host "  Removing: $($module.ModuleBase)" -ForegroundColor Gray
        Remove-Item $module.ModuleBase -Recurse -Force -ErrorAction SilentlyContinue
    }
} catch {
    Write-Host "  No existing modules to clean" -ForegroundColor Gray
}

# Strategy 2: Set up PowerShell Gallery properly
Write-Host "2. Setting up PowerShell Gallery..." -ForegroundColor Yellow
try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    
    # Install NuGet provider
    if (-not (Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue)) {
        Write-Host "  Installing NuGet provider..." -ForegroundColor Gray
        Install-PackageProvider -Name NuGet -Force -Scope CurrentUser -Confirm:$false
    }
    
    # Register PSGallery if not exists
    if (-not (Get-PSRepository PSGallery -ErrorAction SilentlyContinue)) {
        Write-Host "  Registering PSGallery..." -ForegroundColor Gray
        Register-PSRepository -Default
    }
    
    # Set PSGallery as trusted
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
    Write-Host "  ✅ PowerShell Gallery configured" -ForegroundColor Green
} catch {
    Write-Host "  ❌ PowerShell Gallery setup failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Strategy 3: Install PSScriptAnalyzer with multiple methods
Write-Host "3. Installing PSScriptAnalyzer..." -ForegroundColor Yellow

$installMethods = @(
    @{
        Name = "Standard Install"
        ScriptBlock = { Install-Module PSScriptAnalyzer -Force -Scope CurrentUser -Repository PSGallery }
    },
    @{
        Name = "AllowClobber Install"
        ScriptBlock = { Install-Module PSScriptAnalyzer -Force -Scope CurrentUser -Repository PSGallery -AllowClobber }
    },
    @{
        Name = "Skip Publisher Check"
        ScriptBlock = { Install-Module PSScriptAnalyzer -Force -Scope CurrentUser -Repository PSGallery -SkipPublisherCheck }
    },
    @{
        Name = "All Flags"
        ScriptBlock = { Install-Module PSScriptAnalyzer -Force -Scope CurrentUser -Repository PSGallery -AllowClobber -SkipPublisherCheck -AcceptLicense }
    }
)

$installed = $false
foreach ($method in $installMethods) {
    if ($installed) { break }
    
    Write-Host "  Trying: $($method.Name)..." -ForegroundColor Gray
    try {
        & $method.ScriptBlock
        
        # Test if it actually works
        Import-Module PSScriptAnalyzer -Force
        $null = Invoke-ScriptAnalyzer -ScriptDefinition "Write-Host 'test'" -ErrorAction Stop
        
        Write-Host "  ✅ $($method.Name) successful!" -ForegroundColor Green
        $installed = $true
    } catch {
        Write-Host "  ❌ $($method.Name) failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Strategy 4: Manual download if all else fails
if (-not $installed) {
    Write-Host "4. Attempting manual download..." -ForegroundColor Yellow
    try {
        $modulePath = "$env:HOME/.local/share/powershell/Modules/PSScriptAnalyzer"
        New-Item -Path $modulePath -ItemType Directory -Force | Out-Null
        
        # Download specific version that's known to work
        $downloadUrl = "https://www.powershellgallery.com/api/v2/package/PSScriptAnalyzer/1.22.0"
        $zipPath = "/tmp/PSScriptAnalyzer.zip"
        
        Write-Host "  Downloading PSScriptAnalyzer..." -ForegroundColor Gray
        Invoke-WebRequest -Uri $downloadUrl -OutFile $zipPath -UseBasicParsing
        
        Write-Host "  Extracting to $modulePath..." -ForegroundColor Gray
        Expand-Archive -Path $zipPath -DestinationPath "/tmp/PSScriptAnalyzer" -Force
        
        # Find the actual module files and copy them
        $moduleFiles = Get-ChildItem "/tmp/PSScriptAnalyzer" -Recurse -Filter "*.psd1" | Where-Object { $_.Name -eq "PSScriptAnalyzer.psd1" }
        if ($moduleFiles) {
            $sourceDir = $moduleFiles[0].Directory.FullName
            Copy-Item "$sourceDir/*" $modulePath -Recurse -Force
            
            # Test the manual installation
            Import-Module $modulePath -Force
            $null = Invoke-ScriptAnalyzer -ScriptDefinition "Write-Host 'test'" -ErrorAction Stop
            
            Write-Host "  ✅ Manual download successful!" -ForegroundColor Green
            $installed = $true
        }
        
        # Cleanup
        Remove-Item $zipPath -Force -ErrorAction SilentlyContinue
        Remove-Item "/tmp/PSScriptAnalyzer" -Recurse -Force -ErrorAction SilentlyContinue
    } catch {
        Write-Host "  ❌ Manual download failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Final test
Write-Host "`n5. Final verification..." -ForegroundColor Yellow
try {
    Import-Module PSScriptAnalyzer -Force
    $testResult = Invoke-ScriptAnalyzer -ScriptDefinition "Write-Host 'test'"
    
    $version = (Get-Module PSScriptAnalyzer).Version
    Write-Host "✅ PSScriptAnalyzer $version is working correctly!" -ForegroundColor Green
    
    # Show available rules
    $rules = Get-ScriptAnalyzerRule
    Write-Host "📋 Available rules: $($rules.Count)" -ForegroundColor Blue
    
} catch {
    Write-Host "❌ PSScriptAnalyzer still not working: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "📝 Fallback: Will use PowerShell AST parsing instead" -ForegroundColor Yellow
}
