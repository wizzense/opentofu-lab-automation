function Test-PatchingRequirements {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$ProjectRoot = (Get-Location).Path,
        
        [Parameter(Mandatory = $false)]
        [switch]$InstallMissing,
        
        [Parameter(Mandatory = $false)]
        [string]$LogFile,
        
        [Parameter(Mandatory = $false)]
        [string[]]$AffectedFiles
    )
    
    # Function for centralized logging
    if (-not (Get-Command "Write-PatchLog" -ErrorAction SilentlyContinue)) {        function Write-PatchLog {
            param(
                [string]$Message,
                [ValidateSet("INFO", "SUCCESS", "WARNING", "ERROR", "DEBUG")]
                [string]$Level = "INFO",
                [string]$LogFile
            )
            
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            $formattedMessage = "$timestamp $Level $Message"
            
            # Color coding based on level
            $color = switch ($Level) {
                "INFO"    { "Gray" }
                "SUCCESS" { "Green" }
                "WARNING" { "Yellow" }
                "ERROR"   { "Red" }
                "DEBUG"   { "DarkGray" }
                default   { "White" }
            }
            
            Write-Host $formattedMessage -ForegroundColor $color
            
            # Only write to file if LogFile is provided and not empty
            if ($LogFile -and $LogFile.Trim()) {
                $formattedMessage | Out-File -FilePath $LogFile -Append
            }
        }
    }
      Write-PatchLog "Testing patching requirements..." "INFO" -LogFile $LogFile
    Write-PatchLog "Project root: $ProjectRoot" "INFO" -LogFile $LogFile
    
    # Validate project root exists
    if (-not (Test-Path $ProjectRoot)) {
        Write-PatchLog "Project root path does not exist: $ProjectRoot" "ERROR" -LogFile $LogFile
        return @{ AllRequirementsMet = $false; Error = "Invalid project root path" }
    }
    
    # Log affected files if provided
    if ($AffectedFiles -and $AffectedFiles.Count -gt 0) {
        Write-PatchLog "Affected files provided: $($AffectedFiles.Count) files" "INFO" -LogFile $LogFile
        foreach ($file in $AffectedFiles) {
            Write-PatchLog "  - $file" "DEBUG" -LogFile $LogFile
        }
    }
    
    # Required modules
    $requiredModules = @(
        @{
            Name = "PSScriptAnalyzer"
            MinimumVersion = "1.18.0"
            Description = "PowerShell script analysis tool"
        },
        @{
            Name = "Pester"
            MinimumVersion = "5.0.0"
            Description = "PowerShell testing framework"
        },
        @{
            Name = "powershell-yaml"
            MinimumVersion = "0.4.0"
            Description = "PowerShell module for working with YAML"
        }
    )
    
    # Required commands
    $requiredCommands = @(
        @{
            Name = "git"
            TestParam = "--version"
            ExpectedOutput = "git version"
            Description = "Git version control"
        },
        @{
            Name = "yamllint"
            TestParam = "--version"
            ExpectedOutput = "yamllint"
            Description = "YAML validation tool"
            Optional = $true
        },
        @{
            Name = "python"
            TestParam = "--version"
            ExpectedOutput = "Python"
            Description = "Python interpreter"
            Optional = $true
        }
    )
    
    # Results object
    $results = @{
        AllRequirementsMet = $true
        ModulesAvailable = @()
        ModulesMissing = @()
        CommandsAvailable = @()
        CommandsMissing = @()
        Fixes = @()
    }
    
    # Check PowerShell modules
    foreach ($module in $requiredModules) {        Write-PatchLog "Checking for module: $($module.Name)" "INFO" -LogFile $LogFile
        
        $moduleInstalled = Get-Module -Name $module.Name -ListAvailable | Where-Object { $_.Version -ge $module.MinimumVersion }
          if ($moduleInstalled) {
            Write-PatchLog " Module $($module.Name) v$($moduleInstalled.Version) is available" "INFO" -LogFile $LogFile
            $results.ModulesAvailable += $module.Name
        } else {
            Write-PatchLog " Module $($module.Name) v$($module.MinimumVersion)+ not found" "WARNING" -LogFile $LogFile
            $results.ModulesMissing += $module.Name
            $results.AllRequirementsMet = $false
            
            # Add fix command
            $results.Fixes += "Install-Module -Name '$($module.Name)' -Scope CurrentUser -Force"
            
            # Install if requested
            if ($InstallMissing) {
                Write-PatchLog "Installing module $($module.Name)..." "INFO" -LogFile $LogFile
                try {
                    Install-Module -Name $module.Name -Scope CurrentUser -Force
                    Write-PatchLog " Module $($module.Name) installed successfully" "SUCCESS" -LogFile $LogFile
                } catch {
                    Write-PatchLog " Failed to install $($module.Name): $($_.Exception.Message)" "ERROR" -LogFile $LogFile
                }
            }
        }
    }
    
    # Check required commands
    foreach ($command in $requiredCommands) {
        Write-PatchLog "Checking for command: $($command.Name)" "INFO" -LogFile $LogFile
        
        $commandAvailable = Get-Command $command.Name -ErrorAction SilentlyContinue
          if ($commandAvailable) {
            Write-PatchLog " Command $($command.Name) is available" "INFO" -LogFile $LogFile
            $results.CommandsAvailable += $command.Name
        } else {
            $message = " Command $($command.Name) not found"
            $level = if ($command.Optional) { "INFO" } else { "WARNING" }
            Write-PatchLog $message $level -LogFile $LogFile
            
            if (-not $command.Optional) {
                $results.CommandsMissing += $command.Name
                $results.AllRequirementsMet = $false
            }
        }
    }    # Final assessment
    if ($results.AllRequirementsMet) {
        Write-PatchLog "All patching requirements are met!" "INFO" -LogFile $LogFile
    } else {
        Write-PatchLog "Some patching requirements are missing" "WARNING" -LogFile $LogFile
        
        if ($results.Fixes.Count -gt 0) {
            Write-PatchLog "Run the following commands to fix:" "INFO" -LogFile $LogFile
            foreach ($fix in $results.Fixes) {
                Write-PatchLog "  $fix" "INFO" -LogFile $LogFile
            }
        }
    }
    
    # Add Success property for compatibility
    $results.Success = $results.AllRequirementsMet
    if (-not $results.Success) {
        $results.Message = "Some patching requirements are not met"
    } else {
        $results.Message = "All patching requirements are met"
    }
    
    return $results
}
