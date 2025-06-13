# CrossPlatformExecutor.ps1
# Advanced base64 encoding system for cross-platform PowerShell script execution
# This solves shell escaping and encoding issues across Windows/Linux/macOS

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)






]
    [string]$Action,  # 'encode', 'execute', 'validate'
    
    [Parameter(Mandatory = $false)]
    [string]$ScriptPath,
    
    [Parameter(Mandatory = $false)]
    [string]$EncodedScript,
    
    [Parameter(Mandatory = $false)]
    [hashtable]$Parameters = @{},
    
    [Parameter(Mandatory = $false)]
    [switch]$CI
)

$ErrorActionPreference = "Stop"

function ConvertTo-Base64Script {
    param(
        [string]$ScriptPath,
        [hashtable]$Parameters = @{}
    )
    
    






if (-not (Test-Path $ScriptPath)) {
        throw "Script not found: $ScriptPath"
    }
    
    $scriptContent = Get-Content $ScriptPath -Raw
    
    # Inject parameters into script if provided
    if ($Parameters.Count -gt 0) {
        # For scripts with Param blocks, we need to override the parameters after the param block
        if ($scriptContent -match "Param\s*\(") {
            # Find the end of the param block and inject parameter overrides after it
            $lines = $scriptContent -split "`n"
            $paramBlockEnd = -1
            $braceCount = 0
            $inParamBlock = $false
            
            for ($i = 0; $i -lt $lines.Count; $i++) {
                if ($lines[$i] -match "Param\s*\(") {
                    $inParamBlock = $true
                    $braceCount = ($lines[$i] -split '\(' | Measure-Object).Count - 1
                    $braceCount -= ($lines[$i] -split '\)' | Measure-Object).Count - 1
                } elseif ($inParamBlock) {
                    $braceCount += ($lines[$i] -split '\(' | Measure-Object).Count - 1
                    $braceCount -= ($lines[$i] -split '\)' | Measure-Object).Count - 1
                    if ($braceCount -le 0) {
                        $paramBlockEnd = $i
                        break
                    }
                }
            }
            
            if ($paramBlockEnd -gt -1) {
                $paramOverrides = ($Parameters.GetEnumerator() | ForEach-Object {
                    "`$$($_.Key) = '$($_.Value)'"
                }) -join "`n"
                
                $beforeParam = $lines[0..$paramBlockEnd] -join "`n"
                $afterParam = if ($paramBlockEnd + 1 -lt $lines.Count) { $lines[($paramBlockEnd + 1)..($lines.Count - 1)] -join "`n"    } else { ""    }
                
                $scriptContent = @"
$beforeParam

# Auto-injected parameter overrides
$paramOverrides

$afterParam
"@
            }
        } else {
            # For scripts without Param blocks, inject at the beginning
            $paramString = ($Parameters.GetEnumerator() | ForEach-Object {
                "`$$($_.Key) = '$($_.Value)'"
            }) -join "`n"
            
            $scriptContent = @"
# Auto-injected parameters
$paramString

# Original script content
$scriptContent
"@
        }
    }
    
    # Convert to UTF8 bytes then base64
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($scriptContent)
    $base64 = [System.Convert]::ToBase64String($bytes)
    
    return @{
        OriginalPath = $ScriptPath
        EncodedScript = $base64
        Parameters = $Parameters
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss UTC"
    }
}

function ConvertFrom-Base64Script {
    param(
        [string]$EncodedScript
    )
    
    






try {
        $bytes = [System.Convert]::FromBase64String($EncodedScript)
        $scriptContent = [System.Text.Encoding]::UTF8.GetString($bytes)
        return $scriptContent
    } catch {
        throw "Failed to decode base64 script: $($_.Exception.Message)"
    }
}

function Invoke-EncodedScript {
    param(
        [string]$EncodedScript,
        [switch]$WhatIf
    )
    
    






$decodedScript = ConvertFrom-Base64Script -EncodedScript $EncodedScript
    
    if ($WhatIf) {
        Write-Host "Would execute the following script:" -ForegroundColor Cyan
        Write-Host $decodedScript -ForegroundColor Gray
        return @{ ExitCode = 0; WhatIf = $true }
    }
    
    # Execute using a temporary file to avoid command line length limits
    $tempFile = New-TemporaryFile
    try {
        $tempFile = $tempFile.FullName + ".ps1"
        Set-Content -Path $tempFile -Value $decodedScript -Encoding UTF8
        
        # Execute in a new PowerShell process for isolation
        if ($IsWindows -or $env:OS -eq "Windows_NT") {
            $result = Start-Process -FilePath "powershell.exe" -ArgumentList @("-ExecutionPolicy", "Bypass", "-File", $tempFile) -Wait -PassThru -NoNewWindow
        } else {
            $result = Start-Process -FilePath "pwsh" -ArgumentList @("-File", $tempFile) -Wait -PassThru -NoNewWindow
        }
        
        return @{
            ExitCode = $result.ExitCode
            ProcessId = $result.Id
            StartTime = $result.StartTime
            ExitTime = $result.ExitTime
        }
        
    } finally {
        if (Test-Path $tempFile) {
            Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
        }
    }
}

