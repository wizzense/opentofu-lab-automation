#Requires -Version 7.0
<#
.SYNOPSIS
    Error handling module for PatchManager
    
.DESCRIPTION
    Provides standardized error handling functions for PatchManager operations
    including logging, structured error objects, and recovery operations.
    
.NOTES
    - Integrated with GitHub issue reporting
    - Creates comprehensive error logs
    - Provides recovery suggestions
    - Tagged error categorization
#>

function HandlePatchError {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ErrorMessage,
        
        [Parameter(Mandatory = $false)]
        [System.Management.Automation.ErrorRecord]$ErrorRecord = $null,
        [Parameter(Mandatory = $false)]
        [ValidateSet("Git", "PatchValidation", "BranchStrategy", "PullRequest", "Rollback", "General")]
        [string]$ErrorCategory = "General",
        
        [Parameter(Mandatory = $false)]
        [string]$LogPath = "logs/patch-errors.log",
        
        [Parameter(Mandatory = $false)]
        [switch]$Silent = $false,
        
        [Parameter(Mandatory = $false)]
        [int]$IssueNumber = $null
    )

    # Create log directory if needed
    $logDir = Split-Path $LogPath -Parent
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }
    
    # Construct timestamp
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    # Create error log entry
    $logEntry = @"
[$timestamp] [$ErrorCategory] ERROR:
$ErrorMessage

"@

    # Add error record details if available
    if ($ErrorRecord) {
        $logEntry += @"
Exception: $($ErrorRecord.Exception.GetType().FullName)
Stack Trace:
$($ErrorRecord.ScriptStackTrace)

"@
    }
    
    # Write to log file
    $logEntry | Out-File -FilePath $LogPath -Append
    
    # Display error unless silent mode is enabled
    if (-not $Silent) {
        Write-Host "[$ErrorCategory] Error: $ErrorMessage" -ForegroundColor Red
        
        if ($ErrorRecord) {
            Write-Host "See $LogPath for details" -ForegroundColor Yellow
        }
    }
    # Update GitHub issue if provided
    if ($IssueNumber) {
        try {
            # Build suggested actions based on error category
            $suggestedActions = switch ($ErrorCategory) {
                "Git" { "- Check Git repository status and permissions" }
                "PatchValidation" { "- Review changes for syntax errors or validation issues" }
                "BranchStrategy" { "- Verify branch naming and repository structure" }
                "PullRequest" { "- Ensure GitHub permissions are correct" }
                "Rollback" { "- Manual intervention may be required" }
                default { "- Review error details and logs" }
            }
            
            $issueComment = @"
## ❌ Error Encountered

**Category**: $ErrorCategory
**Time**: $timestamp
**Details**: $ErrorMessage

### Suggested Actions
$suggestedActions
- Review error log for detailed troubleshooting
"@
            
            # Use GitHub CLI to add comment
            gh issue comment $IssueNumber --body $issueComment 2>&1 | Out-Null
        } catch {
            # Silently continue if GitHub issue update fails
            $issueUpdateError = "Failed to update GitHub issue: $($_.Exception.Message)"
            $issueUpdateError | Out-File -FilePath $LogPath -Append
        }
    }
    
    # Create structured error object
    $errorObject = [PSCustomObject]@{
        Timestamp   = $timestamp
        Category    = $ErrorCategory
        Message     = $ErrorMessage
        Exception   = $ErrorRecord?.Exception
        StackTrace  = $ErrorRecord?.ScriptStackTrace
        LogPath     = $LogPath
        IssueNumber = $IssueNumber
    }
    
    return $errorObject
}

function Write-PatchLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        [Parameter(Mandatory = $false)]
        [ValidateSet("INFO", "WARNING", "ERROR", "DEBUG", "SUCCESS")]
        [string]$LogLevel = "INFO",
        
        [Parameter(Mandatory = $false)]
        [string]$LogFile = "logs/patch-operations.log",
        
        [Parameter(Mandatory = $false)]
        [switch]$NoConsole
    )
    # Create log directory if needed (only if LogFile is provided)
    if ($LogFile -and $LogFile.Trim()) {
        $logDir = Split-Path $LogFile -Parent
        if (-not (Test-Path $logDir)) {
            New-Item -ItemType Directory -Path $logDir -Force | Out-Null
        }
    }
    
    # Format log message
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$LogLevel] $Message"
    
    # Write to log file (only if LogFile is provided)
    if ($LogFile -and $LogFile.Trim()) {
        $logMessage | Out-File -FilePath $LogFile -Append
    }
    
    # Write to console with color based on log level (unless NoConsole is specified)
    if (-not $NoConsole) {
        $color = switch ($LogLevel) {
            "INFO" { "White" }
            "WARNING" { "Yellow" }
            "ERROR" { "Red" }
            "DEBUG" { "Gray" }
            "SUCCESS" { "Green" }
            default { "White" }
        }
        
        Write-Host $logMessage -ForegroundColor $color
    }
}

# Note: Export-ModuleMember is handled by the parent module
