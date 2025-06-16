#Requires -Version 7.0
<#
.SYNOPSIS
    Backup statistics and analysis for PatchManager
    
.DESCRIPTION
    Migrated from BackupManager to provide comprehensive backup statistics
    with Git integration and historical analysis.
    
.PARAMETER AnalysisType
    Type of analysis: 'Summary', 'Detailed', 'Historical', 'SizeAnalysis'
    
.PARAMETER BackupPaths
    Specific backup paths to analyze (optional)
    
.PARAMETER OutputFormat
    Output format: 'Object', 'JSON', 'Report'
    
.EXAMPLE
    Get-BackupStatistics -AnalysisType 'Summary'
    
.EXAMPLE
    Get-BackupStatistics -AnalysisType 'Detailed' -OutputFormat 'Report'
    
.NOTES
    Part of PatchManager's comprehensive backup analysis system.
#>

function Get-BackupStatistics {
    CmdletBinding()
    param(
        Parameter(Mandatory = $false)
        ValidateSet('Summary', 'Detailed', 'Historical', 'SizeAnalysis')
        string$AnalysisType = 'Summary',
        
        Parameter(Mandatory = $false)
        string$BackupPaths = @(),
        
        Parameter(Mandatory = $false)
        ValidateSet('Object', 'JSON', 'Report')
        string$OutputFormat = 'Object'
    )
    
    begin {
        $ErrorActionPreference = "Stop"
        
        # Initialize statistics tracking
        $script:Stats = @{
            AnalysisTime = Get-Date
            AnalysisType = $AnalysisType
            GitCommit = (git rev-parse HEAD 2>$null)
            BackupLocations = @()
            Summary = @{}
            Details = @{}
        }
        
        # Logging function
        if (-not (Get-Command "Write-CustomLog" -ErrorAction SilentlyContinue)) {
            function Write-CustomLog {
                param(string$Message, string$Level = "INFO")
                $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                $color = switch ($Level) {
                    "ERROR" { "Red" }
                    "WARN" { "Yellow" }
                    "INFO" { "Green" }
                    "DEBUG" { "Cyan" }
                    default { "White" }
                }
                Write-Host "$timestamp PatchManager $Level $Message" -ForegroundColor $color
            }
        }
        
        # Default backup locations
        $DefaultBackupPaths = @(
            "backups",
            "archive", 
            "*.bak",
            "*backup*",
            "*.old",
            "*.orig"
        )
    }
    
    process {
        try {
            Write-CustomLog "Starting PatchManager backup statistics analysis" "INFO"
            Write-CustomLog "Analysis type: $AnalysisType" "INFO"
            
            # Determine backup paths to analyze
            if ($BackupPaths.Count -eq 0) {
                $BackupPaths = $DefaultBackupPaths
            }
            
            $allBackupFiles = @()
            $allBackupDirs = @()
            
            # Collect backup files and directories
            foreach ($path in $BackupPaths) {
                Write-CustomLog "Analyzing backup path: $path" "DEBUG"
                
                try {
                    if ($path.Contains("*")) {
                        # Wildcard pattern - find files
                        $files = Get-ChildItem -Path "." -Recurse -File -Filter $path -ErrorAction SilentlyContinue
                        $allBackupFiles += $files
                        Write-CustomLog "Found $($files.Count) files matching pattern '$path'" "DEBUG"
                    } else {
                        # Directory path
                        if (Test-Path $path -PathType Container) {
                            $dirs = Get-ChildItem -Path $path -Recurse -Directory -ErrorAction SilentlyContinue
                            $files = Get-ChildItem -Path $path -Recurse -File -ErrorAction SilentlyContinue
                            $allBackupDirs += @($path) + $dirs
                            $allBackupFiles += $files
                            Write-CustomLog "Found $($dirs.Count) directories and $($files.Count) files in '$path'" "DEBUG"
                        }
                    }
                } catch {
                    Write-CustomLog "Error analyzing path '$path': $($_.Exception.Message)" "WARN"
                }
            }
            
            # Calculate summary statistics
            $totalFiles = $allBackupFiles.Count
            $totalSize = ($allBackupFiles  Measure-Object Length -Sum).Sum ?? 0
            $totalDirs = $allBackupDirs.Count
            $avgFileSize = if ($totalFiles -gt 0) { $totalSize / $totalFiles } else { 0 }
            
            $script:Stats.Summary = @{
                TotalFiles = $totalFiles
                TotalDirectories = $totalDirs
                TotalSizeBytes = $totalSize
                TotalSizeMB = math::Round($totalSize / 1MB, 2)
                TotalSizeGB = math::Round($totalSize / 1GB, 3)
                AverageFileSizeBytes = math::Round($avgFileSize, 0)
                AverageFileSizeMB = math::Round($avgFileSize / 1MB, 3)
            }
            
            # Perform detailed analysis based on type
            switch ($AnalysisType) {
                'Summary' {
                    # Already calculated above
                }
                'Detailed' {
                    $script:Stats.Details = Get-DetailedBackupAnalysis -Files $allBackupFiles -Directories $allBackupDirs
                }
                'Historical' {
                    $script:Stats.Details = Get-HistoricalBackupAnalysis -Files $allBackupFiles
                }
                'SizeAnalysis' {
                    $script:Stats.Details = Get-SizeAnalysis -Files $allBackupFiles
                }
            }
            
            # Format output based on requested format
            switch ($OutputFormat) {
                'Object' {
                    return $script:Stats
                }
                'JSON' {
                    return ($script:Stats  ConvertTo-Json -Depth 4)
                }
                'Report' {
                    return Format-BackupReport -Stats $script:Stats
                }
            }
            
        } catch {
            Write-CustomLog "Fatal error during backup statistics analysis: $($_.Exception.Message)" "ERROR"
            throw
        }
    }
}

