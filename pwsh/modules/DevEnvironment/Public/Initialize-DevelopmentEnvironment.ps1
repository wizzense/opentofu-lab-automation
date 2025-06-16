#Requires -Version 7.0

<#
.SYNOPSIS
    Sets up the optimal development environment for the OpenTofu Lab Automation project.

.DESCRIPTION
    This function configures the complete development environment including:
    - Pre-commit hooks with emoji prevention and syntax validation
    - PowerShell module installation in standard locations
    - Git command aliases that automatically use PatchManager
    - VS Code integration with proper testing workflows
    - Comprehensive emoji removal from existing files

.PARAMETER InstallModulesGlobally
    Install project modules to standard PowerShell module locations for easier testing.

.PARAMETER SetupGitAliases
    Configure Git command aliases that automatically use PatchManager workflows.

.PARAMETER CleanupEmojis
    Remove existing emojis from all project files and replace with professional language.

.PARAMETER Force
    Force reinstallation/reconfiguration of all components.

.EXAMPLE
    Initialize-DevelopmentEnvironment -InstallModulesGlobally -SetupGitAliases -CleanupEmojis
    
    Sets up the complete optimal development environment.

.NOTES
    Part of the DevEnvironment module. This function integrates all development
    tools and enforces project standards comprehensively.
#>

