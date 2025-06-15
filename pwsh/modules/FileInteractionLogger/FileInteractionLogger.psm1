# File Interaction Logger Module
# Tracks all file read/write operations across the project

$Script:LogFile = "$env:TEMP\opentofu-file-interactions.log"
$Script:LogEnabled = $true

function Start-FileInteractionLogging {
    [CmdletBinding()]
    param(
        [string]$LogPath = "$env:TEMP\opentofu-file-interactions-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
    )
    
    $Script:LogFile = $LogPath
    $Script:LogEnabled = $true
    
    # Initialize log file
    $header = @"
================================================================================
File Interaction Log Started: $(Get-Date)
Process: $($PID) - $($MyInvocation.ScriptName)
User: $env:USERNAME
Working Directory: $(Get-Location)
================================================================================

"@
    
    Add-Content -Path $Script:LogFile -Value $header -Force
    Write-Host "File interaction logging started: $Script:LogFile" -ForegroundColor Green
}

function Stop-FileInteractionLogging {
    $footer = @"

================================================================================
File Interaction Log Ended: $(Get-Date)
================================================================================
"@
    
    if ($Script:LogEnabled -and $Script:LogFile) {
        Add-Content -Path $Script:LogFile -Value $footer -Force
        Write-Host "File interaction logging stopped" -ForegroundColor Yellow
    }
    
    $Script:LogEnabled = $false
}

function Write-FileInteractionLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Operation,
        
        [Parameter(Mandatory)]
        [string]$FilePath,
        
        [string]$ScriptName = $MyInvocation.ScriptName,
        
        [string]$FunctionName = $MyInvocation.InvocationName,
        
        [string]$Details = "",
        
        [string]$Result = "SUCCESS"
    )
    
    if (-not $Script:LogEnabled) { return }
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    $caller = Get-PSCallStack | Select-Object -Skip 1 -First 1
    
    $logEntry = @"
[$timestamp] $Operation
  File: $FilePath
  Script: $($caller.ScriptName)
  Function: $($caller.FunctionName)
  Line: $($caller.ScriptLineNumber)
  Process: $PID
  Details: $Details
  Result: $Result
  Stack: $((Get-PSCallStack | Select-Object -Skip 1 | ForEach-Object { "$($_.ScriptName):$($_.FunctionName):$($_.ScriptLineNumber)" }) -join ' -> ')

"@
    
    try {
        Add-Content -Path $Script:LogFile -Value $logEntry -Force -ErrorAction SilentlyContinue
    } catch {
        # Fail silently to avoid breaking other operations
    }
}

# Override common file operations to add logging
function Set-Content {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Path,
        
        [Parameter(Mandatory, Position = 1, ValueFromPipeline)]
        $Value,
        
        [switch]$Force,
        
        [string]$Encoding
    )
    
    $resolvedPath = Resolve-Path $Path -ErrorAction SilentlyContinue
    if (-not $resolvedPath) { $resolvedPath = $Path }
    
    Write-FileInteractionLog -Operation "SET-CONTENT" -FilePath $resolvedPath -Details "Writing content (Force:$Force, Encoding:$Encoding)"
    
    try {
        if ($Encoding) {
            Microsoft.PowerShell.Management\Set-Content -Path $Path -Value $Value -Force:$Force -Encoding $Encoding
        } else {
            Microsoft.PowerShell.Management\Set-Content -Path $Path -Value $Value -Force:$Force
        }
        Write-FileInteractionLog -Operation "SET-CONTENT" -FilePath $resolvedPath -Details "Content written successfully" -Result "SUCCESS"
    } catch {
        Write-FileInteractionLog -Operation "SET-CONTENT" -FilePath $resolvedPath -Details "Error: $($_.Exception.Message)" -Result "ERROR"
        throw
    }
}

function Add-Content {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Path,
        
        [Parameter(Mandatory, Position = 1, ValueFromPipeline)]
        $Value,
        
        [switch]$Force,
        
        [string]$Encoding
    )
    
    $resolvedPath = Resolve-Path $Path -ErrorAction SilentlyContinue
    if (-not $resolvedPath) { $resolvedPath = $Path }
    
    Write-FileInteractionLog -Operation "ADD-CONTENT" -FilePath $resolvedPath -Details "Appending content (Force:$Force, Encoding:$Encoding)"
    
    try {
        if ($Encoding) {
            Microsoft.PowerShell.Management\Add-Content -Path $Path -Value $Value -Force:$Force -Encoding $Encoding
        } else {
            Microsoft.PowerShell.Management\Add-Content -Path $Path -Value $Value -Force:$Force
        }
        Write-FileInteractionLog -Operation "ADD-CONTENT" -FilePath $resolvedPath -Details "Content appended successfully" -Result "SUCCESS"
    } catch {
        Write-FileInteractionLog -Operation "ADD-CONTENT" -FilePath $resolvedPath -Details "Error: $($_.Exception.Message)" -Result "ERROR"
        throw
    }
}

function Get-Content {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Path,
        
        [switch]$Raw,
        
        [string]$Encoding,
        
        [int]$TotalCount,
        
        [int]$Head,
        
        [int]$Tail
    )
    
    $resolvedPath = Resolve-Path $Path -ErrorAction SilentlyContinue
    if (-not $resolvedPath) { $resolvedPath = $Path }
    
    Write-FileInteractionLog -Operation "GET-CONTENT" -FilePath $resolvedPath -Details "Reading content (Raw:$Raw, Encoding:$Encoding, TotalCount:$TotalCount)"
    
    try {
        $params = @{ Path = $Path }
        if ($Raw) { $params.Raw = $true }
        if ($Encoding) { $params.Encoding = $Encoding }
        if ($TotalCount) { $params.TotalCount = $TotalCount }
        if ($Head) { $params.Head = $Head }
        if ($Tail) { $params.Tail = $Tail }
        
        $result = Microsoft.PowerShell.Management\Get-Content @params
        Write-FileInteractionLog -Operation "GET-CONTENT" -FilePath $resolvedPath -Details "Content read successfully (Length: $($result.Length))" -Result "SUCCESS"
        return $result
    } catch {
        Write-FileInteractionLog -Operation "GET-CONTENT" -FilePath $resolvedPath -Details "Error: $($_.Exception.Message)" -Result "ERROR"
        throw
    }
}

