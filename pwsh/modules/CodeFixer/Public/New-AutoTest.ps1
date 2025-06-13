<#
.SYNOPSIS
Automatically generates tests for PowerShell scripts

.DESCRIPTION
Creates comprehensive test files for PowerShell scripts using
intelligent analysis to determine the script's purpose, parameters,
and functions. Integrates with the existing test automation framework.

.PARAMETER ScriptPath
Path to a PowerShell script to generate tests for

.PARAMETER OutputDirectory
Directory where test files will be created (default: "tests")

.PARAMETER Force
Overwrite existing test files

.PARAMETER PassThru
Return the path to the generated test file

.EXAMPLE
New-AutoTest -ScriptPath "pwsh/runner_scripts/0201_Install-Docker.ps1"

.EXAMPLE
New-AutoTest -ScriptPath "pwsh/runner_scripts/0300_Enable-Service.ps1" -Force
#>
function New-AutoTest {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$true, Position=0)



]
        [string]$ScriptPath,
        
        [Parameter(Mandatory=$false)]
        [string]$OutputDirectory = "tests",
        
        [switch]$Force,
        
        [switch]$PassThru
    )
    
    $ErrorActionPreference = "Stop"
    
    Write-Verbose "Generating test for $ScriptPath"
    
    # Resolve paths
    $fullScriptPath = Resolve-Path $ScriptPath -ErrorAction Stop
    $fullOutputDir = Resolve-Path $OutputDirectory -ErrorAction SilentlyContinue
    
    if (-not $fullOutputDir) {
        if (-not (Test-Path $OutputDirectory)) {
            if ($PSCmdlet.ShouldProcess($OutputDirectory, "Create directory")) {
                New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
            }
        }
        $fullOutputDir = Resolve-Path $OutputDirectory
    }
    
    # Check if script exists
    if (-not (Test-Path $fullScriptPath)) {
        Write-Error "Script not found: $ScriptPath"
        return
    }
    
    # Load the auto test generator
    $autoTestGeneratorPath = Join-Path $PSScriptRoot ".." ".." ".." "tests" "helpers" "New-AutoTestGenerator.ps1"
    if (-not (Test-Path $autoTestGeneratorPath)) {
        Write-Error "Auto test generator not found: $autoTestGeneratorPath"
        return
    }
    
    # Use the existing auto test generator
    $scriptName = [System.IO.Path]::GetFileName($fullScriptPath)
    $scriptDir = [System.IO.Path]::GetDirectoryName($fullScriptPath)
    $testName = $scriptName -replace '\.ps1$', '.Tests.ps1'
    $testPath = Join-Path $fullOutputDir $testName
    
    # Check if test already exists
    if ((Test-Path $testPath) -and -not $Force) {
        Write-Warning "Test file already exists: $testPath. Use -Force to overwrite."
        if ($PassThru) {
            return $testPath
        }
        return
    }
    
    # Generate the test
    if ($PSCmdlet.ShouldProcess($testPath, "Generate test file")) {
        # Import helper function
        . $autoTestGeneratorPath
        
        # Invoke the generator directly
        New-TestForScript -ScriptPath $fullScriptPath -OutputPath $testPath
        
        Write-Verbose "✅ Generated test file: $testPath"
        
        if ($PassThru) {
            return $testPath
        }
    }
}


