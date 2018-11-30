Function Get-SubscriptionNames {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, Position=0)]
        [string]$AzureTenantID,

        [Parameter(Mandatory, Position=1)]
        [string]$ServicePrincipalID,

        [Parameter(Mandatory, Position=2)]
        [string]$ServicePrincipalSecret
    )

    If ( -not((Get-AzContext).Account) ) {
        $SecurePassword = ConvertTo-SecureString -String $ServicePrincipalSecret -AsPlainText -Force
        $SPCredential = [pscredential]::new($ServicePrincipalID, $SecurePassword)
        $Null = Connect-AzAccount -ServicePrincipal -Credential $SPCredential -Tenant $AzureTenantID
    }

    Get-AzSubscription | Select-Object -ExpandProperty Name
}
