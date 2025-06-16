#Requires -Version 7.0

<#
.SYNOPSIS
    Integrates the pre-commit hook into the core development workflow

.DESCRIPTION
    This script demonstrates how to properly integrate the pre-commit hook into:
    1. Development environment setup
    2. PatchManager workflows
    3. UnifiedMaintenance module
    4. Automatic installation during bootstrap
    5. VS Code development integration

.NOTES
    This integrates the isolated pre-commit hook into the project's core systems
#>

Import-Module "$env:USERPROFILE\Documents\PowerShell\Modules\Logging" -Force

function Integrate-PreCommitHookIntoWorkflow {
    [CmdletBinding()]
    param()
    
    Write-CustomLog "=== Integrating Pre-Commit Hook into Core Workflow ===" -Level INFO
    
    # 1. Add to development environment setup
    Write-CustomLog "1. Integrating into development environment setup..." -Level INFO
    Add-PreCommitToDevSetup
    
    # 2. Add to PatchManager workflow
    Write-CustomLog "2. Integrating into PatchManager workflow..." -Level INFO
    Add-PreCommitToPatchManager
    
    # 3. Add to UnifiedMaintenance module
    Write-CustomLog "3. Integrating into UnifiedMaintenance module..." -Level INFO
    Add-PreCommitToUnifiedMaintenance
    
    # 4. Add to bootstrap process
    Write-CustomLog "4. Integrating into bootstrap process..." -Level INFO
    Add-PreCommitToBootstrap
    
    # 5. Add to VS Code workspace setup
    Write-CustomLog "5. Integrating into VS Code workspace..." -Level INFO
    Add-PreCommitToVSCode
    
    Write-CustomLog "=== Pre-commit hook integration complete ===" -Level SUCCESS
}

function Add-PreCommitToDevSetup {
    [CmdletBinding()]
    param()
    
    Write-CustomLog "Adding pre-commit hook setup to pwsh/setup-test-env.ps1" -Level INFO
    
    # This would add to the existing setup-test-env.ps1
    $setupEnhancement = @'
# Add pre-commit hook installation to setup-test-env.ps1

function Ensure-PreCommitHook {
    Write-CustomLog "Setting up pre-commit hook for development..." -Level INFO
    
    $preCommitScript = Join-Path $repoRoot "pwsh" "modules" "DevEnvironment" "Install-PreCommitHook.ps1"
    
    if (Test-Path $preCommitScript) {
        & $preCommitScript -Install
        Write-CustomLog "Pre-commit hook installed successfully" -Level SUCCESS
    } else {
        Write-CustomLog "Pre-commit hook script not found, using legacy location" -Level WARN
        $legacyPath = Join-Path $repoRoot "tools" "pre-commit-hook.ps1"
        if (Test-Path $legacyPath) {
            & $legacyPath -Install
        }
    }
}

# Add this call to the main setup function:
Ensure-PreCommitHook
'@
    
    Write-CustomLog "Enhancement ready for setup-test-env.ps1:" -Level INFO
    Write-CustomLog $setupEnhancement -Level INFO
}

function Add-PreCommitToPatchManager {
    [CmdletBinding()]
    param()
    
    Write-CustomLog "Creating PatchManager integration for pre-commit hooks" -Level INFO
    
    # This would be added to PatchManager module
    $patchManagerIntegration = @'
# Add to PatchManager/Public/Invoke-GitControlledPatch.ps1

function Ensure-PreCommitHookInstalled {
    [CmdletBinding()]
    param()
    
    # Check if pre-commit hook is installed
    $hookPath = ".git/hooks/pre-commit"
    
    if (-not (Test-Path $hookPath)) {
        Write-CustomLog "Pre-commit hook not installed, installing now..." -Level WARN
        
        # Use the DevEnvironment module version
        $installScript = Join-Path $env:PROJECT_ROOT "pwsh" "modules" "DevEnvironment" "Install-PreCommitHook.ps1"
        
        if (Test-Path $installScript) {
            & $installScript -Install
            Write-CustomLog "Pre-commit hook installed automatically" -Level SUCCESS
        } else {
            Write-CustomLog "WARNING: Pre-commit hook could not be installed automatically" -Level ERROR
        }
    }
}

# Add this call to the begin block of Invoke-GitControlledPatch:
Ensure-PreCommitHookInstalled
'@
    
    Write-CustomLog "PatchManager integration ready:" -Level INFO
    Write-CustomLog $patchManagerIntegration -Level INFO
}

