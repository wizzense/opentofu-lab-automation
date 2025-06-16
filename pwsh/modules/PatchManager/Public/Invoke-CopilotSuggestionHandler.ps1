#Requires -Version 7.0
<#
.SYNOPSIS
    Automatically implements GitHub Copilot review suggestions on pull requests
    
.DESCRIPTION
    This function monitors GitHub pull requests for Copilot review comments,
    automatically implements the suggestions, and commits them back to the PR branch.
    This ensures that by the time a human reviews the PR, Copilot's suggestions
    have already been implemented and validated by PatchManager.
    
.PARAMETER PullRequestNumber
    The GitHub pull request number to monitor
    
.PARAMETER Repository
    The repository in format "owner/repo"
    
.PARAMETER AutoCommit
    Automatically commit implemented suggestions
    
.PARAMETER ValidateAfterFix
    Run validation after implementing suggestions
    
.EXAMPLE
    Invoke-CopilotSuggestionHandler -PullRequestNumber 123 -Repository "wizzense/opentofu-lab-automation" -AutoCommit
    
.NOTES
    - Requires GitHub CLI authentication
    - Implements suggestions automatically using PatchManager
    - Validates changes before committing
    - Provides full audit trail of implemented suggestions
#>

function Invoke-CopilotSuggestionHandler {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true)]
        [int]$PullRequestNumber,
        
        [Parameter(Mandatory = $false)]
        [string]$Repository = "wizzense/opentofu-lab-automation",
        
        [Parameter(Mandatory = $false)]
        [switch]$AutoCommit,
        
    [Parameter(Mandatory = $false)]
    [switch]$ValidateAfterFix,
    
    [Parameter(Mandatory = $false)]
    [switch]$WhatIf,
    
    [Parameter(Mandatory = $false)]
    [switch]$BackgroundMonitor,
    
    [Parameter(Mandatory = $false)]
    [int]$MonitorIntervalSeconds = 300,
    
    [Parameter(Mandatory = $false)]
    [string]$LogPath = "logs/copilot-suggestions.log"
    )
      begin {
        # Initialize logging
        $logDir = Split-Path $LogPath -Parent
        if ($logDir -and -not (Test-Path $logDir)) {
            New-Item -ItemType Directory -Path $logDir -Force | Out-Null
        }
        
        function Write-LogMessage {
            param([string]$Message, [string]$Level = "INFO")
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            $logEntry = "[$timestamp] [$Level] $Message"
            Write-Host $logEntry -ForegroundColor $(switch($Level) { 
                "ERROR" { "Red" } 
                "WARN" { "Yellow" } 
                "SUCCESS" { "Green" } 
                default { "White" } 
            })
            Add-Content -Path $LogPath -Value $logEntry
        }
        
        if ($BackgroundMonitor) {
            Write-LogMessage "Starting background monitoring for PR #$PullRequestNumber (interval: ${MonitorIntervalSeconds}s)" "INFO"
        } else {
            Write-LogMessage "Starting Copilot suggestion handler for PR #$PullRequestNumber..." "INFO"
        }
        
        # Verify GitHub CLI is available and authenticated
        if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
            throw "GitHub CLI is required but not found. Please install and authenticate with 'gh auth login'"
        }
        
        # Test GitHub CLI authentication
        try {
            $null = gh auth status 2>&1
            if ($LASTEXITCODE -ne 0) {
                throw "GitHub CLI is not authenticated. Please run 'gh auth login'"
            }
        } catch {
            throw "Failed to verify GitHub CLI authentication: $($_.Exception.Message)"
        }
    }
      process {
        # Background monitoring mode
        if ($BackgroundMonitor) {
            Write-LogMessage "Background monitoring enabled - will check every $MonitorIntervalSeconds seconds" "INFO"
            Write-LogMessage "Press Ctrl+C to stop monitoring" "INFO"
            
            $lastProcessedComments = @()
            
            while ($true) {
                try {
                    $result = Invoke-CopilotSuggestionCheck -PullRequestNumber $PullRequestNumber -Repository $Repository -LastProcessedComments $lastProcessedComments
                    
                    if ($result.NewSuggestions -gt 0) {
                        Write-LogMessage "Found $($result.NewSuggestions) new Copilot suggestions - implementing..." "SUCCESS"
                        
                        # Apply suggestions using PatchManager
                        $patchResult = Invoke-GitControlledPatch -PatchDescription "fix: auto-implement Copilot suggestions from PR #$PullRequestNumber" -PatchOperation {
                            $result.ImplementedSuggestions
                        } -AutoCommitUncommitted:$AutoCommit -SkipCleanup
                        
                        if ($patchResult.Success) {
                            Write-LogMessage "Successfully implemented $($result.NewSuggestions) Copilot suggestions" "SUCCESS"
                        } else {
                            Write-LogMessage "Failed to implement some suggestions: $($patchResult.Message)" "ERROR"
                        }
                        
                        $lastProcessedComments = $result.ProcessedComments
                    } else {
                        Write-LogMessage "No new Copilot suggestions found" "INFO"
                    }
                    
                    Start-Sleep -Seconds $MonitorIntervalSeconds
                    
                } catch {
                    Write-LogMessage "Error during monitoring: $($_.Exception.Message)" "ERROR"
                    Start-Sleep -Seconds $MonitorIntervalSeconds
                }
            }
            return
        }
        
        # Single-run mode (original logic)
        try {            # Get PR review comments from Copilot
            Write-LogMessage "Fetching Copilot review comments for PR #$PullRequestNumber..." "INFO"
            
            $prComments = gh api "repos/$Repository/pulls/$PullRequestNumber/reviews" | ConvertFrom-Json
            $copilotComments = $prComments | Where-Object { $_.user.login -eq "github-copilot[bot]" -or $_.user.type -eq "Bot" }
            
            if (-not $copilotComments) {
                Write-LogMessage "No Copilot review comments found for PR #$PullRequestNumber" "INFO"
                return @{ Success = $true; Message = "No suggestions to implement"; ImplementedCount = 0 }
            }
            
            Write-LogMessage "Found $($copilotComments.Count) Copilot review(s)" "SUCCESS"
            
            # Get detailed review comments
            $allSuggestions = @()
            foreach ($review in $copilotComments) {
                $reviewComments = gh api "repos/$Repository/pulls/reviews/$($review.id)/comments" | ConvertFrom-Json
                foreach ($comment in $reviewComments) {
                    if ($comment.body -match "Suggested change" -or $comment.body -match "```suggestion") {
                        $allSuggestions += @{
                            File = $comment.path
                            Line = $comment.line
                            Body = $comment.body
                            Position = $comment.position
                            DiffHunk = $comment.diff_hunk
                        }
                    }
                }
            }
              if (-not $allSuggestions) {
                Write-LogMessage "No actionable Copilot suggestions found" "WARN"
                return @{ Success = $true; Message = "No actionable suggestions"; ImplementedCount = 0 }
            }
            
            Write-LogMessage "Found $($allSuggestions.Count) actionable Copilot suggestions" "SUCCESS"
            
            # Group suggestions by file for efficient processing
            $suggestionsByFile = $allSuggestions | Group-Object -Property File
            
            $implementedCount = 0
            $failedCount = 0
            $implementedFiles = @()
            
            foreach ($fileGroup in $suggestionsByFile) {
                $filePath = Join-Path $PWD $fileGroup.Name
                Write-Host "Processing suggestions for: $($fileGroup.Name)" -ForegroundColor Cyan
                
                if (-not (Test-Path $filePath)) {
                    Write-Warning "File not found: $filePath"
                    $failedCount++
                    continue
                }
                
                # Parse suggestions and implement them
                foreach ($suggestion in $fileGroup.Group) {
                    try {
                        $implementationResult = Invoke-CopilotSuggestionImplementation -Suggestion $suggestion -FilePath $filePath -WhatIf:$WhatIf
                        
                        if ($implementationResult.Success) {
                            $implementedCount++
                            if ($implementedFiles -notcontains $filePath) {
                                $implementedFiles += $filePath
                            }
                            Write-Host "   Implemented suggestion at line $($suggestion.Line)" -ForegroundColor Green
                        } else {
                            $failedCount++
                            Write-Warning "   Failed to implement suggestion: $($implementationResult.Error)"
                        }
                    } catch {
                        $failedCount++
                        Write-Warning "   Error implementing suggestion: $_"
                    }
                }
            }
            
            # Validate files after implementing suggestions
            if ($ValidateAfterFix -and $implementedFiles.Count -gt 0) {
                Write-Host "Validating files after implementing suggestions..." -ForegroundColor Yellow
                
                foreach ($file in $implementedFiles) {
                    try {
                        # Run basic syntax validation
                        if ($file -match '\.ps1$') {
                            $syntaxErrors = $null
                            [System.Management.Automation.PSParser]::Tokenize((Get-Content $file -Raw), [ref]$syntaxErrors)
                            if ($syntaxErrors) {
                                Write-Warning "Syntax errors found in $file after implementing suggestions"
                                foreach ($error in $syntaxErrors) {
                                    Write-Warning "  Line $($error.StartLine): $($error.Message)"
                                }
                            } else {
                                Write-Host "   $file - Syntax validation passed" -ForegroundColor Green
                            }
                        }
                    } catch {
                        Write-Warning "Failed to validate $file`: $($_.Exception.Message)"
                    }
                }
            }
              # Auto-commit implemented suggestions if requested
            if ($AutoCommit -and $implementedFiles.Count -gt 0 -and -not $WhatIf) {
                Write-Host "Auto-committing implemented Copilot suggestions..." -ForegroundColor Cyan
                
                try {
                    # Use PatchManager for safe committing
                    $patchResult = Invoke-GitControlledPatch -PatchDescription "Implement Copilot review suggestions ($implementedCount fixes)" -PatchOperation {
                        Write-Host "Copilot suggestions implemented automatically" -ForegroundColor Green
                    } -DirectCommit -WhatIf:$WhatIf
                    
                    if ($patchResult.Success) {
                        Write-Host " Successfully committed Copilot suggestions" -ForegroundColor Green
                    } else {
                        Write-Warning "Failed to commit suggestions: $($patchResult.Message)"
                    }
                } catch {
                    Write-Warning "Failed to auto-commit suggestions: $($_.Exception.Message)"
                }
            }
            
            # Return results
            $result = @{
                Success = $true
                Message = "Processed $($allSuggestions.Count) suggestions"
                ImplementedCount = $implementedCount
                FailedCount = $failedCount
                ModifiedFiles = $implementedFiles
            }
            
            Write-Host "Copilot suggestion handling completed:" -ForegroundColor Green
            Write-Host "   Implemented: $implementedCount" -ForegroundColor Green
            Write-Host "   Failed: $failedCount" -ForegroundColor $(if ($failedCount -gt 0) { "Red" } else { "Green" })
            Write-Host "  � Files modified: $($implementedFiles.Count)" -ForegroundColor Cyan
            
            return $result
            
        } catch {
            Write-Error "Failed to process Copilot suggestions: $_"
            return @{ Success = $false; Error = $_.Exception.Message }
        }
    }
}

