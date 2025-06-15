function Step-CleanupScatteredPatchFiles {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [switch]$AutoFix,
        
        [Parameter(Mandatory = $false)]
        [switch]$UpdateChangelog
    )
    
    Write-PatchLog "Starting cleanup of scattered patch files" "STEP"
    
    try {
        # Use the existing Invoke-PatchCleanup function
        $cleanupParams = @{
            Mode = "Full"
            AutoFix = $AutoFix
            UpdateChangelog = $UpdateChangelog
        }
        
        $result = Invoke-PatchCleanup @cleanupParams
        
        if ($result.Success) {
            Write-PatchLog "Successfully cleaned up scattered patch files" "SUCCESS"
            return @{
                Success = $true
                Message = "Cleanup completed successfully"
                FilesProcessed = $result.FilesProcessed
            }
        } else {
            Write-PatchLog "Cleanup completed with warnings: $($result.Message)" "WARNING"
            return @{
                Success = $false
                Message = $result.Message
            }
        }
    } catch {
        Write-PatchLog "Error during cleanup: $($_.Exception.Message)" "ERROR"
        return @{
            Success = $false
            Message = $_.Exception.Message
        }
    }
}