function Remove-Item {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Path,
        
        [switch]$Force,
        
        [switch]$Recurse
    )
    
    $resolvedPath = Resolve-Path $Path -ErrorAction SilentlyContinue
    if (-not $resolvedPath) { $resolvedPath = $Path }
    
    Write-FileInteractionLog -Operation "REMOVE-ITEM" -FilePath $resolvedPath -Details "Removing item (Force:$Force, Recurse:$Recurse)"
    
    try {
        Microsoft.PowerShell.Management\Remove-Item -Path $Path -Force:$Force -Recurse:$Recurse
        Write-FileInteractionLog -Operation "REMOVE-ITEM" -FilePath $resolvedPath -Details "Item removed successfully" -Result "SUCCESS"
    } catch {
        Write-FileInteractionLog -Operation "REMOVE-ITEM" -FilePath $resolvedPath -Details "Error: $($_.Exception.Message)" -Result "ERROR"
        throw
    }
}

function Copy-Item {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Path,
        
        [Parameter(Mandatory, Position = 1)]
        [string]$Destination,
        
        [switch]$Force,
        
        [switch]$Recurse
    )
    
    $resolvedPath = Resolve-Path $Path -ErrorAction SilentlyContinue
    if (-not $resolvedPath) { $resolvedPath = $Path }
    
    Write-FileInteractionLog -Operation "COPY-ITEM" -FilePath $resolvedPath -Details "Copying to: $Destination (Force:$Force, Recurse:$Recurse)"
    
    try {
        Microsoft.PowerShell.Management\Copy-Item -Path $Path -Destination $Destination -Force:$Force -Recurse:$Recurse
        Write-FileInteractionLog -Operation "COPY-ITEM" -FilePath $resolvedPath -Details "Item copied successfully to: $Destination" -Result "SUCCESS"
    } catch {
        Write-FileInteractionLog -Operation "COPY-ITEM" -FilePath $resolvedPath -Details "Error: $($_.Exception.Message)" -Result "ERROR"
        throw
    }
}

function Move-Item {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Path,
        
        [Parameter(Mandatory, Position = 1)]
        [string]$Destination,
        
        [switch]$Force
    )
    
    $resolvedPath = Resolve-Path $Path -ErrorAction SilentlyContinue
    if (-not $resolvedPath) { $resolvedPath = $Path }
    
    Write-FileInteractionLog -Operation "MOVE-ITEM" -FilePath $resolvedPath -Details "Moving to: $Destination (Force:$Force)"
    
    try {
        Microsoft.PowerShell.Management\Move-Item -Path $Path -Destination $Destination -Force:$Force
        Write-FileInteractionLog -Operation "MOVE-ITEM" -FilePath $resolvedPath -Details "Item moved successfully to: $Destination" -Result "SUCCESS"
    } catch {
        Write-FileInteractionLog -Operation "MOVE-ITEM" -FilePath $resolvedPath -Details "Error: $($_.Exception.Message)" -Result "ERROR"
        throw
    }
}

function New-Item {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Path,
        
        [string]$ItemType = "File",
        
        [switch]$Force,
        
        $Value
    )
    
    Write-FileInteractionLog -Operation "NEW-ITEM" -FilePath $Path -Details "Creating new $ItemType (Force:$Force)"
    
    try {
        $params = @{ 
            Path = $Path
            ItemType = $ItemType
            Force = $Force
        }
        if ($Value) { $params.Value = $Value }
        
        $result = Microsoft.PowerShell.Management\New-Item @params
        Write-FileInteractionLog -Operation "NEW-ITEM" -FilePath $Path -Details "Item created successfully" -Result "SUCCESS"
        return $result
    } catch {
        Write-FileInteractionLog -Operation "NEW-ITEM" -FilePath $Path -Details "Error: $($_.Exception.Message)" -Result "ERROR"
        throw
    }
}

# Function to get recent file interactions
function Get-FileInteractionLog {
    [CmdletBinding()]
    param(
        [int]$Last = 50,
        [string]$FilePath,
        [string]$Operation
    )
    
    if (-not (Test-Path $Script:LogFile)) {
        Write-Warning "No file interaction log found at: $Script:LogFile"
        return
    }
    
    $content = Get-Content $Script:LogFile -Raw
    $entries = $content -split '(?=\[\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3}\])' | Where-Object { $_ -match '^\[' }
    
    if ($FilePath) {
        $entries = $entries | Where-Object { $_ -match [regex]::Escape($FilePath) }
    }
    
    if ($Operation) {
        $entries = $entries | Where-Object { $_ -match "^\[\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3}\] $Operation" }
    }
    
    $entries | Select-Object -Last $Last
}

# Auto-start logging when module is imported
Start-FileInteractionLogging

# Export functions
Export-ModuleMember -Function @(
    'Start-FileInteractionLogging',
    'Stop-FileInteractionLogging',
    'Write-FileInteractionLog',
    'Get-FileInteractionLog',
    'Set-Content',
    'Add-Content',
    'Get-Content',
    'Remove-Item',
    'Copy-Item',
    'Move-Item',
    'New-Item'
)
