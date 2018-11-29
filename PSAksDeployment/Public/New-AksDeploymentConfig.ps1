Function New-AksDeploymentConfig {
<#
.SYNOPSIS
    Scaffolds a PowerShell data file (.psd1) containing all input parameters for the cmdlet Invoke-AksDeployment.

.DESCRIPTION
    Scaffolds a PowerShell data file (.psd1) containing all input parameters for the cmdlet Invoke-AksDeployment.
    It tries to be as helpful as possible by prepopulating the following for each parameter :
      - a description
      - the data type
      - valid values
      - the default value

.PARAMETER Path
    The path of the deployment config file to generate.
    Preferably, the file extension should be .psd1 to reflect its content : PowerShell data.

.EXAMPLE

#>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, Position=0)]
        [ValidateScript({ Test-Path -Path (Split-Path $_ -Parent) -PathType Container })]
        [string]$Path
    )

    $CmdData = Get-Command Invoke-AksDeployment
    $Parameters = $CmdData.Parameters.Values
    $Parameters = $Parameters | Where-Object { $_.Attributes.ParameterSetName -eq 'InputsFromParameters' }
    $CommonParams = @( ([System.Management.Automation.PSCmdlet]::CommonParameters) + ([System.Management.Automation.PSCmdlet]::OptionalCommonParameters) )
    $Parameters = $Parameters | Where-Object { $_.Name -notin $CommonParams }

    [System.Collections.ArrayList]$ParameterData = @()
    Foreach ( $Parameter in $Parameters ) {
        Write-ConsoleLog "Gathering metadata for parameter : $($Parameter.Name)"

        $DefaultValue = $ParameterHelp = $ValidValues = $Null
        If ( -not($Parameter.IsDynamic) ) {
            $ParameterHelp = Get-Help Invoke-AksDeployment -Parameter $Parameter.Name
            $DefaultValue = $ParameterHelp.DefaultValue -as [string]
            If ( $ParameterHelp.Type.Name -eq 'String' ) {
                $DefaultValue = '"{0}"' -f $DefaultValue
            }
        }

        If ( $Parameter.Attributes.ValidValues ) {
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

        $ObjectProperties = [ordered]@{
            Name           = $Parameter.Name
            Description    = If ( $ParameterHelp ) {$ParameterHelp.Description.Text} Else {''}
            Type           = If ( $ParameterHelp ) {$ParameterHelp.Type.Name} Else {''}
            DefaultValue   = If ( $DefaultValue ) {$DefaultValue} Else {'""'}
            ValidValues    = [string]$ValidValues
        }

        $ParameterDataObject = New-Object -TypeName PSObject -Property $ObjectProperties
        $Null = $ParameterData.Add($ParameterDataObject)
    }

    $ConfigFileContent = Set-AksConfigValues -TemplatePath "$PSScriptRoot\..\Assets\ConfigTemplate.psd1" -Values $ParameterData
    $Null = New-Item -Path $Path -ItemType File -Force
    Set-Content -Path $Path -Value $ConfigFileContent
    Write-ConsoleLog "New config written to : $Path"
}
