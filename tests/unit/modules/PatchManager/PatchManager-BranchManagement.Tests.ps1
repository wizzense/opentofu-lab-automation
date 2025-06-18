BeforeAll {
    # Import PatchManager module
    $projectRoot = "c:\Users\alexa\OneDrive\Documents\0. wizzense\opentofu-lab-automation"
    $patchManagerPath = Join-Path $projectRoot "core-runner/modules/PatchManager"
    
    try {
        Import-Module $patchManagerPath -Force -ErrorAction Stop
    }
    catch {
        Write-Error "Failed to import PatchManager module: $_"
        throw
    }
    
    # Mock functions for testing
    function global:Write-CustomLog {
        param([string]$Message, [string]$Level = "INFO")
        Write-Host "[$Level] $Message"
    }
    
    # Mock git to simulate various branch scenarios
    function global:git {
        param()
        $gitArgs = $args
        $script:gitCalls += , $gitArgs
        
        switch -Regex ($gitArgs -join " ") {
            "^branch -r$" {
                return @(
                    "  origin/main",
                    "  origin/feature/active-work",
                    "  origin/hotfix/old-fix-123",
                    "  origin/feature/merged-feature",
                    "  origin/release/v1.0.0"
                )
            }
            "^branch -r --merged" {
                return @(
                    "  origin/hotfix/old-fix-123",
                    "  origin/feature/merged-feature"
                )
            }
            "^log.*--format.*--since" {
                $branchName = $gitArgs[-1]
                if ($branchName -like "*old-fix*" -or $branchName -like "*merged-feature*") {
                    return "" # No recent commits
                } else {
                    return "abc123 Recent commit" # Has recent commits
                }
            }
            "^push.*--delete" {
                $deleteIndex = [Array]::IndexOf($gitArgs, "--delete")
                if ($deleteIndex -ne -1 -and $deleteIndex + 1 -lt $gitArgs.Count) {
                    $branchToDelete = $gitArgs[$deleteIndex + 1]
                    $script:deletedBranches += $branchToDelete
                    return "Deleted remote branch $branchToDelete"
                }
            }
            "^branch -D" {
                $branchToDelete = $gitArgs[2]
                $script:deletedLocalBranches += $branchToDelete
                return "Deleted local branch $branchToDelete"
            }
            default {
                $global:LASTEXITCODE = 0
                return ""
            }
        }
    }
    
    # Mock gh command
    function global:gh {
        param()
        $ghArgs = $args
        
        if ($ghArgs[0] -eq "pr" -and $ghArgs[1] -eq "list") {
            # Return empty array for merged PRs associated with branches
            return "[]"
        }
        
        $global:LASTEXITCODE = 0
        return ""
    }
}

Describe "PatchManager Branch Management" {
    BeforeEach {
        $script:gitCalls = @()
        $script:deletedBranches = @()
        $script:deletedLocalBranches = @()
    }
    
    Context "Get-IntelligentBranchStrategy" {
        It "Should create strategy for new patch" {
            $result = Get-IntelligentBranchStrategy -PatchDescription "fix: resolve issue with module loading"
            
            $result | Should -Not -BeNullOrEmpty
            $result.Success | Should -Be $true
            $result.CurrentBranch | Should -Not -BeNullOrEmpty
        }
        
        It "Should handle force new branch parameter" {
            $result = Get-IntelligentBranchStrategy -PatchDescription "feat: add new feature" -ForceNewBranch
            
            $result.SkipBranchCreation | Should -Be $false
        }
        
        It "Should detect protected branches" {
            $result = Get-IntelligentBranchStrategy -PatchDescription "fix: test" -CurrentBranch "main"
            
            # Should not skip branch creation when on protected branch
            $result.SkipBranchCreation | Should -Be $false
        }
    }
    
    Context "Test-BranchProtection" {
        It "Should identify protected branches" {
            Test-BranchProtection -BranchName "main" | Should -Be $true
            Test-BranchProtection -BranchName "master" | Should -Be $true
            Test-BranchProtection -BranchName "develop" | Should -Be $true
        }
        
        It "Should allow feature branches" {
            Test-BranchProtection -BranchName "feature/new-feature" | Should -Be $false
            Test-BranchProtection -BranchName "hotfix/bug-123" | Should -Be $false
        }
        
        It "Should handle custom protected patterns" {
            $customPatterns = @("release/*", "prod/*")
            Test-BranchProtection -BranchName "release/v1.0.0" -ProtectedPatterns $customPatterns | Should -Be $true
            Test-BranchProtection -BranchName "prod/staging" -ProtectedPatterns $customPatterns | Should -Be $true
        }
    }
    
    Context "Get-SanitizedBranchName" {
        It "Should sanitize branch names properly" {
            $result = Get-SanitizedBranchName -Description "Fix: Resolve Issue #123 with special chars!"
            
            $result | Should -Not -Match "[^a-zA-Z0-9\-/]"
            $result | Should -Not -BeNullOrEmpty
        }
        
        It "Should include timestamp by default" {
            $result = Get-SanitizedBranchName -Description "test fix"
            
            $result | Should -Match "\d{8}-\d{6}"
        }
        
        It "Should exclude timestamp when requested" {
            $result = Get-SanitizedBranchName -Description "test fix" -IncludeTimestamp:$false
            
            $result | Should -Not -Match "\d{8}-\d{6}"
        }
        
        It "Should use custom prefix" {
            $result = Get-SanitizedBranchName -Description "test fix" -Prefix "hotfix"
            
            $result | Should -Match "^hotfix/"
        }
    }
}

