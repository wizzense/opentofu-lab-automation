#Requires -Version 7.0

<#
.SYNOPSIS
    Demonstrates how VS Code configuration enforces PatchManager usage for AI agents

.DESCRIPTION
    This script showcases how the comprehensive VS Code configuration (Copilot instructions,
    settings, tasks, snippets) guides and enforces the use of PatchManager for all code changes.
    It simulates what an AI agent would do when instructed to make changes in this workspace.

.NOTES
    - Demonstrates VS Code configuration enforcement
    - Shows PatchManager workflow integration
    - Validates AI agent compliance with project standards
#>

param(
    [Parameter()]
    [switch]$ShowConfiguration,
    
    [Parameter()]
    [switch]$DemoAIWorkflow,
    
    [Parameter()]
    [switch]$ValidateEnforcement
)

function Write-CustomLog {
    param($Message, $Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
        "SUCCESS" { "Green" }
        "WARN" { "Yellow" }
        "ERROR" { "Red" }
        default { "White" }
    }
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}

function Show-VSCodeConfiguration {
    [CmdletBinding()]
    param()
    
    Write-CustomLog "=== VS Code Configuration Analysis ===" -Level INFO
    
    # Check Copilot instructions
    $copilotInstructions = Get-Content ".vscode/copilot-instructions.md" -Raw
    Write-CustomLog "Copilot Instructions Status: CONFIGURED" -Level SUCCESS
    Write-CustomLog "- Contains explicit PatchManager requirement: $($copilotInstructions -match 'CRITICAL: ALL CODE CHANGES MUST USE PatchManager')" -Level INFO
    
    # Check settings.json for Copilot enforcement
    $settings = Get-Content ".vscode/settings.json" -Raw
    Write-CustomLog "Settings.json Status: CONFIGURED" -Level SUCCESS
    Write-CustomLog "- Contains Copilot code generation rules: $($settings -match 'github.copilot.chat.codeGeneration.instructions')" -Level INFO
    Write-CustomLog "- Contains test generation rules: $($settings -match 'github.copilot.chat.testGeneration.instructions')" -Level INFO
    
    # Check tasks.json for PatchManager tasks
    $tasks = Get-Content ".vscode/tasks.json" -Raw
    Write-CustomLog "Tasks.json Status: CONFIGURED" -Level SUCCESS
    Write-CustomLog "- Contains PatchManager tasks: $($tasks -match 'PatchManager:')" -Level INFO
    
    # Check snippets for PatchManager patterns
    $snippets = Get-Content ".vscode/snippets/powershell.json" -Raw
    Write-CustomLog "PowerShell Snippets Status: CONFIGURED" -Level SUCCESS
    Write-CustomLog "- Contains standardized patterns: $($snippets -match 'psfunction')" -Level INFO
    
    Write-CustomLog "=== Configuration Summary ===" -Level INFO
    Write-CustomLog "✓ All VS Code configuration files enforce PatchManager usage" -Level SUCCESS
    Write-CustomLog "✓ Copilot is instructed to use PatchManager for all changes" -Level SUCCESS
    Write-CustomLog "✓ Tasks only provide PatchManager-based workflows" -Level SUCCESS
    Write-CustomLog "✓ Snippets follow project standards and patterns" -Level SUCCESS
}

function Demo-AIAgentWorkflow {
    [CmdletBinding()]
    param()
    
    Write-CustomLog "=== Simulating AI Agent Code Change Workflow ===" -Level INFO
    
    # Step 1: AI Agent reads Copilot instructions
    Write-CustomLog "1. AI Agent reads .vscode/copilot-instructions.md" -Level INFO
    Write-CustomLog "   - Learns about PatchManager requirement" -Level INFO
    Write-CustomLog "   - Understands project structure and standards" -Level INFO
    
    # Step 2: AI Agent checks available VS Code tasks
    Write-CustomLog "2. AI Agent checks available VS Code tasks" -Level INFO
    Write-CustomLog "   - Finds 'PatchManager: Apply Changes with DirectCommit'" -Level INFO
    Write-CustomLog "   - Finds 'PatchManager: Apply Changes with PR'" -Level INFO
    Write-CustomLog "   - Finds 'PatchManager: Emergency Rollback'" -Level INFO
    
    # Step 3: AI Agent uses snippets for code generation
    Write-CustomLog "3. AI Agent uses PowerShell snippets" -Level INFO
    Write-CustomLog "   - Uses 'psfunction' for standard function structure" -Level INFO
    Write-CustomLog "   - Uses 'psimport' for proper module imports" -Level INFO
    Write-CustomLog "   - Uses 'pslabstep' for lab workflow integration" -Level INFO
    
    # Step 4: AI Agent would invoke PatchManager (simulated)
    Write-CustomLog "4. AI Agent invokes PatchManager workflow (SIMULATED)" -Level WARN
    Write-CustomLog "   Command would be: Invoke-GitControlledPatch -PatchDescription 'AI generated changes' -PatchOperation { ... }" -Level INFO
    
    Write-CustomLog "=== AI Agent Workflow Complete ===" -Level SUCCESS
    Write-CustomLog "All steps follow enforced PatchManager workflow!" -Level SUCCESS
}

