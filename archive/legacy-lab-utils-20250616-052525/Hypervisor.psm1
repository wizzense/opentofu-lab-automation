function Get-HVFacts {
    pscustomobject@{
        Provider = 'Hyper-V'
        Version  = '0.1'
    }
}

function Enable-Provider {
    'Hyper-V provider enabled'
}

function Deploy-VM {
    param(
        string$Name
    )
    "Deployed $Name"
}

Export-ModuleMember -Function Get-HVFacts, Enable-Provider, Deploy-VM
