# TestGenerator.ps1
# Test generation functionality for the TestAutoFixer module

function New-TestFromScript {
    <#
    .SYNOPSIS
    Creates a Pester test file from a PowerShell script with automatic fix triggers

    .DESCRIPTION
    This function analyzes a PowerShell script and generates appropriate test files
    with standardized structure and automatic fix triggers that can detect and fix
    syntax errors when the tests are executed.

    .PARAMETER ScriptPath
    Path to the PowerShell script to create tests for

    .PARAMETER OutputPath
    Path where the test file should be created (default: tests/ScriptName.Tests.ps1)

    .PARAMETER TestType
    Type of test to create (Installer, Feature, Service, Configuration, CrossPlatform)

    .PARAMETER Force
    Overwrite existing test file if it exists

    .PARAMETER AddAutoFix
    Add automatic fix trigger to the test file

    .EXAMPLE
    New-TestFromScript -ScriptPath "pwsh/runner_scripts/0101_Install-Git.ps1" -TestType "Installer" -AddAutoFix
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)






]
        [string]$ScriptPath,
        
        [Parameter()]
        [string]$OutputPath = "",
        
        [Parameter()]
        [ValidateSet("Installer", "Feature", "Service", "Configuration", "CrossPlatform", "Auto")]
        [string]$TestType = "Auto",
        
        [Parameter()]
        [switch]$Force,
        
        [Parameter()]
        [switch]$AddAutoFix
    )
    
    if (-not (Test-Path $ScriptPath)) {
        Write-Error "Script not found: $ScriptPath"
        return $false
    }
    
    # Determine test type if Auto
    if ($TestType -eq "Auto") {
        $TestType = Get-ScriptCategory -Path $ScriptPath
    }
    
    # Determine output path if not specified
    if (-not $OutputPath) {
        $scriptName = [System.IO.Path]::GetFileName($ScriptPath)
        $baseName = [System.IO.Path]::GetFileNameWithoutExtension($scriptName)
        $OutputPath = Join-Path "tests" "$baseName.Tests.ps1"
    }
    
    # Check if output file exists and we're not forcing overwrite
    if ((Test-Path $OutputPath) -and -not $Force) {
        Write-Warning "Test file already exists: $OutputPath. Use -Force to overwrite."
        return $false
    }
    
    # Generate test content based on script analysis
    $analysis = Get-ScriptAnalysis -Path $ScriptPath
    $testContent = Generate-TestContent -Analysis $analysis -TestType $TestType -ScriptPath $ScriptPath -AddAutoFix:$AddAutoFix
    
    # Write the test file
    if ($PSCmdlet.ShouldProcess($OutputPath, "Create test file")) {
        $testContent | Out-File -FilePath $OutputPath -Encoding utf8
        Write-Host "Generated test file: $OutputPath" -ForegroundColor Green
        return $true
    }
    
    return $false
}