function Invoke-CopilotSuggestionImplementation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Suggestion,
        
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $false)]
        [switch]$WhatIf
    )
    
    try {
        # Parse the suggestion body to extract the change
        $body = $Suggestion.Body
        
        # Look for suggested change in various formats
        $suggestedChange = $null
        
        # Format 1: "Suggested change" with code blocks
        if ($body -match '```suggestion\s*\n(.*?)\n```') {
            $suggestedChange = $matches[1]
        }
        # Format 2: Direct suggestion after "Suggested change"
        elseif ($body -match 'Suggested change\s*\n([^\n]+)') {
            $suggestedChange = $matches[1]
        }
        # Format 3: Code block with replacement
        elseif ($body -match '```[^\n]*\n(.*?)\n```') {
            $suggestedChange = $matches[1]
        }
        
        if (-not $suggestedChange) {
            return @{ Success = $false; Error = "Could not parse suggestion format" }
        }
        
        # Read the current file content
        $fileContent = Get-Content $FilePath -Raw
        
        # Try to implement the suggestion using the diff hunk context
        if ($Suggestion.DiffHunk) {
            $diffLines = $Suggestion.DiffHunk -split '\n'
            $contextLines = $diffLines | Where-Object { $_ -match '^[ +\-]' }
            
            # Find the line to replace using context
            $linesToReplace = $contextLines | Where-Object { $_ -match '^-' } | ForEach-Object { $_.Substring(1) }
            $replacementLines = $contextLines | Where-Object { $_ -match '^\+' } | ForEach-Object { $_.Substring(1) }
            
            if ($linesToReplace -and $replacementLines) {
                foreach ($oldLine in $linesToReplace) {
                    $trimmedOldLine = $oldLine.Trim()
                    if ($fileContent -match [regex]::Escape($trimmedOldLine)) {
                        if ($WhatIf) {
                            Write-Host "Would replace: '$trimmedOldLine'" -ForegroundColor Yellow
                            Write-Host "         with: '$($replacementLines -join '; ')'" -ForegroundColor Green
                        } else {
                            $fileContent = $fileContent -replace [regex]::Escape($oldLine), $replacementLines[0]
                            Set-Content -Path $FilePath -Value $fileContent -NoNewline
                        }
                        return @{ Success = $true; Change = "Replaced line using diff context" }
                    }
                }
            }
        }
        
        # Fallback: Try to find and replace based on line number
        $lines = Get-Content $FilePath
        if ($Suggestion.Line -le $lines.Count) {
            $targetLine = $lines[$Suggestion.Line - 1]
            
            if ($WhatIf) {
                Write-Host "Would replace line $($Suggestion.Line): '$targetLine'" -ForegroundColor Yellow
                Write-Host "                              with: '$suggestedChange'" -ForegroundColor Green
            } else {
                $lines[$Suggestion.Line - 1] = $suggestedChange
                Set-Content -Path $FilePath -Value $lines
            }
            return @{ Success = $true; Change = "Replaced line at position $($Suggestion.Line)" }
        }
        
        return @{ Success = $false; Error = "Could not locate line to replace" }
        
    } catch {
        return @{ Success = $false; Error = $_.Exception.Message }
    }
}

