#Requires -Version 7.0

BeforeAll {
    # Mock Write-CustomLog function
    function global:Write-CustomLog {
        param([string]$Message, [string]$Level = "INFO")
        Write-Host "[$Level] $Message"
    }
    
    # Mock gh (GitHub CLI) command
    function global:gh {
        param([string[]]$Arguments)
        $script:ghCalls += ,@($Arguments)
        return ""
    }      # Directly source the function file
    $projectRoot = "c:\Users\alexa\OneDrive\Documents\0. wizzense\opentofu-lab-automation"
    $functionPath = Join-Path $projectRoot "core-runner/modules/PatchManager/Public/ErrorHandling.ps1"
    if (Test-Path $functionPath) {
        . $functionPath
    } else {
        throw "Cannot find ErrorHandling.ps1 at $functionPath"
    }
}

Describe "ErrorHandling Module" {
    BeforeEach {
        $script:ghCalls = @()
    }
    
    Context "HandlePatchError function" {
        It "Should handle patch error with all parameters" {
            $errorRecord = try { throw "Test error" } catch { $_ }
            
            { HandlePatchError -ErrorRecord $errorRecord -Context @{Operation = "Test"} -IssueNumber 123 } | Should -Not -Throw
        }
        
        It "Should handle error without issue number" {
            $errorRecord = try { throw "Test error" } catch { $_ }
            
            { HandlePatchError -ErrorRecord $errorRecord -Context @{Operation = "Test"} } | Should -Not -Throw
        }
        
        It "Should handle error without context" {
            $errorRecord = try { throw "Test error" } catch { $_ }
            
            { HandlePatchError -ErrorRecord $errorRecord } | Should -Not -Throw
        }
        
        It "Should send GitHub issue comment when IssueNumber provided" {
            $errorRecord = try { throw "Test error" } catch { $_ }
            
            HandlePatchError -ErrorRecord $errorRecord -Context @{Operation = "Test"} -IssueNumber 123
            
            $script:ghCalls.Count | Should -BeGreaterThan 0
            $script:ghCalls[0] | Should -Contain "issue"
            $script:ghCalls[0] | Should -Contain "comment"
            $script:ghCalls[0] | Should -Contain "123"
        }
    }
    
    Context "Write-PatchLog function" {
        It "Should write log message with default level" {
            { Write-PatchLog -Message "Test message" } | Should -Not -Throw
        }
        
        It "Should accept different log levels" {
            $levels = @("INFO", "WARNING", "ERROR", "DEBUG")
            
            foreach ($level in $levels) {
                { Write-PatchLog -Message "Test message" -Level $level } | Should -Not -Throw
            }
        }
        
        It "Should handle empty message" {
            { Write-PatchLog -Message "" } | Should -Not -Throw
        }
        
        It "Should handle null message gracefully" {
            { Write-PatchLog -Message $null } | Should -Not -Throw
        }
    }
}