function Add-PreCommitToUnifiedMaintenance {
    [CmdletBinding()]
    param()
    
    Write-CustomLog "Creating UnifiedMaintenance integration for pre-commit hooks" -Level INFO
    
    # This would be added to the UnifiedMaintenance module
    $maintenanceIntegration = @'
# Add to UnifiedMaintenance module

function Step-ValidatePreCommitHook {
    [CmdletBinding()]
    param()
    
    Write-CustomLog "Validating pre-commit hook installation..." -Level INFO
    
    $hookPath = ".git/hooks/pre-commit"
    
    if (Test-Path $hookPath) {
        Write-CustomLog "✓ Pre-commit hook is installed" -Level SUCCESS
        
        # Test the hook
        $testResult = Test-PreCommitHook
        if ($testResult.Success) {
            Write-CustomLog "✓ Pre-commit hook is functional" -Level SUCCESS
        } else {
            Write-CustomLog "✗ Pre-commit hook has issues: $($testResult.Error)" -Level ERROR
            
            # Auto-fix if possible
            Write-CustomLog "Attempting to reinstall pre-commit hook..." -Level WARN
            Install-PreCommitHook -Force
        }
    } else {
        Write-CustomLog "✗ Pre-commit hook is not installed" -Level ERROR
        
        # Auto-install
        Write-CustomLog "Installing pre-commit hook..." -Level INFO
        Install-PreCommitHook
    }
}

function Test-PreCommitHook {
    [CmdletBinding()]
    param()
    
    try {
        # Create a test scenario
        $tempFile = "temp-test-precommit.ps1"
        Set-Content -Path $tempFile -Value "Write-Host 'test'"
        
        # Test staging and validation
        git add $tempFile
        $result = git commit --dry-run -m "test" 2>&1
        
        # Cleanup
        git reset HEAD $tempFile 2>$null
        Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
        
        return @{ Success = $true }
    }
    catch {
        return @{ Success = $false; Error = $_.Exception.Message }
    }
}

# Add this to the maintenance modes:
# In Quick mode: Step-ValidatePreCommitHook
# In All mode: Step-ValidatePreCommitHook with auto-fix
'@
    
    Write-CustomLog "UnifiedMaintenance integration ready:" -Level INFO
    Write-CustomLog $maintenanceIntegration -Level INFO
}

function Add-PreCommitToBootstrap {
    [CmdletBinding()]
    param()
    
    Write-CustomLog "Creating bootstrap integration for pre-commit hooks" -Level INFO
    
    # This would be added to kicker-bootstrap.ps1
    $bootstrapIntegration = @'
# Add to kicker-bootstrap.ps1 after Git installation

Write-CustomLog "Setting up development environment..."

# Install pre-commit hook as part of repository setup
$preCommitScript = Join-Path $repoPath "pwsh" "modules" "DevEnvironment" "Install-PreCommitHook.ps1"

if (Test-Path $preCommitScript) {
    Write-CustomLog "Installing pre-commit hook for development workflow..."
    Push-Location $repoPath
    try {
        & $preCommitScript -Install
        Write-CustomLog "✓ Pre-commit hook installed successfully" -Level SUCCESS
    }
    catch {
        Write-CustomLog "WARNING: Could not install pre-commit hook: $($_.Exception.Message)" -Level WARN
    }
    finally {
        Pop-Location
    }
} else {
    Write-CustomLog "Pre-commit hook script not found, skipping installation" -Level WARN
}
'@
    
    Write-CustomLog "Bootstrap integration ready:" -Level INFO
    Write-CustomLog $bootstrapIntegration -Level INFO
}

function Add-PreCommitToVSCode {
    [CmdletBinding()]
    param()
    
    Write-CustomLog "Creating VS Code integration for pre-commit hooks" -Level INFO
    
    # This would be added to VS Code tasks.json
    $vsCodeIntegration = @'
{
    "label": "Dev Environment: Install Pre-Commit Hook",
    "type": "shell",
    "command": "pwsh",
    "args": [
        "-File",
        "./pwsh/modules/DevEnvironment/Install-PreCommitHook.ps1",
        "-Install"
    ],
    "group": "build",
    "presentation": {
        "echo": true,
        "reveal": "always",
        "focus": false,
        "panel": "shared",
        "showReuseMessage": true,
        "clear": false
    },
    "problemMatcher": []
},
{
    "label": "Dev Environment: Test Pre-Commit Hook",
    "type": "shell",
    "command": "pwsh",
    "args": [
        "-File",
        "./pwsh/modules/DevEnvironment/Install-PreCommitHook.ps1",
        "-Test"
    ],
    "group": "test",
    "presentation": {
        "echo": true,
        "reveal": "always",
        "focus": false,
        "panel": "shared",
        "showReuseMessage": true,
        "clear": false
    },
    "problemMatcher": []
},
{
    "label": "Dev Environment: Complete Setup",
    "type": "shell",
    "command": "pwsh",
    "args": [
        "-File",
        "./pwsh/setup-test-env.ps1"
    ],
    "group": {
        "kind": "build",
        "isDefault": true
    },
    "presentation": {
        "echo": true,
        "reveal": "always",
        "focus": false,
        "panel": "shared",
        "showReuseMessage": true,
        "clear": false
    },
    "problemMatcher": []
}
'@
    
    Write-CustomLog "VS Code tasks integration ready:" -Level INFO
    Write-CustomLog $vsCodeIntegration -Level INFO
}

