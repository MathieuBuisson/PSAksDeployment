Function Initialize-TerraformConfigK8s {
    [CmdletBinding()]
    Param()

    $TerraformConfigsPath = Join-Path "$($MyInvocation.MyCommand.Module.ModuleBase)" -ChildPath 'TerraformConfigs'
    Set-Location -Path (Join-Path $TerraformConfigsPath -ChildPath 'k8s')
    & terraform --% init -input=false -force-copy

    If ( -not($?) ) {
        Throw 'An error occurred while initializing the Terraform config. For details, please review the Terraform output above.'
    }
}