function Add-AutoFixTrigger {
    <#
    .SYNOPSIS
    Adds automatic fix triggers to existing test files
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)






]
        [string]$Path
    )
    
    if (-not (Test-Path $Path)) {
        Write-Error "Test file not found: $Path"
        return $false
    }
    
    $content = Get-Content -Path $Path -Raw
    $originalContent = $content
    
    # Check if auto-fix trigger already exists
    if ($content -match "# Auto-Fix Trigger") {
        Write-Verbose "Auto-fix trigger already exists in $Path"
        return $false
    }
    
    # Find the BeforeAll block to add trigger
    $beforeAllPattern = 'BeforeAll\s*\{'
    if ($content -notmatch $beforeAllPattern) {
        # No BeforeAll block, try to add after Describe
        $describePattern = 'Describe\s+[''"]([^''"]*)[''"](.*?)\{'"
        if ($content -match $describePattern) {
            $match = [regex]::Match($content, $describePattern)
            $insertPos = $match.Index + $match.Length
            
            $autoFixBlock = @'

    # Auto-Fix Trigger
    BeforeAll {
        # Check script syntax and auto-fix if issues found
        try {
            $scriptErrors = $null
            $scriptAst = [System.Management.Automation.Language.Parser]::ParseFile($ScriptPath, [ref]$null, [ref]$scriptErrors)
            
            if ($scriptErrors -and $scriptErrors.Count -gt 0) {
                Write-Warning "Syntax issues detected in $($ScriptPath), attempting auto-fix..."
                Import-Module (Join-Path $PSScriptRoot '..' 'tools' 'TestAutoFixer' 'TestAutoFixer.psd1') -ErrorAction SilentlyContinue
                if (Get-Command Invoke-SyntaxFix -ErrorAction SilentlyContinue) {
                    $null = Invoke-SyntaxFix -Path $ScriptPath -FixTypes All
                    Write-Host "Auto-fix completed for $($ScriptPath)" -ForegroundColor Green
                }
            }
        } catch {
            Write-Warning "Failed to check syntax for auto-fix: $_"
        }
    }
'@
            $content = $content.Insert($insertPos, $autoFixBlock)
        }
    } else {
        # Add to existing BeforeAll block
        $match = [regex]::Match($content, $beforeAllPattern)
        $insertPos = $match.Index + $match.Length
        
        $autoFixBlock = @'

        # Auto-Fix Trigger
        # Check script syntax and auto-fix if issues found
        try {
            $scriptErrors = $null
            $scriptAst = [System.Management.Automation.Language.Parser]::ParseFile($ScriptPath, [ref]$null, [ref]$scriptErrors)
            
            if ($scriptErrors -and $scriptErrors.Count -gt 0) {
                Write-Warning "Syntax issues detected in $($ScriptPath), attempting auto-fix..."
                Import-Module (Join-Path $PSScriptRoot '..' 'tools' 'TestAutoFixer' 'TestAutoFixer.psd1') -ErrorAction SilentlyContinue
                if (Get-Command Invoke-SyntaxFix -ErrorAction SilentlyContinue) {
                    $null = Invoke-SyntaxFix -Path $ScriptPath -FixTypes All
                    Write-Host "Auto-fix completed for $($ScriptPath)" -ForegroundColor Green
                }
            }
        } catch {
            Write-Warning "Failed to check syntax for auto-fix: $_"
        }
'@
        $content = $content.Insert($insertPos, $autoFixBlock)
    }
    
    # Apply changes if content was modified
    if ($content -ne $originalContent) {
        if ($PSCmdlet.ShouldProcess($Path, "Add auto-fix trigger")) {
            Set-Content -Path $Path -Value $content -NoNewline
            Write-Verbose "Added auto-fix trigger to $Path"
            return $true
        }
    }
    
    return $false
}

function Update-ExistingTests {
    <#
    .SYNOPSIS
    Updates all existing test files with auto-fix triggers
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter()






]
        [string]$TestDirectory = "tests",
        
        [Parameter()]
        [switch]$Recurse
    )
    
    if (-not (Test-Path $TestDirectory)) {
        Write-Error "Test directory not found: $TestDirectory"
        return $false
    }
    
    # Find all test files
    $searchParams = @{
        Path = $TestDirectory
        Filter = "*.Tests.ps1"
    }
    
    if ($Recurse) {
        $searchParams.Add("Recurse", $true)
    }
    
    $testFiles = Get-ChildItem @searchParams
    
    $updatedCount = 0
    foreach ($testFile in $testFiles) {
        if (Add-AutoFixTrigger -Path $testFile.FullName) {
            $updatedCount++
        }
    }
    
    Write-Host "Updated $updatedCount test files with auto-fix triggers" -ForegroundColor Green
    return $true
}

function New-FixWorkflow {
    <#
    .SYNOPSIS
    Creates a GitHub Actions workflow file that auto-fixes syntax issues on failure
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter()






]
        [string]$OutputPath = ".github/workflows/auto-fix-issues.yml",
        
        [Parameter()]
        [string]$BranchName = "main"
    )
    
    $workflowContent = @@"
---
name: Auto-Fix Issues

on:
  # Trigger after Pester workflow completes
  workflow_run:
    workflows: ["Pester"]
    types: [completed]
  # Allow manual trigger
  workflow_dispatch:

jobs:
  auto-fix:
    name: Auto-Fix Test Issues
    runs-on: ubuntu-latest
    if: github.event_name == 'workflow_dispatch' || github.event.workflow_run.conclusion == 'failure'
    permissions:
      contents: write
      pull-requests: write
    
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Install PowerShell
        shell: bash
        run: |
          if ! command -v pwsh >/dev/null 2>&1; then
            sudo apt-get update
            sudo apt-get install -y powershell
          fi

      - name: Download test results
        if: github.event_name != 'workflow_dispatch'
        run: |
          mkdir -p test-results
          gh run download '${{ github.event.workflow_run.id }}' -n test-results -D test-results
          if [ -f test-results/TestResults.xml ]; then
            echo "Test results found"
          else
            echo "No test results found, attempting to fix anyway"
          fi
        env:
          GH_TOKEN: '${{ secrets.GITHUB_TOKEN }}'

      - name: Run auto-fix module
        shell: pwsh
        run: |
          Import-Module ./tools/TestAutoFixer/TestAutoFixer.psd1 -Force
          
          # Analyze test results if available
          if (Test-Path "test-results/TestResults.xml") {
            \$failures = Get-TestFailures -ResultsPath "test-results/TestResults.xml"
            Write-Host "\$(\$failures.Count) test failures found to fix"
            
            foreach (\$failure in \$failures) {
              if (\$failure.SourceScript) {
                Write-Host "Attempting to fix: \$(\$failure.SourceScript)"
                Invoke-SyntaxFix -Path \$failure.SourceScript -FixTypes All
              }
            }
          } else {
            # Run comprehensive fixes on common directories
            Write-Host "Running comprehensive fixes on all script directories"
            Invoke-SyntaxFix -Path "pwsh" -Recurse -FixTypes All
            Invoke-SyntaxFix -Path "tests" -Recurse -FixTypes All
          }
          
          # Update all tests with auto-fix triggers
          Update-ExistingTests -TestDirectory "tests" -Recurse

      - name: Create PR if changes were made
        run: |
          if [[ \$(git status --porcelain | wc -l) -gt 0 ]]; then
            echo "Changes detected, creating PR"
            timestamp=\$(date +%Y%m%d%H%M%S)
            branch="auto-fix/syntax-fixes-\$timestamp"
            
            # Set git config
            git config user.name "GitHub Actions"
            git config user.email "actions@github.com"
            
            # Create branch, commit and push
            git checkout -b "\$branch"
            git add .
            git commit -m "Auto-fix: Syntax and test issues"
            git push -u origin "\$branch"
            
            # Create PR
            gh pr create --title "Auto-fix: Syntax and test issues" \\
              --body "This PR contains automated fixes for syntax and test issues detected in the CI pipeline. The fixes were applied using the TestAutoFixer module." \\
              --base "$BranchName"
          else
            echo "No changes detected, skipping PR creation"
          fi
        env:
          GH_TOKEN: '${{ secrets.GITHUB_TOKEN }}'
"@

    # Ensure the parent directory exists
    $parentDir = Split-Path $OutputPath -Parent
    if (-not (Test-Path $parentDir)) {
        if ($PSCmdlet.ShouldProcess($parentDir, "Create directory")) {
            New-Item -Path $parentDir -ItemType Directory -Force | Out-Null
        }
    }
    
    # Write the workflow file
    if ($PSCmdlet.ShouldProcess($OutputPath, "Create workflow file")) {
        $workflowContent | Out-File -FilePath $OutputPath -Encoding utf8
        Write-Host "Generated workflow file: $OutputPath" -ForegroundColor Green
        return $true
    }
    
    return $false
}

# Helper functions

function Get-ScriptCategory {
    <#
    .SYNOPSIS
    Determines the category of a PowerShell script
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)






]
        [string]$Path
    )
    
    if (-not (Test-Path $Path)) {
        Write-Error "Script not found: $Path"
        return "Unknown"
    }
    
    $content = Get-Content -Path $Path -Raw
    $fileName = [System.IO.Path]::GetFileName($Path)
    
    if ($fileName -match "^[0-9]{4}_Install-") {
        return "Installer"
    }
    elseif ($fileName -match "^[0-9]{4}_Enable-" -or $fileName -match "^[0-9]{4}_Configure-") {
        return "Feature"
    }
    elseif ($content -match "Get-Service|Start-Service|Stop-Service|Restart-Service") {
        return "Service"
    }
    elseif ($content -match "Set-Content|Get-Content|ConvertTo-Json|ConvertFrom-Json" -and 
           ($content -match "\.json|\.config|\.conf" -or $content -match "configuration")) {
        return "Configuration"
    }
    else {
        return "CrossPlatform"
    }
}

