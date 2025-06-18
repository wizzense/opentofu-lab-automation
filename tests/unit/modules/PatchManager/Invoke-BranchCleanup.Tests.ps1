BeforeAll {
    # Mock Write-CustomLog function
    function global:Write-CustomLog {
        param([string]$Message, [string]$Level = "INFO")
        # Silently handle log messages for cleaner test output
    }
    
    # Mock gh command (GitHub CLI)
    function global:gh {
        param([string[]]$args)
        if ($args[0] -eq "pr" -and $args[1] -eq "list") {
            # Return empty JSON array for merged PRs
            return "[]"
        }
        return ""
    }
    
    # Directly source the function file
    $projectRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $functionPath = Join-Path $projectRoot "pwsh/modules/PatchManager/Public/Invoke-BranchCleanup.ps1"
    . $functionPath    # Mock git commands with proper parameter handling
    function global:git {
        param()
        $gitArgs = $args
        $script:gitCalls += , $gitArgs
        
        Write-Host "Git called with: $($gitArgs -join ' ')" -ForegroundColor Yellow
        
        if ($gitArgs[0] -eq "branch" -and $gitArgs[1] -eq "-r" -and $gitArgs.Length -eq 2) {
            # git branch -r
            $branches = @(
                "  origin/main",
                "  origin/feature/test-branch", 
                "  origin/old-branch",
                "  origin/merged-branch"
            )
            Write-Host "Returning remote branches: $($branches -join ', ')" -ForegroundColor Cyan
            return $branches
        }
        elseif ($gitArgs[0] -eq "branch" -and $gitArgs[1] -eq "-r" -and $gitArgs[2] -eq "--merged") {
            # git branch -r --merged
            $mergedBranches = @(
                "  origin/old-branch",
                "  origin/merged-branch"
            )
            Write-Host "Returning merged branches: $($mergedBranches -join ', ')" -ForegroundColor Cyan
            return $mergedBranches
        }
        elseif ($gitArgs[0] -eq "log") { 
            $branch = $gitArgs[-1]  # Last argument should be the branch
            Write-Host "Getting log for branch: $branch" -ForegroundColor Magenta
            # Return old timestamp for old branches
            if ($branch -like "*old-branch*" -or $branch -like "*merged-branch*") {
                Write-Host "Returning old timestamp for $branch" -ForegroundColor Green
                return "1587459200" # Much older timestamp
            } else {
                Write-Host "Returning recent timestamp for $branch" -ForegroundColor Green
                return "1687459200" # Recent timestamp for other branches
            }
        }        elseif ($gitArgs[0] -eq "push") { 
            if ($gitArgs -contains "--delete") {
                $deleteIndex = [Array]::IndexOf($gitArgs, "--delete")
                $branchToDelete = $gitArgs[$deleteIndex + 1] # Branch name is right after --delete
                Write-Host "Deleting branch: $branchToDelete (args: $($gitArgs -join ' '))" -ForegroundColor Red
                $script:deletedBranches += $branchToDelete
                $global:LASTEXITCODE = 0
                return "Branch deleted successfully"
            }
        }
        elseif ($gitArgs[0] -eq "branch" -and $gitArgs[1] -eq "-D") {
            # Local branch cleanup - just return success
            $global:LASTEXITCODE = 0
            return "Branch deleted"
        }
        
        Write-Host "Unhandled git command: $($gitArgs -join ' ')" -ForegroundColor Red
        $global:LASTEXITCODE = 0
        return ""
    }
}

Describe "Invoke-BranchCleanup" {
    BeforeEach {
        $script:gitCalls = @()
        $script:deletedBranches = @()
    }
    
    It "Should preserve protected branches" {
        Invoke-BranchCleanup -Force
        
        $script:deletedBranches | Should -Not -Contain "main"
        $script:deletedBranches | Should -Not -Contain "master"
        $script:deletedBranches | Should -Not -Contain "develop"
    }
      It "Should delete old merged branches" {
        $result = Invoke-BranchCleanup -Force
        
        Write-Host "Git calls made: $($script:gitCalls.Count)"
        Write-Host "Deleted branches: $($script:deletedBranches -join ', ')"
        Write-Host "Result: $($result | ConvertTo-Json -Depth 2)"
        
        $script:deletedBranches | Should -Contain "old-branch"
        $script:deletedBranches | Should -Contain "merged-branch"
    }
    
    It "Should respect PreserveHours parameter" {
        # Test with preservation period longer than our fixed timestamp
        Invoke-BranchCleanup -PreserveHours 1000000
        
        $script:deletedBranches | Should -BeNullOrEmpty
    }
    
    It "Should handle Force switch correctly" {
        Invoke-BranchCleanup -Force
        
        $script:deletedBranches.Count | Should -BeGreaterThan 0
    }
}
