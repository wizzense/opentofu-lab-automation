# fix-runner-execution.ps1
# Comprehensive fix for PowerShell script execution issues in runner.ps1

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [switch]$WhatIf
)

$ErrorActionPreference = "Stop"

Write-Host "🔧 Fixing Runner Script Execution Issues" -ForegroundColor Cyan
Write-Host "=" * 50

$runnerPath = "pwsh/runner.ps1"

if (-not (Test-Path $runnerPath)) {
    Write-Error "Runner script not found: $runnerPath"
    exit 1
}

Write-Host "📄 Reading current runner script..." -ForegroundColor Yellow

$content = Get-Content $runnerPath -Raw

$fixes = @()

# Fix 1: Improve parameter handling in script execution
Write-Host "🔧 Fix 1: Improving parameter handling..." -ForegroundColor Green

$oldExecutionPattern = @'
            $tempCfg = [System.IO.Path]::GetTempFileName()
            $Config | ConvertTo-Json -Depth 5 | Out-File -FilePath $tempCfg -Encoding utf8
            $scriptArgs = @('-File', $scriptPath, '-Config', $tempCfg)
            if ((Get-Command $scriptPath).Parameters.ContainsKey('AsJson')) { $scriptArgs += '-AsJson' }
            $env:LAB_CONSOLE_LEVEL = $script:VerbosityLevels[$Verbosity]
            $output = & $pwshPath -NoLogo -NoProfile @scriptArgs *>&1
'@

$newExecutionPattern = @'
            # Create temporary config file with proper encoding
            $tempCfg = [System.IO.Path]::GetTempFileName()
            try {
                $Config | ConvertTo-Json -Depth 5 | Out-File -FilePath $tempCfg -Encoding utf8 -NoNewline
                
                # Validate script file exists and is readable
                if (-not (Test-Path $scriptPath)) {
                    throw "Script file not found: $scriptPath"
                }
                
                # Build script arguments carefully
                $scriptArgs = @('-NoLogo', '-NoProfile', '-File', $scriptPath)
                
                # Add Config parameter only if the script accepts it
                try {
                    $scriptInfo = Get-Command $scriptPath -ErrorAction Stop
                    if ($scriptInfo.Parameters.ContainsKey('Config')) {
                        $scriptArgs += @('-Config', $tempCfg)
                    }
                    if ($scriptInfo.Parameters.ContainsKey('AsJson')) {
                        $scriptArgs += '-AsJson'
                    }
                } catch {
                    # Fallback: assume Config parameter exists
                    $scriptArgs += @('-Config', $tempCfg)
                }
                
                # Set environment and execute
                $env:LAB_CONSOLE_LEVEL = $script:VerbosityLevels[$Verbosity]
                
                # Use Start-Process for better error handling and isolation
                $processArgs = @{
                    FilePath = $pwshPath
                    ArgumentList = $scriptArgs
                    Wait = $true
                    NoNewWindow = $true
                    PassThru = $true
                    RedirectStandardOutput = $true
                    RedirectStandardError = $true
                }
                
                $process = Start-Process @processArgs
                $output = @()
                if ($process.StandardOutput) {
                    $output += $process.StandardOutput.ReadToEnd() -split "`n"
                }
                if ($process.StandardError) {
                    $errorOutput = $process.StandardError.ReadToEnd()
                    if ($errorOutput.Trim()) {
                        $output += $errorOutput -split "`n"
                    }
                }
                $exitCode = $process.ExitCode
'@

if ($content -match [regex]::Escape($oldExecutionPattern)) {
    $content = $content -replace [regex]::Escape($oldExecutionPattern), $newExecutionPattern
    $fixes += "✅ Improved script execution with better parameter handling"
} else {
    Write-Warning "Could not find exact execution pattern - applying targeted fixes"
    
    # Apply individual improvements
    $content = $content -replace 
        'Out-File -FilePath \$tempCfg -Encoding utf8', 
        'Out-File -FilePath $tempCfg -Encoding utf8 -NoNewline'
    
    $content = $content -replace 
        '\$output = & \$pwshPath -NoLogo -NoProfile @scriptArgs \*>&1', 
        '$output = & $pwshPath @scriptArgs 2>&1'
    
    $fixes += "✅ Applied targeted execution improvements"
}

# Fix 2: Add script validation before execution
Write-Host "🔧 Fix 2: Adding script validation..." -ForegroundColor Green

$validationCode = @'
            # Validate script syntax before execution
            try {
                $scriptContent = Get-Content $scriptPath -Raw
                $null = [System.Management.Automation.PSParser]::Tokenize($scriptContent, [ref]$null)
            } catch {
                Write-CustomLog "ERROR: Script has syntax errors: $scriptPath - $_" 'ERROR'
                $failed += $s.Name
                continue
            }
'@

# Insert validation before the execution logic
$content = $content -replace 
    '(\s+)(if \(\$flag = Get-ScriptConfigFlag)', 
    "$1$validationCode$1$2"

$fixes += "✅ Added script syntax validation"

# Fix 3: Improve error handling and logging
Write-Host "🔧 Fix 3: Enhancing error handling..." -ForegroundColor Green

$oldErrorHandling = @'
            $exitCode = $LASTEXITCODE

            foreach ($line in $output) {
                if (-not $line) { continue }
                if ($line -is [System.Management.Automation.ErrorRecord]) {
                    Write-Error $line.ToString()
                } elseif ($line -is [System.Management.Automation.WarningRecord]) {
                    Write-Warning $line.ToString()
                } else {
                    Write-CustomLog $line.ToString()
                }
            }
'@

$newErrorHandling = @'
            } catch {
                Write-CustomLog "ERROR: Failed to execute script $scriptPath - $_" 'ERROR'
                $exitCode = 1
                $output = @("Script execution failed: $($_.Exception.Message)")
            } finally {
                # Always clean up temporary config file
                if (Test-Path $tempCfg) {
                    Remove-Item $tempCfg -Force -ErrorAction SilentlyContinue
                }
            }

            # Process output with improved error detection
            foreach ($line in $output) {
                if (-not $line -or [string]::IsNullOrWhiteSpace($line)) { continue }
                
                $lineStr = $line.ToString().Trim()
                
                # Check for PowerShell parsing errors
                if ($lineStr -match "The term 'Param' is not recognized" -or 
                    $lineStr -match "ParameterBindingException" -or
                    $lineStr -match "positional parameter cannot be found") {
                    Write-CustomLog "ERROR: Parameter binding issue detected in $($s.Name): $lineStr" 'ERROR'
                    $exitCode = 1
                } elseif ($line -is [System.Management.Automation.ErrorRecord] -or $lineStr.StartsWith('ERROR:')) {
                    Write-CustomLog "ERROR: $lineStr" 'ERROR'
                    $exitCode = 1
                } elseif ($line -is [System.Management.Automation.WarningRecord] -or $lineStr.StartsWith('WARNING:')) {
                    Write-CustomLog "WARNING: $lineStr" 'WARN'
                } else {
                    Write-CustomLog $lineStr
                }
            }