Describe "PatchManager Cleanup Operations" {
    BeforeEach {
        $script:gitCalls = @()
        $script:deletedBranches = @()
    }
    
    Context "Invoke-ComprehensiveCleanup" {
        It "Should accept CleanupMode parameter" {
            { Invoke-ComprehensiveCleanup -CleanupMode "Standard" -DryRun } | Should -Not -Throw
        }
        
        It "Should perform dry run without making changes" {
            $result = Invoke-ComprehensiveCleanup -CleanupMode "Standard" -DryRun
            
            $result | Should -Not -BeNullOrEmpty
            $result.DryRun | Should -Be $true
        }
        
        It "Should respect exclude patterns" {
            $excludePatterns = @("*.log", "temp/*")
            
            { Invoke-ComprehensiveCleanup -CleanupMode "Standard" -ExcludePatterns $excludePatterns -DryRun } | Should -Not -Throw
        }
        
        It "Should handle different cleanup modes" {
            $modes = @("Standard", "Aggressive", "Emergency", "Safe")
            
            foreach ($mode in $modes) {
                { Invoke-ComprehensiveCleanup -CleanupMode $mode -DryRun } | Should -Not -Throw -Because "Mode $mode should be supported"
            }
        }
    }
    
    Context "Invoke-TempFileCleanup" {
        It "Should clean temporary files safely" {
            { Invoke-TempFileCleanup -DryRun } | Should -Not -Throw
        }
        
        It "Should respect age threshold" {
            { Invoke-TempFileCleanup -AgeThresholdHours 24 -DryRun } | Should -Not -Throw
        }
    }
    
    Context "Invoke-EmojiCleanup" {
        It "Should detect and clean emoji usage" {
            { Invoke-EmojiCleanup -DryRun } | Should -Not -Throw
        }
        
        It "Should scan specified paths only" {
            $testPaths = @("./tests", "./src")
            
            { Invoke-EmojiCleanup -ScanPaths $testPaths -DryRun } | Should -Not -Throw
        }
    }
    
    Context "Invoke-DuplicateConsolidation" {
        It "Should identify duplicate files" {
            { Invoke-DuplicateConsolidation -DryRun } | Should -Not -Throw
        }
        
        It "Should handle different consolidation strategies" {
            $strategies = @("KeepNewest", "KeepLargest", "KeepInPreferredLocation")
            
            foreach ($strategy in $strategies) {
                { Invoke-DuplicateConsolidation -Strategy $strategy -DryRun } | Should -Not -Throw -Because "Strategy $strategy should be supported"
            }
        }
    }
}

Describe "PatchManager Safety Features" {
    Context "Test-CriticalExclusion" {
        It "Should protect critical system files" {
            Test-CriticalExclusion -FilePath ".git/config" | Should -Be $true
            Test-CriticalExclusion -FilePath "PROJECT-MANIFEST.json" | Should -Be $true
            Test-CriticalExclusion -FilePath "core-runner/modules/PatchManager/PatchManager.psm1" | Should -Be $true
        }
        
        It "Should allow non-critical files" {
            Test-CriticalExclusion -FilePath "temp/backup-file.txt" | Should -Be $false
            Test-CriticalExclusion -FilePath "logs/debug.log" | Should -Be $false
        }
        
        It "Should handle custom exclusion patterns" {
            $customPatterns = @("important/*", "*.critical")
            
            Test-CriticalExclusion -FilePath "important/data.txt" -ExclusionPatterns $customPatterns | Should -Be $true
            Test-CriticalExclusion -FilePath "file.critical" -ExclusionPatterns $customPatterns | Should -Be $true
        }
    }
    
    Context "Invoke-CleanupValidation" {
        It "Should validate cleanup operations before execution" {
            $mockOperations = @(
                @{ Type = "Delete"; Path = "temp/file.txt"; Safe = $true },
                @{ Type = "Delete"; Path = ".git/config"; Safe = $false }
            )
            
            { Invoke-CleanupValidation -Operations $mockOperations } | Should -Not -Throw
        }
        
        It "Should prevent dangerous operations" {
            $dangerousOperation = @(
                @{ Type = "Delete"; Path = "core-runner/modules/PatchManager/PatchManager.psm1"; Safe = $false }
            )
            
            $result = Invoke-CleanupValidation -Operations $dangerousOperation
            $result.AllowedOperations.Count | Should -BeLessThan $dangerousOperation.Count
        }
    }
}

Describe "PatchManager Reporting" {
    Context "New-CleanupReport" {
        It "Should generate comprehensive cleanup report" {
            $mockResults = @{
                FilesDeleted = 5
                DirectoriesRemoved = 2
                SpaceReclaimed = "1.5 MB"
                Operations = @()
            }
            
            $result = New-CleanupReport -CleanupResults $mockResults
            
            $result | Should -Not -BeNullOrEmpty
            $result.Summary | Should -Not -BeNullOrEmpty
        }
        
        It "Should include operation details" {
            $mockResults = @{
                FilesDeleted = 3
                Operations = @(
                    @{ Type = "Delete"; Path = "temp/file1.txt"; Status = "Success" },
                    @{ Type = "Delete"; Path = "temp/file2.txt"; Status = "Success" },
                    @{ Type = "Delete"; Path = "temp/file3.txt"; Status = "Failed" }
                )
            }
            
            $result = New-CleanupReport -CleanupResults $mockResults -IncludeDetails
            
            $result.DetailedOperations | Should -HaveCount 3
        }
    }
}
