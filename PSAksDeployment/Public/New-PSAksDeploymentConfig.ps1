Function New-PSAksDeploymentConfig {
<#
.SYNOPSIS
    Scaffolds a PowerShell data file (.psd1) containing all input parameters for the cmdlet Invoke-PSAksDeployment.

.DESCRIPTION
    Scaffolds a PowerShell data file (.psd1) containing all input parameters for the cmdlet Invoke-PSAksDeployment.
    It tries to be as helpful as possible by prepopulating the following for each parameter :
      - a description
      - the data type
      - valid values
      - the default value

.PARAMETER ServicePrincipalID
    The application ID of the Service Principal used by Terraform (and the AKS cluster) to access Azure.

.PARAMETER ServicePrincipalSecret
    The password of the Service Principal used by Terraform (and the AKS cluster) to access Azure.

.PARAMETER AzureTenantID
    The ID of the Azure AD tenant where the Terraform Service Principal (and the target subscription) live.

.PARAMETER Subscription
    The name of the Azure subscription where the AKS instance (and other Azure resources) will be deployed.

.PARAMETER ClusterLocation
    The Azure region where the AKS cluster (and other Azure resources) will be deployed.

.PARAMETER Path
    The path of the deployment config file to generate.
    Preferably, the file extension should be .psd1 to reflect its content : PowerShell data.

.EXAMPLE
    PS C:\> $ScaffoldParams = @{
        ServicePrincipalID = '29x1ecd3-190f-42c9-8660-088f69d121ba'
        ServicePrincipalSecret = 'tsWpRr6/YCxNyh8efMvjWbe5JoOiOw03xR1o9S5CLhZ='
        AzureTenantID = '96v3b174-9cdb-4a5e-9177-18c3bccc87cb'
        Subscription = 'DevOps'
        ClusterLocation = 'North Europe'
        Path = '.\TestScaffold.psd1'
    }
    PS C:\> New-PSAksDeploymentConfig @ScaffoldParams

#>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, Position=0)]
        [string]$ServicePrincipalID,

        [Parameter(Mandatory, Position=1)]
        [string]$ServicePrincipalSecret,

        [Parameter(Mandatory, Position=2)]
        [string]$AzureTenantID,

        [Parameter(Mandatory, Position=3)]
        [string]$Subscription,

        [Parameter(Mandatory, Position=4)]
        [string]$ClusterLocation,

        [Parameter(Mandatory, Position=5)]
        [ValidateScript({ Test-Path -Path (Split-Path $_ -Parent) -PathType Container })]
        [string]$Path
    )

    $CmdData = Get-Command Invoke-PSAksDeployment
    $Parameters = $CmdData.Parameters.Values
    $Parameters = $Parameters | Where-Object { $_.Attributes.ParameterSetName -eq 'InputsFromParameters' }
    $CommonParams = @( ([System.Management.Automation.PSCmdlet]::CommonParameters) + ([System.Management.Automation.PSCmdlet]::OptionalCommonParameters) )
    $Parameters = $Parameters | Where-Object { $_.Name -notin $CommonParams }

    [System.Collections.ArrayList]$ParameterData = @()
    Foreach ( $Parameter in $Parameters ) {
        Write-ConsoleLog "Gathering metadata for parameter : $($Parameter.Name)"
        $DefaultValue = $ParameterHelp = $ValidValues = $Null

        $ParameterHelp = Get-Help Invoke-PSAksDeployment -Parameter $Parameter.Name
        $DefaultValue = $ParameterHelp.DefaultValue -as [string]
        If ( $ParameterHelp.Type.Name -eq 'String' ) {
            $DefaultValue = '"{0}"' -f $DefaultValue
        }

        If ( $Parameter.Name -eq 'Subscription' ) {
            $ValidValuesArray = @(Get-SubscriptionNames $AzureTenantID $ServicePrincipalID $ServicePrincipalSecret).ForEach({ '"{0}"' -f $_ })
            $ValidValues = $ValidValuesArray -join ', '
        }
        ElseIf ( $Parameter.Name -eq 'ClusterLocation' ) {
            $ValidValuesArray = @(Get-AksLocations $AzureTenantID $ServicePrincipalID $ServicePrincipalSecret).ForEach({ '"{0}"' -f $_ })
            $ValidValues = $ValidValuesArray -join ', '
        }
        ElseIf ( $Parameter.Name -eq 'LogAnalyticsWorkspaceLocation' ) {
            $ValidValuesArray = @(Get-LogAnalyticsLocations $AzureTenantID $ServicePrincipalID $ServicePrincipalSecret).ForEach({ '"{0}"' -f $_ })
            $ValidValues = $ValidValuesArray -join ', '
        }
        ElseIf ( $Parameter.Name -eq 'KubernetesVersion' ) {
            $K8sVersionParams = @{
                AzureTenantID          = $AzureTenantID
                Subscription           = $Subscription
                ServicePrincipalID     = $ServicePrincipalID
                ServicePrincipalSecret = $ServicePrincipalSecret
                ClusterLocation        = $ClusterLocation
            }
            $ValidValuesArray = @(Get-KubernetesVersions @K8sVersionParams).ForEach({ '"{0}"' -f $_ })
            $ValidValues = $ValidValuesArray -join ', '
        }
        ElseIf ( $Parameter.Attributes.ValidValues ) {
            $ValidValuesArray = @($Parameter.Attributes.ValidValues).ForEach({ '"{0}"' -f $_ })
            $ValidValues = $ValidValuesArray -join ', '
        }
        ElseIf ( $Parameter.Attributes.RegexPattern -eq '^[A-Za-z]{1}[-\w]+\w{1}$') {
            $ValidValues = 'The name can contain only letters, numbers, and hyphens. The name must start with a letter and must end with a letter or a number.'
        }
        ElseIf ( $Parameter.Attributes.TypeId.Name -contains 'ValidateRangeAttribute' ) {
            $ValidValues = 'Between {0} and {1}.' -f $Parameter.Attributes.MinRange.ToString(), $Parameter.Attributes.MaxRange.ToString()
        }
        Else {
            $ValidValues = ''
        }

        $ObjectProperties = @{
            Name         = $Parameter.Name
            Description  = $ParameterHelp.Description.Text
            Type         = $ParameterHelp.Type.Name
            DefaultValue = If ( $DefaultValue ) {$DefaultValue} Else {'""'}
            ValidValues  = $ValidValues
        }

        $ParameterDataObject = New-Object -TypeName PSObject -Property $ObjectProperties
        $Null = $ParameterData.Add($ParameterDataObject)
    }

    $ConfigFileContent = Set-AksConfigValues -TemplatePath "$PSScriptRoot\..\Assets\ConfigTemplate.psd1" -Values $ParameterData
    $Null = New-Item -Path $Path -ItemType File -Force
    Set-Content -Path $Path -Value $ConfigFileContent
    Write-ConsoleLog "New config written to : $Path"
}