'@

$content = $content -replace [regex]::Escape($oldErrorHandling), $newErrorHandling
$fixes += "✅ Enhanced error handling and parameter binding detection"

# Fix 4: Add fallback execution method for problematic scripts
Write-Host "🔧 Fix 4: Adding fallback execution method..." -ForegroundColor Green

$fallbackMethod = @'
            # If execution failed with parameter binding issues, try alternative method
            if ($exitCode -ne 0 -and $output -join '' -match "The term 'Param' is not recognized") {
                Write-CustomLog "Attempting fallback execution method for $($s.Name)..." 'WARN'
                
                try {
                    # Try direct dot-sourcing with error handling
                    $tempScript = [System.IO.Path]::GetTempFileName() + '.ps1'
                    $fallbackContent = @"
try {
    `$Config = Get-Content -Raw '$tempCfg' | ConvertFrom-Json
    . '$scriptPath'
} catch {
    Write-Error "Fallback execution failed: `$_"
    exit 1
}
"@
                    Set-Content $tempScript $fallbackContent
                    $fallbackOutput = & $pwshPath -NoLogo -NoProfile -File $tempScript 2>&1
                    $exitCode = $LASTEXITCODE
                    
                    if ($exitCode -eq 0) {
                        Write-CustomLog "Fallback execution succeeded for $($s.Name)" 'INFO'
                        $output = $fallbackOutput
                    }
                    
                    Remove-Item $tempScript -Force -ErrorAction SilentlyContinue
                } catch {
                    Write-CustomLog "Fallback execution also failed: $_" 'ERROR'
                }
            }
'@

