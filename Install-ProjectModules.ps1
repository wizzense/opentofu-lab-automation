#Requires -Version 7.0

<#
.SYNOPSIS
    Installs project modules to standard PowerShell module locations for seamless testing

.DESCRIPTION
    This script solves the constant module import issues by installing our project modules
    (LabRunner, PatchManager, Logging, etc.) to the standard PowerShell module locations
    where they can be imported normally without complex path gymnastics.

.PARAMETER Mode
    Install: Installs modules to standard locations
    Uninstall: Removes modules and cleans up
    Reinstall: Uninstalls then installs
    Status: Shows current installation status

.PARAMETER Scope
    CurrentUser: Install for current user only (default, no admin required)
    AllUsers: Install for all users (requires admin)

.PARAMETER Force
    Force overwrite existing modules

.EXAMPLE
    .\Install-ProjectModules.ps1 -Mode Install
    Installs all project modules for current user

.EXAMPLE
    .\Install-ProjectModules.ps1 -Mode Uninstall
    Removes all installed project modules

.EXAMPLE
    .\Install-ProjectModules.ps1 -Mode Status
    Shows which project modules are currently installed
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter()]
    [ValidateSet("Install", "Uninstall", "Reinstall", "Status")]
    [string]$Mode = "Install",
    
    [Parameter()]
    [ValidateSet("CurrentUser", "AllUsers")]
    [string]$Scope = "CurrentUser",
    
    [Parameter()]
    [switch]$Force
)

# Project modules to manage
$ProjectModules = @(
    @{
        Name = "LabRunner"
        SourcePath = ".\pwsh\modules\LabRunner"
        Description = "Core lab automation and execution framework"
    },
    @{
        Name = "PatchManager" 
        SourcePath = ".\pwsh\modules\PatchManager"
        Description = "Git-controlled patch management and validation"
    },
    @{
        Name = "Logging"
        SourcePath = ".\pwsh\modules\Logging"
        Description = "Centralized logging system"
    },
    @{
        Name = "TestingFramework"
        SourcePath = ".\pwsh\modules\TestingFramework"
        Description = "Unified testing and validation framework"
    },
    @{
        Name = "UnifiedMaintenance"
        SourcePath = ".\pwsh\modules\UnifiedMaintenance"  
        Description = "Comprehensive maintenance automation"
    },
    @{
        Name = "ScriptManager"
        SourcePath = ".\pwsh\modules\ScriptManager"
        Description = "One-off script management (legacy)"
    }
)

function Write-ModuleLog {
    param($Message, $Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
        "SUCCESS" { "Green" }
        "WARN" { "Yellow" } 
        "ERROR" { "Red" }
        "INFO" { "Cyan" }
        default { "White" }
    }
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}

function Get-ModuleInstallPath {
    param([string]$ModuleName, [string]$Scope)
    
    if ($Scope -eq "AllUsers") {
        $basePath = $env:ProgramFiles
        if (-not $basePath) { $basePath = "C:\Program Files" }
        return Join-Path $basePath "WindowsPowerShell\Modules\$ModuleName"
    } else {
        $documentsPath = [Environment]::GetFolderPath('MyDocuments')
        return Join-Path $documentsPath "WindowsPowerShell\Modules\$ModuleName"
    }
}

function Test-ModuleInstallation {
    param([string]$ModuleName)
    
    $installed = Get-Module -ListAvailable -Name $ModuleName -ErrorAction SilentlyContinue
    if ($installed) {
        return @{
            Installed = $true
            Version = $installed[0].Version
            Path = $installed[0].ModuleBase
            Multiple = $installed.Count -gt 1
        }
    } else {
        return @{
            Installed = $false
            Version = $null
            Path = $null
            Multiple = $false
        }
    }
}

function Install-ProjectModule {
    param(
        [hashtable]$ModuleInfo,
        [string]$Scope,
        [switch]$Force
    )
    
    $sourcePath = Resolve-Path $ModuleInfo.SourcePath -ErrorAction SilentlyContinue
    if (-not $sourcePath) {
        Write-ModuleLog "Source path not found: $($ModuleInfo.SourcePath)" -Level ERROR
        return $false
    }
    
    $destinationPath = Get-ModuleInstallPath -ModuleName $ModuleInfo.Name -Scope $Scope
    
    # Check if already installed
    $existing = Test-ModuleInstallation -ModuleName $ModuleInfo.Name
    if ($existing.Installed -and -not $Force) {
        Write-ModuleLog "$($ModuleInfo.Name) already installed at $($existing.Path)" -Level WARN
        return $true
    }
    
    try {
        if ($PSCmdlet.ShouldProcess($destinationPath, "Install module $($ModuleInfo.Name)")) {
            # Create destination directory
            if (-not (Test-Path $destinationPath)) {
                New-Item -ItemType Directory -Path $destinationPath -Force | Out-Null
            } elseif ($Force) {
                # Remove existing installation
                Remove-Item -Path $destinationPath -Recurse -Force -ErrorAction SilentlyContinue
                New-Item -ItemType Directory -Path $destinationPath -Force | Out-Null
            }
            
            # Copy module files
            Copy-Item -Path "$sourcePath\*" -Destination $destinationPath -Recurse -Force
            
            # Verify installation
            $verification = Test-ModuleInstallation -ModuleName $ModuleInfo.Name
            if ($verification.Installed) {
                Write-ModuleLog "Successfully installed $($ModuleInfo.Name) to $destinationPath" -Level SUCCESS
                return $true
            } else {
                Write-ModuleLog "Failed to verify installation of $($ModuleInfo.Name)" -Level ERROR
                return $false
            }
        }
    }
    catch {
        Write-ModuleLog "Error installing $($ModuleInfo.Name): $($_.Exception.Message)" -Level ERROR
        return $false
    }
}

