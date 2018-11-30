Function Get-AksLocations {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, Position = 0)]
        [string]$AzureTenantID,

        [Parameter(Mandatory, Position = 1)]
        [string]$ServicePrincipalID,

        [Parameter(Mandatory, Position = 2)]
        [string]$ServicePrincipalSecret
    )

    If ( -not((Get-AzContext).Account) ) {
        $SecurePassword = ConvertTo-SecureString -String $ServicePrincipalSecret -AsPlainText -Force
        $SPCredential = [pscredential]::new($ServicePrincipalID, $SecurePassword)
        $Null = Connect-AzAccount -ServicePrincipal -Credential $SPCredential -Tenant $AzureTenantID
    }

    $Providers = Get-AzResourceProvider -ProviderNamespace 'Microsoft.ContainerService'
    $Providers.ResourceTypes.Where{($_.ResourceTypeName -eq 'managedClusters')}.Locations
}
