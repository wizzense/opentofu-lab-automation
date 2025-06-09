function Get-Platform {
    if ($IsWindows) { return 'Windows' }
    elseif ($IsLinux) { return 'Linux' }
    elseif ($IsMacOS) { return 'MacOS' }
    elseif ($PSVersionTable.OS) {
        if ($PSVersionTable.OS -match 'Windows') { return 'Windows' }
        elseif ($PSVersionTable.OS -match 'Darwin') { return 'MacOS' }
        elseif ($PSVersionTable.OS -match 'Linux') { return 'Linux' }
    }
    return 'Unknown'
}