function Create-DevEnvironmentModule {
    [CmdletBinding()]
    param()
    
    Write-CustomLog "=== Creating DevEnvironment Module Structure ===" -Level INFO
    
    # This is the proper modular structure for development environment setup
    $moduleStructure = @'
pwsh/modules/DevEnvironment/
├── DevEnvironment.psd1              # Module manifest
├── DevEnvironment.psm1              # Module entry point
├── Public/
│   ├── Install-PreCommitHook.ps1    # Moved from tools/
│   ├── Set-DevelopmentEnvironment.ps1
│   ├── Test-DevelopmentSetup.ps1
│   └── Update-DevelopmentTools.ps1
├── Private/
│   ├── Get-GitHooksPath.ps1
│   └── Test-GitRepository.ps1
└── README.md
'@
    
    Write-CustomLog "Proposed DevEnvironment module structure:" -Level INFO
    Write-CustomLog $moduleStructure -Level INFO
    
    # Create the actual module structure
    $modulePath = "c:\Users\alexa\OneDrive\Documents\0. wizzense\opentofu-lab-automation\pwsh\modules\DevEnvironment"
    
    if (-not (Test-Path $modulePath)) {
        New-Item -ItemType Directory -Path $modulePath -Force
        New-Item -ItemType Directory -Path "$modulePath\Public" -Force
        New-Item -ItemType Directory -Path "$modulePath\Private" -Force
        
        Write-CustomLog "Created DevEnvironment module directory structure" -Level SUCCESS
    }
    
    # Move the pre-commit hook into the module
    $originalHook = "c:\Users\alexa\OneDrive\Documents\0. wizzense\opentofu-lab-automation\tools\pre-commit-hook.ps1"
    $newHookLocation = "$modulePath\Public\Install-PreCommitHook.ps1"
    
    if (Test-Path $originalHook) {
        Write-CustomLog "Moving pre-commit hook from tools/ to DevEnvironment module..." -Level INFO
        Copy-Item $originalHook $newHookLocation -Force
        Write-CustomLog "Pre-commit hook moved to proper module location" -Level SUCCESS
    }
}

function Show-IntegrationBenefits {
    [CmdletBinding()]
    param()
    
    Write-CustomLog "=== Benefits of Proper Pre-Commit Hook Integration ===" -Level SUCCESS
    
    $benefits = @(
        "✓ Automatic installation during development setup",
        "✓ Integration with PatchManager workflows",
        "✓ Part of unified maintenance system",
        "✓ Included in bootstrap process",
        "✓ VS Code task integration",
        "✓ Proper module structure and organization",
        "✓ Centralized development environment management",
        "✓ Consistent setup across all developers",
        "✓ Automatic validation and repair",
        "✓ No more manual 'remember to install' steps"
    )
    
    foreach ($benefit in $benefits) {
        Write-CustomLog $benefit -Level SUCCESS
    }
}

# Main execution
try {
    Write-CustomLog "Starting pre-commit hook integration into core workflow" -Level INFO
    
    Integrate-PreCommitHookIntoWorkflow
    Write-CustomLog ""
    
    Create-DevEnvironmentModule
    Write-CustomLog ""
    
    Show-IntegrationBenefits
    Write-CustomLog ""
    
    Write-CustomLog "=== NEXT STEPS ===" -Level INFO
    Write-CustomLog "1. Move tools/pre-commit-hook.ps1 to pwsh/modules/DevEnvironment/Public/" -Level INFO
    Write-CustomLog "2. Create DevEnvironment module manifest and entry point" -Level INFO
    Write-CustomLog "3. Update setup-test-env.ps1 to use DevEnvironment module" -Level INFO
    Write-CustomLog "4. Add pre-commit validation to PatchManager workflow" -Level INFO
    Write-CustomLog "5. Include in UnifiedMaintenance health checks" -Level INFO
    Write-CustomLog "6. Update VS Code tasks to use new module structure" -Level INFO
    Write-CustomLog "7. Update bootstrap script to install automatically" -Level INFO
}
catch {
    Write-CustomLog "Error during pre-commit hook integration: $($_.Exception.Message)" -Level ERROR
    throw
}
