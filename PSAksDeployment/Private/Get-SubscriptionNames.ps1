Function Get-SubscriptionNames {
    [CmdletBinding()]
    Param()

    If ( -not((Get-AzContext).Account) ) {
        $TerraformUserCreds = Get-Credential -UserName '' -Message 'Please enter the secret for the Terraform Service Principal.'
        Connect-AzAccount -ServicePrincipal -Credential $TerraformUserCreds -Tenant ''
    }

    Get-AzSubscription | Select-Object -ExpandProperty Name
}