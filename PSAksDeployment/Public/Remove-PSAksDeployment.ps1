Function Remove-PSAksDeployment {
<#
.SYNOPSIS
    Deletes an Azure Kubernetes Service (AKS) cluster previously deployed with the cmdlet "Invoke-PSAksDeployment".

.DESCRIPTION
    Deletes an Azure Kubernetes Service (AKS) cluster previously deployed with the cmdlet "Invoke-PSAksDeployment", and all associated Azure resources.
    Use at your own risk.

.PARAMETER Subscription
    The name of the Azure subscription where the AKS instance (and other Azure resources) will be deleted.

.PARAMETER ClusterLocation
    The Azure region where the AKS cluster (and other Azure resources) will be deleted.

.PARAMETER LogAnalyticsWorkspaceLocation
    The Azure region where the Log Analytics workspace will be deleted.
    This might not be possible to provision the Log Analytics workspace in the same region as the AKS cluster, because Log Analytics is available in a limited set of regions.

.PARAMETER ServicePrincipalID
    The application ID of the Service Principal used by Terraform (and the AKS cluster) to access Azure.

.PARAMETER ServicePrincipalSecret
    The password of the Service Principal used by Terraform (and the AKS cluster) to access Azure.

.PARAMETER AzureTenantID
    The ID of the Azure AD tenant where the Terraform Service Principal (and the target subscription) live.

.PARAMETER ClusterName
    The name of the AKS cluster.
    The name of the resource group and the cluster DNS prefix are derived from this value.

.PARAMETER KubernetesVersion
    The version of Kubernetes software running in the AKS Cluster.

.PARAMETER NodeCount
    The number of worker nodes in the AKS cluster.

.PARAMETER NodeSize
    The VM size for the AKS cluster nodes.
    This is more descriptive version of Azure VM sizes, it follows a naming convention as :
    {VM Family}_{Number of vCPUs}_{Number of GB of RAM}

.PARAMETER OSDiskSizeGB
    The OS disk size (GB) for the cluster nodes.
    If set to 0, the default osDisk size for the specified vmSize is applied.

.PARAMETER MaxPodsPerNode
    The maximum number of pods that can run on a node.

.PARAMETER Environment
    The type of environment this cluster is for.
    Some policies may apply only to 'Production' environments.

.PARAMETER ConfigPath
    To specify all input parameters from a PowerShell data file, instead of at the command line.
    It is recommended to scaffold this file using "New-PSAksDeploymentConfig" and then, populate/adjust values to your needs.
    CAUTION : Do not keep this file in source control after populating sensitive data, like the Service Principal secret.

.EXAMPLE

#>
    [CmdletBinding(DefaultParameterSetName='InputsFromParameters')]
    Param(
        [Parameter(Mandatory, Position=0, ParameterSetName='InputsFromParameters')]
        [string]$ServicePrincipalID,

        [Parameter(Mandatory, Position=1, ParameterSetName='InputsFromParameters')]
        [string]$ServicePrincipalSecret,

        [Parameter(Mandatory, Position=2, ParameterSetName='InputsFromParameters')]
        [string]$AzureTenantID,

        [Parameter(Mandatory, Position=3, ParameterSetName='InputsFromParameters')]
        [string]$Subscription,

        [Parameter(Mandatory, Position=4, ParameterSetName='InputsFromParameters')]
        [ValidateLength(3, 29)]
        [ValidatePattern('^[A-Za-z]{1}[-\w]+\w{1}$')]
        [string]$ClusterName,

        [Parameter(Mandatory, Position=5, ParameterSetName='InputsFromParameters')]
        [string]$ClusterLocation,

        [Parameter(Mandatory, Position=6, ParameterSetName='InputsFromParameters')]
        [string]$LogAnalyticsWorkspaceLocation,

        [Parameter(Mandatory=$False, Position=7, ParameterSetName='InputsFromParameters')]
        [string]$KubernetesVersion = '1.11.5',

        [Parameter(Mandatory=$False, Position=8, ParameterSetName='InputsFromParameters')]
        [ValidateRange(1, 100)]
        [int]$NodeCount = 3,

        [Parameter(Mandatory=$False, Position=9, ParameterSetName='InputsFromParameters')]
        [ValidateSet('B_2vCPU_8GB', 'B_4vCPU_16GB', 'D_2vCPU_8GB', 'D_4vCPU_16GB', 'D_8vCPU_32GB', 'E_2vCPU_16GB', 'E_4vCPU_32GB', 'F_2vCPU_4GB', 'F_4vCPU_8GB', 'DS_2vCPU_7GB', 'DS_4vCPU_14GB')]
        [string]$NodeSize = 'D_2vCPU_8GB',

        [Parameter(Mandatory=$False, Position=10, ParameterSetName='InputsFromParameters')]
        [ValidateRange(0, 1024)]
        [int]$OSDiskSizeGB = 30,

        [Parameter(Mandatory=$False, Position=11, ParameterSetName='InputsFromParameters')]
        # OpenShift sets this to 250 so it's a safe maximum (https://docs.openshift.com/container-platform/3.11/scaling_performance/cluster_limits.html)
        [ValidateRange(110, 250)]
        [int]$MaxPodsPerNode = 110,

        [Parameter(Mandatory=$False, Position=12, ParameterSetName='InputsFromParameters')]
        [ValidateSet('Dev', 'QA', 'Staging', 'Prod')]
        [string]$Environment = 'Dev',

        [Parameter(Mandatory, ParameterSetName='InputsFromConfigFile')]
        [ValidateScript( { Test-Path -Path $_ -PathType Leaf })]
        [string]$ConfigPath
    )

    Begin {
        $ErrorActionPreference = 'Stop'

        If ( $PSCmdlet.ParameterSetName -eq 'InputsFromParameters' ) {
            $ConfigKeys = ($PSCmdlet.MyInvocation.MyCommand.Parameters.Values | Where-Object { $_.Attributes.ParameterSetName -eq 'InputsFromParameters' }).Name
            $Config = @{}
            Foreach ( $ConfigKey in $ConfigKeys ) {
                $Config.Add($ConfigKey, (Get-Variable -Name $ConfigKey -ValueOnly))
            }
            Validate-ConfigKeysAndValues -Config $Config
        }
        ElseIf ( $PSCmdlet.ParameterSetName -eq 'InputsFromConfigFile' ) {
            $Config = Import-PowerShellDataFile -Path $ConfigPath
            Validate-ConfigKeysAndValues -Config $Config

            Foreach ( $ConfigKey in $Config.Keys ) {
                New-Variable -Name $ConfigKey -Value $Config[$ConfigKey] -Visibility Public -Force
            }
        }

        $TerraformConfigsPath = Join-Path "$($MyInvocation.MyCommand.Module.ModuleBase)" -ChildPath 'TerraformConfigs'
        Push-Location -StackName 'PSAksDeletion'
        Set-Location -Path (Join-Path $TerraformConfigsPath -ChildPath 'aks')
    }
    Process {
        $SelectedSubscription = Set-AzContext -Subscription $Subscription

        $NodeVMSize = ConvertTo-AzureVMSize -SizeDisplayName $NodeSize
        Write-ConsoleLog "Input Node size [$NodeSize] maps to : $NodeVMSize"

        $SubsIdVar = '-var subscription_id={0}' -f $SelectedSubscription.Subscription.Id
        $SecretVar = 'client_secret={0}' -f $ServicePrincipalSecret
        $TenantVar = 'tenant_id={0}' -f $AzureTenantID
        $ClientVar = 'client_id={0}' -f $ServicePrincipalID
        $ClusterVar = 'cluster_name={0}' -f $ClusterName
        $LocationVar = 'location="{0}"' -f $ClusterLocation
        $WorkspaceVar = 'loganalytics_workspace_location="{0}"' -f $LogAnalyticsWorkspaceLocation
        $VersionVar = 'kubernetes_version={0}' -f $KubernetesVersion
        $AgentCountVar = 'agent_count={0}' -f $NodeCount.ToString()
        $AgentSizeVar = 'agent_vm_size={0}' -f $NodeVMSize
        $DiskSizeVar = 'os_disk_size_GB={0}' -f $OSDiskSizeGB.ToString()
        $MaxPodsVar = 'agent_max_pods={0}' -f $MaxPodsPerNode.ToString()
        $EnvVar = 'environment={0}' -f $Environment

        $DestroyCmdVars = $SubsIdVar, $SecretVar, $TenantVar, $ClientVar, $ClusterVar, $LocationVar, $WorkspaceVar, $VersionVar, $AgentCountVar, $AgentSizeVar, $DiskSizeVar, $MaxPodsVar, $EnvVar -join ' -var '
        $DestroyCmd = [scriptblock]::Create("terraform destroy -auto-approve $DestroyCmdVars")
        & $DestroyCmd

        If ( $LASTEXITCODE -eq 1 ) {
            Throw 'An error occurred while creating the Terraform plan. For details, please review the Terraform output above.'
        }
    }
    End {
        Pop-Location -StackName 'PSAksDeletion'
        Write-ConsoleLog 'Deletion complete.'
    }
}