function Initialize-DevelopmentEnvironment {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter()]
        [switch]$InstallModulesGlobally,
        
        [Parameter()]
        [switch]$SetupGitAliases,
        
        [Parameter()]
        [switch]$CleanupEmojis,
        
        [Parameter()]
        [switch]$Force
    )
    
    begin {
        Write-CustomLog "=== Initializing Optimal Development Environment ===" -Level INFO
        
        # Import required modules
        Import-Module "$env:USERPROFILE\Documents\PowerShell\Modules\Logging" -Force -ErrorAction SilentlyContinue
        Import-Module "$env:USERPROFILE\Documents\PowerShell\Modules\TestingFramework" -Force -ErrorAction SilentlyContinue
        Import-Module "$env:USERPROFILE\Documents\PowerShell\Modules\UnifiedMaintenance" -Force -ErrorAction SilentlyContinue
        
        $results = @{
            PreCommitHook = $false
            ModulesInstalled = $false
            GitAliases = $false
            EmojisRemoved = $false
            Errors = @()
        }
    }
    
    process {
        try {            # Step 1: Install pre-commit hook with emoji prevention
            if ($PSCmdlet.ShouldProcess("Pre-commit hook", "Install with emoji prevention")) {
                try {
                    Write-CustomLog "Installing pre-commit hook with emoji prevention..." -Level INFO
                    
                    # Force reinstall if requested
                    if ($Force -and (Test-Path ".git\hooks\pre-commit")) {
                        Remove-Item ".git\hooks\pre-commit" -Force
                        Write-CustomLog "Removed existing pre-commit hook for forced reinstall" -Level INFO
                    }
                    
                    $hookResult = Install-PreCommitHook
                    
                    if ($hookResult.Success) {
                        Write-CustomLog "Pre-commit hook installed successfully" -Level SUCCESS
                        $results.PreCommitHook = $true
                    }
                }
                catch {
                    $error = "Failed to install pre-commit hook: $($_.Exception.Message)"
                    Write-CustomLog $error -Level ERROR
                    $results.Errors += $error
                }
            }
            
            # Step 2: Install modules globally for easier testing
            if ($InstallModulesGlobally -and $PSCmdlet.ShouldProcess("PowerShell modules", "Install globally")) {
                try {
                    Write-CustomLog "Installing project modules to standard PowerShell locations..." -Level INFO
                    
                    # Use the PowerShell module installer we created
                    $moduleResult = Install-PowerShellModules -Install
                    
                    if ($moduleResult -and $moduleResult.Contains("SUCCESS")) {
                        Write-CustomLog "Modules installed globally successfully" -Level SUCCESS
                        $results.ModulesInstalled = $true
                    }
                }
                catch {
                    $error = "Failed to install modules globally: $($_.Exception.Message)"
                    Write-CustomLog $error -Level ERROR
                    $results.Errors += $error
                }
            }
            
            # Step 3: Setup Git aliases that use PatchManager
            if ($SetupGitAliases -and $PSCmdlet.ShouldProcess("Git aliases", "Configure PatchManager integration")) {
                try {
                    Write-CustomLog "Setting up Git aliases for automatic PatchManager usage..." -Level INFO
                    
                    # Source the Git aliases script
                    $aliasScript = "c:\Users\alexa\OneDrive\Documents\0. wizzense\opentofu-lab-automation\Setup-GitPatchManagerAliases.ps1"
                    if (Test-Path $aliasScript) {
                        & $aliasScript
                        Write-CustomLog "Git aliases configured for PatchManager integration" -Level SUCCESS
                        $results.GitAliases = $true
                    } else {
                        Write-CustomLog "Git aliases script not found at $aliasScript" -Level WARN
                    }
                }
                catch {
                    $error = "Failed to setup Git aliases: $($_.Exception.Message)"
                    Write-CustomLog $error -Level ERROR
                    $results.Errors += $error
                }
            }
            
            # Step 4: Clean up existing emojis
            if ($CleanupEmojis -and $PSCmdlet.ShouldProcess("Project files", "Remove emojis")) {
                try {
                    Write-CustomLog "Removing emojis from project files..." -Level INFO
                    
                    $emojiResult = Remove-ProjectEmojis -Path "." -CreateBackup
                    
                    Write-CustomLog "Emoji cleanup completed:" -Level SUCCESS
                    Write-CustomLog "  Files scanned: $($emojiResult.FilesScanned)" -Level INFO
                    Write-CustomLog "  Files modified: $($emojiResult.FilesModified)" -Level INFO
                    Write-CustomLog "  Emojis replaced: $($emojiResult.EmojisReplaced)" -Level INFO
                    
                    $results.EmojisRemoved = $true
                }
                catch {
                    $error = "Failed to remove emojis: $($_.Exception.Message)"
                    Write-CustomLog $error -Level ERROR
                    $results.Errors += $error
                }
            }
            
            # Step 5: Validate VS Code integration
            Write-CustomLog "Validating VS Code integration..." -Level INFO
            
            $vscodeDir = ".vscode"
            if (Test-Path $vscodeDir) {
                $requiredFiles = @(
                    "$vscodeDir\copilot-instructions.md",
                    "$vscodeDir\settings.json",
                    "$vscodeDir\tasks.json",
                    "$vscodeDir\extensions.json"
                )
                
                $missingFiles = $requiredFiles | Where-Object { -not (Test-Path $_) }
                
                if ($missingFiles.Count -eq 0) {
                    Write-CustomLog "All VS Code configuration files present" -Level SUCCESS
                } else {
                    Write-CustomLog "Missing VS Code files: $($missingFiles -join ', ')" -Level WARN
                }
            } else {
                Write-CustomLog "VS Code configuration directory not found" -Level WARN
            }
            
            # Step 6: Test the complete setup
            Write-CustomLog "Testing development environment setup..." -Level INFO
            
            try {
                # Test module imports
                $testModules = @("Logging", "TestingFramework", "UnifiedMaintenance", "DevEnvironment")
                foreach ($module in $testModules) {
                    if (Get-Module -ListAvailable -Name $module) {
                        Write-CustomLog "  Module available: $module" -Level SUCCESS
                    } else {
                        Write-CustomLog "  Module missing: $module" -Level WARN
                    }
                }
                
                # Test pre-commit hook
                if (Test-Path ".git\hooks\pre-commit") {
                    Write-CustomLog "  Pre-commit hook: Installed" -Level SUCCESS
                } else {
                    Write-CustomLog "  Pre-commit hook: Missing" -Level WARN
                }
                
                # Test Git aliases
                $gitAliases = git config --get-regexp "alias\." 2>$null
                if ($gitAliases -and $gitAliases.Count -gt 0) {
                    Write-CustomLog "  Git aliases: Configured ($($gitAliases.Count) aliases)" -Level SUCCESS
                } else {
                    Write-CustomLog "  Git aliases: Not configured" -Level WARN
                }
                
            }
            catch {
                Write-CustomLog "Error during environment testing: $($_.Exception.Message)" -Level ERROR
            }
        }
        catch {
            Write-CustomLog "Critical error during development environment setup: $($_.Exception.Message)" -Level ERROR
            throw
        }
    }
    
    end {
        Write-CustomLog "=== Development Environment Setup Complete ===" -Level INFO
        
        # Summary
        $successCount = ($results.PreCommitHook, $results.ModulesInstalled, $results.GitAliases, $results.EmojisRemoved | Where-Object { $_ }).Count
        $totalSteps = 4
        
        Write-CustomLog "Setup Summary:" -Level INFO
        Write-CustomLog "  Pre-commit hook: $(if ($results.PreCommitHook) { 'SUCCESS' } else { 'SKIPPED/FAILED' })" -Level $(if ($results.PreCommitHook) { 'SUCCESS' } else { 'WARN' })
        Write-CustomLog "  Modules globally: $(if ($results.ModulesInstalled) { 'SUCCESS' } else { 'SKIPPED/FAILED' })" -Level $(if ($results.ModulesInstalled) { 'SUCCESS' } else { 'WARN' })
        Write-CustomLog "  Git aliases: $(if ($results.GitAliases) { 'SUCCESS' } else { 'SKIPPED/FAILED' })" -Level $(if ($results.GitAliases) { 'SUCCESS' } else { 'WARN' })
        Write-CustomLog "  Emoji removal: $(if ($results.EmojisRemoved) { 'SUCCESS' } else { 'SKIPPED/FAILED' })" -Level $(if ($results.EmojisRemoved) { 'SUCCESS' } else { 'WARN' })
        
        if ($results.Errors.Count -gt 0) {
            Write-CustomLog "Errors encountered:" -Level ERROR
            foreach ($error in $results.Errors) {
                Write-CustomLog "  - $error" -Level ERROR
            }
        }
        
        if ($successCount -eq $totalSteps) {
            Write-CustomLog "OPTIMAL DEVELOPMENT ENVIRONMENT READY!" -Level SUCCESS
        } else {
            Write-CustomLog "Development environment setup completed with warnings" -Level WARN
        }
        
        return $results
    }
}

Export-ModuleMember -Function Initialize-DevelopmentEnvironment