function Uninstall-ProjectModule {
    param([hashtable]$ModuleInfo)
    
    $status = Test-ModuleInstallation -ModuleName $ModuleInfo.Name
    if (-not $status.Installed) {
        Write-ModuleLog "$($ModuleInfo.Name) is not installed" -Level INFO
        return $true
    }
    
    try {
        if ($PSCmdlet.ShouldProcess($status.Path, "Uninstall module $($ModuleInfo.Name)")) {
            # Remove loaded module first
            Get-Module -Name $ModuleInfo.Name | Remove-Module -Force -ErrorAction SilentlyContinue
            
            # Remove from all possible locations
            $allInstances = Get-Module -ListAvailable -Name $ModuleInfo.Name
            foreach ($instance in $allInstances) {
                if (Test-Path $instance.ModuleBase) {
                    Remove-Item -Path $instance.ModuleBase -Recurse -Force
                    Write-ModuleLog "Removed $($ModuleInfo.Name) from $($instance.ModuleBase)" -Level SUCCESS
                }
            }
            
            # Verify removal
            $verification = Test-ModuleInstallation -ModuleName $ModuleInfo.Name
            if (-not $verification.Installed) {
                Write-ModuleLog "Successfully uninstalled $($ModuleInfo.Name)" -Level SUCCESS
                return $true
            } else {
                Write-ModuleLog "Failed to completely remove $($ModuleInfo.Name)" -Level WARN
                return $false
            }
        }
    }
    catch {
        Write-ModuleLog "Error uninstalling $($ModuleInfo.Name): $($_.Exception.Message)" -Level ERROR
        return $false
    }
}

function Show-InstallationStatus {
    Write-ModuleLog "=== Project Module Installation Status ===" -Level INFO
    Write-Host ""
    
    foreach ($module in $ProjectModules) {
        $status = Test-ModuleInstallation -ModuleName $module.Name
        
        if ($status.Installed) {
            $statusText = "INSTALLED"
            $color = "Green"
            $details = "v$($status.Version) at $($status.Path)"
            if ($status.Multiple) {
                $details += " (Multiple versions found!)"
                $color = "Yellow"
            }
        } else {
            $statusText = "NOT INSTALLED"
            $color = "Red"
            $details = "Not found in PowerShell module path"
        }
        
        Write-Host "  $($module.Name.PadRight(20)) [$statusText]" -ForegroundColor $color -NoNewline
        Write-Host " - $details" -ForegroundColor Gray
    }
    
    Write-Host ""
    Write-ModuleLog "=== PowerShell Module Paths ===" -Level INFO
    $env:PSModulePath -split ';' | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
}

# Main execution
try {
    Write-ModuleLog "OpenTofu Lab Automation - Project Module Manager" -Level INFO
    Write-ModuleLog "Mode: $Mode | Scope: $Scope | Force: $($Force.IsPresent)" -Level INFO
    Write-Host ""
    
    switch ($Mode) {
        "Status" {
            Show-InstallationStatus
        }
        
        "Install" {
            Write-ModuleLog "Installing project modules to standard PowerShell locations..." -Level INFO
            $successCount = 0
            
            foreach ($module in $ProjectModules) {
                if (Install-ProjectModule -ModuleInfo $module -Scope $Scope -Force:$Force) {
                    $successCount++
                }
            }
            
            Write-Host ""
            Write-ModuleLog "Installation complete: $successCount/$($ProjectModules.Count) modules installed successfully" -Level SUCCESS
            
            if ($successCount -eq $ProjectModules.Count) {
                Write-Host ""
                Write-ModuleLog "All modules can now be imported normally:" -Level INFO
                foreach ($module in $ProjectModules) {
                    Write-Host "  Import-Module $($module.Name) -Force" -ForegroundColor Cyan
                }
            }
        }
        
        "Uninstall" {
            Write-ModuleLog "Uninstalling project modules from standard PowerShell locations..." -Level INFO
            $successCount = 0
            
            foreach ($module in $ProjectModules) {
                if (Uninstall-ProjectModule -ModuleInfo $module) {
                    $successCount++
                }
            }
            
            Write-Host ""
            Write-ModuleLog "Uninstallation complete: $successCount/$($ProjectModules.Count) modules removed successfully" -Level SUCCESS
        }
        
        "Reinstall" {
            Write-ModuleLog "Reinstalling project modules..." -Level INFO
            
            # First uninstall
            foreach ($module in $ProjectModules) {
                Uninstall-ProjectModule -ModuleInfo $module | Out-Null
            }
            
            # Then install
            $successCount = 0
            foreach ($module in $ProjectModules) {
                if (Install-ProjectModule -ModuleInfo $module -Scope $Scope -Force:$true) {
                    $successCount++
                }
            }
            
            Write-Host ""
            Write-ModuleLog "Reinstallation complete: $successCount/$($ProjectModules.Count) modules installed successfully" -Level SUCCESS
        }
    }
    
    if ($Mode -ne "Status") {
        Write-Host ""
        Write-ModuleLog "=== Updated Status ===" -Level INFO
        Show-InstallationStatus
    }
}
catch {
    Write-ModuleLog "Error during $Mode operation: $($_.Exception.Message)" -Level ERROR
    throw
}