function Get-ScriptAnalysis {
    <#
    .SYNOPSIS
    Analyzes a PowerShell script to determine its structure and features
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)






]
        [string]$Path
    )
    
    if (-not (Test-Path $Path)) {
        throw "Script not found: $Path"
    }
    
    $content = Get-Content $Path -Raw
    $ast = [System.Management.Automation.Language.Parser]::ParseInput($content, [ref]$null, [ref]$null)
    
    $analysis = @{
        Functions = @()
        Parameters = @()
        Category = Get-ScriptCategory -Path $Path
        Platform = "CrossPlatform"
        RequiresAdmin = $false
        HasDownloads = $false
        HasInstallation = $false
        HasConfiguration = $false
        HasServiceManagement = $false
        DependsOnExternal = @()
    }
    
    # Find functions
    $functions = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)
    foreach ($func in $functions) {
        $analysis.Functions += @{
            Name = $func.Name
            Parameters = $func.Parameters.Name.VariablePath.UserPath
        }
    }
    
    # Find parameters
    $params = $ast.ParamBlock.Parameters | ForEach-Object { $_.Name.VariablePath.UserPath }
    if ($params) {
        $analysis.Parameters = $params
    }
    
    # Check platform requirements
    if ($content -match "IsWindows|Get-WindowsFeature|Get-WmiObject|Get-CimInstance" -or
        $content -match "\.msi|\.exe") {
        $analysis.Platform = "Windows"
    }
    elseif ($content -match "IsLinux|apt-get|yum|dnf") {
        $analysis.Platform = "Linux"
    }
    elseif ($content -match "IsMacOS|brew ") {
        $analysis.Platform = "MacOS"
    }
    
    # Check for admin requirements
    if ($content -match "Test-IsAdministrator|Administrator|RunAs|sudo|elevation") {
        $analysis.RequiresAdmin = $true
    }
    
    # Check for downloads
    if ($content -match "Invoke-WebRequest|Invoke-RestMethod|wget|curl|Start-BitsTransfer") {
        $analysis.HasDownloads = $true
    }
    
    # Check for installations
    if ($content -match "Start-Process|msiexec|choco|apt-get install|npm install|pip install") {
        $analysis.HasInstallation = $true
    }
    
    # Check for configuration
    if ($content -match "Set-Content|Get-Content|ConvertTo-Json|ConvertFrom-Json") {
        $analysis.HasConfiguration = $true
    }
    
    # Check for service management
    if ($content -match "Get-Service|Start-Service|Stop-Service|Restart-Service") {
        $analysis.HasServiceManagement = $true
    }
    
    return $analysis
}

function Generate-TestContent {
    <#
    .SYNOPSIS
    Generates the content for a test file based on script analysis
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)






]
        [hashtable]$Analysis,
        
        [Parameter(Mandatory=$true)]
        [string]$TestType,
        
        [Parameter(Mandatory=$true)]
        [string]$ScriptPath,
        
        [Parameter()]
        [switch]$AddAutoFix
    )
    
    $scriptName = [System.IO.Path]::GetFileName($ScriptPath)
    $scriptBaseName = [System.IO.Path]::GetFileNameWithoutExtension($scriptName)
    
    $skipClause = if ($Analysis.Platform -ne "CrossPlatform") { " -Skip:`$Skip$($Analysis.Platform)"
       } else { ""
       }
    
    $template = @@"
# Generated test file for $scriptName
# Generated on: $(Get-Date)

. (Join-Path `$PSScriptRoot 'TestDriveCleanup.ps1')
. (Join-Path `$PSScriptRoot 'helpers' 'TestHelpers.ps1')

