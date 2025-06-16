






BeforeAll {
        Disable-InteractivePrompts
        Enable-WindowsMocks
    if (Get-PSDrive TestDrive -ErrorAction SilentlyContinue) {
        Remove-PSDrive TestDrive -Force -ErrorAction SilentlyContinue
    }
}



