function Invoke-IntelligentBranchStrategy {
    CmdletBinding()
    param(
        string$PatchDescription,
        string$CurrentBranch = "main"
    )
    
    try {
        Write-Verbose "Analyzing branch strategy for: $PatchDescription"
        
        # Get current branch
        $currentBranch = git rev-parse --abbrev-ref HEAD 2>$null
        if (-not $currentBranch) { $currentBranch = "main" }
        
        # Determine strategy based on current branch
        $strategy = @{
            Success = $true
            CurrentBranch = $currentBranch
            SkipBranchCreation = $false
            NewBranchName = $null
            Message = "Branch strategy determined"
        }
        
        # Anti-recursive logic: if already on a feature branch, work in place
        if ($currentBranch -match "^(patchfeaturefixhotfix)/" -and $currentBranch -ne "main") {
            $strategy.SkipBranchCreation = $true
            $strategy.NewBranchName = $currentBranch
            $strategy.Message = "Working from current feature branch: $currentBranch"
            Write-Verbose "Anti-recursive protection: Using current branch $currentBranch"
        } else {
            # Create new branch from main
            $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
            $cleanDesc = $PatchDescription -replace '^\w\s-', '' -replace '\s+', '-'
            $strategy.NewBranchName = "patch/$timestamp-$cleanDesc"
            $strategy.Message = "Creating new branch: $($strategy.NewBranchName)"
            Write-Verbose "Creating new patch branch: $($strategy.NewBranchName)"
        }
        
        return $strategy
    } catch {
        return @{
            Success = $false
            Message = "Failed to determine branch strategy: $($_.Exception.Message)"
            CurrentBranch = $currentBranch
            SkipBranchCreation = $true
            NewBranchName = $currentBranch
        }
    }
}