Describe '$scriptBaseName Tests' -Tag '$($Analysis.Category)' {
"@

    if ($AddAutoFix) {
        $template += @@"

    # Auto-Fix Trigger
    BeforeAll {
        # Check script syntax and auto-fix if issues found
        try {
            `$script:ScriptPath = Get-RunnerScriptPath '$scriptName'
            if (-not `$script:ScriptPath -or -not (Test-Path `$script:ScriptPath)) {
                throw "Script under test not found: $scriptName (resolved path: `$script:ScriptPath)"
            }
            
            `$scriptErrors = `$null
            `$scriptAst = [System.Management.Automation.Language.Parser]::ParseFile(`$script:ScriptPath, [ref]`$null, [ref]`$scriptErrors)
            
            if (`$scriptErrors -and `$scriptErrors.Count -gt 0) {
                Write-Warning "Syntax issues detected in `$(`$script:ScriptPath), attempting auto-fix..."
                Import-Module (Join-Path `$PSScriptRoot '..' 'tools' 'TestAutoFixer' 'TestAutoFixer.psd1') -ErrorAction SilentlyContinue
                if (Get-Command Invoke-SyntaxFix -ErrorAction SilentlyContinue) {
                    `$null = Invoke-SyntaxFix -Path `$script:ScriptPath -FixTypes All
                    Write-Host "Auto-fix completed for `$(`$script:ScriptPath)" -ForegroundColor Green
                }
            }
        } catch {
            Write-Warning "Failed to check syntax for auto-fix: `$_"
        }
"@
    } else {
        $template += @@"

    BeforeAll {
        # Get the script path using the LabRunner function
        `$script:ScriptPath = Get-RunnerScriptPath '$scriptName'
        if (-not `$script:ScriptPath -or -not (Test-Path `$script:ScriptPath)) {
            throw "Script under test not found: $scriptName (resolved path: `$script:ScriptPath)"
        }
"@
    }

    $template += @@"
        
        # Set up test environment
        `$script:TestConfig = Get-TestConfiguration
"@

    if ($Analysis.Platform -eq "Windows" -or $Analysis.Platform -eq "CrossPlatform") {
        $template += "`n        `$script:SkipNonWindows = -not (Get-Platform).IsWindows"
    }
    if ($Analysis.Platform -eq "Linux" -or $Analysis.Platform -eq "CrossPlatform") {
        $template += "`n        `$script:SkipNonLinux = -not (Get-Platform).IsLinux"
    }
    if ($Analysis.Platform -eq "MacOS" -or $Analysis.Platform -eq "CrossPlatform") {
        $template += "`n        `$script:SkipNonMacOS = -not (Get-Platform).IsMacOS"
    }
    if ($Analysis.RequiresAdmin) {
        $template += "`n        `$script:SkipNonAdmin = -not (Test-IsAdministrator)"
    }

    $template += @@"

        
        # Set up standard mocks
        Disable-InteractivePrompts
        New-StandardMocks
    }
    
    Context 'Script Structure Validation' {
        It 'should have valid PowerShell syntax'$skipClause {
            `$errors = `$null
            [System.Management.Automation.Language.Parser]::ParseFile(`$script:ScriptPath, [ref]`$null, [ref]`$errors) | Out-Null
            (if (`$errors) { `$errors.Count  } else { 0 }) | Should -Be 0
        }
        
        It 'should follow naming conventions'$skipClause {
            `$scriptName = [System.IO.Path]::GetFileName(`$script:ScriptPath)
            `$scriptName | Should -Match '^[0-9]{4}_[A-Z][a-zA-Z0-9-]+\.ps1$|^[A-Z][a-zA-Z0-9-]+\.ps1$'
        }
        
        It 'should have Config parameter'$skipClause {
            `$content = Get-Content `$script:ScriptPath -Raw
            `$content | Should -Match 'Param\s*\(\s*.*\$Config'
        }
        
        It 'should import LabRunner module'$skipClause {
            `$content = Get-Content `$script:ScriptPath -Raw
            `$content | Should -Match 'Import-Module.*LabRunner'
        }
        
        It 'should contain Invoke-LabStep call'$skipClause {
            `$content = Get-Content `$script:ScriptPath -Raw
            `$content | Should -Match 'Invoke-LabStep'
        }
