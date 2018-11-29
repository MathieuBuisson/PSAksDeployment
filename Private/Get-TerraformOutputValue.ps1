Function Get-TerraformOutputValue {
    [CmdletBinding()]
    Param(
        [Parameter(Position=0, Mandatory)]
        [string]$OutputKey
    )

    $OutputJson = & terraform.exe --% output -no-color -json
    $OutputObj = $OutputJson | ConvertFrom-Json
    $OutputObj.$OutputKey.value
}