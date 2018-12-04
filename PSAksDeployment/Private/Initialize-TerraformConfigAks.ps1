Function Initialize-TerraformConfigAks {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, Position=0)]
        [string]$TerraformOutputFolder,

        [Parameter(Mandatory, Position=1)]
        [string]$ClusterName
    )

    # Discard output of any previous deployment for the same cluster
    $DeploymentOutputFolder = Join-Path -Path $TerraformOutputFolder -ChildPath "TF_$ClusterName"
    If ( Test-Path -Path $DeploymentOutputFolder ) {
        Write-ConsoleLog 'Deleting previous deployment output folder'
        Get-ChildItem $DeploymentOutputFolder -File -Recurse | Remove-Item -Force -Confirm:$False
        Remove-Item -Path $DeploymentOutputFolder -Force -Recurse -Confirm:$False
    }

    $TerraformConfigsPath = Join-Path "$($MyInvocation.MyCommand.Module.ModuleBase)" -ChildPath 'TerraformConfigs'
    Push-Location -StackName 'PSAksDeployment'
    Set-Location -Path (Join-Path $TerraformConfigsPath -ChildPath 'aks')

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