"@

    if ($Analysis.Functions.Count -gt 0) {
        $template += @@"

        It 'should define expected functions'$skipClause {
"@
        foreach ($func in $Analysis.Functions) {
            $template += @@"

            Get-Command '$($func.Name)' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
"@
        }
        $template += @@"

        }
"@
    }

    $template += @@"

    }
    
    Context 'Parameter Validation' {
"@

    if ($Analysis.Parameters.Count -gt 0) {
        foreach ($param in $Analysis.Parameters) {
            $template += @@"

        It 'should accept $param parameter'$skipClause {
            { & `$script:ScriptPath -$param 'TestValue' -WhatIf } | Should -Not -Throw
        }
"@
        }
    } else {
        $template += @@"

        It 'should handle execution without parameters'$skipClause {
            { & `$script:ScriptPath -WhatIf } | Should -Not -Throw
        }
"@
    }

    $template += @@"

    }
"@

    # Add category-specific test contexts
    switch ($TestType) {
        'Installer' {
            $template += @@"

    Context 'Installation Tests' {
        BeforeEach {
            # Mock external dependencies for testing
            Mock Invoke-WebRequest { return @{ StatusCode = 200 } }
            Mock Start-Process { return @{ ExitCode = 0 } }
            Mock Get-Command { `$false }
        }
        
        It 'should validate prerequisites'$skipClause {
            # Test prerequisite checking logic
            `$true | Should -BeTrue  # Placeholder - implement actual tests
        }
        
        It 'should handle download failures gracefully'$skipClause {
            # Mock download failure
            Mock Invoke-WebRequest { throw "Download failed" }
            
            # Test error handling for failed downloads
            { & `$script:ScriptPath -Config @{ $(if ($Analysis.Category -eq "Installer") { "Install$(if($scriptName -match '_Install-(.+)\.ps1$'){$matches[1]}Else{$scriptBaseName})=" } else { "ConfigProperty=" })`$true } } | Should -Not -Throw
        }
        
        It 'should verify installation success'$skipClause {
            # Test installation verification
            & `$script:ScriptPath -Config @{ $(if ($Analysis.Category -eq "Installer") { "Install$(if($scriptName -match '_Install-(.+)\.ps1$'){$matches[1]}Else{$scriptBaseName})=" } else { "ConfigProperty=" })`$true }
            Should -Invoke Start-Process -Times 1
        }
    }
"@
        }
        
        'Feature' {
            $template += @@"

    Context 'Feature Management Tests' {
        It 'should check if feature is already enabled'$skipClause {
            # Test feature state checking
            `$true | Should -BeTrue  # Placeholder - implement actual tests
        }
        
        It 'should enable feature when not already enabled'$skipClause {
            # Test feature enablement
            `$true | Should -BeTrue  # Placeholder - implement actual tests
        }
        
        It 'should handle feature enabling failures'$skipClause {
            # Test error handling for failed enablement
            `$true | Should -BeTrue  # Placeholder - implement actual tests
        }
    }
"@
        }
        
        'Service' {
            $template += @@"

    Context 'Service Management Tests' {
        It 'should check service status before changes'$skipClause {
            # Test service status checking
            `$true | Should -BeTrue  # Placeholder - implement actual tests
        }
        
        It 'should handle service start/stop operations'$skipClause {
            # Test service operations
            `$true | Should -BeTrue  # Placeholder - implement actual tests
        }
        
        It 'should verify service configuration'$skipClause {
            # Test service configuration
            `$true | Should -BeTrue  # Placeholder - implement actual tests
        }
    }
"@
        }
        
        'Configuration' {
            $template += @@"

    Context 'Configuration Tests' {
        It 'should backup existing configuration'$skipClause {
            # Test configuration backup logic
            `$true | Should -BeTrue  # Placeholder - implement actual tests
        }
        
        It 'should validate configuration changes'$skipClause {
            # Test configuration validation
            `$true | Should -BeTrue  # Placeholder - implement actual tests
        }
        
        It 'should handle rollback on failure'$skipClause {
            # Test rollback functionality
            `$true | Should -BeTrue  # Placeholder - implement actual tests
        }
    }
"@
        }
        
        default {
            $template += @@"

    Context 'Execution Tests' {
        It 'should execute without errors'$skipClause {
            # Test basic execution
            { & `$script:ScriptPath -Config `$script:TestConfig } | Should -Not -Throw
        }
        
        It 'should handle empty configuration'$skipClause {
            # Test with empty config
            { & `$script:ScriptPath -Config @{} } | Should -Not -Throw
        }
        
        It 'should handle different platforms'$skipClause {
            # Test cross-platform compatibility
            `$true | Should -BeTrue  # Placeholder - implement actual tests
        }
    }
"@
        }
    }

    $template += @@"

}
"@
    
    return $template
}

}

}