# Helper function for detailed backup analysis
function Get-DetailedBackupAnalysis {
    param($Files, $Directories)
    
    $filesByExtension = $Files  Group-Object Extension  ForEach-Object {
        @{
            Extension = $_.Name
            Count = $_.Count
            TotalSize = ($_.Group  Measure-Object Length -Sum).Sum
        }
    }  Sort-Object TotalSize -Descending
    
    $filesByAge = @{
        Last24Hours = ($Files  Where-Object { $_.LastWriteTime -gt (Get-Date).AddDays(-1) }).Count
        LastWeek = ($Files  Where-Object { $_.LastWriteTime -gt (Get-Date).AddDays(-7) }).Count
        LastMonth = ($Files  Where-Object { $_.LastWriteTime -gt (Get-Date).AddDays(-30) }).Count
        LastYear = ($Files  Where-Object { $_.LastWriteTime -gt (Get-Date).AddDays(-365) }).Count
        OlderThanYear = ($Files  Where-Object { $_.LastWriteTime -le (Get-Date).AddDays(-365) }).Count
    }
    
    $largestFiles = $Files  Sort-Object Length -Descending  Select-Object -First 10  ForEach-Object {
        @{
            Name = $_.Name
            Path = $_.FullName
            SizeBytes = $_.Length
            SizeMB = math::Round($_.Length / 1MB, 2)
            LastModified = $_.LastWriteTime
        }
    }
    
    return @{
        FilesByExtension = $filesByExtension
        FilesByAge = $filesByAge
        LargestFiles = $largestFiles
        DirectoryStructure = $Directories  ForEach-Object { $_.FullName }
    }
}

# Helper function for historical backup analysis
function Get-HistoricalBackupAnalysis {
    param($Files)
    
    $monthlyStats = $Files  Group-Object { $_.LastWriteTime.ToString("yyyy-MM") }  ForEach-Object {
        @{
            Month = $_.Name
            Count = $_.Count
            TotalSize = ($_.Group  Measure-Object Length -Sum).Sum
        }
    }  Sort-Object Month -Descending
    
    $dailyStats = $Files  Where-Object { $_.LastWriteTime -gt (Get-Date).AddDays(-30) }  
        Group-Object { $_.LastWriteTime.ToString("yyyy-MM-dd") }  ForEach-Object {
        @{
            Date = $_.Name
            Count = $_.Count
            TotalSize = ($_.Group  Measure-Object Length -Sum).Sum
        }
    }  Sort-Object Date -Descending
    
    return @{
        MonthlyStatistics = $monthlyStats
        DailyStatistics = $dailyStats
        GrowthTrend = if ($monthlyStats.Count -gt 1) { 
            $latest = $monthlyStats0.TotalSize
            $previous = $monthlyStats1.TotalSize
            math::Round((($latest - $previous) / $previous) * 100, 2)
        } else { 0 }
    }
}

