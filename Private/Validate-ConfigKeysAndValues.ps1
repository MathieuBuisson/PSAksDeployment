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
            Throw "The config file doesn't contain a key for parameter : [$ParameterName]"
        }
    }

    Write-ConsoleLog "Validating that the config contains allowed values"
    Foreach ( $Parameter in $Parameters ) {

        If ( $Parameter.Attributes.ValidValues ) {
            If ( $Config[$Parameter.Name] -notin $Parameter.Attributes.ValidValues ) {
                Throw "$($Config[$Parameter.Name]) is not a valid $($Parameter.Name) value"
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
