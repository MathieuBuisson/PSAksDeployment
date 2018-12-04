Function Initialize-TerraformConfigK8s {
    [CmdletBinding()]
    Param()

    $TerraformConfigsPath = Join-Path "$($MyInvocation.MyCommand.Module.ModuleBase)" -ChildPath 'TerraformConfigs'
    Set-Location -Path (Join-Path $TerraformConfigsPath -ChildPath 'k8s')

    # Discard any previous deployment's temporary state file
    $StateFilePath = Join-Path -Path $PWD.ProviderPath -ChildPath '.terraform/terraform.tfstate'
    If ( Test-Path -Path $StateFilePath ) {
        Write-ConsoleLog 'Deleting previous deployment state file'
        Remove-Item -Path $StateFilePath -Force -Confirm:$False
    }

    & terraform --% init -input=false -reconfigure

    If ( -not($?) ) {
        Throw 'An error occurred while initializing the Terraform config. For details, please review the Terraform output above.'
    }
}