# Helper function for size analysis
function Get-SizeAnalysis {
    param($Files)
    
    $sizeRanges = @{
        'Tiny (<1KB)' = ($Files  Where-Object { $_.Length -lt 1KB }).Count
        'Small (1KB-1MB)' = ($Files  Where-Object { $_.Length -ge 1KB -and $_.Length -lt 1MB }).Count
        'Medium (1MB-10MB)' = ($Files  Where-Object { $_.Length -ge 1MB -and $_.Length -lt 10MB }).Count
        'Large (10MB-100MB)' = ($Files  Where-Object { $_.Length -ge 10MB -and $_.Length -lt 100MB }).Count
        'Huge (>100MB)' = ($Files  Where-Object { $_.Length -ge 100MB }).Count
    }
    
    $duplicateSizes = $Files  Group-Object Length  Where-Object { $_.Count -gt 1 }  ForEach-Object {
        @{
            Size = $_.Name
            Count = $_.Count
            Files = $_.Group  ForEach-Object { $_.FullName }
        }
    }
    
    return @{
        SizeDistribution = $sizeRanges
        PotentialDuplicates = $duplicateSizes
        CompressionOpportunity = math::Round((($Files  Where-Object { $_.Extension -in @('.txt', '.log', '.xml', '.json', '.csv') }  Measure-Object Length -Sum).Sum ?? 0) / 1MB, 2)
    }
}

# Helper function to format backup report
function Format-BackupReport {
    param($Stats)
    
    $report = @"
# PatchManager Backup Statistics Report

**Analysis Date:** $($Stats.AnalysisTime)
**Analysis Type:** $($Stats.AnalysisType)
**Git Commit:** $($Stats.GitCommit)

## Summary
- **Total Files:** $($Stats.Summary.TotalFiles)
- **Total Directories:** $($Stats.Summary.TotalDirectories)
- **Total Size:** $($Stats.Summary.TotalSizeMB) MB ($($Stats.Summary.TotalSizeGB) GB)
- **Average File Size:** $($Stats.Summary.AverageFileSizeMB) MB

"@
    
    if ($Stats.Details) {
        $report += "`n## Detailed Analysis`n"
        
        if ($Stats.Details.FilesByExtension) {
            $report += "`n### Files by Extension`n"
            foreach ($ext in $Stats.Details.FilesByExtension  Select-Object -First 5) {
                $sizeMB = math::Round($ext.TotalSize / 1MB, 2)
                $report += "- **$($ext.Extension):** $($ext.Count) files ($sizeMB MB)`n"
            }
        }
        
        if ($Stats.Details.FilesByAge) {
            $report += "`n### Files by Age`n"
            $report += "- **Last 24 Hours:** $($Stats.Details.FilesByAge.Last24Hours) files`n"
            $report += "- **Last Week:** $($Stats.Details.FilesByAge.LastWeek) files`n"
            $report += "- **Last Month:** $($Stats.Details.FilesByAge.LastMonth) files`n"
            $report += "- **Last Year:** $($Stats.Details.FilesByAge.LastYear) files`n"
            $report += "- **Older than Year:** $($Stats.Details.FilesByAge.OlderThanYear) files`n"
        }
        
        if ($Stats.Details.LargestFiles) {
            $report += "`n### Largest Files`n"
            foreach ($file in $Stats.Details.LargestFiles  Select-Object -First 5) {
                $report += "- **$($file.Name):** $($file.SizeMB) MB`n"
            }
        }
    }
    
    $report += "`n---`n*Generated by PatchManager v2.0*"
    
    return $report
}