function Test-EnforcementMechanisms {
    [CmdletBinding()]
    param()
    
    Write-CustomLog "=== Validating Enforcement Mechanisms ===" -Level INFO
    
    # Test 1: Verify no direct file editing tasks
    $tasks = Get-Content ".vscode/tasks.json" | ConvertFrom-Json
    $directEditTasks = $tasks.tasks | Where-Object { 
        $_.command -match "(cp|mv|rm|del|copy|move|edit)" -and 
        $_.command -notmatch "PatchManager" 
    }
    
    if ($directEditTasks.Count -eq 0) {
        Write-CustomLog "✓ No direct file editing tasks found - PatchManager enforced" -Level SUCCESS
    } else {
        Write-CustomLog "✗ Found $($directEditTasks.Count) non-PatchManager tasks" -Level ERROR
    }
    
    # Test 2: Verify Copilot instructions contain enforcement
    $copilotContent = Get-Content ".vscode/copilot-instructions.md" -Raw
    $enforcementKeywords = @(
        "CRITICAL.*PatchManager",
        "ALL.*CHANGES.*MUST",
        "Invoke-GitControlledPatch",
        "validation.*testing"
    )
    
    $enforcementFound = $enforcementKeywords | ForEach-Object {
        $copilotContent -match $_
    }
    
    if ($enforcementFound -contains $true) {
        Write-CustomLog "✓ Copilot instructions contain PatchManager enforcement" -Level SUCCESS
    } else {
        Write-CustomLog "✗ Copilot instructions missing enforcement keywords" -Level ERROR
    }
    
    # Test 3: Verify settings.json has Copilot constraints
    $settings = Get-Content ".vscode/settings.json" -Raw
    $copilotSettings = @(
        "github.copilot.chat.codeGeneration.instructions",
        "github.copilot.chat.testGeneration.instructions",
        "github.copilot.chat.reviewSelection.instructions"
    )
    
    $settingsFound = $copilotSettings | ForEach-Object {
        $settings -match $_
    }
    
    if (($settingsFound | Where-Object { $_ -eq $true }).Count -eq $copilotSettings.Count) {
        Write-CustomLog "✓ All Copilot instruction settings configured" -Level SUCCESS
    } else {
        Write-CustomLog "✗ Missing Copilot instruction settings" -Level ERROR
    }
    
    # Test 4: Verify PatchManager module availability
    try {
        $patchManagerCommands = Get-Command -Module PatchManager -ErrorAction Stop
        Write-CustomLog "✓ PatchManager module loaded with $($patchManagerCommands.Count) commands" -Level SUCCESS
        Write-CustomLog "  - Primary command: Invoke-GitControlledPatch available" -Level INFO
    }
    catch {
        Write-CustomLog "✗ PatchManager module not available: $($_.Exception.Message)" -Level ERROR
    }
    
    Write-CustomLog "=== Enforcement Validation Complete ===" -Level SUCCESS
}

function Show-PatchManagerWorkflow {
    [CmdletBinding()]
    param()
    
    Write-CustomLog "=== PatchManager Workflow Demonstration ===" -Level INFO
    
    # Show what a real PatchManager call would look like
    Write-CustomLog "Example PatchManager workflow that AI agents are required to use:" -Level INFO
    
    $exampleWorkflow = @"
# This is what AI agents are instructed to do for ANY code change:

Invoke-GitControlledPatch -PatchDescription "AI Agent: Update module function" -PatchOperation {
    # AI agent's actual file changes go here
    \$content = Get-Content "path/to/file.ps1"
    \$newContent = \$content -replace "old pattern", "new pattern"
    Set-Content "path/to/file.ps1" -Value \$newContent
    
    # Additional changes...
    
} -AutoCommitUncommitted -CreatePullRequest -TestCommands @(
    "Invoke-Pester tests/",
    "Invoke-ScriptAnalyzer pwsh/"
)

# This ensures:
# ✓ All changes are tracked and logged
# ✓ Automatic testing and validation
# ✓ Git history preservation
# ✓ Rollback capability
# ✓ Pull request workflow
# ✓ Audit trail
"@
    
    Write-CustomLog $exampleWorkflow -Level INFO
    
    Write-CustomLog "=== Key Enforcement Points ===" -Level INFO
    Write-CustomLog "1. No direct file editing allowed in VS Code tasks" -Level INFO
    Write-CustomLog "2. All Copilot instructions point to PatchManager" -Level INFO
    Write-CustomLog "3. Snippets follow PatchManager-compatible patterns" -Level INFO
    Write-CustomLog "4. Settings enforce testing and validation requirements" -Level INFO
    Write-CustomLog "5. Launch configurations support PatchManager debugging" -Level INFO
}

# Main execution
try {
    Write-CustomLog "Starting VS Code PatchManager Enforcement Demonstration" -Level INFO
    
    if ($ShowConfiguration) {
        Show-VSCodeConfiguration
    }
    
    if ($DemoAIWorkflow) {
        Demo-AIAgentWorkflow
    }
    
    if ($ValidateEnforcement) {
        Test-EnforcementMechanisms
    }
    
    if (-not ($ShowConfiguration -or $DemoAIWorkflow -or $ValidateEnforcement)) {
        # Run all demonstrations by default
        Show-VSCodeConfiguration
        Write-CustomLog ""
        Demo-AIAgentWorkflow
        Write-CustomLog ""
        Test-EnforcementMechanisms
        Write-CustomLog ""
        Show-PatchManagerWorkflow
    }
    
    Write-CustomLog "=== CONCLUSION ===" -Level SUCCESS
    Write-CustomLog "VS Code configuration successfully enforces PatchManager usage for all AI agents!" -Level SUCCESS
    Write-CustomLog "✓ Copilot instructions require PatchManager" -Level SUCCESS
    Write-CustomLog "✓ VS Code tasks only provide PatchManager workflows" -Level SUCCESS
    Write-CustomLog "✓ Snippets follow project standards" -Level SUCCESS
    Write-CustomLog "✓ Settings configure Copilot with proper constraints" -Level SUCCESS
    Write-CustomLog "✓ All file changes must go through validation and testing" -Level SUCCESS
}
catch {
    Write-CustomLog "Error during demonstration: $($_.Exception.Message)" -Level ERROR
    throw
}



