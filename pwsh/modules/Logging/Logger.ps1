# Logger.ps1 - Standardized Logging Module for OpenTofu Lab Automation
# 
# This module provides standardized logging across the OpenTofu Lab Automation project
# Usage: Include this directly or via the proper module imports

function Write-CustomLog {
    [CmdletBinding()]
    param(
        [Parameter(Position=0, Mandatory=$true)]
        [string]$Message,
        
        [Parameter(Position=1)]
        [ValidateSet('INFO', 'WARN', 'ERROR', 'DEBUG', 'SUCCESS', 'CRITICAL')]
        [string]$Level = 'INFO',
        
        [Parameter()]
        [switch]$NoTimestamp,
        
        [Parameter()]
        [string]$LogFile,
        
        [Parameter()]
        [switch]$NoConsole,
        
        [Parameter()]
        [switch]$NoFileOutput
    )

    # Define colors for different log levels
    $color = switch ($Level) {
        "INFO"     { "Cyan" }
        "WARN"     { "Yellow" }
        "ERROR"    { "Red" }
        "DEBUG"    { "Gray" }
        "SUCCESS"  { "Green" }
        "CRITICAL" { "Red" }
        default    { "White" }
    }

    # Generate timestamp
    $timestamp = if (-not $NoTimestamp) { 
        "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')]" 
    } else {
        ""
    }

    # Format the log message
    $formattedMessage = "$timestamp [$Level] $Message"

    # Output to console if not suppressed
    if (-not $NoConsole) {
        Write-Host $formattedMessage -ForegroundColor $color
    }

    # Output to file if requested or configured
    if (-not $NoFileOutput) {
        # Determine log file path - respect provided path or use defaults
        $logFilePath = $LogFile
        
        # If no log file explicitly specified, check for configured path
        if (-not $logFilePath) {
            # Try to get from script scope
            if (Get-Variable -Name LogFilePath -Scope Script -ErrorAction SilentlyContinue) {
                $logFilePath = $script:LogFilePath
            }
            # Try to get from environment variable
            elseif ($env:LAB_LOG_PATH) {
                $logFilePath = $env:LAB_LOG_PATH
            }
            # Use default location
            else {
                $logDir = if ($env:LAB_LOG_DIR) { 
                    $env:LAB_LOG_DIR 
                } else { 
                    if ($IsWindows -or $env:OS -eq "Windows_NT") { "C:\temp" } else { "/tmp" }
                }
                
                # Ensure log directory exists
                if (-not (Test-Path $logDir)) {
                    try {
                        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
                    } catch {
                        # If we can't create log dir, use PowerShell temp path
                        $logDir = [System.IO.Path]::GetTempPath()
                    }
                }
                
                $logFilePath = Join-Path $logDir "opentofu-lab-automation.log"
            }
        }
        
        # Write to log file
        try {
            $formattedMessage | Out-File -FilePath $logFilePath -Encoding utf8 -Append -ErrorAction SilentlyContinue
        } catch {
            # If we can't write to the log file, output a warning to console only
            if (-not $NoConsole) {
                Write-Host "[$timestamp] [ERROR] Failed to write to log file: $_" -ForegroundColor "Red"
            }
        }
    }
}

# Helper function for reading input with logging
function Read-LoggedInput {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Prompt,
        
        [switch]$AsSecureString,
        
        [string]$Level = 'INFO',
        
        [switch]$NoLog
    )

    if (-not $NoLog) {
        Write-CustomLog "$Prompt (user input requested)" -Level $Level
    }
    
    if ($AsSecureString) {
        $result = Read-Host -Prompt $Prompt -AsSecureString
        if (-not $NoLog) {
            Write-CustomLog "Secure input received" -Level $Level
        }
        return $result
    }
    
    $answer = Read-Host -Prompt $Prompt
      if (-not $NoLog) {
        Write-CustomLog "$($Prompt): $answer" -Level $Level
    }
    
    return $answer
}

# Function to set the log path for the session
function Set-LoggingPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$LogFilePath,
        
        [switch]$CreateDirectory
    )
    
    if ($CreateDirectory) {
        $logDir = Split-Path -Parent $LogFilePath
        if (-not (Test-Path $logDir)) {
            try {
                New-Item -ItemType Directory -Path $logDir -Force | Out-Null
                Write-CustomLog "Created log directory: $logDir" -Level "INFO"
            } catch {
                Write-CustomLog "Failed to create log directory: $_" -Level "ERROR"
                return $false
            }
        }
    }
    
    $script:LogFilePath = $LogFilePath
    Write-CustomLog "Set log path to: $LogFilePath" -Level "INFO"
    return $true
}

# Function to consolidate logs from different sources
function Merge-LogFiles {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string[]]$LogFiles,
        
        [Parameter(Mandatory=$true)]
        [string]$OutputFile,
        
        [switch]$SortByTimestamp
    )
    
    try {
        $allLogs = @()
        
        foreach ($file in $LogFiles) {
            if (Test-Path $file) {
                $content = Get-Content -Path $file -ErrorAction SilentlyContinue
                $allLogs += $content
            }
        }
        
        if ($SortByTimestamp) {
            # Extract timestamps and sort (expects format like [2023-04-25 14:30:45])
            $allLogs = $allLogs | 
                ForEach-Object { 
                    if ($_ -match '^\[([\d-]+ [\d:]+)\]') {
                        [PSCustomObject]@{
                            Timestamp = [datetime]::ParseExact($matches[1], 'yyyy-MM-dd HH:mm:ss', $null)
                            Line = $_
                        }
                    } else {
                        [PSCustomObject]@{ 
                            Timestamp = [datetime]::MinValue
                            Line = $_ 
                        }
                    }
                } | 
                Sort-Object -Property Timestamp | 
                Select-Object -ExpandProperty Line
        }
        
        $allLogs | Out-File -FilePath $OutputFile -Encoding utf8
        Write-CustomLog "Merged $($LogFiles.Count) log files into $OutputFile" -Level "INFO"
        
        return $true
    } catch {
        Write-CustomLog "Failed to merge log files: $_" -Level "ERROR"
        return $false
    }
}

# Function to configure log verbosity
function Set-LogVerbosity {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet("Quiet", "Normal", "Verbose", "Debug")]
        [string]$Level
    )
    
    switch ($Level) {
        "Quiet" {
            $script:LoggingLevel = 0  # Only errors and critical messages
            $env:LAB_CONSOLE_LEVEL = 0
        }
        "Normal" {
            $script:LoggingLevel = 1  # Errors, warnings, and info
            $env:LAB_CONSOLE_LEVEL = 1
        }
        "Verbose" {
            $script:LoggingLevel = 2  # All except debug
            $env:LAB_CONSOLE_LEVEL = 2
        }
        "Debug" {
            $script:LoggingLevel = 3  # Everything
            $env:LAB_CONSOLE_LEVEL = 3
        }
    }
    
    Write-CustomLog "Set logging verbosity to $Level" -Level "INFO"
}

# Export functions if importing as a module
Export-ModuleMember -Function Write-CustomLog, Read-LoggedInput, Set-LoggingPath, Merge-LogFiles, Set-LogVerbosity
