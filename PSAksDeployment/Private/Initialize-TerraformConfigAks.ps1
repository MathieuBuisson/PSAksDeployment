Function Initialize-TerraformConfigAks {
    [CmdletBinding()]
    Param()

    $TerraformConfigsPath = Join-Path "$($MyInvocation.MyCommand.Module.ModuleBase)" -ChildPath 'TerraformConfigs'
    Push-Location -StackName 'PSAksDeployment'
    Set-Location -Path (Join-Path $TerraformConfigsPath -ChildPath 'aks')
    & terraform --% init -input=false -force-copy

    If ( -not($?) ) {
        Throw 'An error occurred while initializing the Terraform config. For details, please review the Terraform output above.'
    }
}