function Test-EncodedScript {
    param(
        [string]$EncodedScript
    )
    
    






try {
        $decodedScript = ConvertFrom-Base64Script -EncodedScript $EncodedScript
        
        # Validate PowerShell syntax
        $null = [System.Management.Automation.PSParser]::Tokenize($decodedScript, [ref]$null)
        
        return @{
            Valid = $true
            DecodedLength = $decodedScript.Length
            ContainsParam = $decodedScript -match "Param\s*\("
            ContainsFunction = $decodedScript -match "function\s+"
        }
    } catch {
        return @{
            Valid = $false
            Error = $_.Exception.Message
        }
    }
}

# Main execution logic
switch ($Action.ToLower()) {
    "encode" {
        if (-not $ScriptPath) {
            throw "ScriptPath parameter required for encode action"
        }
        
        $result = ConvertTo-Base64Script -ScriptPath $ScriptPath -Parameters $Parameters
        
        if ($CI) {
            # Output JSON for CI consumption
            $result | ConvertTo-Json -Depth 3
        } else {
            Write-Host "Script encoded successfully:" -ForegroundColor Green
            Write-Host "  Original: $($result.OriginalPath)" -ForegroundColor Gray
            Write-Host "  Encoded length: $($result.EncodedScript.Length) characters" -ForegroundColor Gray
            Write-Host "  Parameters: $($result.Parameters.Count)" -ForegroundColor Gray
            Write-Host "`nEncoded script:" -ForegroundColor Cyan
            Write-Host $result.EncodedScript
        }
    }
    
    "execute" {
        if (-not $EncodedScript) {
            throw "EncodedScript parameter required for execute action"
        }
        
        $result = Invoke-EncodedScript -EncodedScript $EncodedScript
        
        if ($CI) {
            $result | ConvertTo-Json -Depth 3
        } else {
            Write-Host "Script execution completed:" -ForegroundColor Green
            Write-Host "  Exit Code: $($result.ExitCode)" -ForegroundColor Gray
            if ($result.WhatIf) {
                Write-Host "  Mode: WhatIf (no actual execution)" -ForegroundColor Yellow
            }
        }
        
        exit $result.ExitCode
    }
    
    "validate" {
        if (-not $EncodedScript) {
            throw "EncodedScript parameter required for validate action"
        }
        
        $result = Test-EncodedScript -EncodedScript $EncodedScript
        
        if ($CI) {
            $result | ConvertTo-Json -Depth 3
        } else {
            Write-Host "Script validation result:" -ForegroundColor Cyan
            Write-Host "  Valid: $($result.Valid)" -ForegroundColor $$(if (result.Valid) { "Green" } else { "Red" })
            if ($result.Valid) {
                Write-Host "  Decoded length: $($result.DecodedLength) characters" -ForegroundColor Gray
                Write-Host "  Contains Param block: $($result.ContainsParam)" -ForegroundColor Gray
                Write-Host "  Contains functions: $($result.ContainsFunction)" -ForegroundColor Gray
            } else {
                Write-Host "  Error: $($result.Error)" -ForegroundColor Red
            }
        }
        
        if (-not $result.Valid) {
            exit 1
        }
    }
    
    default {
        throw "Invalid action: $Action. Valid actions are: encode, execute, validate"
    }
}

# Usage examples:
<#
# Encode a script with parameters
.\CrossPlatformExecutor.ps1 -Action encode -ScriptPath "path/to/script.ps1" -Parameters @{ConfigPath="config.json"; Environment="prod"}

# Execute an encoded script
.\CrossPlatformExecutor.ps1 -Action execute -EncodedScript "base64encodedstring..."

# Validate an encoded script
.\CrossPlatformExecutor.ps1 -Action validate -EncodedScript "base64encodedstring..."

# CI usage (JSON output)
.\CrossPlatformExecutor.ps1 -Action encode -ScriptPath "script.ps1" -CI
#>



