# CrossPlatformExecutor.ps1
# Enhanced cross-platform PowerShell script executor with proper working directory support
# Compatible with Python integration for OpenTofu Lab Automation

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$Action = "execute",  # 'encode', 'execute', 'validate'
    
    [Parameter(Mandatory = $false)]
    [string]$ScriptPath,
    
    [Parameter(Mandatory = $false)]
    [string]$EncodedScript,
    
    [Parameter(Mandatory = $false)]
    [string]$WorkingDirectory,
    
    [Parameter(Mandatory = $false)]
    [hashtable]$Parameters = @{},
    
    [Parameter(Mandatory = $false)]
    [switch]$CI,
    
    [Parameter(Mandatory = $false)]
    [switch]$NonInteractive
)

$ErrorActionPreference = "Stop"

function Write-LogMessage {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "HH:mm:ss"
    Write-Host "[$timestamp] $Level`: $Message"
}

function Set-WorkingDirectoryIfProvided {
    param([string]$Directory)
    
    if ($Directory -and (Test-Path $Directory)) {
        try {
            Set-Location $Directory
            Write-LogMessage "Changed to working directory: $Directory"
            return $true
        } catch {
            Write-LogMessage "Failed to change to working directory: $Directory. Error: $_" -Level "WARNING"
            return $false
        }
    }
    return $true
}

function ConvertTo-Base64Script {
    param(
        [string]$ScriptPath,
        [hashtable]$Parameters = @{}
    )
    
    if (-not (Test-Path $ScriptPath)) {
        throw "Script not found: $ScriptPath"
    }
    
    $scriptContent = Get-Content $ScriptPath -Raw -Encoding UTF8
    
    # Inject parameters into script if provided
    if ($Parameters.Count -gt 0) {
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
    
    # Convert to base64
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($scriptContent)
    $encoded = [System.Convert]::ToBase64String($bytes)
    
    return @{
        EncodedScript = $encoded
        OriginalSize = $scriptContent.Length
        EncodedSize = $encoded.Length
    }
}

function ConvertFrom-Base64Script {
    param([string]$EncodedScript)
    
    if (-not $EncodedScript) {
        throw "No encoded script provided"
    }
    
    try {
        $bytes = [System.Convert]::FromBase64String($EncodedScript)
        $decoded = [System.Text.Encoding]::UTF8.GetString($bytes)
        return $decoded
    } catch {
        throw "Failed to decode script: $_"
    }
}

function Invoke-EncodedScript {
    param(
        [string]$EncodedScript,
        [hashtable]$Parameters = @{}
    )
    
    $decodedScript = ConvertFrom-Base64Script -EncodedScript $EncodedScript
    
    Write-LogMessage "Executing decoded PowerShell script (length: $($decodedScript.Length) characters)"
    
    try {
        # Create a script block and execute it
        $scriptBlock = [ScriptBlock]::Create($decodedScript)
        
        if ($Parameters.Count -gt 0) {
            Write-LogMessage "Executing with parameters: $($Parameters.Keys -join ', ')"
            & $scriptBlock @Parameters
        } else {
            & $scriptBlock
        }
        
        Write-LogMessage "Script execution completed successfully"
        return $LASTEXITCODE
    } catch {
        Write-LogMessage "Script execution failed: $_" -Level "ERROR"
        throw
    }
}

function Test-ScriptExecution {
    Write-LogMessage "Testing PowerShell execution capabilities..."
    
    $testScript = @"
Write-Host "PowerShell execution test successful"
Write-Host "Working Directory: `$(Get-Location)"
Write-Host "PowerShell Version: `$(`$PSVersionTable.PSVersion)"
if (`$PSVersionTable.Platform) {
    Write-Host "Platform: `$(`$PSVersionTable.Platform)"
} else {
    Write-Host "Platform: Windows (Legacy PowerShell)"
}
Write-Host "Execution Policy: `$(Get-ExecutionPolicy)"
"@
    
    try {
        $encoded = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($testScript))
        Invoke-EncodedScript -EncodedScript $encoded
        Write-LogMessage "✓ PowerShell execution test passed"
        return $true
    } catch {
        Write-LogMessage "✗ PowerShell execution test failed: $_" -Level "ERROR"
        return $false
    }
}

# Main execution logic
try {
    Write-LogMessage "CrossPlatformExecutor.ps1 starting..."
    Write-LogMessage "Action: $Action"
    Write-LogMessage "PowerShell Version: $($PSVersionTable.PSVersion)"
    Write-LogMessage "Current Location: $(Get-Location)"
    
    # Set working directory if provided
    if ($WorkingDirectory) {
        if (-not (Set-WorkingDirectoryIfProvided -Directory $WorkingDirectory)) {
            Write-LogMessage "Warning: Could not set working directory, continuing with current directory" -Level "WARNING"
        }
    }
    
    switch ($Action.ToLower()) {
        "encode" {
            if (-not $ScriptPath) {
                throw "ScriptPath is required for encode action"
            }
            
            Write-LogMessage "Encoding script: $ScriptPath"
            $result = ConvertTo-Base64Script -ScriptPath $ScriptPath -Parameters $Parameters
            
            Write-Host "=== ENCODED SCRIPT ==="
            Write-Host $result.EncodedScript
            Write-Host "=== END ENCODED SCRIPT ==="
            Write-LogMessage "Encoding completed. Original: $($result.OriginalSize) bytes, Encoded: $($result.EncodedSize) bytes"
        }
        
        "execute" {
            if ($EncodedScript) {
                Write-LogMessage "Executing encoded script"
                $exitCode = Invoke-EncodedScript -EncodedScript $EncodedScript -Parameters $Parameters
                exit $exitCode
            } elseif ($ScriptPath) {
                Write-LogMessage "Encoding and executing script: $ScriptPath"
                $result = ConvertTo-Base64Script -ScriptPath $ScriptPath -Parameters $Parameters
                $exitCode = Invoke-EncodedScript -EncodedScript $result.EncodedScript -Parameters $Parameters
                exit $exitCode
            } else {
                throw "Either EncodedScript or ScriptPath is required for execute action"
            }
        }
        
        "validate" {
            Write-LogMessage "Running validation tests..."
            $testPassed = Test-ScriptExecution
            
            if ($testPassed) {
                Write-LogMessage "✓ Validation completed successfully"
                exit 0
            } else {
                Write-LogMessage "✗ Validation failed" -Level "ERROR"
                exit 1
            }
        }
        
        default {
            throw "Unknown action: $Action. Valid actions are: encode, execute, validate"
        }
    }
    
} catch {
    Write-LogMessage "Fatal error: $_" -Level "ERROR"
    Write-LogMessage "Stack trace: $($_.ScriptStackTrace)" -Level "ERROR"
    exit 1
}
