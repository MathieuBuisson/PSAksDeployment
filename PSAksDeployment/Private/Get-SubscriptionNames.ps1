Function Get-SubscriptionNames {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string]$AzureTenantID
    )

    If ( -not((Get-AzContext).Account) ) {
        $TerraformUserCreds = Get-Credential -Message 'Please enter the ID and secret for the Terraform Service Principal.'
        Connect-AzAccount -ServicePrincipal -Credential $TerraformUserCreds -Tenant $AzureTenantID
    }

    Get-AzSubscription | Select-Object -ExpandProperty Name
}
