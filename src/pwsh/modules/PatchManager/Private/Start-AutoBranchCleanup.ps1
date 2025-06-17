function Start-AutoBranchCleanup {
    <#
    .SYNOPSIS
    Automatically cleans up branches after PR merge with monitoring
    
    .DESCRIPTION
    Monitors pull requests and automatically cleans up branches after they are merged.
    Runs in background to avoid blocking the main process.
    
    .PARAMETER BranchName
    Name of the branch to monitor
    
    .PARAMETER PullRequestNumber
    Pull request number to monitor
    
    .PARAMETER Remote
    Git remote name (defaults to 'origin')
    
    .PARAMETER CheckIntervalSeconds
    How often to check PR status (defaults to 300 seconds / 5 minutes)
    
    .PARAMETER MaxWaitHours
    Maximum time to wait before giving up (defaults to 24 hours)
    
    .PARAMETER LogPath
    Path for monitoring logs
    
    .EXAMPLE
    Start-AutoBranchCleanup -BranchName "patch/feature" -PullRequestNumber 123
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$BranchName,
        
        [Parameter(Mandatory = $true)]
        [int]$PullRequestNumber,
        
        [Parameter(Mandatory = $false)]
        [string]$Remote = "origin",
        
        [Parameter(Mandatory = $false)]
        [int]$CheckIntervalSeconds = 300,
        
        [Parameter(Mandatory = $false)]
        [int]$MaxWaitHours = 24,
        
        [Parameter(Mandatory = $false)]
        [string]$LogPath = (Join-Path $env:PROJECT_ROOT "logs" "branch-cleanup.log")
    )
    
    try {
        # Create logs directory if it doesn't exist
        $logDir = Split-Path $LogPath -Parent
        if (-not (Test-Path $logDir)) {
            New-Item -ItemType Directory -Path $logDir -Force | Out-Null
        }
        
        # Background monitoring script
        $monitoringScript = {
            param($BranchName, $PullRequestNumber, $Remote, $CheckIntervalSeconds, $MaxWaitHours, $LogPath)
            
            function Write-CleanupLog {
                param([string]$Message)
                $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                $logEntry = "[$timestamp] $Message"
                Add-Content -Path $LogPath -Value $logEntry
                Write-Host $logEntry -ForegroundColor Cyan
            }
            
            Write-CleanupLog "Starting branch cleanup monitoring for: $BranchName (PR #$PullRequestNumber)"
            
            $maxChecks = ($MaxWaitHours * 3600) / $CheckIntervalSeconds
            $checkCount = 0
            
            do {
                $checkCount++
                Write-CleanupLog "Check $checkCount/$maxChecks - Monitoring PR #$PullRequestNumber"
                
                try {
                    # Check if gh CLI is available
                    $ghAvailable = Get-Command gh -ErrorAction SilentlyContinue
                    if (-not $ghAvailable) {
                        Write-CleanupLog "GitHub CLI not available. Cannot monitor PR status automatically."
                        Write-CleanupLog "Manual cleanup required for branch: $BranchName"
                        break
                    }
                    
                    # Check PR status
                    $prInfo = gh pr view $PullRequestNumber --json state,mergedAt,url 2>$null | ConvertFrom-Json
                    
                    if ($prInfo.state -eq "MERGED") {
                        Write-CleanupLog "PR #$PullRequestNumber was merged at $($prInfo.mergedAt)"
                        
                        # Wait a bit for CI/CD to complete
                        Write-CleanupLog "Waiting 2 minutes for CI/CD completion..."
                        Start-Sleep -Seconds 120
                        
                        # Clean up the branch
                        Write-CleanupLog "Cleaning up merged branch: $BranchName"
                        
                        # Switch to main branch before cleanup
                        $currentBranch = git branch --show-current
                        if ($currentBranch -eq $BranchName) {
                            Write-CleanupLog "Switching from $BranchName to main for cleanup"
                            git checkout main 2>&1 | Out-Null
                            git pull $Remote main 2>&1 | Out-Null
                        }
                        
                        # Delete remote branch
                        $deleteResult = git push $Remote --delete $BranchName 2>&1
                        if ($LASTEXITCODE -eq 0) {
                            Write-CleanupLog "Successfully deleted remote branch: $BranchName"
                            
                            # Delete local branch
                            $localDeleteResult = git branch -D $BranchName 2>&1
                            if ($LASTEXITCODE -eq 0) {
                                Write-CleanupLog "Successfully deleted local branch: $BranchName"
                            } else {
                                Write-CleanupLog "Failed to delete local branch: $localDeleteResult"
                            }
                            
                            # Run git cleanup
                            Write-CleanupLog "Running git maintenance..."
                            git remote prune $Remote 2>&1 | Out-Null
                            git gc --prune=now 2>&1 | Out-Null
                            
                            Write-CleanupLog "Branch cleanup completed successfully for: $BranchName"
                            break
                        } else {
                            Write-CleanupLog "Failed to delete remote branch: $deleteResult"
                            Write-CleanupLog "Manual cleanup may be required for: $BranchName"
                            break
                        }
                    }
                    elseif ($prInfo.state -eq "CLOSED") {
                        Write-CleanupLog "PR #$PullRequestNumber was closed without merging. Preserving branch: $BranchName"
                        break
                    }
                    else {
                        Write-CleanupLog "PR #$PullRequestNumber is still open (state: $($prInfo.state))"
                    }
                }
                catch {
                    Write-CleanupLog "Error checking PR status: $($_.Exception.Message)"
                    # Continue monitoring despite errors
                }
                
                if ($checkCount -lt $maxChecks) {
                    Write-CleanupLog "Next check in $CheckIntervalSeconds seconds..."
                    Start-Sleep -Seconds $CheckIntervalSeconds
                }
                
            } while ($checkCount -lt $maxChecks)
            
            if ($checkCount -ge $maxChecks) {
                Write-CleanupLog "Maximum wait time exceeded. Stopping monitoring for: $BranchName"
                Write-CleanupLog "Manual cleanup may be required if PR was merged."
            }
            
            Write-CleanupLog "Branch cleanup monitoring completed for: $BranchName"
        }
        
        # Start the background job
        $job = Start-Job -ScriptBlock $monitoringScript -ArgumentList $BranchName, $PullRequestNumber, $Remote, $CheckIntervalSeconds, $MaxWaitHours, $LogPath
        
        Write-Host "[SYMBOL] Branch cleanup monitoring started" -ForegroundColor Green
        Write-Host "  Branch: $BranchName" -ForegroundColor Cyan
        Write-Host "  PR: #$PullRequestNumber" -ForegroundColor Cyan
        Write-Host "  Job ID: $($job.Id)" -ForegroundColor Gray
        Write-Host "  Log: $LogPath" -ForegroundColor Gray
        Write-Host "  Will check every $CheckIntervalSeconds seconds for up to $MaxWaitHours hours" -ForegroundColor Gray
        
        return @{
            Success = $true
            JobId = $job.Id
            BranchName = $BranchName
            PullRequestNumber = $PullRequestNumber
            LogPath = $LogPath
            MonitoringDetails = @{
                CheckIntervalSeconds = $CheckIntervalSeconds
                MaxWaitHours = $MaxWaitHours
                Remote = $Remote
            }
        }
    }
    catch {
        Write-Error "Failed to start branch cleanup monitoring: $($_.Exception.Message)"
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

