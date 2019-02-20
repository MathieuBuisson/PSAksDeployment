Function Invoke-PSAksDeployment {
<#
.SYNOPSIS
    Performs the provisioning and initial configuration of an Azure Kubernetes Service (AKS) cluster.

.DESCRIPTION
    Performs the provisioning and initial configuration of an Azure Kubernetes Service (AKS) cluster.
    This is mainly composed of :
      - an AKS cluster
      - an Azure Log Analytics workspace with the ContainerInsights solution
      - a Public IP address for the ingress controller
      - a "management" namespace
      - Tiller installation and initialization
      - Nginx ingress controller installation and configuration
      - cert-manager installation and configuration
      - a TLS certificate for the ingress controller (to support HTTPS)
      - secret-propagator

    This function is mostly an input validation and orchestration layer on top of Terraform.

.PARAMETER Subscription
    The name of the Azure subscription where the AKS instance (and other Azure resources) will be deployed.

.PARAMETER ClusterLocation
    The Azure region where the AKS cluster (and other Azure resources) will be deployed.

.PARAMETER LogAnalyticsWorkspaceLocation
    The Azure region where the Log Analytics workspace will be deployed.
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

.PARAMETER LetsEncryptEmail
    The email address used to register with Let's Encrypt and used by the cluster's certificate issuer.

.PARAMETER TerraformOutputFolder
    The root directory where output folders/files will be stored.
    The most important folders/files are related to the Terraform plan(s) and Terraform state file(s).

.PARAMETER ConfigPath
    To specify all input parameters from a PowerShell data file, instead of at the command line.
    It is recommended to scaffold this file using "New-PSAksDeploymentConfig" and then, populate/adjust values to your needs.
    CAUTION : Do not keep this file in source control after populating sensitive data, like the Service Principal secret.

.EXAMPLE
    PS C:\> Invoke-PSAksDeployment -ClusterLocation 'North Europe' -Subscription 'InfraDev' -ServicePrincipalSecret 'zaWpRr9/YCxNyh8efMvjWbe5JoOiOw03xR1o9S5CLhY=' -ClusterName 'infradev-k8s' -LogAnalyticsWorkspaceLocation 'West Europe' -NodeCount 4

    Provisions and configures an AKS cluster according to the parameter values specified at the command line.

.EXAMPLE
    PS C:\> Invoke-PSAksDeployment -ConfigPath ./Dev_Config.psd1

    Provisions and configures an AKS cluster according to the parameter values in the file "Dev_Config.psd1" in the current directory.
#>
    [CmdletBinding(DefaultParameterSetName = 'InputsFromParameters')]
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
        [string]$KubernetesVersion = '1.12.5',

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

        [Parameter(Mandatory, Position=13, ParameterSetName='InputsFromParameters')]
        [string]$LetsEncryptEmail,

        [Parameter(Mandatory=$False, Position=14, ParameterSetName='InputsFromParameters')]
        [string]$TerraformOutputFolder = $env:TEMP,

        [Parameter(Mandatory, ParameterSetName='InputsFromConfigFile')]
        [ValidateScript({ Test-Path -Path $_ -PathType Leaf })]
        [string]$ConfigPath
    )

    Begin {
        $ErrorActionPreference = 'Stop'
        $Null = Disable-AzContextAutosave -Scope CurrentUser

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
        $AksDeploymentStartTime = [System.DateTime]::Now
    }
    Process {
        $SelectedSubscription = Set-AzContext -Subscription $Subscription
        Write-ConsoleLog "Azure subscription : $($SelectedSubscription.Name)"
        Write-ConsoleLog "Kubernetes Version : $KubernetesVersion"

        $NodeVMSize = ConvertTo-AzureVMSize -SizeDisplayName $NodeSize
        Write-ConsoleLog "Input Node size [$NodeSize] maps to : $NodeVMSize"

        Set-TerraformBackendPaths -RootFolder $TerraformOutputFolder -ClusterName $ClusterName
        Initialize-TerraformConfigAks $TerraformOutputFolder -ClusterName $ClusterName

        $AKSConfigParams = @{
            SubscriptionId                = $SelectedSubscription.Subscription.Id
            ServicePrincipalID            = $ServicePrincipalID
            ServicePrincipalSecret        = $ServicePrincipalSecret
            AzureTenantID                 = $AzureTenantID
            ClusterName                   = $ClusterName
            ClusterLocation               = $ClusterLocation
            LogAnalyticsWorkspaceLocation = $LogAnalyticsWorkspaceLocation
            KubernetesVersion             = $KubernetesVersion
            NodeCount                     = $NodeCount
            NodeVMSize                    = $NodeVMSize
            OSDiskSizeGB                  = $OSDiskSizeGB
            MaxPodsPerNode                = $MaxPodsPerNode
            Environment                   = $Environment
            TerraformOutputFolder         = $TerraformOutputFolder
        }
        Invoke-TerraformConfigAks @AKSConfigParams

        Set-AksKubeConfig -ClusterName $ClusterName -ClusterId (Get-TerraformOutputValue 'AKS_resource_ID')

        $IngressCtrlIPAddress = Get-TerraformOutputValue 'ingressctrl_ip_address'
        Write-ConsoleLog "Ingress controller IP address : [$IngressCtrlIPAddress]"
        Initialize-TerraformConfigK8s

        $K8sConfigParams = @{
            ClusterName             = $ClusterName
            TerraformOutputFolder   = $TerraformOutputFolder
            # We should not need more than 2 replicas for Tiller
            TillerReplicaCount      = [math]::Min($NodeCount, 2)
            IngressCtrlReplicaCount = [math]::Min($NodeCount, 2)
            IngressCtrlIPAddress    = $IngressCtrlIPAddress
            LetsEncryptEmail        = $LetsEncryptEmail
            LetsEncryptEnvironment  = If ( $Environment -eq 'Prod' ) {'prod'} Else {'staging'}
            IngressCtrlFqdn         = '{0}.{1}.cloudapp.azure.com' -f $ClusterName, ($ClusterLocation -replace '\s','').ToLower()
            Environment             = $Environment
        }
        Invoke-TerraformConfigK8s @K8sConfigParams
    }
    End {
        Pop-Location -StackName 'PSAksDeployment'
        Write-ConsoleLog 'Deployment complete.'
        $AksDeploymentEndTime = [System.DateTime]::Now
        $AksDeploymentDuration = $AksDeploymentEndTime - $AksDeploymentStartTime
        Write-ConsoleLog ('Deployment run duration : {0:mm} minutes {0:ss} seconds' -f $AksDeploymentDuration)
    }
}
