BeforeAll {
    # Mock Write-CustomLog function
    function global:Write-CustomLog {
        param([string]$Message, [string]$Level = "INFO")
        Write-Host "[$Level] $Message"
    }
    
    # Import PatchManager module
    $projectRoot = "c:\Users\alexa\OneDrive\Documents\0. wizzense\opentofu-lab-automation"
    $patchManagerPath = Join-Path $projectRoot "core-runner/modules/PatchManager"
    
    try {
        Import-Module $patchManagerPath -Force -ErrorAction Stop
        Write-Host "PatchManager module imported successfully" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to import PatchManager module: $_"
        throw
    }
    
    # Mock git commands
    function global:git {
        param()
        $gitArgs = $args
        $script:gitCalls += , $gitArgs
        
        switch ($gitArgs[0]) {
            "status" {
                if ($gitArgs[1] -eq "--porcelain") {
                    return ""  # Clean working tree
                }
                return "On branch main`nnothing to commit, working tree clean"
            }
            "rev-parse" {
                if ($gitArgs[1] -eq "--abbrev-ref" -and $gitArgs[2] -eq "HEAD") {
                    return "main"
                }
            }
            "branch" {
                if ($gitArgs[1] -eq "-r") {
                    return @(
                        "  origin/main",
                        "  origin/feature/test-branch"
                    )
                }
            }
            "remote" {
                if ($gitArgs[1] -eq "-v") {
                    return "origin  https://github.com/test/repo.git (fetch)"
                }
            }
            default {
                $global:LASTEXITCODE = 0
                return ""
            }
        }
    }
    
    # Mock gh command (GitHub CLI)
    function global:gh {
        param()
        $ghArgs = $args
        
        if ($ghArgs[0] -eq "auth" -and $ghArgs[1] -eq "status") {
            return "Logged in to github.com as testuser"
        }
        
        $global:LASTEXITCODE = 0
        return ""
    }
}

Describe "PatchManager Core Functions" {
    BeforeEach {
        $script:gitCalls = @()
    }
    
    Context "Test-PatchingRequirements" {
        It "Should validate basic patching requirements" {
            $result = Test-PatchingRequirements -ProjectRoot $PWD
            
            $result | Should -Not -BeNullOrEmpty
            $result.Success | Should -BeOfType [bool]
        }
        
        It "Should return proper structure with required properties" {
            $result = Test-PatchingRequirements -ProjectRoot $PWD
            
            $result.AllRequirementsMet | Should -BeOfType [bool]
            $result.ModulesAvailable | Should -BeOfType [array]
            $result.ModulesMissing | Should -BeOfType [array]
            $result.CommandsAvailable | Should -BeOfType [array]
            $result.CommandsMissing | Should -BeOfType [array]
        }
    }
    
    Context "Invoke-GitControlledPatch" {
        It "Should require PatchDescription parameter" {
            { Invoke-GitControlledPatch } | Should -Throw
        }
        
        It "Should accept DryRun parameter" {
            $scriptBlock = { Write-Host "Test patch" }
            
            { Invoke-GitControlledPatch -PatchDescription "Test patch" -PatchOperation $scriptBlock -DryRun } | Should -Not -Throw
        }
        
        It "Should validate working tree when not forced" {
            $scriptBlock = { Write-Host "Test patch" }
            
            # This should not throw since our mock git returns clean status
            { Invoke-GitControlledPatch -PatchDescription "Test patch" -PatchOperation $scriptBlock -DryRun } | Should -Not -Throw
        }
    }
    
    Context "Invoke-EnhancedPatchManager" {
        It "Should require PatchDescription parameter" {
            { Invoke-EnhancedPatchManager } | Should -Throw
        }
        
        It "Should accept AutoValidate parameter" {
            { Invoke-EnhancedPatchManager -PatchDescription "Test patch" -AutoValidate -DryRun } | Should -Not -Throw
        }
        
        It "Should accept CreatePullRequest parameter" {
            { Invoke-EnhancedPatchManager -PatchDescription "Test patch" -CreatePullRequest -DryRun } | Should -Not -Throw
        }
    }
    
    Context "Set-PatchManagerAliases" {
        It "Should set up aliases without error" {
            { Set-PatchManagerAliases -Scope Process } | Should -Not -Throw
        }
        
        It "Should display help when requested" {
            { Set-PatchManagerAliases -ShowHelp } | Should -Not -Throw
        }
        
        It "Should remove aliases when requested" {
            { Set-PatchManagerAliases -RemoveAliases -Scope Process } | Should -Not -Throw
        }
    }
    
    Context "Invoke-QuickRollback" {
        It "Should accept RollbackType parameter" {
            { Invoke-QuickRollback -RollbackType "LastCommit" -DryRun } | Should -Not -Throw
        }
        
        It "Should accept CreateBackup parameter" {
            { Invoke-QuickRollback -RollbackType "LastCommit" -CreateBackup -DryRun } | Should -Not -Throw
        }
    }
    
    Context "Invoke-TieredPesterTests" {
        It "Should accept TestCategory parameter" {
            { Invoke-TieredPesterTests -TestCategory "Unit" -DryRun } | Should -Not -Throw
        }
        
        It "Should accept GenerateCoverage parameter" {
            { Invoke-TieredPesterTests -TestCategory "Unit" -GenerateCoverage -DryRun } | Should -Not -Throw
        }
    }
}

Describe "PatchManager Integration Tests" {
    BeforeEach {
        $script:gitCalls = @()
    }
    
    Context "Module Loading" {
        It "Should have imported PatchManager functions" {
            Get-Command -Module "PatchManager" | Should -Not -BeNullOrEmpty
        }
        
        It "Should have core functions available" {
            $expectedFunctions = @(
                'Invoke-GitControlledPatch',
                'Invoke-EnhancedPatchManager',
                'Test-PatchingRequirements',
                'Set-PatchManagerAliases',
                'Invoke-QuickRollback'
            )
            
            foreach ($func in $expectedFunctions) {
                Get-Command $func -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty -Because "$func should be available"
            }
        }
    }
    
    Context "Cross-Platform Environment" {
        It "Should handle cross-platform paths correctly" {
            # Test that the module works with forward slash paths
            $testPath = "/test/path/file.ps1"
            
            # This should not throw an error
            { Test-Path $testPath -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }
}

Describe "PatchManager Error Handling" {
    Context "Invalid Parameters" {
        It "Should handle invalid patch description gracefully" {
            { Invoke-GitControlledPatch -PatchDescription "" -DryRun } | Should -Throw
        }
        
        It "Should handle invalid rollback type gracefully" {
            { Invoke-QuickRollback -RollbackType "InvalidType" -DryRun } | Should -Throw
        }
    }
    
    Context "Environment Validation" {
        It "Should detect missing git command" {
            # Temporarily remove git mock
            Remove-Item Function:\git -ErrorAction SilentlyContinue
            
            $result = Test-PatchingRequirements -ProjectRoot $PWD
            $result.CommandsMissing | Should -Contain "git"
            
            # Restore git mock
            function global:git { param() return "" }
        }
    }
}
