#Requires -Version 7.0

<#
.SYNOPSIS
    Creates aliases that redirect common git/gh commands to use PatchManager workflows

.DESCRIPTION
    This script creates PowerShell aliases that intercept common git and GitHub CLI commands
    and redirect them to use PatchManager workflows instead. This ensures that all changes
    go through proper validation, testing, and change control even when using familiar
    git commands.

.PARAMETER Scope
    The scope for the aliases (Process, CurrentUser, LocalMachine)

.PARAMETER ShowAliases
    Display all created aliases

.PARAMETER RemoveAliases
    Remove all PatchManager aliases

.EXAMPLE
    Set-PatchManagerAliases
    Creates aliases in the current session

.EXAMPLE
    Set-PatchManagerAliases -Scope CurrentUser
    Creates persistent aliases for the current user

.NOTES
    - Aliases redirect to PatchManager workflows
    - Original git commands available as git-original
    - Ensures all changes go through proper validation
    - Part of OpenTofu Lab Automation project
#>

function Set-PatchManagerAliases {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter()]
        [ValidateSet('Process', 'CurrentUser', 'LocalMachine')]
        [string]$Scope = 'Process',
        
        [Parameter()]
        [switch]$ShowAliases,
        
        [Parameter()]
        [switch]$RemoveAliases
    )
    
    begin {
        Import-Module "$PSScriptRoot\..\Logging\Logging.psm1" -Force -ErrorAction SilentlyContinue
        
        function Write-Log {
            param($Message, $Level = "INFO")
            if (Get-Command Write-CustomLog -ErrorAction SilentlyContinue) {
                Write-CustomLog $Message -Level $Level
            } else {
                Write-Host "[$Level] $Message"
            }
        }
        
        # Store original git executable path
        $script:OriginalGitPath = (Get-Command git -ErrorAction SilentlyContinue).Source
        $script:OriginalGhPath = (Get-Command gh -ErrorAction SilentlyContinue).Source
          # Define alias mappings
        $script:PatchManagerAliases = @{
            # Git command replacements
            'git-commit' = {
                param([string[]]$args)
                Write-Log "Intercepted 'git commit' - redirecting to PatchManager (args: $($args -join ' '))" -Level WARN
                Write-Host "Direct git commits not allowed! Use PatchManager instead:" -ForegroundColor Red
                Write-Host "   Invoke-GitControlledPatch -PatchDescription 'your description' -PatchOperation { your changes }" -ForegroundColor Yellow
                Write-Host "   Or use VS Code task: 'PatchManager: Apply Changes with PR'" -ForegroundColor Cyan
            }
            
            'git-push' = {
                param([string[]]$args)
                Write-Log "Intercepted 'git push' - redirecting to PatchManager (args: $($args -join ' '))" -Level WARN
                Write-Host "Direct git push not allowed! Use PatchManager instead:" -ForegroundColor Red
                Write-Host "   Changes should go through PR workflow via PatchManager" -ForegroundColor Yellow
                if ($args -contains '--force') {
                    Write-Host "WARNING: Force push detected - this is especially dangerous!" -ForegroundColor Red
                }
            }
            
            'git-add' = {
                param([string[]]$args)
                if ($args -contains '.') {
                    Write-Log "Intercepted 'git add .' - suggesting PatchManager" -Level WARN
                    Write-Host "TIP: Consider using PatchManager for staged changes:" -ForegroundColor Yellow
                    Write-Host "   Invoke-GitControlledPatch -AutoCommitUncommitted" -ForegroundColor Cyan
                } else {
                    # Allow specific file adds
                    & $script:OriginalGitPath add @args
                }
            }
              'git-checkout' = {
                param([string[]]$args)
                if ($args[0] -eq '-b' -or $args -contains '--branch') {
                    Write-Log "Intercepted 'git checkout -b' - redirecting to PatchManager (args: $($args -join ' '))" -Level WARN
                    Write-Host "Direct branch creation not allowed! Use PatchManager instead:" -ForegroundColor Red
                    Write-Host "   PatchManager automatically creates branches with proper naming" -ForegroundColor Yellow
                    Write-Host "   Invoke-GitControlledPatch -ForceNewBranch" -ForegroundColor Cyan
                } else {
                    # Allow branch switching
                    & $script:OriginalGitPath checkout @args
                }
            }
              'git-merge' = {
                param([string[]]$args)
                Write-Log "Intercepted 'git merge' - redirecting to PatchManager (args: $($args -join ' '))" -Level WARN
                Write-Host "Direct git merge not allowed! Use GitHub PR workflow instead:" -ForegroundColor Red
                Write-Host "   Merges should happen through GitHub PR reviews" -ForegroundColor Yellow
                Write-Host "   PatchManager creates PRs automatically with -CreatePullRequest" -ForegroundColor Cyan
            }
              'git-rebase' = {
                param([string[]]$args)
                Write-Log "Intercepted 'git rebase' - suggesting PatchManager rollback (args: $($args -join ' '))" -Level WARN
                Write-Host "WARNING: Git rebase detected - consider PatchManager rollback instead:" -ForegroundColor Yellow
                Write-Host "   Invoke-QuickRollback -RollbackType LastCommit" -ForegroundColor Cyan
                Write-Host "   Or use VS Code task: 'PatchManager: Emergency Rollback'" -ForegroundColor Cyan
            }
              # GitHub CLI replacements
            'gh-pr-create' = {
                param([string[]]$args)
                Write-Log "Intercepted 'gh pr create' - redirecting to PatchManager (args: $($args -join ' '))" -Level WARN
                Write-Host "TIP: PatchManager can create PRs automatically:" -ForegroundColor Yellow
                Write-Host "   Invoke-GitControlledPatch -CreatePullRequest" -ForegroundColor Cyan
            }
              'gh-pr-merge' = {
                param([string[]]$args)
                Write-Log "Intercepted 'gh pr merge' - manual merge blocked (args: $($args -join ' '))" -Level WARN
                Write-Host "Direct PR merge not allowed! Use GitHub web interface for review" -ForegroundColor Red
                Write-Host "   PRs require human review and approval before merging" -ForegroundColor Yellow
            }
            
            # Safe git commands (read-only)
            'git-status' = { & $script:OriginalGitPath status @args }
            'git-log' = { & $script:OriginalGitPath log @args }
            'git-diff' = { & $script:OriginalGitPath diff @args }
            'git-branch' = { & $script:OriginalGitPath branch @args }
            'git-remote' = { & $script:OriginalGitPath remote @args }
            'git-show' = { & $script:OriginalGitPath show @args }
            'git-ls-files' = { & $script:OriginalGitPath ls-files @args }
            
            # GitHub CLI safe commands
            'gh-status' = { & $script:OriginalGhPath status @args }
            'gh-pr-list' = { & $script:OriginalGhPath pr list @args }
            'gh-pr-view' = { & $script:OriginalGhPath pr view @args }
            'gh-repo-view' = { & $script:OriginalGhPath repo view @args }
        }
        
        # PatchManager convenience aliases
        $script:ConvenienceAliases = @{
            'patch' = {
                param([string]$description, [scriptblock]$operation)
                if (-not $description -or -not $operation) {
                    Write-Host "Usage: patch 'description' { your changes }" -ForegroundColor Yellow
                    Write-Host "Example: patch 'fix typo' { (Get-Content file.txt) -replace 'old', 'new' | Set-Content file.txt }" -ForegroundColor Cyan
                    return
                }
                Invoke-GitControlledPatch -PatchDescription $description -PatchOperation $operation -CreatePullRequest
            }
            
            'quickpatch' = {
                param([string]$description, [scriptblock]$operation)
                if (-not $description -or -not $operation) {
                    Write-Host "Usage: quickpatch 'description' { your changes }" -ForegroundColor Yellow
                    return
                }
                Invoke-GitControlledPatch -PatchDescription $description -PatchOperation $operation -DirectCommit -AutoCommitUncommitted
            }
            
            'rollback' = {
                param([string]$type = 'LastCommit')
                Invoke-QuickRollback -RollbackType $type -CreateBackup
            }
            
            'patchstatus' = {
                Write-Host "=== PatchManager Status ===" -ForegroundColor Cyan
                & $script:OriginalGitPath status
                Write-Host "`n=== Available PatchManager Commands ===" -ForegroundColor Green
                Write-Host "  patch 'desc' { changes }     - Create PR with changes"
                Write-Host "  quickpatch 'desc' { changes } - Direct commit changes"
                Write-Host "  rollback                      - Rollback last commit"
                Write-Host "  patchhelp                     - Show full help"
            }
            
            'patchhelp' = {
                Write-Host "=== PatchManager Command Reference ===" -ForegroundColor Cyan
                Write-Host ""
                Write-Host "Basic Usage:" -ForegroundColor Green
                Write-Host "  patch 'description' { changes }  - Standard workflow with PR"
                Write-Host "  quickpatch 'desc' { changes }    - Direct commit for small fixes"
                Write-Host ""
                Write-Host "Advanced Usage:" -ForegroundColor Green
                Write-Host "  Invoke-GitControlledPatch -PatchDescription 'desc' -PatchOperation { changes } -CreatePullRequest"
                Write-Host "  Invoke-QuickRollback -RollbackType LastCommit"
                Write-Host ""
                Write-Host "VS Code Tasks:" -ForegroundColor Green
                Write-Host "  'PatchManager: Apply Changes with PR'"
                Write-Host "  'PatchManager: Apply Changes with DirectCommit'"
                Write-Host "  'PatchManager: Emergency Rollback'"
                Write-Host ""
                Write-Host "Blocked Commands (use PatchManager instead):" -ForegroundColor Red
                Write-Host "  git commit, git push, git merge, git checkout -b, gh pr create, gh pr merge"
            }
        }
    }
    
    process {
        if ($RemoveAliases) {
            Write-Log "Removing PatchManager aliases..." -Level INFO
            
            # Remove all our aliases
            $allAliases = $script:PatchManagerAliases.Keys + $script:ConvenienceAliases.Keys
            foreach ($aliasName in $allAliases) {
                if (Get-Alias $aliasName -ErrorAction SilentlyContinue) {
                    Remove-Alias $aliasName -Scope $Scope -Force -ErrorAction SilentlyContinue
                    Write-Log "Removed alias: $aliasName" -Level SUCCESS
                }
            }
            
            # Restore original git alias
            if ($script:OriginalGitPath) {
                Set-Alias -Name git -Value $script:OriginalGitPath -Scope $Scope -Force
                Write-Log "Restored original git command" -Level SUCCESS
            }
            
            return
        }
        
        if ($ShowAliases) {
            Write-Host "=== PatchManager Aliases ===" -ForegroundColor Cyan
            Write-Host ""
            Write-Host "Intercepted Git Commands:" -ForegroundColor Red
            $script:PatchManagerAliases.Keys | Where-Object { $_ -like 'git-*' -and $_ -notin @('git-status', 'git-log', 'git-diff', 'git-branch', 'git-remote', 'git-show', 'git-ls-files') } | Sort-Object | ForEach-Object {
                Write-Host "  $_" -ForegroundColor Red
            }
            
            Write-Host ""
            Write-Host "Safe Git Commands (allowed):" -ForegroundColor Green
            @('git-status', 'git-log', 'git-diff', 'git-branch', 'git-remote', 'git-show', 'git-ls-files') | ForEach-Object {
                Write-Host "  $_" -ForegroundColor Green
            }
            
            Write-Host ""
            Write-Host "Convenience Aliases:" -ForegroundColor Cyan
            $script:ConvenienceAliases.Keys | Sort-Object | ForEach-Object {
                Write-Host "  $_" -ForegroundColor Cyan
            }
            
            return
        }
        
        Write-Log "Setting up PatchManager aliases (Scope: $Scope)..." -Level INFO
        
        # Create a wrapper function for git that intercepts dangerous commands
        $gitWrapper = {
            param([string[]]$args)
            
            if ($args.Count -eq 0) {
                & $script:OriginalGitPath
                return
            }
            
            $command = $args[0]
            $aliasName = "git-$command"
            
            if ($script:PatchManagerAliases.ContainsKey($aliasName)) {
                & $script:PatchManagerAliases[$aliasName] @($args[1..($args.Count-1)])
            } else {
                # Allow unknown git commands to pass through
                & $script:OriginalGitPath @args
            }
        }
        
        # Create a wrapper function for gh that intercepts dangerous commands  
        $ghWrapper = {
            param([string[]]$args)
            
            if ($args.Count -lt 2) {
                & $script:OriginalGhPath @args
                return
            }
            
            $subcommand = "$($args[0])-$($args[1])"
            $aliasName = "gh-$subcommand"
            
            if ($script:PatchManagerAliases.ContainsKey($aliasName)) {
                & $script:PatchManagerAliases[$aliasName] @($args[2..($args.Count-1)])
            } else {
                # Allow unknown gh commands to pass through
                & $script:OriginalGhPath @args
            }
        }
        
        if ($PSCmdlet.ShouldProcess("Creating PatchManager aliases", "Set-Alias")) {
            # Set up the main git and gh wrappers
            Set-Alias -Name git -Value $gitWrapper -Scope $Scope -Force
            if ($script:OriginalGhPath) {
                Set-Alias -Name gh -Value $ghWrapper -Scope $Scope -Force
            }
            
            # Create convenience aliases
            foreach ($aliasName in $script:ConvenienceAliases.Keys) {
                Set-Alias -Name $aliasName -Value $script:ConvenienceAliases[$aliasName] -Scope $Scope -Force
                Write-Log "Created convenience alias: $aliasName" -Level SUCCESS
            }
            
            # Create original command aliases for emergency use
            if ($script:OriginalGitPath) {
                Set-Alias -Name git-original -Value $script:OriginalGitPath -Scope $Scope -Force
                Write-Log "Created emergency alias: git-original" -Level INFO
            }
            
            if ($script:OriginalGhPath) {
                Set-Alias -Name gh-original -Value $script:OriginalGhPath -Scope $Scope -Force
                Write-Log "Created emergency alias: gh-original" -Level INFO
            }
            
            Write-Log "PatchManager aliases configured successfully!" -Level SUCCESS
            Write-Log "Use 'patchhelp' for command reference" -Level INFO
            Write-Log "Use 'git-original' or 'gh-original' for emergency access to original commands" -Level WARN
        }
    }
    
    end {
        if (-not $RemoveAliases -and -not $ShowAliases) {
            Write-Host ""
            Write-Host "PatchManager aliases are now active!" -ForegroundColor Green
            Write-Host "Type 'patchhelp' for usage information" -ForegroundColor Cyan
            Write-Host "Type 'patchstatus' to see current status" -ForegroundColor Cyan
            Write-Host ""
        }
    }
}

# Auto-export the function
Export-ModuleMember -Function Set-PatchManagerAliases
