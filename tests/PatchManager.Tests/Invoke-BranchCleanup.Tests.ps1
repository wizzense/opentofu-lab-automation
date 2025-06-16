BeforeAll {
    Import-Module $PSScriptRoot/../../pwsh/modules/PatchManager -Force
    
    # Mock git commands    function global:git {
        param([string[]]$gitArgs)
        $script:gitCalls += , $gitArgs
        
        switch ($gitArgs[0]) {
            "branch" {
                if ($args -contains "-r") {
                    @(
                        "origin/main",
                        "origin/feature/test-branch",
                        "origin/old-branch",
                        "origin/merged-branch"
                    )
                }
            }
            "log" { "1687459200" } # Fixed timestamp for testing
            "push" { 
                if ($args -contains "--delete") {
                    $script:deletedBranches += $args[-1]
                    return 0
                }
            }
        }
    }
}

Describe "Invoke-BranchCleanup" {
    BeforeEach {
        $script:gitCalls = @()
        $script:deletedBranches = @()
    }
    
    It "Should preserve protected branches" {
        Invoke-BranchCleanup -Force
        
        $deletedBranches | Should -Not -Contain "main"
        $deletedBranches | Should -Not -Contain "master"
        $deletedBranches | Should -Not -Contain "develop"
    }
    
    It "Should delete old merged branches" {
        Invoke-BranchCleanup -Force
        
        $deletedBranches | Should -Contain "old-branch"
        $deletedBranches | Should -Contain "merged-branch"
    }
    
    It "Should respect PreserveHours parameter" {
        # Test with preservation period longer than our fixed timestamp
        Invoke-BranchCleanup -PreserveHours 1000000
        
        $deletedBranches | Should -BeNullOrEmpty
    }
    
    It "Should handle Force switch correctly" {
        Invoke-BranchCleanup -Force
        
        $deletedBranches.Count | Should -BeGreaterThan 0
    }
}