function Invoke-CopilotSuggestionCheck {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [int]$PullRequestNumber,
        
        [Parameter(Mandatory = $true)]
        [string]$Repository,
        
        [Parameter(Mandatory = $false)]
        [array]$LastProcessedComments = @()
    )
    
    try {
        # Get current PR review comments from Copilot
        $prComments = gh api "repos/$Repository/pulls/$PullRequestNumber/reviews" | ConvertFrom-Json
        $copilotComments = $prComments | Where-Object { $_.user.login -eq "github-copilot[bot]" -or $_.user.type -eq "Bot" }
        
        if (-not $copilotComments) {
            return @{ 
                NewSuggestions = 0; 
                ProcessedComments = $LastProcessedComments;
                ImplementedSuggestions = @()
            }
        }
        
        # Get detailed review comments and compare with last processed
        $allCurrentSuggestions = @()
        foreach ($review in $copilotComments) {
            $reviewComments = gh api "repos/$Repository/pulls/reviews/$($review.id)/comments" | ConvertFrom-Json
            foreach ($comment in $reviewComments) {
                if ($comment.body -match "Suggested change" -or $comment.body -match "```suggestion") {
                    $allCurrentSuggestions += @{
                        Id = $comment.id
                        File = $comment.path
                        Line = $comment.line
                        Body = $comment.body
                        Position = $comment.position
                        DiffHunk = $comment.diff_hunk
                    }
                }
            }
        }
        
        # Find new suggestions (not in last processed)
        $newSuggestions = $allCurrentSuggestions | Where-Object { $_.Id -notin $LastProcessedComments.Id }
        
        $implementedSuggestions = @()
        if ($newSuggestions) {
            foreach ($suggestion in $newSuggestions) {
                $filePath = Join-Path $PWD $suggestion.File
                $implementation = Invoke-CopilotSuggestionImplementation -Suggestion $suggestion -FilePath $filePath
                $implementedSuggestions += @{
                    File = $suggestion.File
                    Success = $implementation.Success
                    Change = $implementation.Change
                    Error = $implementation.Error
                }
            }
        }
        
        return @{
            NewSuggestions = $newSuggestions.Count
            ProcessedComments = $allCurrentSuggestions
            ImplementedSuggestions = $implementedSuggestions
        }
        
    } catch {
        throw "Failed to check Copilot suggestions: $($_.Exception.Message)"
    }
}

Export-ModuleMember -Function Invoke-CopilotSuggestionHandler