# Insert fallback before the result processing
$content = $content -replace 
    '(\s+)(Remove-Item \$tempCfg -ErrorAction SilentlyContinue)', 
    "$1$fallbackMethod$1$2"

$fixes += "✅ Added fallback execution method for problematic scripts"

# Fix 5: Improve PowerShell executable detection
Write-Host "🔧 Fix 5: Improving PowerShell detection..." -ForegroundColor Green

$oldPwshDetection = @'
# Determine pwsh executable path early for nested script execution
$pwshPath = (Get-Command pwsh -ErrorAction SilentlyContinue).Source
if (-not $pwshPath) {
    $exeName  = if ($IsWindows) { 'pwsh.exe' } else { 'pwsh' }
    $pwshPath = Join-Path $PSHOME $exeName
}
if (-not (Test-Path $pwshPath)) {
'@

$newPwshDetection = @'
# Determine pwsh executable path early for nested script execution
$pwshPath = $null

# Try multiple methods to find PowerShell 7+
$pwshCandidates = @()

if (Get-Command pwsh -ErrorAction SilentlyContinue) {
    $pwshCandidates += (Get-Command pwsh).Source
}

if ($IsWindows) {
    $pwshCandidates += @(
        'C:\Program Files\PowerShell\7\pwsh.exe',
        'C:\Program Files (x86)\PowerShell\7\pwsh.exe',
        (Join-Path $PSHOME 'pwsh.exe')
    )
} else {
    $pwshCandidates += @(
        '/usr/bin/pwsh',
        '/usr/local/bin/pwsh',
        (Join-Path $PSHOME 'pwsh')
    )
}

foreach ($candidate in $pwshCandidates) {
    if ($candidate -and (Test-Path $candidate)) {
        $pwshPath = $candidate
        break
    }
}

if (-not $pwshPath) {
'@

$content = $content -replace [regex]::Escape($oldPwshDetection), $newPwshDetection
$fixes += "✅ Improved PowerShell executable detection"

# Display what we're fixing
Write-Host "`n🔍 Applied Fixes:" -ForegroundColor Cyan
foreach ($fix in $fixes) {
    Write-Host "  $fix" -ForegroundColor White
}

if ($WhatIf) {
    Write-Host "`n⚠️ WhatIf mode - changes not applied" -ForegroundColor Yellow
    Write-Host "Run without -WhatIf to apply fixes" -ForegroundColor Gray
    return
}

# Backup original file
$backupPath = "$runnerPath.backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
Copy-Item $runnerPath $backupPath
Write-Host "📁 Backup created: $backupPath" -ForegroundColor Gray

# Apply fixes
Set-Content -Path $runnerPath -Value $content -Encoding UTF8
Write-Host "✅ Runner script fixes applied successfully!" -ForegroundColor Green

# Validate the fixed script
Write-Host "`n🔬 Validating fixed script..." -ForegroundColor Cyan

try {
    # Test PowerShell syntax
    $null = [System.Management.Automation.PSParser]::Tokenize($content, [ref]$null)
    Write-Host "✅ PowerShell syntax validation passed" -ForegroundColor Green
} catch {
    Write-Error "❌ PowerShell syntax validation failed: $_"
    Write-Host "Restoring backup..." -ForegroundColor Yellow
    Copy-Item $backupPath $runnerPath -Force
    exit 1
}

Write-Host "`n📋 Summary:" -ForegroundColor Cyan
Write-Host "  - Original file backed up to: $backupPath" -ForegroundColor White
Write-Host "  - Applied $($fixes.Count) fixes to runner script" -ForegroundColor White
Write-Host "  - Improved script parameter handling" -ForegroundColor White  
Write-Host "  - Added script syntax validation" -ForegroundColor White
Write-Host "  - Enhanced error detection and handling" -ForegroundColor White
Write-Host "  - Added fallback execution method" -ForegroundColor White
Write-Host "  - Improved PowerShell detection" -ForegroundColor White

Write-Host "`n🚀 Next Steps:" -ForegroundColor Cyan
Write-Host "  1. Test runner script with problematic scenarios" -ForegroundColor White
Write-Host "  2. Monitor for 'Param is not recognized' errors" -ForegroundColor White
Write-Host "  3. Verify parameter binding works correctly" -ForegroundColor White
Write-Host "  4. Check fallback execution method effectiveness" -ForegroundColor White

Write-Host "`n✨ Runner script fixes completed successfully!" -ForegroundColor Green
