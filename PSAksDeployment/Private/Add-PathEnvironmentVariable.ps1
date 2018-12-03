Function Add-PathEnvironmentVariable {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string]$PathToAdd
    )

    $PathToAdd = $PathToAdd.TrimEnd('/\')

    # Ensuring $PathToAdd is persisted in the user scope environment
    $RegistryKey = 'HKCU:\Environment'
    $CurrentRegistryValue = (Get-ItemProperty -Path $RegistryKey -Name 'Path').Path
    $CurrentRegistryArray = ($CurrentRegistryValue -split ';').ForEach({ $_.TrimEnd('/\') })

    If ( $PathToAdd -notin $CurrentRegistryArray ) {
        Write-ConsoleLog "Adding path [$PathToAdd] to [$RegistryKey]"
        $NewRegistryValue = '{0};{1}' -f $PathToAdd, $CurrentRegistryValue
        Set-ItemProperty -Path $RegistryKey -Name 'Path' -Value $NewRegistryValue
    }
    Else {
        Write-ConsoleLog "Path [$PathToAdd] is already persisted to user scope environment"
    }

    # Ensuring $PathToAdd is in the current process environment
    $CurrentProcessArray = ($Env:Path -split ';').ForEach({ $_.TrimEnd('/\') })
    If ( $PathToAdd -notin $CurrentProcessArray ) {
        Write-ConsoleLog "Adding path [$PathToAdd] to the current process environment"
        $NewPathValue = '{0};{1}' -f $PathToAdd, $Env:Path
        $Env:Path = $NewPathValue
    }
    Else {
        Write-ConsoleLog "Path [$PathToAdd] is already in current process environment"
    }
}
