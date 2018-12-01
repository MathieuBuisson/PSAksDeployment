Function Validate-ConfigKeysAndValues {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [Hashtable]$Config
    )

    $ConfigKeys = $Config.Keys
    Write-ConsoleLog "Validating that the config has all expected keys"
    $CmdData = Get-Command Invoke-AksDeployment
    $Parameters = $CmdData.Parameters.Values
    $Parameters = $Parameters | Where-Object { $_.Attributes.ParameterSetName -eq 'InputsFromParameters' }

    Foreach ( $ParameterName in $Parameters.Name ) {
        If ( $ParameterName -notin $ConfigKeys ) {
            Throw "The config doesn't contain a key for parameter : [$ParameterName]"
        }
    }

    Write-ConsoleLog "Validating that the config contains allowed values"
    Foreach ( $Parameter in $Parameters ) {

        If ( $Parameter.Name -eq 'Subscription' ) {
            $ValidSubscriptionNames = Get-SubscriptionNames $Config['AzureTenantID'] $Config['ServicePrincipalID'] $Config['ServicePrincipalSecret']
            If ( $Config[$Parameter.Name] -notin $ValidSubscriptionNames ) {
                Throw "$($Config[$Parameter.Name]) is not one of the valid values : $($ValidSubscriptionNames -join ', ')"
            }
        }
        ElseIf ( $Parameter.Name -eq 'ClusterLocation' ) {
            $ValidAksLocations = Get-AksLocations $Config['AzureTenantID'] $Config['ServicePrincipalID'] $Config['ServicePrincipalSecret']
            If ( $Config[$Parameter.Name] -notin $ValidAksLocations ) {
                Throw "$($Config[$Parameter.Name]) is not one of the valid values : $($ValidAksLocations -join ', ')"
            }
        }
        ElseIf ( $Parameter.Name -eq 'LogAnalyticsWorkspaceLocation' ) {
            $ValidLogAnalyticsLocations = Get-LogAnalyticsLocations $Config['AzureTenantID'] $Config['ServicePrincipalID'] $Config['ServicePrincipalSecret']
            If ( $Config[$Parameter.Name] -notin $ValidLogAnalyticsLocations ) {
                Throw "$($Config[$Parameter.Name]) is not one of the valid values : $($ValidLogAnalyticsLocations -join ', ')"
            }
        }
        ElseIf ( $Parameter.Name -eq 'KubernetesVersion' ) {
            $K8sVersionParams = @{
                AzureTenantID          = $Config['AzureTenantID']
                Subscription           = $Config['Subscription']
                ServicePrincipalID     = $Config['ServicePrincipalID']
                ServicePrincipalSecret = $Config['ServicePrincipalSecret']
                ClusterLocation        = $Config['ClusterLocation']
            }
            $ValidK8sVersions = Get-KubernetesVersions @K8sVersionParams

            If ( $Config[$Parameter.Name] -notin $ValidK8sVersions ) {
                Throw "$($Config[$Parameter.Name]) is not one of the valid values : $($ValidK8sVersions -join ', ')"
            }
        }
        ElseIf ( $Parameter.Attributes.ValidValues ) {
            $ValidSet = $Parameter.Attributes.ValidValues
            If ( $Config[$Parameter.Name] -notin $ValidSet ) {
                Throw "$($Config[$Parameter.Name]) is not one of the valid values : $($ValidSet -join ', ')"
            }
        }
        ElseIf ( $Parameter.Attributes.RegexPattern -eq '^[A-Za-z]{1}[-\w]+\w{1}$') {
            If ( $Config[$Parameter.Name] -notmatch $Parameter.Attributes.RegexPattern ) {
                Throw "$($Config[$Parameter.Name]) is not a valid $($Parameter.Name) value"
            }
        }
        ElseIf ( $Parameter.Attributes.TypeId.Name -contains 'ValidateRangeAttribute' ) {
            If ( $Config[$Parameter.Name] -lt $Parameter.Attributes.MinRange ) {
                Throw "$($Config[$Parameter.Name]) is less than the lowest valid $($Parameter.Name) value"
            }
            If ( $Config[$Parameter.Name] -gt $Parameter.Attributes.MaxRange ) {
                Throw "$($Config[$Parameter.Name]) is greater than the highest valid $($Parameter.Name) value"
            }
        }
        Else {
            If ( -not($Config[$Parameter.Name]) ) {
                Throw "The specified value for parameter $($Parameter.Name) is null or empty"
            }
        }
    }
}
