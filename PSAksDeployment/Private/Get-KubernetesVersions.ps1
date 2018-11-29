Function Get-KubernetesVersions {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, Position=0)]
        [string]$AzureTenantID,

        [Parameter(Mandatory, Position=1)]
        [string]$Subscription,

        [Parameter(Mandatory, Position=2)]
        [string]$ServicePrincipalID,

        [Parameter(Mandatory, Position=3)]
        [string]$ServicePrincipalSecret,

        [Parameter(Mandatory, Position=4)]
        [string]$ClusterLocation
    )

    $TokenEndpoint = 'https://login.windows.net/{0}/oauth2/token' -f $AzureTenantID
    $ARMResource = 'https://management.core.windows.net/'

    $Body = @{
        'resource'= $ARMResource
        'client_id' = $ServicePrincipalID
        'grant_type' = 'client_credentials'
        'client_secret' = $ServicePrincipalSecret
    }
    $TokenRequestParams = @{
        ContentType = 'application/x-www-form-urlencoded'
        Headers = @{'accept'='application/json'}
        Body = $Body
        Method = 'Post'
        URI = $TokenEndpoint
        ErrorAction = 'Stop'
    }
    $Token = Invoke-RestMethod @TokenRequestParams

    $BaseUrl = 'https://management.azure.com'
    $SubscriptionId = (Get-AzSubscription -SubscriptionName $Subscription).Id
    $Region = ($ClusterLocation -replace '\s','').ToLower()
    $FullUrl = '{0}/subscriptions/{1}/providers/Microsoft.ContainerService/locations/{2}/orchestrators?api-version=2017-09-30&resource-type=managedClusters' -f $BaseUrl, $SubscriptionId, $Region

    $OrchestratorRequestParams = @{
        ContentType = 'application/x-www-form-urlencoded'
        Headers = @{'authorization'="Bearer $($Token.access_token)"}
        Method = 'Get'
        URI = $FullUrl
        ErrorAction = 'Stop'
    }
    $Response = Invoke-RestMethod @OrchestratorRequestParams
    $Response.properties.orchestrators.orchestratorVersion
}