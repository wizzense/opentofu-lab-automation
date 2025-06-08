function Expand-All {
    
    # Expand-All -ZipFile "C:\path\to\your\archive.zip"

    param(
        [string]$ZipFile
    )

    if ($ZipFile) {
        # Expand a specific zip file if provided
        if (-not (Test-Path $ZipFile)) {
            Write-Host "File '$ZipFile' does not exist."
            return
        }
        Write-Host "Specified ZIP file: $ZipFile"
        $confirmation = Read-Host "Do you want to expand this archive? (y/n)"
        if ($confirmation -ne 'y') {
            Write-Host "Operation canceled."
            return
        }
        $destination = Join-Path -Path (Split-Path $ZipFile -Parent) -ChildPath (Split-Path $ZipFile -LeafBase)
        Write-Host "Expanding archive: $ZipFile to $destination"
        Expand-Archive -Path $ZipFile -DestinationPath $destination -Force
        Write-Host "Archive expanded."
    }
    else {
        # Expand all zip files recursively in the current directory
        $currentDir = Get-Location
        Write-Host "Current Directory: $currentDir"
        $confirmation = Read-Host "Do you want to expand all archives in this directory and its subdirectories? (y/n)"
        if ($confirmation -ne 'y') {
            Write-Host "Operation canceled."
            return
        }
        Get-ChildItem -Path $currentDir -Recurse -Filter *.zip | ForEach-Object {
            $destination = Join-Path -Path $_.DirectoryName -ChildPath $_.BaseName
            Write-Host "Expanding archive: $($_.FullName) to $destination"
            Expand-Archive -Path $_.FullName -DestinationPath $destination -Force
        }
        Write-Host "All archives expanded."
    }
}

