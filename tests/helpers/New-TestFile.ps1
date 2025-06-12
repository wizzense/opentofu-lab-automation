<#
.SYNOPSIS
Generates test files based on templates for new runner scripts

.DESCRIPTION
This script analyzes runner scripts and generates appropriate test files
using the extensible testing framework templates.

.EXAMPLE
./New-TestFile.ps1 -ScriptName "0025_Install-Docker.ps1" -TestType "Installer"

.EXAMPLE
./New-TestFile.ps1 -ScriptName "0050_Enable-Hyper-V.ps1" -TestType "Feature"
#>

param(
    [Parameter(Mandatory)]
    [string]$ScriptName,
    
    [Parameter(Mandatory)]
    [ValidateSet('Installer', 'Feature', 'Service', 'Configuration', 'CrossPlatform', 'Integration')]
    [string]$TestType,
    
    [string]$OutputPath,
    
    [switch]$Overwrite,
    
    [switch]$DryRun
)

# Load the framework
. (Join-Path $PSScriptRoot 'TestHelpers.ps1')

function Get-ScriptAnalysis {
    param([string]$ScriptPath)
    
    if (-not (Test-Path $ScriptPath)) {
        throw "Script not found: $ScriptPath"
    }
    
    $content = Get-Content $ScriptPath -Raw
    $ast = [System.Management.Automation.Language.Parser]::ParseFile($ScriptPath, [ref]$null, [ref]$null)
    
    $analysis = @{
        HasConfigParam = $content -match 'Param\s*\(\s*.*\$Config'
        HasLabStep = $content -match 'Invoke-LabStep'
        HasImportModule = $content -match 'Import-Module.*LabRunner'
        ConfigProperties = @()
        MockCandidates = @()
        Platform = 'Any'
    }
    
    # Extract configuration properties that look like boolean flags
    $configMatches = [regex]::Matches($content, '\$Config\.([A-Za-z][A-Za-z0-9_]*)')
    foreach ($match in $configMatches) {
        $propertyName = $match.Groups[1].Value
        if ($propertyName -notin $analysis.ConfigProperties) {
            $analysis.ConfigProperties += $propertyName
        }
    }
    
    # Find command invocations that might need mocking
    $commandMatches = [regex]::Matches($content, '(Start-Process|Invoke-WebRequest|Get-Command|Install-WindowsFeature|Enable-WindowsOptionalFeature|New-NetFirewallRule|Get-Service)')
    foreach ($match in $commandMatches) {
        $command = $match.Groups[1].Value
        if ($command -notin $analysis.MockCandidates) {
            $analysis.MockCandidates += $command
        }
    }
    
    # Detect platform specificity
    if ($content -match 'Windows|Hyper-V|Net-|WindowsFeature|Registry') {
        $analysis.Platform = 'Windows'
    } elseif ($content -match 'apt-get|yum|systemctl') {
        $analysis.Platform = 'Linux'
    } elseif ($content -match 'brew|launchctl') {
        $analysis.Platform = 'macOS'
    }
    
    return $analysis
}

