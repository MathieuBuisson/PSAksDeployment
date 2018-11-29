Function Get-LogAnalyticsLocations {
    [CmdletBinding()]
    Param()

    If ( -not((Get-AzContext).Account) ) {
        $TerraformUserCreds = Get-Credential -UserName '' -Message 'Please enter the secret for the Terraform Service Principal.'
        Connect-AzAccount -ServicePrincipal -Credential $TerraformUserCreds -Tenant ''
    }

    $Providers = Get-AzResourceProvider -ProviderNamespace 'Microsoft.OperationalInsights'
    $Providers.ResourceTypes.Where{($_.ResourceTypeName -eq 'workspaces')}.Locations
}