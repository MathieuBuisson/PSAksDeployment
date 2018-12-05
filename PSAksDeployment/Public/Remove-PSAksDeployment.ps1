Function Remove-PSAksDeployment {
<#
.SYNOPSIS
    Deletes an Azure Kubernetes Service (AKS) cluster previously deployed with the cmdlet "Invoke-PSAksDeployment".

.DESCRIPTION
    Deletes an Azure Kubernetes Service (AKS) cluster previously deployed with the cmdlet "Invoke-PSAksDeployment".
    This actually deletes all associated Azure resources, including the containing resource group.
    It finds the resource group based on PSAksDeployment naming convention : "${$ClusterName}-rg".
    Use at your own risk.

.PARAMETER AzureTenantID
    The ID of the Azure AD tenant where the Terraform Service Principal (and the target subscription) live.

.PARAMETER ServicePrincipalID
    The application ID of the Service Principal used by Terraform (and the AKS cluster) to access Azure.

.PARAMETER ServicePrincipalSecret
    The password of the Service Principal used by Terraform (and the AKS cluster) to access Azure.

.PARAMETER Subscription
    The name of the Azure subscription where the AKS instance (and other Azure resources) will be deleted.

.PARAMETER ClusterName
    The name of the AKS cluster to delete.
    The name of the resource group and the cluster DNS prefix are derived from this value.

.EXAMPLE
    PS C:\> Remove-PSAksDeployment -AzureTenantID '86f3b174-9cdb-4a5e-9177-18c3bccc87zv' -ServicePrincipalID '39c1ecd3-190f-42c9-8660-088f69d121wz' -ServicePrincipalSecret 'zaWpRr9/YCxNyh8efMvjWbe5JoOiOw03xR1o9S5CLhY=' -Subscription 'InfraDev' -ClusterName 'infradev-k8s'

    Deletes the AKS cluster named "infradev-k8s" and all associated resources.
#>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, Position=0)]
        [string]$AzureTenantID,

        [Parameter(Mandatory, Position=1)]
        [string]$ServicePrincipalID,

        [Parameter(Mandatory, Position=2)]
        [string]$ServicePrincipalSecret,

        [Parameter(Mandatory, Position=3)]
        [string]$Subscription,

        [Parameter(Mandatory, Position=4)]
        [ValidateLength(3, 29)]
        [ValidatePattern('^[A-Za-z]{1}[-\w]+\w{1}$')]
        [string]$ClusterName
    )

    $ErrorActionPreference = 'Stop'

    If ( -not((Get-AzContext).Account) ) {
        $SecurePassword = ConvertTo-SecureString -String $ServicePrincipalSecret -AsPlainText -Force
        $SPCredential = [pscredential]::new($ServicePrincipalID, $SecurePassword)
        $Null = Connect-AzAccount -ServicePrincipal -Credential $SPCredential -Tenant $AzureTenantID
    }

    $SelectedSubscription = Set-AzContext -Subscription $Subscription
    Write-ConsoleLog "Azure subscription : $($SelectedSubscription.Name)"

    # Not using `terraform destroy` because it fails to destroy the ingress public IP
    # Because it is not aware of the Azure resource attached to this IP : the load-balancer.
    $RGName = '{0}-rg' -f $ClusterName
    $RG = Get-AzResourceGroup -Name $RGName -ErrorAction SilentlyContinue

    If ( $RG ) {
        Write-ConsoleLog "Deleting resource group [$RGName], this may take several minutes..."
        $RG | Remove-AzResourceGroup -Force
    }
    Else {
        Throw "Could not find resource group [$RGName] in subscription [$Subscription]"
    }
}