function New-InstallerTestContent {
    param($ScriptName, $Analysis)
    
    $enabledProperty = $Analysis.ConfigProperties | Where-Object { $_ -match 'Install' } | Select-Object -First 1
    if (-not $enabledProperty) {
        $enabledProperty = 'InstallEnabled'  # fallback
    }
    
    $installerCommand = $Analysis.MockCandidates | Where-Object { $_ -match 'Start-Process|Install' } | Select-Object -First 1
    if (-not $installerCommand) {
        $installerCommand = 'Start-Process'  # fallback
    }
    
    $platformClause = if ($Analysis.Platform -ne 'Any') { " -RequiredPlatforms @('$($Analysis.Platform)')" } else { '' }
    
    return @"
# filepath: /workspaces/opentofu-lab-automation/tests/$($ScriptName -replace '\.ps1$', '.Tests.ps1')
<#
.SYNOPSIS
Tests for $ScriptName

.DESCRIPTION
Auto-generated test using the extensible testing framework.
Customize as needed for specific requirements.
#>

. (Join-Path `$PSScriptRoot 'TestDriveCleanup.ps1')
. (Join-Path `$PSScriptRoot 'helpers' 'TestHelpers.ps1')
. (Join-Path `$PSScriptRoot 'helpers' 'TestTemplates.ps1')

# Generated installer test for $ScriptName
New-InstallerScriptTest -ScriptName '$ScriptName' -EnabledProperty '$enabledProperty' -InstallerCommand '$installerCommand'$platformClause -AdditionalMocks @{
    # Add any script-specific mocks here
    # Example:
    # 'Get-SomeSpecificCommand' = { [PSCustomObject]@{ Status = 'Ready' } }
}

# TODO: Review and customize the following:
# 1. Verify the EnabledProperty '$enabledProperty' is correct
# 2. Verify the InstallerCommand '$installerCommand' is correct  
# 3. Add any additional configuration properties needed
# 4. Add script-specific mock implementations
# 5. Add custom validation scenarios if needed
"@
}

function New-FeatureTestContent {
    param($ScriptName, $Analysis)
    
    $enabledProperty = $Analysis.ConfigProperties | Where-Object { $_ -match 'Enable|Allow' } | Select-Object -First 1
    if (-not $enabledProperty) {
        $enabledProperty = 'FeatureEnabled'  # fallback
    }
    
    $featureCommands = $Analysis.MockCandidates | Where-Object { $_ -match 'Enable|Install|New-' }
    if (-not $featureCommands) {
        $featureCommands = @('Enable-WindowsOptionalFeature')  # fallback
    }
    
    $commandsArray = "'" + ($featureCommands -join "', '") + "'"
    $platformClause = if ($Analysis.Platform -ne 'Any') { " -RequiredPlatforms @('$($Analysis.Platform)')" } else { '' }
    
    return @"
# filepath: /workspaces/opentofu-lab-automation/tests/$($ScriptName -replace '\.ps1$', '.Tests.ps1')
<#
.SYNOPSIS
Tests for $ScriptName

.DESCRIPTION
Auto-generated test using the extensible testing framework.
Customize as needed for specific requirements.
#>

. (Join-Path `$PSScriptRoot 'TestDriveCleanup.ps1')
. (Join-Path `$PSScriptRoot 'helpers' 'TestHelpers.ps1')
. (Join-Path `$PSScriptRoot 'helpers' 'TestTemplates.ps1')

# Generated feature test for $ScriptName
New-FeatureScriptTest -ScriptName '$ScriptName' -EnabledProperty '$enabledProperty' -FeatureCommands @($commandsArray)$platformClause -AdditionalMocks @{
    # Add any script-specific mocks here
    # Example:
    # 'Get-WindowsOptionalFeature' = { [PSCustomObject]@{ State = 'Disabled' } }
}

# TODO: Review and customize the following:
# 1. Verify the EnabledProperty '$enabledProperty' is correct
# 2. Verify the FeatureCommands are correct
# 3. Add any additional configuration properties needed
# 4. Add script-specific mock implementations
"@
}

function New-ServiceTestContent {
    param($ScriptName, $Analysis)
    
    $serviceName = 'TestService'  # This would need manual specification
    
    return @"
# filepath: /workspaces/opentofu-lab-automation/tests/$($ScriptName -replace '\.ps1$', '.Tests.ps1')
<#
.SYNOPSIS
Tests for $ScriptName

.DESCRIPTION
Auto-generated test using the extensible testing framework.
Customize as needed for specific requirements.
#>

. (Join-Path `$PSScriptRoot 'TestDriveCleanup.ps1')
. (Join-Path `$PSScriptRoot 'helpers' 'TestHelpers.ps1')
. (Join-Path `$PSScriptRoot 'helpers' 'TestTemplates.ps1')

# Generated service test for $ScriptName
New-ServiceScriptTest -ScriptName '$ScriptName' -ServiceName '$serviceName' -RequiredPlatforms @('Windows') -AdditionalMocks @{
    # Add any script-specific mocks here
}

# TODO: Review and customize the following:
# 1. Set the correct ServiceName (currently: '$serviceName')
# 2. Add any additional configuration properties needed
# 3. Add script-specific mock implementations
"@
}

function New-ConfigurationTestContent {
    param($ScriptName, $Analysis)
    
    $enabledProperty = $Analysis.ConfigProperties | Where-Object { $_ -match 'Config|Setup|Set' } | Select-Object -First 1
    if (-not $enabledProperty) {
        $enabledProperty = 'ConfigEnabled'  # fallback
    }
    
    $configCommands = $Analysis.MockCandidates | Where-Object { $_ -match 'Set-|New-|Config' }
    if (-not $configCommands) {
        $configCommands = @('Set-ItemProperty')  # fallback
    }
    
    $commandsArray = "'" + ($configCommands -join "', '") + "'"
    $platformClause = if ($Analysis.Platform -ne 'Any') { " -RequiredPlatforms @('$($Analysis.Platform)')" } else { '' }
    
    return @"
# filepath: /workspaces/opentofu-lab-automation/tests/$($ScriptName -replace '\.ps1$', '.Tests.ps1')
<#
.SYNOPSIS
Tests for $ScriptName

.DESCRIPTION
Auto-generated test using the extensible testing framework.
Customize as needed for specific requirements.
#>

. (Join-Path `$PSScriptRoot 'TestDriveCleanup.ps1')
. (Join-Path `$PSScriptRoot 'helpers' 'TestHelpers.ps1')
. (Join-Path `$PSScriptRoot 'helpers' 'TestTemplates.ps1')

# Generated configuration test for $ScriptName
New-ConfigurationScriptTest -ScriptName '$ScriptName' -EnabledProperty '$enabledProperty' -ConfigurationCommands @($commandsArray)$platformClause -AdditionalMocks @{
    # Add any script-specific mocks here
}

# TODO: Review and customize the following:
# 1. Verify the EnabledProperty '$enabledProperty' is correct
# 2. Verify the ConfigurationCommands are correct
# 3. Add any additional configuration properties needed
# 4. Add script-specific mock implementations
"@
}

# Main execution
try {
    $scriptPath = Get-RunnerScriptPath $ScriptName
    if (-not $scriptPath -or -not (Test-Path $scriptPath)) {
        throw "Script not found: $ScriptName"
    }
    
    Write-Host "Analyzing script: $scriptPath" -ForegroundColor Green
    $analysis = Get-ScriptAnalysis $scriptPath
    
    Write-Host "Analysis results:" -ForegroundColor Yellow
    Write-Host "  Platform: $($analysis.Platform)"
    Write-Host "  Config Properties: $($analysis.ConfigProperties -join ', ')"
    Write-Host "  Mock Candidates: $($analysis.MockCandidates -join ', ')"
    
    # Generate test content based on type
    $testContent = switch ($TestType) {
        'Installer' { New-InstallerTestContent $ScriptName $analysis }
        'Feature' { New-FeatureTestContent $ScriptName $analysis }
        'Service' { New-ServiceTestContent $ScriptName $analysis }
        'Configuration' { New-ConfigurationTestContent $ScriptName $analysis }
        default { throw "Test type $TestType not implemented yet" }
    }
    
    # Determine output path
    if (-not $OutputPath) {
        $OutputPath = Join-Path $PSScriptRoot '..' ($ScriptName -replace '\.ps1$', '.Tests.ps1')
    }
    
    if ($DryRun) {
        Write-Host "`nGenerated test content:" -ForegroundColor Cyan
        Write-Host $testContent
        Write-Host "`nWould write to: $OutputPath" -ForegroundColor Yellow
    } else {
        if ((Test-Path $OutputPath) -and -not $Overwrite) {
            throw "Test file already exists: $OutputPath. Use -Overwrite to replace it."
        }
        
        Set-Content -Path $OutputPath -Value $testContent -Encoding UTF8
        Write-Host "Generated test file: $OutputPath" -ForegroundColor Green
        Write-Host "Please review and customize the generated test as needed." -ForegroundColor Yellow
    }
    
} catch {
    Write-Error "Failed to generate test: $_"
    exit 1
}
